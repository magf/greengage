#!/bin/bash
#
# ci/scripts/run_pgupgrade_test.bash
#
# Wrapper for running the pg_upgrade (Greengage 6 -> Greengage 7) test
# inside the docker image built from ci/Dockerfile.pg_upgrade. This script
# only owns the docker invocation, so it can be called the same way from
# any CI (GitHub Actions, Concourse, local shell, etc), keeping the CI
# definition itself formal/thin. The setup and test scripts it runs inside
# the container are configurable so this wrapper doesn't need editing if
# those paths ever move.
#
# Required environment variables:
#   IMAGE           - pg_upgrade docker image (both GG6 and GG7 installs)
#   SQL_DUMP        - path on the host to a GG6 SQL dump to load before the
#                     upgrade
#
# Optional environment variables:
#   LOGS            - host directory to store logs (default: $PWD/logs)
#   SETUP_SCRIPT    - path *inside the image* to the `gpadmin' setup script,
#                     run as root before the test
#                     (default: gpdb_src/concourse/scripts/setup_gpadmin_user.bash)
#   TEST_SCRIPT     - path *inside the image* to the pg_upgrade test script,
#                     run as `gpadmin'
#                     (default: gpdb_src/ci/scripts/pg_upgrade_run_6X_to_7X_migration.bash)
#   CLEANUP_SCRIPT  - path *inside the image* to a filter script, forwarded
#                     to test_gpdb.sh -f
#                     (default: gpdb_src/src/bin/pg_upgrade/cleanup_regression_dump_from_6X.sql)
#   DUMP_OPTIONS    - extra options for the pre/post-upgrade pg_dump, forwarded
#                     to test_gpdb.sh -d (default: --data-only --extra-float-digits=-3)

set -euo pipefail

LOGS=${LOGS:-$PWD/logs}
SETUP_SCRIPT=${SETUP_SCRIPT:-gpdb_src/concourse/scripts/setup_gpadmin_user.bash}
TEST_SCRIPT=${TEST_SCRIPT:-gpdb_src/ci/scripts/pg_upgrade_run_6X_to_7X_migration.bash}
CLEANUP_SCRIPT=${CLEANUP_SCRIPT:-gpdb_src/src/bin/pg_upgrade/cleanup_regression_dump_from_6X.sql}
DUMP_OPTIONS=${DUMP_OPTIONS:---data-only --extra-float-digits=-3}

# Only what actually needs to cross into the container via `docker run -e
# NAME` (no `=value`) has to be exported - LOGS stays host-side (used only
# for the -v mount below).
export SETUP_SCRIPT TEST_SCRIPT CLEANUP_SCRIPT DUMP_OPTIONS

unset_vars=()
for var in IMAGE SQL_DUMP; do
    if [ -z "${!var:-}" ]; then
        echo "This test expects the environment variable: $var"
        unset_vars+=("$var")
    fi
done

if [ "${#unset_vars[@]}" -gt 0 ]; then
    echo "Not set required $(IFS=', '; echo "${unset_vars[*]}") var(s). Exiting."
    exit 1
fi

SQL_DUMP=$(realpath "$SQL_DUMP")
if [ ! -f "$SQL_DUMP" ]; then
    echo "SQL_DUMP is set to '$SQL_DUMP', but no such file exists. Exiting."
    exit 1
fi

echo "SETUP_SCRIPT: $SETUP_SCRIPT"
echo "TEST_SCRIPT: $TEST_SCRIPT"
echo "CLEANUP_SCRIPT: $CLEANUP_SCRIPT"
echo "DUMP_OPTIONS: $DUMP_OPTIONS"

mkdir -p "$LOGS"

set -x

# NB: the heredoc delimiter is quoted ('EOF') on purpose - nothing inside it
# is expanded on the host. SETUP_SCRIPT/TEST_SCRIPT/SQL_SCHEMA/
# CLEANUP_SCRIPT/DUMP_OPTIONS are container-side env vars, passed in
# through -e above.
docker run -i \
  -v "$LOGS":/logs \
  -v "$SQL_DUMP":/dump.sql:ro \
  -e SQL_SCHEMA=/dump.sql \
  -e SETUP_SCRIPT \
  -e TEST_SCRIPT \
  -e CLEANUP_SCRIPT \
  -e DUMP_OPTIONS \
  "$IMAGE" /bin/bash << 'EOF'
set -eo pipefail

"$SETUP_SCRIPT"
su gpadmin "$TEST_SCRIPT"
EOF
