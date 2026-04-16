# ProxmoxVE Contribution Agent Guide

This file is a repo-grounded operating manual for adding or modifying Proxmox VE helper scripts here, especially new `ct/` container scripts and their matching `install/` scripts.

It is based on the current repository structure, contribution docs, workflow files, helper-library docs, and live source code in `misc/*.func`, `ct/`, `install/`, and `.github/`.

## Scope

Use this guide when:

- adding a new container script in `ct/`
- adding the matching install script in `install/`
- updating an existing script pair
- preparing a contribution for upstream review

Do not treat this as generic shell advice. Follow repo patterns first.

## Canonical Sources In This Repo

Start here:

- `README.md`
- `docs/README.md`
- `docs/contribution/README.md`
- `docs/contribution/CONTRIBUTING.md`
- `docs/contribution/GUIDE.md`
- `docs/contribution/AI.md`
- `docs/contribution/FORK_SETUP.md`
- `docs/contribution/CODE-AUDIT.md`
- `docs/contribution/HELPER_FUNCTIONS.md`

Script-specific docs:

- `docs/ct/README.md`
- `docs/ct/DETAILED_GUIDE.md`
- `docs/install/README.md`
- `docs/install/DETAILED_GUIDE.md`
- `docs/contribution/templates_ct/AppName.sh`
- `docs/contribution/templates_install/AppName-install.sh`
- `docs/contribution/templates_json/AppName.md`

Architecture and runtime behavior:

- `docs/TECHNICAL_REFERENCE.md`
- `docs/DEV_MODE.md`
- `docs/EXIT_CODES.md`
- `docs/guides/DEFAULTS_SYSTEM_GUIDE.md`
- `docs/guides/CONFIGURATION_REFERENCE.md`
- `docs/guides/UNATTENDED_DEPLOYMENTS.md`
- `docs/misc/README.md`
- `docs/misc/build.func/README.md`
- `docs/misc/build.func/BUILD_FUNC_ENVIRONMENT_VARIABLES.md`
- `docs/misc/install.func/README.md`
- `docs/misc/tools.func/README.md`

Ground truth in code:

- `misc/build.func`
- `misc/core.func`
- `misc/install.func`
- `misc/tools.func`
- `misc/alpine-install.func`
- `misc/alpine-tools.func`

Contribution process and enforcement:

- `.editorconfig`
- `.github/pull_request_template.md`
- `.github/workflows/close-new-script-prs.yml`
- `.github/CODEOWNERS`
- `.github/CODE_OF_CONDUCT.md`
- `SECURITY.md`

Useful real script references:

- `ct/sparkyfitness.sh` + `install/sparkyfitness-install.sh`
- `ct/open-archiver.sh` + `install/open-archiver-install.sh`
- `ct/nginx-ui.sh` + `install/nginx-ui-install.sh`
- `ct/qdrant.sh`
- `ct/hev-socks5-server.sh`
- `ct/duplicati.sh`
- `install/miniflux-install.sh`

## Non-Negotiable Repo Truths

1. A new container app contribution is normally a pair:
   - `ct/<name>.sh`
   - `install/<name>-install.sh`

2. The CT script runs on the Proxmox host.

3. The install script runs inside the container.

4. Container apps are installed bare-metal inside the container.
   - Do not solve app installation by using Docker unless the app itself is explicitly a Docker-oriented helper script.

5. Prefer repo helper functions over custom logic.
   - Use `setup_*`, `check_for_gh_release`, `fetch_and_deploy_gh_release`, DB helpers, cleanup helpers, etc.

6. Website metadata is not committed as repo JSON.
   - Request or update it via the website’s “Report issue” flow.

7. Header art is a real sidecar in this repo.
   - `header_info()` downloads `ct/headers/<nsapp>`.
   - In practice, a new CT script should also add `ct/headers/<nsapp>` to avoid runtime warnings.

8. Committed source URLs must point back to upstream `community-scripts/ProxmoxVE`, not your fork, and not `ProxmoxVED`.

9. Testing during development is done by pushing to your fork and running the CT script via `curl`, not by `bash ct/foo.sh`.

10. If the end goal is an upstream new-script PR, repo automation matters:
   - `.github/workflows/close-new-script-prs.yml` and `.github/pull_request_template.md` indicate unauthorized new-script PRs to `community-scripts/ProxmoxVE` can be closed and should go through `community-scripts/ProxmoxVED` first for testing/review.

## Repository Execution Model

### CT path

`ct/<app>.sh`:

- sources `misc/build.func`
- defines app defaults
- initializes:
  - `header_info "$APP"`
  - `variables`
  - `color`
  - `catch_errors`
- optionally defines `update_script()`
- calls:
  - `start`
  - `build_container`
  - `description`

### Install path

`build_container()` in `misc/build.func`:

- derives the install script name from `APP`
- exports `FUNCTIONS_FILE_PATH`
- downloads either:
  - `misc/install.func` for Debian/Ubuntu
  - `misc/alpine-install.func` for Alpine
- installs base bootstrap packages in the container before the install script runs:
  - `sudo`
  - `curl`
  - `mc`
  - `gnupg2`
  - `jq`
- executes:
  - `install/${var_install}.sh`

`install/<app>-install.sh`:

- sources `$FUNCTIONS_FILE_PATH`
- initializes:
  - `color`
  - `verb_ip6`
  - `catch_errors`
  - `setting_up_container`
  - `network_check`
  - `update_os`
- performs app installation/configuration
- finishes with:
  - `motd_ssh`
  - `customize`
  - `cleanup_lxc`

## Naming Rules That Actually Matter

The live code in `misc/build.func` is the key rule:

- `NSAPP=$(echo "${APP,,}" | tr -d ' ')`
- `var_install="${NSAPP}-install"`

Implications:

1. The install script name is derived from `APP`, not from the CT filename.

2. Spaces in `APP` are removed for `NSAPP`.

3. Hyphens in `APP` are preserved.

Examples:

- `APP="Pihole"` -> `NSAPP="pihole"` -> install script `install/pihole-install.sh`
- `APP="Nginx-UI"` -> `NSAPP="nginx-ui"` -> install script `install/nginx-ui-install.sh`
- `APP="Open-Archiver"` -> `NSAPP="open-archiver"` -> install script `install/open-archiver-install.sh`

Practical rule:

- choose `APP` carefully so its normalized form matches:
  - the install filename
  - the header file name under `ct/headers/`
  - usually the website/script slug too

Why this matters beyond filenames:

- `build_container()` uses `var_install="${NSAPP}-install"`
- `customize()` writes `/usr/bin/update` that curls `ct/${app}.sh`
- `description()` builds the script page link from `SCRIPT_SLUG` or `NSAPP`

If the public website slug should differ from `NSAPP`, set `SCRIPT_SLUG` explicitly in the CT script.

File naming in the live repo is lowercase and usually hyphenated. Follow that pattern for new files.

## Required Sidecar Files For A New CT Contribution

Usually create all of the following:

- `ct/<nsapp>.sh`
- `install/<nsapp>-install.sh`
- `ct/headers/<nsapp>`

Out-of-repo follow-up:

- website metadata request via website “Report issue”

Not repo-tracked contribution files:

- `/usr/local/community-scripts/default.vars`
- `/usr/local/community-scripts/defaults/<nsapp>.vars`

Those defaults files are runtime/user state, not contribution artifacts.

## CT Script Contract

Modern CT scripts follow this shape:

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright...
# Author...
# License...
# Source...

APP="MyApp"
var_tags="${var_tags:-tag1;tag2}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  ...
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:PORT${CL}"
```

### CT defaults

Common required defaults:

- `APP`
- `var_tags`
- `var_cpu`
- `var_ram`
- `var_disk`
- `var_os`
- `var_version`
- `var_unprivileged`

Common optional or advanced defaults supported by `build.func`:

- `var_hostname`
- `var_brg` / `var_bridge`
- `var_net`
- `var_gateway`
- `var_vlan`
- `var_mtu`
- `var_ipv6_method`
- `var_gpu`
- `var_tun`
- `var_fuse`
- `var_nesting`
- `var_ssh`
- `var_timezone`
- `var_template_storage`
- `var_container_storage`
- `var_protection`
- `var_verbose`

Default posture for new apps:

- Debian 13 unless app requires another OS
- unprivileged container unless the app truly requires privileged behavior

Use privileged only when justified by app behavior, device access, or nested/containerized requirements. Existing examples with `var_unprivileged=0` are generally special cases.

### CT update_script expectations

Preferred pattern:

1. `header_info`
2. `check_container_storage`
3. `check_container_resources`
4. verify installation exists
5. `check_for_gh_release ...`
6. stop services
7. back up user data/config
8. redeploy using `CLEAN_INSTALL=1 fetch_and_deploy_gh_release ...`
9. rebuild/reinstall dependencies if needed
10. restore user data/config
11. start services
12. `msg_ok "Updated successfully!"`
13. `exit`

Use helper functions:

- `check_for_gh_release`
- `fetch_and_deploy_gh_release`

Do not reimplement GitHub release comparison/download logic unless absolutely necessary.

Choose the right release mode:

- `tarball`
- `prebuild`
- `binary`
- `singlefile`

Reference patterns:

- tarball/update with rebuild: `ct/sparkyfitness.sh`, `ct/open-archiver.sh`
- prebuilt archive: `ct/nginx-ui.sh`
- binary package: `ct/duplicati.sh`, `ct/qdrant.sh`
- single binary: `ct/hev-socks5-server.sh`

## Install Script Contract

Modern install scripts follow this shape:

```bash
#!/usr/bin/env bash

# Copyright...
# Author...
# License...
# Source...

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y ...
msg_ok "Installed Dependencies"

...

motd_ssh
customize
cleanup_lxc
```

### Install script rules

1. Always source `$FUNCTIONS_FILE_PATH`.

2. Always initialize with:
   - `color`
   - `verb_ip6`
   - `catch_errors`
   - `setting_up_container`
   - `network_check`
   - `update_os`

3. Prefer helper functions for runtimes, repos, DBs, and release deployment.

4. Use `msg_info` and `msg_ok` around custom work blocks.

5. Use `$STD` for noisy shell commands.

6. End with:
   - `motd_ssh`
   - `customize`
   - `cleanup_lxc`

### Important repo nuance

`misc/install.func` already calls `get_lxc_ip` while loading, so `LOCAL_IP` is usually available immediately after sourcing `$FUNCTIONS_FILE_PATH`.

Calling `get_lxc_ip` explicitly is still acceptable when the script wants to be explicit or wants a refreshed value.

### Dependency policy

Add app-specific packages only.

Guaranteed bootstrap packages from `build_container()`:

- `sudo`
- `curl`
- `mc`
- `gnupg2`
- `jq`

Do not assume more than that from the base bootstrap path.

If your app needs other packages, install them explicitly or via helper functions.

### Logging rule

`setup_*` and similar helper functions already emit their own status output.

Do not wrap helper calls like these in extra `msg_info/msg_ok` blocks:

- `setup_nodejs`
- `setup_php`
- `setup_postgresql`
- `setup_postgresql_db`
- `setup_mariadb`
- `setup_mariadb_db`
- `setup_uv`
- `fetch_and_deploy_gh_release`

Use `msg_info/msg_ok` for custom steps you authored, not around helpers that already self-report.

## Helper Functions To Prefer

### GitHub release helpers

- `fetch_and_deploy_gh_release`
- `check_for_gh_release`
- `get_latest_github_release`

`fetch_and_deploy_gh_release` is the preferred release deployment mechanism and also handles version tracking.

### Runtime helpers

- `setup_nodejs`
- `setup_uv`
- `setup_go`
- `setup_rust`
- `setup_ruby`
- `setup_java`
- `setup_php`
- `setup_composer`

### Database helpers

- `setup_postgresql`
- `setup_postgresql_db`
- `setup_mariadb`
- `setup_mariadb_db`
- `setup_mysql`
- `setup_mongodb`
- `setup_meilisearch`

### Utility helpers

- `get_lxc_ip`
- `ensure_dependencies`
- `setup_ffmpeg`
- `setup_hwaccel`
- `setup_adminer`
- `create_self_signed_cert`
- `cleanup_lxc`

### Messaging and environment helpers

- `color`
- `catch_errors`
- `setting_up_container`
- `network_check`
- `update_os`
- `motd_ssh`
- `customize`

## Style And Formatting

From `.editorconfig` and current repo patterns:

- UTF-8
- LF line endings
- 2-space indentation
- max line length 120
- Markdown may keep trailing whitespace; scripts should stay tidy

Script style:

- shebang first line
- modern headers:
  - copyright
  - author
  - license
  - source
- use `[[ ... ]]` in Bash logic
- quote variables unless there is a deliberate reason not to
- keep multiline package installs readable
- prefer `/opt/<app>` for app payloads unless the app clearly belongs elsewhere

Author header guidance from docs:

- new scripts should use the modern `community-scripts ORG` header style
- add `Co-Author:` when collaboration warrants it

## ASCII Headers

`header_info()` pulls from:

- `ct/headers/<nsapp>`

If no header exists, the runtime attempts to download it and may warn on failure.

Practical rule:

- add a matching header file for every new CT script

Header filename must match normalized app name:

- lowercase
- spaces removed
- hyphens preserved if present in `APP`

## Defaults, Advanced Settings, And Non-Interactive Behavior

Configuration precedence:

1. environment variables
2. app defaults file
3. global defaults file
4. built-in CT defaults

Relevant docs:

- `docs/guides/DEFAULTS_SYSTEM_GUIDE.md`
- `docs/guides/CONFIGURATION_REFERENCE.md`
- `docs/misc/build.func/BUILD_FUNC_ENVIRONMENT_VARIABLES.md`

This matters when testing because environment overrides like `var_cpu`, `var_ram`, `var_version`, `var_net`, etc. can change behavior without editing the script.

## Dev Mode And Debugging

Useful dev modes from `docs/DEV_MODE.md` and `misc/core.func`:

- `motd`
- `keep`
- `trace`
- `pause`
- `breakpoint`
- `logs`
- `dryrun`

Example:

```bash
export dev_mode="motd,keep,trace,logs"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"
```

Use when:

- debugging failed installs
- preserving failed containers
- collecting detailed logs
- pausing between steps

Also use:

- `var_verbose=yes`
- `bash -n ct/myapp.sh`
- `bash -n install/myapp-install.sh`
- `shellcheck ct/myapp.sh`
- `shellcheck install/myapp-install.sh`

## Contribution Workflow

### Fork setup

For fork-based development, the repo’s documented workflow is:

1. fork the repository
2. clone your fork
3. run:

```bash
bash docs/contribution/setup-fork.sh --full
```

That rewrites hardcoded URLs to point to the fork for realistic testing.

### Important consequence of setup-fork

It modifies a large number of files.

Do not submit those repo-wide URL rewrites in the final PR unless explicitly intended.

The contribution docs repeatedly require cherry-picking or otherwise submitting only your app-specific changes.

### Real test workflow

1. create or update the script files locally
2. push to your fork
3. wait roughly 10-30 seconds for GitHub raw content to update
4. test via:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"
```

Do not treat `bash ct/myapp.sh` as the real integration test.

Why:

- CT scripts download helper libraries via hardcoded URLs
- `setup-fork.sh` rewrites those URLs
- local `bash ct/myapp.sh` does not validate the remote raw URL path the same way

### Submission routing

For upstream new-script contributions, repo automation and templates indicate:

- unauthorized new-script PRs to `community-scripts/ProxmoxVE` can be closed
- new scripts should go through `community-scripts/ProxmoxVED` first for testing/review

If the immediate task is just to add code in this workspace, implement locally first and decide submission routing later.

## PR And Review Expectations

From `.github/pull_request_template.md` and docs:

- self-review completed
- tested thoroughly
- no security risks
- clear PR type
- clean diff

For new scripts, the intended clean diff is usually just:

- `ct/<nsapp>.sh`
- `install/<nsapp>-install.sh`
- `ct/headers/<nsapp>`

Website metadata remains outside the repo.

## Security And Support Constraints

From `SECURITY.md`:

- supported PVE lines:
  - 8.4.x
  - 9.0.x
  - 9.1.x
- 8.0-8.3 are limited support
- older than 8.0 unsupported

Testing nuance called out by repo docs:

- Debian 13 containers can fail on some hosts
- temporary fallback for testing may be `var_version=12`

Security bugs are reported privately, not via public issues.

## Practical Playbook For A New CT Script

When asked to add a new CT app here, follow this sequence:

1. Identify the upstream app’s distribution model.
   - GitHub tarball
   - prebuilt archive
   - `.deb`
   - single binary
   - language package build

2. Pick 2-3 existing script pairs that match the app’s stack and artifact type.

3. Choose the normalized app name early.
   - decide `APP`
   - ensure it maps cleanly to `NSAPP`
   - ensure matching names for:
     - `ct/<nsapp>.sh`
     - `install/<nsapp>-install.sh`
     - `ct/headers/<nsapp>`

4. Decide container defaults.
   - CPU
   - RAM
   - disk
   - OS
   - privileged vs unprivileged

5. Implement the install script first or alongside the CT script.
   - the CT script cannot work without its pair

6. Use helper functions instead of hand-rolled install logic wherever possible.

7. Implement `update_script()` in the CT layer.
   - stop services
   - back up mutable data
   - redeploy
   - rebuild/migrate
   - restore data
   - restart services

8. Add the header file.

9. Run static checks.

10. Push to fork and test via raw GitHub `curl`.

11. If preparing an upstream submission, cherry-pick only the intended contribution files onto a clean branch.

## Reference Patterns By App Type

Use these as style and behavior references:

- Node/Pnpm/PostgreSQL/full rebuild:
  - `ct/sparkyfitness.sh`
  - `install/sparkyfitness-install.sh`

- Node/PostgreSQL/Meilisearch:
  - `ct/open-archiver.sh`
  - `install/open-archiver-install.sh`

- prebuilt binary + service:
  - `ct/nginx-ui.sh`
  - `install/nginx-ui-install.sh`

- simple binary update:
  - `ct/qdrant.sh`

- singlefile binary:
  - `ct/hev-socks5-server.sh`

- `.deb` style binary release:
  - `ct/duplicati.sh`

- minimal DB-backed binary install:
  - `install/miniflux-install.sh`

## Repo Realities And Doc Drift

When docs disagree, prefer live code and current file patterns.

Known realities worth remembering:

- file naming in the repo is lowercase and often hyphenated, even where older docs show `AppName.sh`
- `APP` normalization, not CT filename alone, determines install/header naming
- `misc/install.func` already performs `get_lxc_ip`
- helper docs sometimes imply broader base-package bootstrapping than the actual `build_container()` bootstrap path guarantees
- docs call the ASCII header optional, but current runtime behavior makes adding one the practical default
- some older docs mention creating repo-side defaults files; actual defaults live under `/usr/local/community-scripts/` at runtime, not as contribution files

## Short Contribution Checklist

- [ ] `ct/<nsapp>.sh` added or updated
- [ ] `install/<nsapp>-install.sh` added or updated
- [ ] `ct/headers/<nsapp>` added or updated
- [ ] CT script sources upstream `misc/build.func`
- [ ] install script sources `$FUNCTIONS_FILE_PATH`
- [ ] helper functions used instead of custom install/version logic
- [ ] `update_script()` implemented or a clear no-update message provided
- [ ] install script ends with `motd_ssh`, `customize`, `cleanup_lxc`
- [ ] no Docker-based app install approach unless the script itself is for Docker tooling
- [ ] committed URLs point to `community-scripts/ProxmoxVE`
- [ ] metadata request handled via website, not repo JSON
- [ ] tested via raw GitHub `curl` from fork
- [ ] PR diff contains only intended contribution files
