# CI migration rules

## Google Cloud Build

### Trigger Rules

To replicate the GitLab CI rules in Google Cloud Build for the `magf/greengage` repository in project `tactile-acrobat-461712-m0`, we define triggers for branches matching `^(7\.x|main)$`, tags matching `^7\..*`, and pull requests to `7.x` or `main`.

### Prerequisites

- **Project**: `tactile-acrobat-461712-m0`
- **Repository**: `magf/greengage` (connected via Cloud Build GitHub App, 2nd gen)
- **Connection**: `github-magf-connection`
- **Region**: `europe-west4`
- **Build Config**: `cloudbuild.yaml` in the repository root
- **Artifact Registry**: Repository `greengage` in `europe-west4`
- **Submodules**: `gpAux/extensions/pgbouncer/source`, `gpcontrib/gpcloud/test/googletest`

### Trigger Configuration

#### Trigger for Push to Branch (7.x or main)

**Purpose**: Build for pushes to branches `7.x` or `main`.

- **Name**: `build-gpdb7-branch`
- **Region**: `europe-west4`
- **Event**: Push to a Branch
- **Source**: `magf/greengage`
- **Branch**: `^7\.x$|^main$`
- **Build Config**: `/cloudbuild.yaml`
- **Substitutions**:

  ```yaml
  _IMAGE_VERSION: 7
  _SOURCE_BRANCH: $BRANCH_NAME
  ```

**Console Setup**:

1. Go to **Cloud Build** → **Triggers**.
2. Click **Create Trigger**.
3. Set Name to `build-gpdb7-branch`, Region to `europe-west4`.
4. Select **Push to a branch**, Branch to `^7\.x$|^main$`.
5. Set Repository to `github-magf-connection/greengage`.
6. Set Build Config to `/cloudbuild.yaml`.
7. Add Substitutions: `_IMAGE_VERSION=7`, `_SOURCE_BRANCH=$BRANCH_NAME`.
8. Click **Create**.
**CLI Setup**:

```bash
gcloud builds triggers create github \
  --project=tactile-acrobat-461712-m0 \
  --region=europe-west4 \
  --name=build-gpdb7-branch \
  --repository=projects/tactile-acrobat-461712-m0/locations/europe-west4/connections/github-magf-connection/repositories/greengage \
  --branch-pattern="^7\.x$|^main$" \
  --build-config=cloudbuild.yaml \
  --substitutions="_IMAGE_VERSION=7,_SOURCE_BRANCH=\$BRANCH_NAME"
```

#### Trigger for Push New Tag (7.*)

**Purpose**: Build for tags starting with `7.` (e.g., `7.0.0`).

- **Name**: `build-gpdb7-tag`
- **Region**: `europe-west4`
- **Event**: Push New Tag
- **Source**: `magf/greengage`
- **Tag**: `^7\..*`
- **Build Config**: `/cloudbuild.yaml`
- **Substitutions**:

  ```yaml
  _IMAGE_VERSION: 7
  ```

**Console Setup**:

1. Create Trigger, Name `build-gpdb7-tag`.
2. Select **Push new tag**, Tag to `^7\..*`.
3. Set Repository to `github-magf-connection/greengage`.
4. Add Substitution: `_IMAGE_VERSION=7`.
5. Set Build Config to `/cloudbuild.yaml`.
**CLI Setup**:

```bash
gcloud builds triggers create github \
  --project=tactile-acrobat-461712-m0 \
  --region=europe-west4 \
  --name=build-gpdb7-tag \
  --repository=projects/tactile-acrobat-461712-m0/locations/europe-west4/connections/github-magf-connection/repositories/greengage \
  --tag-pattern="^7\..*" \
  --build-config=cloudbuild.yaml \
  --substitutions="_IMAGE_VERSION=7"
```

#### Trigger for Pull Request (7.x or main)

**Purpose**: Build for pull requests targeting `7.x` or `main`.

- **Name**: `build-gpdb7-pr`
- **Region**: `europe-west4`
- **Event**: Pull Request
- **Source**: `magf/greengage`
- **Branch**: `^7\.x$|^main$`
- **Build Config**: `/cloudbuild.yaml`
- **Substitutions**:

  ```yaml
  _IMAGE_VERSION: 7
  _SOURCE_BRANCH: $BRANCH_NAME
  _TARGET_BRANCH: $PULL_REQUEST
  _PULL_REQUEST_NUMBER: $PULL_REQUEST_NUMBER
  ```

**Console Setup**:

1. Create Trigger, Name `build-gpdb7-pr`.
2. Select **Pull Request**, Branch to `^7\.x$|^main$`.
3. Set Repository to `github-magf-connection/greengage`.
4. Add Substitutions: `_IMAGE_VERSION=7`, `_SOURCE_BRANCH=$BRANCH_NAME`, `_TARGET_BRANCH=$PULL_REQUEST`, `_PULL_REQUEST_NUMBER=$PULL_REQUEST_NUMBER`.
5. Set Build Config to `/cloudbuild.yaml`.
**CLI Setup**:

```bash
gcloud builds triggers create github \
  --project=tactile-acrobat-461712-m0 \
  --region=europe-west4 \
  --name=build-gpdb7-pr \
  --repository=projects/tactile-acrobat-461712-m0/locations/europe-west4/connections/github-magf-connection/repositories/greengage \
  --pull-request-pattern="^7\.x$|^main$" \
  --build-config=cloudbuild.yaml \
  --substitutions="_IMAGE_VERSION=7,_SOURCE_BRANCH=\$BRANCH_NAME,_TARGET_BRANCH=\$PULL_REQUEST,_PULL_REQUEST_NUMBER=\$PULL_REQUEST_NUMBER"
```

### Testing Triggers

To test:

1. **Push to a branch**:

   ```bash
   git clone https://github.com/magf/greengage.git
   cd greengage
   git checkout -b 7.x
   git commit --allow-empty -m "Test branch trigger"
   git push origin 7.x
   ```

   ```bash
   git checkout main
   git commit --allow-empty -m "Test main trigger"
   git push origin main
   ```

2. **Push a tag**:

   ```bash
   git tag 7.0.0
   git push origin 7.0.0
   ```

3. **Create a PR**:

   ```bash
   git checkout -b feature/test
   git commit --allow-empty -m "Test PR"
   git push origin feature/test
   gh pr create --base 7.x --head feature/test --title "Test PR" --body "Test"
   ```

4. Check builds:

   ```bash
   gcloud builds list --project=tactile-acrobat-461712-m0
   ```

### Troubleshooting

- **Trigger not firing**:
  - Verify repository connection in **Triggers**.
  - Check GitHub webhook: `https://github.com/magf/greengage/settings/hooks`.
  - Ensure regex `^7\.x$|^main$` matches branch.
- **Build fails**:
  - Check logs:

    ```bash
    gcloud builds log $(gcloud builds list --project=tactile-acrobat-461712-m0 --limit=1 --format="value(id)")
    ```

  - Verify `ci/Dockerfile.ubuntu` and submodules.
- **Permissions**:

  ```bash
  gcloud projects add-iam-policy-binding tactile-acrobat-461712-m0 \
    --member=serviceAccount:844888677936@cloudbuild.gserviceaccount.com \
    --role=roles/cloudbuild.builds.builder
  ```
