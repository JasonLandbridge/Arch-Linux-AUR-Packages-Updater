---
name: aur-makepkg
description: Comprehensive guide for building Arch Linux packages using makepkg, covering the build process, configuration, debugging, and optimization.
---

# Skill: aur-makepkg

## Purpose

Comprehensive guide for building Arch Linux packages using makepkg. Covers the build process, configuration, environment variables, debugging, and optimization for creating packages from PKGBUILDs.

## When to Use This Skill

This skill should be used when:
- Building packages from PKGBUILDs
- Configuring makepkg behavior
- Debugging build failures
- Optimizing build process
- Creating custom package configurations

## When NOT to Use This Skill

- For using pacman directly (see aur-pacman skill)
- For official package building (uses devtools)
- For non-Arch Linux systems

## Overview

makepkg is a script provided by the pacman package that automates building packages. It reads a PKGBUILD and performs these steps in order:

1. **Verify** - Check if dependencies and makedepends are met
2. **Download** - Fetch sources and verify integrity (hashes or PGP signatures)
3. **Extract** - Unpack sources and apply patches (prepare() function)
4. **Build** - Compile software (build() function)
5. **Package** - Install into fake root ($pkgdir), strip symbols, compress man pages
6. **Archive** - Create .pkg.tar.zst file

## Basic Usage

### Simple Build
```bash
# Build package (requires dependencies)
makepkg -s

# Build and install automatically
makepkg -si

# Skip dependency installation
makepkg
```

### Cleaning
```bash
# Clean up after build (default behavior)
makepkg -c

# Clean build directory BEFORE building (pristine environment)
makepkg -C
```

### Force Overwrite
```bash
# Overwrite existing package in output directory
makepkg -f
```

### Output Control
```bash
# Output directories are configured in makepkg.conf
# Package output directory
PKGDEST=/home/packages

# Source download directory  
SRCDEST=/home/sources

# Sign the package
makepkg --sign
```

## Configuration Files

Configuration hierarchy (later files override earlier ones):
1. `/etc/makepkg.conf` - Global
2. `/etc/makepkg.conf.d/*.conf` - System-wide drops
3. `~/.makepkg.conf` or `$XDG_CONFIG_HOME/pacman/makepkg.conf` - User-specific

### /etc/makepkg.conf

Global configuration for all users.

```bash
# Package output directory
PKGDEST=/home/packages

# Source download directory (recommended for VCS packages)
SRCDEST=/home/sources

# Log directory
LOGDEST=/home/buildlogs

# GPG key for signing
GPGKEY="your fingerprint"

# Parallel compilation
MAKEFLAGS="-j$(nproc)"
```

### ~/.makepkg.conf

User-specific overrides.

```bash
# Disable signature verification (NOT RECOMMENDED)
# Use --skippgpcheck flag or add !sign to BUILDENV

# Use all CPU cores
MAKEFLAGS="-j$(nproc)"

# Color output
USE_COLOR=1
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| MAKEFLAGS | Compiler flags (e.g., -j4) |
| PKGDEST | Package output directory |
| SRCDEST | Source download directory |
| SRCPKGDEST | Source package directory |
| LOGDEST | Build log directory |
| PACKAGER | Package maintainer name (email obfuscated) |
| GPGKEY | GPG key for signing |
| BUILDENV | Build tools (ccache, distcc) |

### Example Usage
```bash
# Build with specific settings
MAKEFLAGS="-j4" PKGDEST="/tmp/packages" makepkg -s

# Set maintainer info (email obfuscated per AUR guidelines)
PACKAGER="Your Name <you at example dot com>" makepkg
```

## Build Process Stages

### 1. Package Verification
```bash
# Download sources and verify integrity (no extraction or building)
makepkg --verifysource

# Download and extract only (no build)
makepkg --nobuild
```

### 2. Dependency Resolution
```bash
# Install missing dependencies and build
makepkg -s
```

### 3. Source Extraction
```bash
# Default: sources are extracted automatically

# Skip extraction (if sources already present)
makepkg --noextract
```

### 4. Building
```bash
# Build package (default behavior)
makepkg

# Parallel compilation is controlled via MAKEFLAGS, not a flag
MAKEFLAGS="-j$(nproc)" makepkg
```

### 5. Package Creation
```bash
# Create package (default, runs after build)
makepkg

# Package only (skip build if already done)
makepkg --pkg

# Sign package
makepkg --sign
```

## Debugging Builds

### View Build Log
```bash
# Default location: current directory (where PKGBUILD is)
less ./mypackage.log

# Or specify log location
LOGDEST=/tmp/logs makepkg
```

### Interactive Build
```bash
# Log all function output to files
makepkg --log

# Debug mode (shows commands as they run)
makepkg --debug
```

### Common Build Issues

**Missing Dependencies**
```bash
# Install missing deps
makepkg -s

# Check what's missing
makepkg -o 2>&1 | grep "could not satisfy"
```

**Permission Errors**
```bash
# CRITICAL: Never build as root - PKGBUILDs can contain arbitrary commands
# If only root is available, use:
runuser -u nobody -- makepkg -s

# Fix ownership
chown -R $USER:$USER ./mypackage
```

**Checksum Mismatch**
```bash
# Update checksums
updpkgsums PKGBUILD

# Or manually generate
makepkg -g >> PKGBUILD
```

**Network Issues**
```bash
# Use proxy
export HTTP_PROXY=http://proxy:8080
export HTTPS_PROXY=http://proxy:8080

# Use specific downloader
DLAGENTS=("ftp::/usr/bin/curl -fC - -o %o %u")
```

**Incompatible Flags**
If build succeeds manually but fails via makepkg, incompatible makepkg.conf settings may be the cause. Disable defaults in PKGBUILD:

```bash
options=('!makeflags' '!buildflags' '!debug')
```

## Package Signing

### Generate GPG Key
```bash
gpg --full-gen-key
# Use RSA, 4096 bits, expires in 2 years
```

### Sign Package
```bash
# Sign during build
makepkg --sign

# Sign existing package
gpg --detach-sign package.pkg.tar.zst

# Sign package and append
gpg --armor --detach-sign --yes
```

### Verify Package
```bash
# Verify signature
gpg --verify package.pkg.tar.zst.sig

# Verify with pacman
pacman -U package.pkg.tar.zst
```

## Optimization

### Parallel Compilation
```bash
# In makepkg.conf
MAKEFLAGS="-j$(nproc)"

# Or on command line (note: -j is for makepkg's MAKEFLAGS, not a direct flag)
MAKEFLAGS="-j$(nproc)" makepkg
```

### Build Environment
```bash
# makepkg assumes base-devel is installed
# Never list base-devel members in makedepends:
# WRONG:  makedepends=('gcc' 'make')
# CORRECT: makedepends=()  # base-devel provides these
```

### Mold Linker (Optional)
For faster builds, use the mold linker:

```bash
# Install mold
pacman -S mold

# Add to LDFLAGS in makepkg.conf
LDFLAGS="-fuse-ld=mold"
```

### CCACHE
```bash
# Install ccache
pacman -S ccache

# Enable in /etc/makepkg.conf or ~/.makepkg.conf:
BUILDENV=(!distcc color ccache !check)
```

### DistCC
```bash
# Install distcc
pacman -S distcc

# Enable in /etc/makepkg.conf or ~/.makepkg.conf:
BUILDENV=(distcc !color !ccache !check)

# Configure hosts in /etc/distcc/hosts or via environment
DISTCC_HOSTS="localhost host1 host2"
```

## Source Management

### Unique Filenames (:: Syntax)
When a source URL doesn't include a useful filename, use `::` to specify one:

```bash
source=("https://example.com/download.php?file=12345::https://example.com/file.tar.gz")
```

This renames the downloaded file to `12345` instead of the query-string filename.

### Generating .SRCINFO
For AUR submission, generate .SRCINFO:

```bash
makepkg --printsrcinfo > .SRCINFO
```

**Mandatory for AUR:** Regenerate .SRCINFO whenever metadata changes (pkgver, depends, etc.). The AUR web interface uses this file - if missing or outdated, the correct version won't display.

### Custom Download Agents
```bash
# In /etc/makepkg.conf or PKGBUILD
DLAGENTS=('http::/usr/bin/curl -LC - -b cookies.txt -c cookies.txt -o %o %u'
          'https::/usr/bin/wget --passive-ftp -O %o %u'
          'git::git clone %u %o')
```

### Offline Build
```bash
# Download and verify sources (prepares for offline build)
makepkg --verifysource

# Then build offline (sources must already be in SRCDEST)
makepkg
```

## PKGBUILD Testing

### Dry Run
```bash
# Download and extract only (no build)
makepkg --nobuild

# Skip prepare() function
makepkg --noprepare
```

### Debug Functions
```bash
# Debug specific function
bash -x PKGBUILD
```

## Package Output

### Formats
```bash
# Default: .pkg.tar.zst (compressed)
makepkg

# Create source package (PKG.src.tar.zst)
makepkg --source

# Create source package with ALL sources (including downloaded during build)
makepkg --allsource

# Package only (skip build)
makepkg --pkg
```

### Package Naming
The package name and version are defined in the PKGBUILD via `pkgname` and `pkgver` variables - they cannot be overridden via command-line flags.

## Common Commands Summary

| Command | Purpose |
|---------|---------|
| `makepkg -s` | Syncdeps: Install missing dependencies |
| `makepkg -i` | Install: Build and install with pacman |
| `makepkg -c` | Clean: Remove work files after build |
| `makepkg -C` | Cleanbuild: Remove $srcdir before build |
| `makepkg -f` | Force: Overwrite existing package |
| `makepkg -g` | Geninteg: Generate integrity checksums |
| `updpkgsums` | Preferred tool to update checksums |
| `makepkg --allsource` | Create source package with all sources |
| `makepkg --printsrcinfo` | Generate .SRCINFO for AUR |
| `makepkg --sign` | Sign the package |
| `makepkg --verifysource` | Verify: Download and check integrity |
| `makepkg --skippgpcheck` | Skip PGP signature verification |

## Best Practices

1. **Never build as root** - Use a normal user (PKGBUILDs can contain arbitrary commands)
2. **Always verify sources** - Check checksums with `updpkgsums`
3. **Keep build logs** - Use `makepkg --log` for debugging
4. **Use ABS** - Get official PKGBUILDs with `abs`
5. **Test in clean environment** - Use `archbuild` or containers
6. **Sign packages** - For secure distribution
7. **Configure output dirs** - Keep organized
8. **Use SPDX license identifiers** - E.g., `GPL-3.0-or-later`, not `GPL3`
9. **Quote variables** - Use `"$pkgdir"` and `"$srcdir"` to handle spaces
10. **License AUR submissions** - Recommend 0BSD license for repo files
11. **Use namcap** - Audit PKGBUILDs and packages for common errors
12. **Never use $pkgdir/$srcdir in .install** - Scripts run chrooted on target system, not build environment

## Auditing Tools

```bash
# Install namcap
pacman -S namcap

# Audit PKGBUILD
namcap PKGBUILD

# Audit built package
namcap package.pkg.tar.zst

# Check for shell scripting errors
shellcheck --shell=bash --exclude=SC2034,SC2154,SC2164 PKGBUILD
```

## Install Scripts

`.install` scripts run chrooted in the target system's installation directory. They do NOT have access to build-time variables like `$pkgdir` or `$srcdir`. Only use actual system paths:

```bash
# WRONG - uses build-time variables
post_install() {
  rm -rf "$pkgdir"/usr/share/cache
}

# CORRECT - uses system paths
post_install() {
  rm -rf /usr/share/cache
}
```

## Related Skills

- **aur-guides** - Main dispatcher
- **aur-pkgbuild** - PKGBUILD creation
- **aur-audit** - Validation
- **aur-submission** - AUR submission
- **aur-package-guidelines** - Standards
