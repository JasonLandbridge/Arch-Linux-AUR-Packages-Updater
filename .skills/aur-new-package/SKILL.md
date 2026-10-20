---
name: aur-new-package
description: Use when adding a new maintained Arch Linux or AUR package to this repository.
---

# Adding a maintained package

A successful build is only one part of package creation. Complete the package, updater, publishing, documentation, and handoff integration together. Use `AGENTS.md` for repository contracts and the repo-local `aur-pkgbuild` and `aur-makepkg` skills for packaging details.

## Integration checklist

1. **Inspect upstream and a nearby package.** Check AUR name availability, the current release, Linux assets or source build requirements, supported architectures, dependencies, and licensing. Choose the appropriate source, `-bin`, or VCS package name. Reuse maintained examples; for background applications, consult the user-service/configuration examples named in `AGENTS.md`.
2. **Create the package directory.** Supply `PKGBUILD`, matching `.SRCINFO`, and every required launcher, unit, configuration file, or install hook. Install upstream notices and licenses appropriately. Use version-specific sources and real checksums for release downloads.
3. **Integrate updates.** Follow the exact Renovate `pkgver` metadata shape in `AGENTS.md` and the current `renovate.json` matching rules. For GitHub releases, use the upstream `owner/repo` with `datasource=github-releases`. Keep `pkgrel` immediately after `pkgver`. Confirm that the selected datasource/versioning can track the intended release channel.
4. **Integrate publishing.** Add the package directory to the manual selector in `.github/workflows/publish.yml`. Follow the existing public/private publisher selection. Preserve single-package automatic detection; separate package assets must accompany the metadata because PR CI only regenerates/commits `PKGBUILD` and `.SRCINFO`.
5. **Account for README documentation.** Add the package's AUR, repository-folder, and upstream links using the existing maintained-package list format. If higher-priority instructions require explicit README authorization and the user has not supplied it, request that authorization rather than silently omitting this integration step. Do not claim that an AUR listing is already published merely because its link was added.
6. **Verify after implementation.** Run the focused package-directory build and `.SRCINFO` generation command required by `AGENTS.md`. Validate the completed package archive and exercise the packaged executable with a meaningful smoke scenario. Validate user units when present. Report architecture/runtime limits, skipped dependency checks, or blockers explicitly; follow the documented timeout recovery rule.
7. **Prepare the exact file set.** When a commit is authorized, explicitly force-add new package metadata and required assets because nested files may be ignored. Stage only intended source files, not downloaded licenses/archives, extracted sources, or built packages. Include the publishing selector and authorized README change. Commit and push only to the user-authorized branch; open a PR only when requested.
8. **Notify upstream after publication.** Confirm that the public AUR package exists and its version matches the release being announced. Check upstream issues/discussions for an existing package announcement to avoid duplicates, and respect the project's contribution/contact guidance. When upstream posting is authorized, open a concise issue thanking the maintainer, link the AUR package and packaging source, and describe the verified automatic-update workflow. Distinguish automated AUR package maintenance from updates on users' machines, and identify community packaging without implying upstream endorsement. Make clear that this is an informational heads-up, with no action required and closure welcome. If posting has not been authorized, request permission; if publication is pending, report that the announcement is deferred.

## Completion evidence

Report the package/version, supported architectures, shipped assets, updater and publishing integration, README status, checks actually exercised, remaining limitations, and commit/branch/PR only when performed. Include the upstream announcement URL, or the specific reason it was deferred.

## Common omissions

- A built archive does not replace `.SRCINFO` or runtime verification.
- A file existing locally does not prove it will be included in a commit.
- CI metadata regeneration does not ship omitted service/configuration assets.
- A push to a development branch does not mean publication to AUR.
