# JasonLandbridge AUR Packages

This repository is the source of truth for AUR packages maintained by **JasonLandbridge**.

Yes: if CI is healthy and AUR secrets are configured, you should update packages here and let GitHub Actions publish changes to AUR, instead of editing package repos directly on AUR.

## Maintained packages

- [`youtube-dl-gui`](https://aur.archlinux.org/packages/youtube-dl-gui) - [repo folder](./youtube-dl-gui)
- [`omniroute-bin`](https://aur.archlinux.org/packages/omniroute-bin) - [repo folder](./omniroute-bin)
- [`mcp-linker-bin`](https://aur.archlinux.org/packages/mcp-linker-bin) - [repo folder](./mcp-linker-bin)

## Workflow

1. Edit package files in this repo (`PKGBUILD`, packaging assets, `.SRCINFO`).
2. Keep Renovate metadata on `pkgver`:

```bash
pkgver=1.2.3 # renovate: datasource=github-tags depName=owner/repo
```

3. Open or update a PR to `main`.
4. CI runs checksum and metadata update flow.
5. Merge to `main` to publish to AUR.

## References   

- [AUR](https://wiki.archlinux.org/title/Arch_User_Repository)
- [Renovate](https://github.com/apps/renovate)
- [Maintaining AUR packages with Renovate](https://docs.renovatebot.com/user-stories/maintaining-aur-packages-with-renovate/)

## License

Repository code is licensed under the [MIT License](./LICENSE.md). Package runtime licensing is defined in each package `PKGBUILD`.
