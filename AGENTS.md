# AGENTS

## Scope
- This repo is an AUR package source-of-truth repo: Renovate updates `pkgver`, PR CI regenerates checksums and `.SRCINFO`, and merge-to-`main` publishes to AUR.
- Agents SHOULD trust `renovate.json` and `.github/workflows/` over prose. `README.md` package listings can lag the actual package directories.
- Repo-local Arch/AUR skills live in `.skills/`. Agents MUST load the relevant repo-local AUR/Arch skills before doing package work.

## Build And Verification
- Agents MUST use focused one-shot verification from the package directory being edited: `updpkgsums && makepkg && makepkg --printsrcinfo > .SRCINFO`.
- Agents SHOULD verify only the touched package. CI is package-scoped and does not run a repo-wide build/test suite.
- Agents MUST NOT run blocking/watch commands; this repo has no dev server workflow.

## Package Layout
- Each maintained package directory MUST contain both `PKGBUILD` and `.SRCINFO`.
- Root-level package assets may be consumed by package builds; for example `youtube-dl-gui/PKGBUILD` references `../../electron-builder.yml`.
- When a package is added or removed, agents MUST update `README.md` in the same change.
- Application packages SHOULD ship a `systemd --user` service when auto-start/background use is part of the package workflow. Existing repo examples are `mcpproxy-bin` and `omniroute-bin`, which install units to `/usr/lib/systemd/user/*.service`.

## Git And Ignore Gotchas
- `.gitignore` ignores subfolder contents via `*/**`. New or re-added package files will often need `git add -f <pkg>/PKGBUILD <pkg>/.SRCINFO`.
- Agents MUST NOT assume a changed file is staged just because it exists under a tracked package directory.

## Renovate Contract
- `renovate.json` only scans files named `PKGBUILD` via `managerFilePatterns: /(^|/)PKGBUILD$/`.
- The `pkgver` line MUST keep this exact shape: `pkgver=<version> # renovate: datasource=<datasource> depName=<depName>`.
- Agents SHOULD prefer Renovate's built-in version extraction (`extractVersionTemplate` strips an optional leading `v`) over custom version munging.

## CI Contracts
- `updpkgsums.yml` triggers on PR `opened`/`synchronize` to `main`, finds the changed package with `git diff --name-only origin/main origin/${GITHUB_HEAD_REF} "*PKGBUILD" | head -1 | xargs dirname`, then runs `.github/actions/aur`.
- `.github/actions/aur/entrypoint.sh` is the executable source of truth for package validation: it runs `updpkgsums`, installs `depends` and `makedepends` from `PKGBUILD`, runs `makepkg`, then regenerates `.SRCINFO`.
- The PR auto-commit step only writes `*/PKGBUILD` and `*/.SRCINFO`.
- `publish.yml` triggers on pushes to `main` that touch `*/PKGBUILD`, but it discovers the package from `git diff --name-only HEAD HEAD~1 "*/.SRCINFO" | head -1 | xargs dirname`.
- Agents MUST update and commit `.SRCINFO` with the matching `PKGBUILD`; otherwise publish will skip because no package is detected.
- CI logic assumes one updated package per PR/push because both workflows select only the first changed package with `head -1`.

## Editing Rules
- Agents SHOULD prefer changing workflow/action logic over README text when behavior changes.
- Agents MUST preserve the current path matching semantics (`*PKGBUILD`, `*/.SRCINFO`) unless intentionally changing package detection behavior.
- Agents SHOULD keep GitHub Action pins as full commit SHAs when editing workflow dependencies.
