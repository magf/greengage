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

- **Push events** to versioned release branch (`6.x`) after merged PR, or
  versioned release tags (`6.*`).
- **Pull requests** to any branch.

It executes the following jobs in a matrix strategy for multiple target
operating systems:

- **Build**: Constructs and pushes Docker images to the GitHub Container
  Registry (GHCR) with development commit SHA tag and branchname tag. Runs for
  pull requests and all push events (`6.x` and tags).
- **Tests**: Runs multiple test suites only for pull requests:
  - Behave tests
  - Regression tests
  - Orca tests
  - Resource group tests
- **Upload**: Retags and pushes final Docker images to GHCR and optionally
  DockerHub. Runs for push to `6.x` (retags to `latest`) and tags (uses
  tag like `6.28.2`) after build.

## Release Workflow

A separate workflow `Greengage release` handles the uploading of Debian
packages to GitHub releases. It is triggered when a release is published and
uses a composite action to manage package deployment.

### Key Features

- **Triggers:** `release: [published]` - Runs when a release is published,
including re-publishing.
- **Concurrency:** Uses the same concurrency group as the CI workflow
  (`Greengage CI-${{ github.ref }}`) to ensure proper sequencing and prevent
  race conditions.
- **Multi-OS Matrix:** Builds and uploads packages for ubuntu 22.04 and
  ubuntu 24.04 in parallel.
- **Artifact-based Packages:** Downloads built packages as an artifact of the
  successful CI run for the tag (named
  `{artifact_prefix}-{target_os}{target_os_version}`). If the artifact is not
  found, falls back to restoring packages from cache.
- **OS-specific Filenames:** Inserts `~{target_os}{target_os_version}` into
  each package filename before the architecture suffix prior to upload
  (e.g. `greengage6_6.30.1_amd64.deb` → `greengage6_6.30.1~ubuntu24.04_amd64.deb`).
- **Manual Recovery:** If neither the artifact nor the cache is found, the
  workflow reports an error with a link to the CI run and asks to re-run it.
  It does not automatically trigger builds to avoid infinite loops.
- **Safe Uploads:** Uploads packages with fixed naming patterns and optional
  overwrite (`clobber` flag).

### Behavior

1. **Normal Flow (Artifact Available):** Waits for the CI run of the tag to
   succeed, downloads the package artifact, inserts
   `~{target_os}{target_os_version}` into each package filename before the
   architecture suffix, and uploads the packages to the release.
2. **Artifact Missing:** Tries to restore packages from cache. If the cache is
   also missing, reports an error with a link to the CI run and requires
   re-running it.
3. **CI Run Failed:** Reports the failure with a link to the failed run and
   requires manual fixing before retrying.

The release workflow is designed to be robust and provide clear feedback when
issues occur, ensuring that releases are always consistent and reliable.

## Configuration

The workflow is parameterized to support flexibility:

- **Version**: Specifies the Greengage version (e.g., `6`), hardcoded in the
  CI workflow for branch `6.x`.
- **Target OS**: Supports multiple operating systems, defined in the matrix
  strategy. Ubuntu 22.04 uses no version suffix for backward compatibility with
  existing artifact naming; Ubuntu 24.04 support is available.

## Usage

To use this pipeline:

1. Ensure the repository has a valid `GITHUB_TOKEN` with `packages: read`
   permissions for GHCR access and `actions: write` for artifact upload.
2. Configure DockerHub credentials (`DOCKERHUB_TOKEN`, `DOCKERHUB_USERNAME`)
   for DockerHub uploads:
   - For `greengagedb/greengage`: mandatory — login failure will stop the
     workflow.
   - For other repositories: optional — login failure is allowed and other
     processes (GHCR upload, etc.) are unaffected.
3. Configure the version and target OS parameters in the branch-specific
   workflow configuration.
4. Create a pull request or push to `6.x` or tag (`6.*`) to trigger the
   pipeline.

## Important Notes on `target_os_version`

> **⚠️ BACKWARD COMPATIBILITY WARNING**
>
> For `ubuntu`, specifying `target_os_version: "22.04"` explicitly is **not
> recommended** and may break backward compatibility with previous CI versions.
>
> **Reason**: In earlier CI versions, Ubuntu version was not versioned — it was
> hardcoded as the only possible option. The version did not appear anywhere in
> the configuration.
>
> **Recommended approach**:
> - For `ubuntu`, **omit** `target_os_version` (leave it empty) to use the
>   default behavior.
> - Specify `target_os_version: "24.04"` only when you explicitly need Ubuntu
>   24.04.
>
> **Example**:
> ```yaml
> # Correct for default Ubuntu (recommended)
> - target_os: ubuntu
>
> # Correct for explicit Ubuntu 24.04
> - target_os: ubuntu
>   target_os_version: "24.04"
>
> # NOT recommended (breaks backward compatibility)
> - target_os: ubuntu
>   target_os_version: "22.04"
> ```
>
> **Note**: The release workflow (`greengage-release.yml`) is exempt from this
> rule — it explicitly sets `target_os_version` for all matrix entries to
> ensure unambiguous artifact name matching with the build workflow.

## Additional Documentation

Detailed README files for each process are available in the directory [README](https://github.com/greengagedb/greengage-ci/blob/main/README/)
of the `greengagedb/greengage-ci` repository:

- Build process:
  [README/REUSABLE-BUILD.md](https://github.com/greengagedb/greengage-ci/blob/main/README/REUSABLE-BUILD.md)
- Package process:
  [README/REUSABLE-PACKAGE.md](https://github.com/greengagedb/greengage-ci/blob/main/README/README/REUSABLE-PACKAGE.md)
- Behave tests:
  [README/REUSABLE-TESTS-BEHAVE.md](https://github.com/greengagedb/greengage-ci/blob/main/README/REUSABLE-TESTS-BEHAVE.md)
- Orca tests:
  [README/REUSABLE-TESTS-ORCA.md](https://github.com/greengagedb/greengage-ci/blob/main/README/REUSABLE-TESTS-ORCA.md)
- Regression tests:
  [README/REUSABLE-TESTS-REGRESSION.md](https://github.com/greengagedb/greengage-ci/blob/main/README/REUSABLE-TESTS-REGRESSION.md)
- Resource group tests:
  [README/REUSABLE-TESTS-RESGROUP.md](https://github.com/greengagedb/greengage-ci/blob/main/README/REUSABLE-TESTS-RESGROUP.md)
- Upload process:
  [README/REUSABLE-UPLOAD.md](https://github.com/greengagedb/greengage-ci/blob/main/README/REUSABLE-UPLOAD.md)

## Notes

- The pipeline uses `fail-fast: false` for build and package jobs, and
  `fail-fast: true` for test jobs.
- Tests (behave, regression, orca, resgroup) run only for pull requests.
- Upload runs only for push events to `6.x` or tags (`6.*`).
- Package job rebuilds production-ready version without debug extensions and
  creates Debian packages for release.
- For `greengagedb/greengage`, DockerHub credentials (`DOCKERHUB_TOKEN`,
  `DOCKERHUB_USERNAME`) are mandatory — login failure will stop the workflow.
  For other repositories they are optional — if missing or invalid, DockerHub
  upload is skipped but other processes (GHCR upload, etc.) are unaffected.
- For specific details on each stage, refer to the respective reusable workflow
  files and their READMEs in the `greengagedb/greengage-ci` repository.
