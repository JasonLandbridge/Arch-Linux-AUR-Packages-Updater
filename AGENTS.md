# AGENTS

## Scope
- This repo is an AUR package source-of-truth repo: Renovate updates `pkgver`, PR CI regenerates checksums and `.SRCINFO`, and merge-to-`main` publishes to AUR.
- Agents SHOULD trust `renovate.json` and `.github/workflows/` over prose. `README.md` package listings can lag the actual package directories.
- Repo-local Arch/AUR skills live in `.skills/`. Agents MUST load the relevant repo-local AUR/Arch skills before doing package work.

## Build And Verification
- Agents MUST use focused one-shot verification from the package directory being edited: `updpkgsums && makepkg && makepkg --printsrcinfo > .SRCINFO`.
- Agents SHOULD verify only the touched package. CI is package-scoped and does not run a repo-wide build/test suite.
- Agents MUST NOT run blocking/watch commands; this repo has no dev server workflow.
- If a build command times out while `makepkg` is compressing a package, agents MUST treat the generated `*.pkg.tar.*` as suspect, remove it, and rebuild before claiming the package archive is valid. Validate completed archives with `tar -tf <pkgfile> >/dev/null`.
- For packages that cannot satisfy local runtime dependencies on the host, agents MAY use `makepkg --nodeps` for local packaging verification only, but MUST still run `makepkg --verifysource`, regenerate `.SRCINFO`, and document which dependency check was skipped.

## Package Layout
- Each maintained package directory MUST contain both `PKGBUILD` and `.SRCINFO`.
- Root-level package assets may be consumed by package builds; for example `youtube-dl-gui/PKGBUILD` references `../../electron-builder.yml`.
- When a package is added or removed, agents MUST update `README.md` in the same change.
- Application packages SHOULD ship a `systemd --user` service when auto-start/background use is part of the package workflow. Existing repo examples are `mcpproxy-bin` and `omniroute-bin`, which install units to `/usr/lib/systemd/user/*.service`.
- Keep `PKGBUILD` files lean: put user-facing units, launchers, environment files, desktop files, and sample/default config files in separate package-directory files, then list them in `source=()` and install them from `$srcdir`. Do not embed long heredocs in `PKGBUILD` when a separate file would be clearer.
- For user-service packages with runtime configuration, prefer the `omniroute-bin` pattern: ship the service file separately, ship default user-editable config/env files under `/usr/share/doc/$pkgname/`, add a `<pkgname>.install` hook when appropriate to best-effort copy defaults into the invoking user's `${XDG_CONFIG_HOME:-$HOME/.config}/<app>/` with `cp -n`, and never overwrite user edits on upgrade.
- When package source files are renamed or added under a package directory, remember `.gitignore` ignores nested contents; use `git add -f` for new package assets and stage deletions of old names so AUR receives the real file set.

## Git And Ignore Gotchas
- `.gitignore` ignores subfolder contents via `*/**`. New or re-added package files will often need `git add -f <pkg>/PKGBUILD <pkg>/.SRCINFO`.
- Agents MUST NOT assume a changed file is staged just because it exists under a tracked package directory.

## Renovate Contract
- `renovate.json` only scans files named `PKGBUILD` via `managerFilePatterns: /(^|/)PKGBUILD$/`.
- The `pkgver` line MUST keep this exact shape: `pkgver=<version> # renovate: datasource=<datasource> depName=<depName>`.
- Private packages and binary packages are not exempt from the Renovate contract; if Renovate should update them, their `pkgver` line MUST include the metadata comment. For GitHub Release assets, agents SHOULD use `datasource=github-releases` and `depName=<owner>/<repo>`.
- Agents SHOULD prefer Renovate's built-in version extraction (`extractVersionTemplate` strips an optional leading `v`) over custom version munging.

## CI Contracts
- `updpkgsums.yml` triggers on PR `opened`/`synchronize` to `main`, finds the changed package with `git diff --name-only origin/main origin/${GITHUB_HEAD_REF} "*PKGBUILD" | head -1 | xargs dirname`, then runs `.github/actions/aur`.
- `.github/actions/aur/entrypoint.sh` is the executable source of truth for package validation: it runs `updpkgsums`, installs `depends` and `makedepends` from `PKGBUILD`, runs `makepkg`, then regenerates `.SRCINFO`.
- The PR auto-commit step only writes `*/PKGBUILD` and `*/.SRCINFO`; agents MUST commit separate package assets and install scripts themselves.
- `publish.yml` normally auto-detects one package from the latest commit. Its manual `workflow_dispatch` package dropdown can force-publish a selected package that auto-detection skipped.
- `publish.yml` selects the publishing target once through `.github/scripts/select-publisher.sh`: package directories with `.private` publish to the private binary repository, and packages without `.private` publish to AUR.
- Private packages require `PRIVATE_REPO_UPLOAD_URL` and `PRIVATE_REPO_UPLOAD_TOKEN` GitHub Actions secrets; AUR packages MUST NOT require those secrets.
- Agents MUST update and commit `.SRCINFO` with the matching `PKGBUILD`; otherwise automatic publishing can skip the package.
- CI logic assumes one automatically detected package per PR/push because package discovery selects only the first changed package. Do not broaden this behavior without explicit user approval; use the manual publish selector for additional packages when needed.
- When adding a maintained package directory, add it to the manual publish dropdown in `.github/workflows/publish.yml`; when removing a package, remove its dropdown option.

## systemd User Services And Configuration
- Follow an existing package pattern before inventing a new one; use `omniroute-bin` as the primary example for a separately shipped user unit, environment file, and best-effort per-user setup hook.
- Install user units to `/usr/lib/systemd/user/*.service` and validate them with `systemd-analyze --user verify <unit>`.
- Prefer systemd user specifiers over hard-coded home paths. `%E` is the user configuration directory (`$XDG_CONFIG_HOME`, falling back to `$HOME/.config`) and is suitable for `EnvironmentFile=`, `TABBY_ROOT`, and similar settings.
- Remember that systemd `EnvironmentFile` syntax is not shell syntax: values do not expand `$HOME` or other shell variables. Defaults that need a path SHOULD use unit specifiers in the service; documented overrides SHOULD use real absolute paths.
- A package install hook MAY identify the invoking desktop user through `SUDO_USER`, create the XDG config directory, and copy defaults with `cp -n`. It MUST silently leave existing user files unchanged and provide manual commands when best-effort setup is unavailable.
- Keep runtime data-location behavior aligned with upstream semantics. If an application uses one root for config and state, document that choosing an XDG config root also places its database/logs beneath that root.

## Editing Rules
- Agents SHOULD prefer changing workflow/action logic over README text when behavior changes.
- Agents MUST preserve the current path matching semantics (`*PKGBUILD`, `*/.SRCINFO`) unless intentionally changing package detection behavior.
- Agents SHOULD keep GitHub Action pins as full commit SHAs when editing workflow dependencies.
- Agents MUST inspect nearby package examples and ask before making repo-wide workflow or packaging-pattern changes that are not required by the requested package change.
