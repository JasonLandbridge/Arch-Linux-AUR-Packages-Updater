---
name: aur-package-guidelines
description: Comprehensive guide to Arch Linux package guidelines and standards for consistency, quality, and interoperability across the Arch Linux ecosystem.
---

# Skill: aur-package-guidelines

## Purpose

Comprehensive guide to Arch Linux package guidelines and standards. This skill covers the official packaging standards that ensure consistency, quality, and interoperability across the Arch Linux ecosystem, including both official repositories and the AUR.

## When to Use This Skill

This skill should be used when:
- Understanding Arch Linux packaging standards
- Ensuring packages meet official requirements
- Learning about package naming conventions
- Configuring package metadata
- Understanding licensing requirements
- Following best practices for package structure

## When NOT to Use This Skill

- For non-Arch Linux distributions (each distro has its own standards)
- For packages already in official repos
- For binary-only distribution formats

## Package Naming Conventions

### Allowed Characters
- Only lowercase letters (a-z)
- Numbers (0-9)
- Special characters: `@ . _ + -`
- **Cannot start with hyphen (-) or dot (.)**

### Naming Patterns

**Match source tarball:**
```bash
# If upstream is foobar-2.5.tar.gz, use:
pkgname=foobar
```

**Library packages:**
```bash
pkgname=gtk3      # Major version suffix for compatibility
pkgname=qt5       # Qt version
pkgname=libfoo    # Generic library
```

**Application packages:**
```bash
pkgname=firefox
pkgname=vim
pkgname=code
```

**Kernel modules:**
```bash
pkgname=nvidia-dkms
pkgname=virtualbox-host-modules
```

### Version Suffixes (When Required)
- Use `-git`, `-svn`, `-hg` for VCS packages (development versions)
- Use `-bin` for prebuilt binaries (when source available)
- Use major version for incompatible libraries (gtk2, gtk3, gtk4)
- **Never** suffix with upstream version number (not `libfoo2`)

### Anti-patterns
```bash
# BAD - starts with hyphen
pkgname=-package

# BAD - contains uppercase
pkgname=PackageName

# BAD - uses version as suffix
pkgname=libfoo2

# BAD - special characters at start
pkgname=.hidden
```

## Versioning

### pkgver Rules
- Must match upstream version exactly
- Allowed: letters, numbers, periods, underscores
- **No hyphens** - replace with underscore
- Examples:
  - `pkgver=1.0.0` - standard
  - `pkgver=2.0_beta` - beta release
  - `pkgver=20230101` - date-based (use ISO 8601, reversed)

### pkgrel Rules
- Starts at 1 for each new upstream version
- Increments for PKGBUILD fixes without upstream changes
- Resets to 1 on new upstream release
- Format: positive integer (can include subrelease like `1.1`)

### arch (Architecture)
- Standard: `arch=('x86_64')` for most packages
- Architecture-independent (scripts, fonts): `arch=('any')`

### epoch (Rarely Used)
- Forces package to be newer than any previous version
- Default: 0
- Use only when version scheme changes break comparison
- Example: `epoch=1` makes `1:5.13-2` newer than any `0:x.x.x-x`

### pkgdesc (Package Description)
- Keep to ~80 characters or less
- Do NOT include the package name (self-referencing)
- Good: `A fast text editor`
- Bad: `Vim is a fast text editor`

## Dependencies

### Core Principles
1. **List ALL direct dependencies** - never rely on transitive deps
2. **Runtime vs Build-time** - use depends vs makedepends appropriately
3. **Check binaries** - use `ldd` or `readelf` to find library deps
4. **Verify scripts** - check build scripts for required tools

### Dependency Types

| Type | When to Use |
|------|--------------|
| `depends` | Required to build AND run |
| `makedepends` | Only needed for building |
| `checkdepends` | Only for running test suites |
| `optdepends` | Optional features, enhances functionality |

### Finding Dependencies

```bash
# Find library dependencies
ldd /path/to/binary

# Find undefined symbols
readelf -d /path/to/binary | grep NEEDED

# Find script requirements
grep -h '^#!' /path/to/scripts/*

# Use namcap (after building)
namcap package.pkg.tar.zst
```

### Common Mistakes
- **Listing `base-devel` packages in makedepends** - Never list gcc, make, etc. (base-devel is assumed)
- Relying on transitive dependencies
- Missing optional features' dependencies
- Not checking all binaries in the package
- Not quoting variables: always use `"$pkgdir"` and `"$srcdir"`

## Directory Structure

### Standard Layout

| Path | Use For |
|------|---------|
| `/usr/bin` | Executables |
| `/usr/lib` | Libraries (.so files) |
| `/usr/include` | Header files |
| `/usr/lib/pkgname` | Modules, plugins |
| `/usr/share/doc` | Documentation |
| `/usr/share/info` | GNU Info pages |
| `/usr/share/licenses` | License files |
| `/usr/share/man` | Man pages |
| `/usr/share/pkgname` | Application data |
| `/var/lib/pkgname` | Persistent data |
| `/etc` | System config |
| `/etc/pkgname` | Package config (recommended) |
| `/opt/pkgname` | Large self-contained apps |

### Forbidden Paths
Never create packages containing:
- `/bin`, `/sbin` (use `/usr/bin`)
- `/dev`, `/home`, `/srv`
- `/media`, `/mnt`, `/proc`
- `/root`, `/selinux`, `/sys`
- `/tmp`, `/var/tmp` (use `/tmp` at runtime)
- `/run` (system runtime)

### Configuration Files
- Place in `/etc/packagename/`
- Use backup array for user modifications (use relative paths, **no leading slash**):
  - Correct: `backup=('etc/pacman.conf')`
  - Wrong: `backup=('/etc/pacman.conf')`
- Handle .pacnew and .pacsave properly

## Licensing

### Two Types of Licenses

1. **PKGBUILD license field** - Upstream software license
   - Use SPDX identifiers (GPL-3.0-or-later, MIT, BSD-3-Clause, etc.)
   - Multiple licenses: Use OR syntax: `license=('GPL-3.0-or-later OR LGPL-2.1-only')`

2. **Package source license** - Your PKGBUILD modifications
   - Use 0BSD license (standard for Arch packages)
   - Create LICENSE file with exact content

### Setting Up License Files

```bash
# Create LICENSE file with 0BSD (for AUR promotion eligibility)
install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
```

License file content (0BSD):
```
Copyright (c) 2026 Your Name

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
```

### SPDX License Identifiers
- Use proper identifiers: `GPL-3.0-or-later`, `MIT`, `BSD-3-Clause`, `Apache-2.0`, `LGPL-2.1-only`
- Use `custom:LicenseName` for non-standard licenses
- Check https://spdx.org/licenses/ for full list
- Common correct identifiers:
  - GPL → GPL-3.0-or-later
  - LGPL → LGPL-2.1-only
  - BSD → BSD-3-Clause

## Package Etiquette

### DO
- Use HTTPS for all source URLs
- Include valid checksums (b2 or sha512 preferred)
- Add PGP signatures when available
- Use meaningful commit messages
- Respond to user feedback
- Keep pkgrel meaningful
- Prefix custom variables/functions with underscore: `_myvar`
- Quote variables: `"$pkgdir"`, `"$srcdir"`
- Obfuscate email in maintainer comments: `# Maintainer: Name <you at example dot com>`

### DON'T
- Install to `/usr/local/`
- Create new variables without underscore prefix (`_`)
- Use makepkg functions (error, msg, warning) - use printf/echo
- Leave empty arrays without removing
- Use `replaces` in AUR (unless renaming package, e.g., Ethereal → Wireshark)
- Use conflicts or provides instead for alternate versions
- Submit duplicates of existing packages
- Pack prebuilt binaries (except -bin suffix)

## makepkg Duties

When makepkg runs, it automatically:

1. Checks dependencies (depends, makedepends)
2. Downloads sources
3. Verifies integrity
4. Extracts sources
5. Applies patches
6. Builds software
7. Installs to fake root (DESTDIR)
8. Strips binaries
9. Strips debug symbols
10. Compresses man/info pages
11. Generates package metadata
12. Creates package archive

## Security Considerations

### Source Verification
- Use HTTPS URLs
- Include checksums
- Verify PGP signatures
- Use `validpgpkeys` for known keys

### Safe Practices
- Never disable checksum verification
- Don't skip signature checks
- Avoid downloading from untrusted mirrors
- Verify upstream signatures
- **Never** diminish package security (e.g., remove PGP/checksums) even if upstream is temporarily broken - wait for fix instead

### Namcap Checks
Run `namcap` to detect:
- Missing dependencies
- Incorrect permissions
- Redundant dependencies
- Security issues
- Common mistakes

## Reproducible Builds

### Environment Variables
```bash
# Set timestamp for reproducible builds
SOURCE_DATE_EPOCH=$(date +%s)
```

### Verification
```bash
# Check if package is reproducible
makerepropkg package.pkg.tar.zst
# or
repro -f package.pkg.tar.zst
```

## Best Practices Summary

1. **Naming**: lowercase, no leading dash/dot, match source tarball
2. **Version**: match upstream, no hyphens, use ISO 8601 for dates
3. **Deps**: list all direct deps, no base-devel in makedepends
4. **Sources**: HTTPS, checksums, signatures, unique filenames with `::`
5. **Dirs**: follow standard layout, no forbidden paths
6. **License**: SPDX identifiers, include LICENSE file (0BSD)
7. **pkgdesc**: ~80 chars max, no self-reference
8. **Variables**: quote "$pkgdir" and "$srcdir", prefix custom with `_`
9. **AUR**: regenerate .SRCINFO on metadata changes
10. **Validation**: use namcap, respond to users

## Related Skills

- **aur-guides** - Main dispatcher
- **aur-pkgbuild** - PKGBUILD syntax
- **aur-audit** - Validation
- **aur-submission** - AUR submission
- **aur-makepkg** - Build process
