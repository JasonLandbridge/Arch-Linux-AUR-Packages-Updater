# AGENTS

## What this repo is
- This repo is an AUR maintenance template: Renovate bumps `pkgver`, CI regenerates checksums/`.SRCINFO`, and merge-to-`main` publishes to AUR.
- Source of truth is workflows in `.github/workflows/` and Renovate config in `renovate.json` (not prose docs).

## Non-obvious constraints
- Package folders are ignored by default via `.gitignore` (`*/**`); only `.github/**` is unignored. You MUST force-add package files (for example `git add -f <pkg>/PKGBUILD <pkg>/.SRCINFO`) or they will not be committed.
- CI logic assumes one updated package per PR run: both workflows select the first changed package via `head -1`.
- `publish.yml` detects the package from changed `*/.SRCINFO` in `HEAD~1..HEAD`; if `.SRCINFO` was not updated/committed, publish step will skip.

## Renovate requirements for PKGBUILD
- Every maintained package directory MUST contain `PKGBUILD` and `.SRCINFO`.
- `PKGBUILD` MUST include `pkgver=<version> # renovate: datasource=<datasource> depName=<depName>` exactly on the `pkgver` line (regex manager depends on this format).
- Renovate manager pattern is defined in `renovate.json` and scans only files named `PKGBUILD`.
- `extractVersionTemplate` strips optional leading `v` from upstream tags; prefer this flow over custom version munging.
- Per Renovate's AUR user story, use supported datasources like `github-tags`/`git-tags` and set `depName` to the upstream source (for example `Azure/bicep`).

## CI flows you should preserve
- PR to `main` (`opened`/`synchronize`) triggers `updpkgsums.yml`:
- Finds changed package with `git diff origin/main origin/${GITHUB_HEAD_REF} "*PKGBUILD"`.
- Runs local Docker action `.github/actions/aur` which does: `updpkgsums`, installs `depends`/`makedepends` with `paru`, runs `makepkg`, regenerates `.SRCINFO`.
- Auto-commits only `*/PKGBUILD` and `*/.SRCINFO`.
- Push to `main` touching `*/PKGBUILD` triggers `publish.yml`:
- Uses `KSXGitHub/github-actions-deploy-aur` with secrets `AUR_USERNAME`, `AUR_EMAIL`, `AUR_SSH_PRIVATE_KEY`.

## Local verification (focused, one package)
- From package directory, the CI-equivalent sequence is: `updpkgsums`, then `makepkg`, then `makepkg --printsrcinfo > .SRCINFO`.
- If dependencies are missing, CI behavior comes from `.github/actions/aur/entrypoint.sh` (`source PKGBUILD` then `paru -Syu ... "${depends[@]}" "${makedepends[@]}"`).

## Editing guidance for agents
- Prefer changing workflow/action logic over README text when behavior changes.
- Do not broaden file patterns lightly: `*PKGBUILD` and `*/.SRCINFO` matching semantics drive package detection.
- Keep action pins as commit SHAs (current workflows are fully pinned).
