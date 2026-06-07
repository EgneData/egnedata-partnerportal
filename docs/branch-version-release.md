# Branch, Version, and Release

## Branch → build-type → version → image

| Branch        | Build type     | Version format                            | Git tag?     | Images pushed? |
|---------------|----------------|-------------------------------------------|--------------|----------------|
| `main`        | `RELEASE`      | `<major>.<minor>.<patch>`                 | Yes `v1.7.0` | yes            |
| `develop`     | `STAGE`        | `0.YYYYMMDD.9HHMMSS-rc.<short-sha>`       | No           | yes            |
| `feature/*`   | `FEATURE`      | `0.YYYYMMDD.9HHMMSS-beta.<short-sha>`     | No           | yes            |
| `hotfix/*`    | `HOTFIX`       | `0.YYYYMMDD.9HHMMSS-beta.<short-sha>`     | No           | yes            |
| pull requests | `PULL_REQUEST` | `0.1.2-SNAPSHOT`                          | No           | no             |
| `dependabot/*`| `DEPENDABOT`   | `0.1.2-SNAPSHOT`                          | No           | no             |
| other         | `OTHER`        | `0.1.2-SNAPSHOT`                          | No           | no             |

Timestamps use `TZ='Europe/Oslo'` (correct DST). `stage` pre-release suffix is `-rc.`; `feature`/`hotfix` use `-beta.`.

## Image paths on ghcr.io

Base: `ghcr.io/egnedata/egnedata-partnerportal/`

| Build type | Image path                                                         | Moving tag |
|------------|--------------------------------------------------------------------|------------|
| `RELEASE`  | `release/{server,intermediate}:<version>`                          | `latest`   |
| `STAGE`    | `stage/{server,intermediate}:<version>`                            | `stage`    |
| `FEATURE`  | `features/<sanitized-branch>-<7hex>/{server,intermediate}:<version>` | none     |
| `HOTFIX`   | `hotfix/<sanitized-branch>-<7hex>/{server,intermediate}:<version>` | none       |

Branch sanitization: strip `feature/`/`hotfix/` prefix, lowercase, replace invalid chars with `-`, collapse runs, trim to ~100 chars, append 7-char SHA1 of the full ref for uniqueness.

Example release ref: `ghcr.io/egnedata/egnedata-partnerportal/release/server:1.7.0`

## Release process

Releases flow `develop` → `main` via fast-forward merge only. Two equivalent entry points:

**Option 1 — GitHub Actions** ([`release-to-main.yml`](../.github/workflows/release-to-main.yml)):

1. Actions → **Release to Main** → **Run workflow**
2. Select branch `develop`.
3. Enter the version (e.g. `v1.8.0`) or leave empty for a merge-only run.
4. Tick **Dry run** to preview without pushing.

**Option 2 — local script** ([`bin/release_to_main.sh`](../bin/release_to_main.sh)):

```sh
git checkout develop && git pull

bin/release_to_main.sh            # merge only (tag computed by build.yml)
bin/release_to_main.sh v1.8.0     # merge + pre-mint tag locally
bin/release_to_main.sh --dry-run  # preview
```

After either entry point pushes to `main`, [`build.yml`](../.github/workflows/build.yml) takes over:

1. Full test gate (Java server, intermediate, Flutter, bats).
2. `semantic-version` computes the next semver from existing `v*` tags.
3. `tag-release` mints `v<version>` on the merge commit.
4. `docker-publish` pushes `release/{server,intermediate}:<version>` and `:latest`.

## Dry run — feature path smoke test

[`bin/ci-dry-run.sh`](../bin/ci-dry-run.sh) pushes a probe commit to a throwaway `feature/ci-dry-run-<sha>` branch, watches the `build.yml` run, and asserts the computed image path contains the correct `features/<sanitized>-<7hex>/{server,intermediate}` pattern — without writing anything to the registry.

```sh
bash bin/ci-dry-run.sh          # run smoke test, delete remote branch on success
bash bin/ci-dry-run.sh --keep   # leave remote branch for inspection
```

## Cutover — enabling image publishing

Publishing is gated behind a **repository variable**. Until it is set, every `docker-publish` run builds the images but pushes nothing (`push: false` — a genuine dry run):

```sh
gh variable set PUBLISH_IMAGES --body true
```

That single command is the go-live switch. Once set:

- `RELEASE`, `STAGE`, `FEATURE`, and `HOTFIX` runs push images to ghcr.
- `PULL_REQUEST`, `DEPENDABOT`, and `OTHER` runs never push regardless of the variable.

**First-time visibility**: a newly created ghcr package defaults to private. After the first push, open the package settings on GitHub and set visibility to public (or leave private if that is intentional).
