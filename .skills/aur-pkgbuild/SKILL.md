---
name: aur-pkgbuild
description: Comprehensive guide for creating and editing PKGBUILD files - the core build scripts used by makepkg to create Arch Linux packages.
---

# Skill: aur-pkgbuild

## Purpose

Comprehensive guide for creating and editing PKGBUILD files - the core build scripts used by makepkg to create Arch Linux packages. This skill covers all PKGBUILD variables, functions, and best practices for building packages for Arch Linux and the AUR.

## When to Use This Skill

This skill should be used when:
- Creating a new PKGBUILD from scratch
- Editing or updating an existing PKGBUILD
- Understanding PKGBUILD syntax and variables
- Building split packages
- Working with package functions (prepare, build, check, package)
- Creating install scripts (.install files)

## When NOT to Use This Skill

- For packages that will be submitted to official Arch repos (use different guidelines)
- For non-Arch Linux distributions
- For binary-only packages (use -bin suffix instead)

## PKGBUILD Variables Overview

### Required Variables

```bash
pkgname=packagename        # Package name (lowercase, alphanumeric + @._+-)
pkgver=1.0.0              # Upstream version (no hyphens, use _ instead)
pkgrel=1                   # Release number (resets on new upstream version)
arch=('x86_64')            # Target architecture(s)
```

### Optional but Recommended

```bash
pkgdesc="Description"     # Max ~80 chars, no self-referencing
url="https://example.com"  # Official project URL
license=('GPL-3.0-or-later')  # SPDX license identifier
groups=()                  # Package groups (e.g., 'plasma')
```

## Package Naming

### Rules
- Only lowercase alphanumeric characters and: `@ . _ + -`
- Cannot start with hyphen (`-`) or dot (`.`)
- Should match upstream source tarball name when possible

### Suffixes (AUR specific)
- `-git`, `-svn`, `-hg`, `-bzr`, `-darcs` for VCS packages
- `-bin` for prebuilt binaries (when source available)
- Never use version numbers as suffix (e.g., not `libfoo2`)

### Examples
```bash
pkgname=firefox            # Good: matches upstream
pkgname=gtk3               # Good: version suffix for compatibility
pkgname=screen-sidebar     # Good: alternate version with patch
pkgname=code-git           # Good: VCS package
pkgname=vim-bin           # Good: prebuilt binary
```

## Version Management

### pkgver
- Must match upstream version exactly
- Can contain: letters, numbers, periods, underscores
- **Cannot contain hyphens** - replace with underscore
- Use `pkgver()` function for VCS packages

```bash
# If upstream is "v1.0.0", use:
pkgver=1.0.0

# If upstream is "release-1_0", use:
pkgver=1_0
```

### pkgrel (Release)
- Starts at 1 for each new upstream version
- Increments for package-only fixes (PKGBUILD changes)
- Resets to 1 when upstream releases new version

### epoch
- Used to force package to be "newer" than any previous version
- Default is 0, rarely needed
- Example: `epoch=1` makes `1:1.0.0-1` newer than any `0:x.x.x-x`

## Dependencies

### depends
Runtime dependencies required to build AND run the package.
```bash
depends=('glibc>=2.20' 'gtk3')
```

### makedepends
Dependencies only needed for building.
```bash
makedepends=('cmake' 'ninja')
```
**Note:** Do NOT include packages from `base-devel` (gcc, make, etc.)

### checkdepends
Dependencies only needed for running test suites.
```bash
checkdepends=('python-pytest')
```

### optdepends
Optional features, not required for basic functionality.
```bash
optdepends=('cups: printing support'
            'sane: scanner support')
```

### Architecture-specific dependencies
```bash
depends_x86_64=('lib32-glibc')
```

### Best Practices
- **Never rely on transitive dependencies** - list ALL direct deps
- Use `ldd` or `readelf` on binaries to find library deps
- Use `namcap` to detect missing deps
- Check scripts for required tools

## Package Relations

### provides
What the package provides (libraries, virtual packages).
```bash
provides=('libfoo.so' 'qt5')
provides=('qt=5.15.0')  # With version
```
**Note:** Do NOT include `$pkgname` - it's implicit.

### conflicts
Packages that cannot be installed alongside this one.
```bash
conflicts=('old-package' 'another-package')
```

### replaces
Obsolete packages replaced by this one.
```bash
replaces=('wireshark-qt')  # For official repo packages
```
**Note:** Avoid in AUR - use `conflicts` and `provides` instead.

## Sources and Integrity

### source array
```bash
source=("${pkgname}-${pkgver}.tar.gz::https://example.com/download")
source=('localfile.patch')
source=('git+https://github.com/user/repo.git')
```

### Integrity variables
```bash
sha256sums=('abc123...')    # Recommended
sha512sums=('def456...')    # Stronger
b2sums=('ghi789...')        # Strongest
md5sums=('xyz...')         # Legacy, avoid
sha1sums=('old...')         # Legacy, avoid
cksums=('crc...')           # CRC32, minimal security
```

Generate with:
```bash
makepkg -g >> PKGBUILD        # Generate new checksums
updpkgsums PKGBUILD           # Update existing (preferred)
```

### Special source handling
```bash
# Custom filename to avoid conflicts
source=('unique-name.tar.gz::https://example.com/download')

# PGP signature verification
source=('file.tar.gz'
        'file.tar.gz.sig')
validpgpkeys=('KEYFINGERPRINT')

# Git sources
source=('name::git+https://repo.git#branch=main')

# Skip extraction (filename only, not full path)
noextract=('file.tar.gz')
```

### Security
- Always use HTTPS URLs
- Prefer b2 or sha512 checksums
- Use PGP signatures when available
- Use `SKIP` only for VCS sources

## Package Functions

### prepare()
Run before build - apply patches, modify sources.
```bash
prepare() {
    cd "$pkgname-$pkgver"
    patch -p1 -i "$srcdir/fix.patch"
}
```

### build()
Compile the software.
```bash
build() {
    cd "$pkgname-$pkgver"
    ./configure --prefix=/usr
    make
}
```

### check()
Run test suite (optional).
```bash
check() {
    cd "$pkgname-$pkgver"
    make test
}
```

### package()
Install into fake root for packaging.
```bash
package() {
    cd "$pkgname-$pkgver"
    make DESTDIR="$pkgdir" install
}
```

## Split Packages

### pkgbase
```bash
pkgbase="project-name"  # Used when multiple packages from one source
pkgname=(package1 package2)
```

### Per-package functions
```bash
package_package1() {
    # Install files for package1
    install -Dm644 file1 "$pkgdir/usr/bin/app1"
}

package_package2() {
    # Install files for package2
    install -Dm644 file2 "$pkgdir/usr/bin/app2"
}
```

**Note:** All packages required to build the entire set must be in the **global makedepends** array. makepkg does not check split package dependencies before the build begins.

## Install Scripts (.install)

**CRITICAL:** .install scripts do NOT have access to $pkgdir or $srcdir. These scripts run on the user's system during pacman operations, not during the build process. They reference the actual system paths, not build directories.

### Script functions
```bash
pre_install() {
    echo "Running before installation"
}

post_install() {
    echo "Package installed!"
}

pre_upgrade() {
    echo "Before upgrade"
}

post_upgrade() {
    echo "After upgrade"
}

pre_remove() {
    echo "Before removal"
}

post_remove() {
    echo "After removal"
}
```

### Example install file
```bash
post_install() {
    # Show message to user - system paths only
    echo "Please run systemctl daemon-reload"
}
```

**Do NOT use $pkgdir or $srcdir in .install files.**

## Options

### Common options
```bash
options=('!emptydirs'    # Remove empty directories (default: keep them)
         '!libtool'      # Remove .la libtool files (default: keep them)
         '!ccache'       # Don't use ccache
         '!strip'        # Don't strip binaries (default: strip them)
         'upx'           # Compress binaries
         'zipman'      # Compress man pages
)
```

## Directory Structure

### Standard paths
| Path | Purpose |
|------|---------|
| `/usr/bin` | Executables |
| `/usr/lib` | Libraries |
| `/usr/include` | Headers |
| `/usr/share/doc` | Documentation |
| `/usr/share/licenses` | License files |
| `/usr/share/man` | Man pages |
| `/etc` | Configuration files |
| `/etc/package` | Package config (recommended) |
| `/opt/package` | Large self-contained apps |
| `/var/lib/package` | Persistent data |

### Forbidden paths
Do NOT include: `/bin`, `/sbin`, `/dev`, `/home`, `/srv`, `/media`, `/mnt`, `/proc`, `/root`, `/selinux`, `/sys`, `/tmp`, `/var/tmp`, `/run`

## Licensing

### PKGBUILD license field
**Always use SPDX license identifiers** from the official SPDX License List.

```bash
license=('GPL-3.0-or-later')           # Single license (SPDX)
license=('GPL-3.0-or-later' 'MIT')      # Multiple licenses (SPDX)
license=('custom:NAME')                # Custom license - requires license file
license=('BSD-3-Clause')              # BSD variants need license file
```

### License file installation
For custom licenses or license families (MIT, BSD), you must provide the license text:
```bash
package() {
    # ... build commands ...
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
```

### AUR Repository License
The PKGBUILD and helper files in your AUR submission should be licensed under **0BSD**:
- Include a LICENSE file in the repository root
- This is separate from the upstream software's license

## Common Patterns

### Simple autotools package
```bash
# Maintainer: Your Name <you at example dot com>

pkgname=example
pkgver=1.0.0
pkgrel=1
pkgdesc="An example package"
arch=('x86_64')
url="https://example.com"
license=('MIT')
depends=('glibc' 'gtk3')
makedepends=()  # Don't list base-devel packages (gcc, make, etc.)
source=("${pkgname}-${pkgver}.tar.gz::https://example.com/download")
sha256sums=('REPLACEME')

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

### CMake package
```bash
makedepends=('cmake' 'ninja')

build() {
    cmake -B build -S "$pkgname-$pkgver" \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DBUILD_SHARED_LIBS=ON
    cmake --build build
}

package() {
    DESTDIR="$pkgdir" cmake --install build
}
```

### Python package (setup.py)
```bash
makedepends=('python-setuptools')
depends=('python')

build() {
    cd "$srcdir/$pkgname-$pkgver"
    python setup.py build
}

package() {
    cd "$srcdir/$pkgname-$pkgver"
    python setup.py install --root="$pkgdir" --optimize=1
}
```

## Validation

### Using namcap
```bash
namcap PKGBUILD           # Check PKGBUILD
namcap package.pkg.tar.zst # Check built package
```

### Using shellcheck
```bash
shellcheck --shell=bash --exclude=SC2034,SC2154,SC2164 PKGBUILD
```

## Best Practices Summary

1. **Use HTTPS** for all source URLs
2. **List ALL direct dependencies** - never transitive; exclude base-devel packages from makedepends
3. **Use b2 or sha512** for checksums
4. **Add PGP signatures** when available
5. **Use lowercase** package names
6. **No hyphens in pkgver** - use underscore
7. **Reset pkgrel to 1** on new upstream version
8. **Include LICENSE file** in package (0BSD for AUR repo)
9. **Use namcap** before submission
10. **Keep functions simple** and readable
11. **Always quote** "$pkgdir" and "$srcdir" to prevent path-related build failures
12. **Regenerate .SRCINFO** after every metadata change before pushing to AUR
13. **Use :: syntax** in source array if upstream filename is generic (e.g., v1.0.tar.gz)
14. **Prefix custom variables/functions** with underscore (_) to avoid conflicts with makepkg
15. **Never use $pkgdir or $srcdir** in .install scripts - they run on target system
16. **Use SPDX license identifiers** (e.g., GPL-3.0-or-later, MIT, BSD-3-Clause)

## Related Skills

- **aur-guides** - Main dispatcher
- **aur-package-guidelines** - General standards
- **aur-audit** - Validation tools
- **aur-makepkg** - Build process
- **aur-vcs-packages** - VCS-specific packages
- **aur-submission** - AUR submission
