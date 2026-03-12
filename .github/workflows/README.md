# Greengage CI Workflow

This directory contains the CI pipelines for the Greengage project,
orchestrating the build, test, and upload stages for containerized
environments. The pipeline is designed to be flexible, with parameterized
inputs for version and target operating systems, allowing it to adapt to
different branches and configurations.

## ⚠️ Important Notice

Whenever the list of **NAMES of required jobs** in the workflow (including any
**reusable workflows**) is **added, removed, or renamed**, you must contact a
repository administrator to update the **Branch Protection Rules** accordingly.
Without this, new, deleted, or renamed jobs will not be recognized as required
when checking Pull Requests.

## Overview

The `Greengage CI` workflow triggers on:

- **Push events** to `main` branch (after merged PR) or versioned release tags
  (`6.*`).
- **Pull requests** to any branch.

It executes the following jobs in a matrix strategy for multiple target
operating systems:

- **Build**: Constructs and pushes Docker images to the GitHub Container
  Registry (GHCR) with development commit SHA tag and branchname tag. Runs for
  pull requests and all push events (main and tags).
- **Tests**: Runs multiple test suites only for pull requests, including:
  - Behave tests
  - Regression tests
  - Orca tests
  - Resource group tests
- **Upload**: Retags and pushes final Docker images to GHCR and optionally
  DockerHub. Runs for push to `main` (retags to `latest`) and tags (uses tag
  like `6.28.2`) after build.

## Release Workflow

A separate workflow `Greengage release` handles the uploading of Debian package
to GitHub releases. It is triggered when a release is published and uses a
composite action to manage package deployment.

### Key Features

- **Triggers:** `release: [published]` - Runs when a release is published,
including re-publishing.
- **Concurrency:** Uses the same concurrency group as the CI workflow
(`Greengage CI-${{ github.ref }}`) to ensure proper sequencing and prevent race
conditions.
- **Cache-based Artifacts:** Restores built packages from cache using the
commit SHA as the key, rather than downloading artifacts from previous jobs.
- **Manual Recovery:** If the cache is missing, the workflow checks the status
of the last build for the tag and provides clear instructions for manual
intervention. It does not automatically trigger builds to avoid infinite loops.
- **Safe Uploads:** Uploads packages with fixed naming patterns and optional
overwrite (`clobber` flag).

### Behavior

1. **Normal Flow (Cache Available):** Restores packages from cache, renames
them to the pattern `${PACKAGE_NAME}${VERSION}.${EXT}`, and uploads to the
release.
2. **Cache Miss Scenarios:**
   - **No previous build or previous build successful:** Provides instructions
   to manually trigger the CI build, then restart the release workflow.
   - **Previous build failed:** Reports the failure with a link to the failed
   run and requires manual fixing before retrying.

The release workflow is designed to be robust and provide clear feedback when
issues occur, ensuring that releases are always consistent and reliable.

## SQL Dump Workflow

A separate workflow `Greengage SQL Dump` is responsible for generating SQL dump
artifacts after the main CI process completes successfully. It is triggered
automatically upon the completion of the `Greengage CI` workflow.

### Key Features

- **Triggers:** `workflow_run: workflows: ["Greengage CI"], types: [completed]`
- **Branch Targeting:** Runs only for the `main` and `7.x` branches.
- **Version Detection:** Automatically determines the database version (6 or 7)
based on the triggering branch.
- **Matrix Strategy:** Runs across multiple OS configurations (e.g., `ubuntu`,
`ubuntu24.04`) to generate dumps for all available build targets.
- **Image Existence Check:** Before creating a SQL dump, the workflow checks
if the Docker image exists in GHCR using `docker manifest inspect`. This handles
cases where the matrix includes OS versions for which no image was built.
- **Conditional Dump Generation:** If the image exists, the workflow runs the
regression test suite with the `dump_db: "true"` parameter to generate a SQL
dump archive. If the image does not exist, the dump creation and upload steps
are skipped for that matrix entry.
- **Artifact Upload:** Uploads the generated SQL dump archive as a named
artifact (e.g., `sqldump_ggdb7_ubuntu24.04`).
- **Verification Job:** A final job checks if at least one SQL dump was created
across all matrix configurations. If no images were found (and thus no dumps
created), the workflow fails with an error.
- **Controlled Execution:** Since the main CI workflow runs on `main` and `7.x`
branches only for push events (which occur after final merge of a PR), SQL dump
are generated exclusively for verified, approved patches after they are merged
into the main branches.
- **Artifact Retention:** The generated SQL dump artifact is retained 90 days
after the last download. Each new run of the `behave tests gpexpand` workflow
(which consumes this artifact as a consumer) resets this retention period to
90 days when it downloads the artifact.

### Behavior

1. **Triggering:** Automatically starts after the `Greengage CI` workflow
finishes on the `main` or `7.x` branch.
2. **Preparation:** Configures Docker storage on the runner to utilize
`/mnt/docker` for increased disk space.
3. **Version Mapping:** Maps the branch name (`main` -> version 6, `7.x` ->
version 7) and constructs the expected Docker image name.
4. **Image Existence Check:** For each matrix entry, checks if the Docker image
exists in GHCR using `docker manifest inspect`. Sets `exists=true` if found,
`exists=false` otherwise.
5. **Conditional Dump Generation:** If `exists=true`, runs the regression test
suite with the `dump_db` option enabled, which creates a `*_postgres_sqldump.tar`
file. If `exists=false`, skips dump creation for that matrix entry.
6. **Artifact Upload:** If `exists=true`, uploads the generated SQL dump archive
as a named artifact (e.g., `sqldump_ggdb7_ubuntu24.04`).
7. **Artifact Info Export:** Saves artifact name and URL to job outputs for
use by the verification job.
8. **Verification and Report:** A final verification job:
   - Collects results from all matrix entries
   - Displays a report with artifact names and URLs
   - Counts successful dump creations
   - Fails the workflow if no dumps were created (zero images found)
   - Succeeds if at least one dump was created

This workflow ensures that a current database schema dump is available as an
artifact following successful CI runs on the primary branches `main` and `7.x`.

## Configuration

The workflow is parameterized to support flexibility:

- **Version**: Specifies the Greengage version (e.g., `6`), configurable per
  branch.
- **Target OS**: Supports multiple operating systems, defined in the matrix
  strategy.

All jobs use reusable workflows stored in the `greengagedb/greengage-ci`
repository, accessible publicly for detailed inspection.

## Usage

To use this pipeline:

1. Ensure the repository has a valid `GITHUB_TOKEN` with `packages: write`
   permissions for GHCR access.
2. Optionally configure `DOCKERHUB_TOKEN` and `DOCKERHUB_USERNAME` for
   DockerHub uploads.
3. Configure the version and target OS parameters in the branch-specific
   workflow configuration.
4. Create a pull request or push a tag (`6.*`) to trigger the pipeline.

## Additional Documentation

Detailed README files for each process are available in the `README` directory
of the `greengagedb/greengage-ci` repository. For example:

- Build process:
  [README/REUSABLE-BUILD.md](https://github.com/greengagedb/greengage-ci/blob/main/README/REUSABLE-BUILD.md)
- Behave tests:
  [README/REUSABLE-TESTS-BEHAVE.md](https://github.com/greengagedb/greengage-ci/blob/main/README/REUSABLE-TESTS-BEHAVE.md)
- Regression tests:
  [README/REUSABLE-TESTS-REGRESSION.md](https://github.com/greengagedb/greengage-ci/blob/main/README/REUSABLE-TESTS-REGRESSION.md)
- Orca tests:
  [README/REUSABLE-TESTS-ORCA.md](https://github.com/greengagedb/greengage-ci/blob/main/README/REUSABLE-TESTS-ORCA.md)
- Resource group tests:
  [README/REUSABLE-TESTS-RESGROUP.md](https://github.com/greengagedb/greengage-ci/blob/main/README/REUSABLE-TESTS-RESGROUP.md)
- Upload process:
  [README/REUSABLE-UPLOAD.md](https://github.com/greengagedb/greengage-ci/blob/main/README/REUSABLE-UPLOAD.md)

## Notes

- The pipeline uses a `fail-fast: false` strategy to ensure all matrix entries
  are executed, even if one fails. This allows the SQL Dump workflow to check
  all OS configurations and skip missing images gracefully.
- The full process, including build, tests, and upload, runs only before pull
  request approval. For push events (main or tags), a build occurs to ensure
  correct commit references and product version, using the closest tag to HEAD,
  followed by upload. If DockerHub credentials (`DOCKERHUB_TOKEN`,
  `DOCKERHUB_USERNAME`) are missing or invalid, DockerHub upload is skipped,
  but other processes (GHCR upload, etc.) are unaffected.
- For specific details on each stage, refer to the respective reusable workflow
  files and their READMEs in the `greengagedb/greengage-ci` repository.
