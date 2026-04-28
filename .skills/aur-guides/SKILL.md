---
name: aur-guides
description: Master skill for AUR (Arch User Repository) package development, serving as a comprehensive guide and dispatcher for creating, auditing, and submitting Arch Linux packages.
---

# Skill: aur-guides

## Purpose

Master skill for AUR (Arch User Repository) package development, serving as a comprehensive guide and dispatcher for creating, auditing, and submitting Arch Linux packages. This skill provides a structured workflow for AUR development while allowing users to focus on specific areas as needed.

## When to Use This Skill

This skill should be used when:
- Working with AUR packages, PKGBUILDs, or Arch Linux package development
- Creating new packages for the AUR
- Auditing or reviewing existing packages
- Submitting or maintaining packages in the AUR
- Configuring makepkg or pacman for package building
- Working with version control system (VCS) packages
- Using AUR helpers (yay, paru, etc.)

## When NOT to Use This Skill

- For packaging software for distribution outside Arch Linux
- For official Arch packages (those go through Package Maintainers)
- For binary-only packages (use flatpak, snap, or AppImage instead)

## Core Capabilities

1. **Workflow Orchestration** - Guide through the complete AUR package development lifecycle
2. **Skill Dispatching** - Route to specific skills for focused assistance
3. **Best Practices** - Apply Arch Linux packaging standards and guidelines
4. **Validation** - Ensure packages meet official requirements
5. **Documentation** - Provide references to official Arch resources

## Package Development Workflow

### Complete AUR Package Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUR Package Development                      │
├─────────────────────────────────────────────────────────────────┤
│  1. Planning                                                    │
│     ↓                                                           │
│  2. Create PKGBUILD  ───→ aur-pkgbuild skill                    │
│     ↓                                                           │
│  3. Verify Guidelines ──→ aur-package-guidelines skill          │
│     ↓                                                           │
│  4. Build & Test ───────→ aur-makepkg skill                     │
│     ↓                                                           │
│  5. Audit Package ──────→ aur-audit skill                       │
│     ↓                                                           │
│  6. Submit to AUR ──────→ aur-submission skill                  │
│     ↓                                                           │
│  7. Maintain Package ───→ aur-submission skill                  │
└─────────────────────────────────────────────────────────────────┘
```

### Quick Reference: Which Skill to Use

| Task | Skill to Use |
|------|--------------|
| Create new PKGBUILD | `aur-pkgbuild` |
| Learn package standards | `aur-package-guidelines` |
| Submit to AUR | `aur-submission` |
| Audit/validate package | `aur-audit` |
| Configure build process | `aur-makepkg` |
| VCS packages (git, svn, etc.) | `aur-vcs-packages` |
| Pacman usage | `aur-pacman` |
| AUR helpers (yay, paru) | `aur-helpers` |

## Workflow Examples

### Example 1: Creating a New AUR Package

**Scenario:** User wants to package a new application for the AUR

**Recommended workflow:**
1. Load `aur-pkgbuild` - Create the PKGBUILD with proper structure
2. Load `aur-package-guidelines` - Verify compliance with Arch standards
3. Load `aur-makepkg` - Build and test the package
4. Load `aur-audit` - Run namcap and shellcheck
5. Load `aur-submission` - Submit to AUR

### Example 2: Maintaining an Existing Package

**Scenario:** User wants to update an existing AUR package

**Recommended workflow:**
1. Load `aur-pkgbuild` - Review/ update PKGBUILD
2. Load `aur-makepkg` - Rebuild with new version
3. Load `aur-audit` - Validate changes
4. Load `aur-submission` - Push updates to AUR

### Example 3: VCS Package Development

**Scenario:** User wants to create a -git package from a GitHub repository

**Recommended workflow:**
1. Load `aur-vcs-packages` - Understand VCS-specific requirements
2. Load `aur-pkgbuild` - Create PKGBUILD with proper VCS handling
3. Load `aur-audit` - Validate package
4. Load `aur-submission` - Submit package

## Key Resources

### Official Documentation

- **Arch Wiki:** https://wiki.archlinux.org/
- **AUR:** https://aur.archlinux.org/
- **Pacman Manual:** https://man.archlinux.org/man/pacman.8
- **PKGBUILD Manual:** https://man.archlinux.org/man/PKGBUILD.5
- **Makepkg Manual:** https://man.archlinux.org/man/makepkg.8

### Important Guidelines

- [Arch Package Guidelines](https://wiki.archlinux.org/title/Arch_package_guidelines)
- [AUR Submission Guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines)
- [PKGBUILD Reference](https://wiki.archlinux.org/title/PKGBUILD)
- [VCS Package Guidelines](https://wiki.archlinux.org/title/VCS_package_guidelines)

## Common Patterns

### PKGBUILD Structure

```bash
# Maintainer and contributors (email obfuscated as per AUR guidelines)
# Maintainer: Your Name <you at example dot com>
# Contributor: Original Author <author at example dot com>

pkgname=package-name
pkgver=1.0.0
pkgrel=1
epoch=
pkgdesc="A short description of the package"
arch=('x86_64')
url="https://example.com"
license=('SPDX License Identifier')
makedepends=()
depends=()
optdepends=()
provides=()
conflicts=()
replaces=()
backup=()
options=()
install=
changelog=
source=("${pkgname}-${pkgver}.tar.gz::https://example.com/download")
sha256sums=('abcdef123456789...')

prepare() {
    cd "$srcdir"
}

build() {
    cd "$srcdir/${pkgname}-${pkgver}"
    ./configure --prefix=/usr
    make
}

package() {
    cd "$srcdir/${pkgname}-${pkgver}"
    make DESTDIR="$pkgdir" install
}
```

### Common Dependencies

- **base-devel**: Always installed, do not list in makedepends
- **namcap**: Package auditing tool
- **shellcheck**: Bash script validation
- **pkgctl**: Modern Arch packaging tooling

### Essential Commands

```bash
# Build package
makepkg -s

# Build and install
makepkg -i

# Generate checksums
makepkg -g >> PKGBUILD

# Update checksums (preferred method)
updpkgsums PKGBUILD

# Generate .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# Audit PKGBUILD
namcap PKGBUILD

# Audit built package
namcap package-name.pkg.tar.zst

# Check bash syntax (with recommended exclusions for PKGBUILD)
shellcheck --shell=bash --exclude=SC2034,SC2154,SC2164 PKGBUILD

# Check that the package builds in a chroot
pkgctl build
```

## Best Practices Summary

1. **Always use HTTPS** for source URLs
2. **Include all direct dependencies** - never rely on transitive deps
3. **Use appropriate checksums** - prefer b2 or sha512
4. **Add PGP signatures** when available
5. **Use namcap** to validate packages
6. **Follow naming conventions** - lowercase, no dashes at start
7. **Include LICENSE file** with 0BSD license (for the AUR repo/PKGBUILD itself)
8. **Use SPDX license identifiers** in the license field (e.g., GPL-3.0-or-later)
9. **Generate .SRCINFO** before pushing to AUR
10. **Never use replaces** in AUR unless renaming
11. **Use conflicts/provides** for alternate versions
12. **Use VCS suffixes** (-git, -svn, -hg) for development versions
13. **Always quote** "$pkgdir" and "$srcdir" to prevent path-related build failures
14. **Use :: syntax** in source array for unique filenames to prevent download conflicts

## Related Skills

For focused assistance on specific areas:

- **aur-pkgbuild** - Detailed PKGBUILD creation and syntax
- **aur-package-guidelines** - General Arch packaging standards
- **aur-submission** - AUR submission and maintenance
- **aur-audit** - Package auditing and security
- **aur-makepkg** - Build configuration and process
- **aur-vcs-packages** - Version control system packages
- **aur-pacman** - Pacman package manager usage
- **aur-helpers** - AUR helper tools

## Notes

- This skill is language and AUR helper agnostic
- Always verify against official documentation
- Use namcap for validation before submission
- Follow Arch Linux philosophy: keep it simple
