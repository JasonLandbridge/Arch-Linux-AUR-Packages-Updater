---
name: aur-vcs-packages
description: Comprehensive guide for creating and maintaining Version Control System (VCS) packages in the AUR, covering git, svn, hg, bzr, and darcs packages.
---

# Skill: aur-vcs-packages

## Purpose

Comprehensive guide for creating and maintaining Version Control System (VCS) packages in the AUR. Covers git, svn, hg, bzr, and darcs packages, pkgver updates, and VCS package best practices.

## When to Use This Skill

This skill should be used when:
- Creating a -git, -svn, -hg, -bzr, or -darcs package
- Updating VCS packages
- Converting a package to track upstream development
- Setting up pkgver for automatic updates

## When NOT to Use This Skill

- For stable release packages (use regular aur-pkgbuild instead)
- For packages tracking specific tagged releases (not development)
- For non-VCS sources

## Overview

VCS packages track development versions of software using version control systems. They use suffixes like -git, -svn, -hg to indicate the VCS type.

### Common Suffixes
- `-git` - Git repositories
- `-svn` - Subversion repositories
- `-hg` - Mercurial repositories
- `-bzr` - Bazaar repositories
- `-darcs` - Darcs repositories

## PKGBUILD Structure

### Basic VCS PKGBUILD

```bash
pkgname=package-name-git
pkgver=1.2.3.r123.gabcdef
pkgrel=1
pkgdesc="Description of the package"
arch=('x86_64')
url="https://github.com/user/repo"
license=('MIT')
depends=('some-dependency')
makedepends=('git' 'some-dev-package')
provides=("package-name=${pkgver}")
conflicts=('package-name')
source=("${pkgname}::git+https://github.com/user/repo.git")
sha256sums=('SKIP')

pkgver() {
  cd "$srcdir/${pkgname}"
  # Extract version with r delimiter for monotonicity
  printf "%s.r%s.g%s" \
    "$(git tag --sort=-version:refname | head -1 | sed 's/^v//')" \
    "$(git rev-list --count HEAD)" \
    "$(git rev-parse --short HEAD)"
}

build() {
  cd "$srcdir/${pkgname}"
  ./configure --prefix=/usr
  make
}

package() {
  cd "$srcdir/${pkgname}"
  make DESTDIR="$pkgdir" install
}
```

### pkgver Function

The pkgver function updates the version string automatically. **Use the r delimiter** to ensure version monotonicity.

#### Git Examples
```bash
# Tag-based versioning with r delimiter (recommended standard)
pkgver() {
  cd "$srcdir/${pkgname}"
  printf "%s.r%s.g%s" \
    "$(git describe --tags | sed 's/^v//')" \
    "$(git rev-list --count HEAD)" \
    "$(git rev-parse --short HEAD)"
}

# Alternative: Tag-based with version:refname sorting
pkgver() {
  cd "$srcdir/${pkgname}"
  printf "%s.r%s.g%s" \
    "$(git tag --sort=-version:refname | head -1 | sed 's/^v//')" \
    "$(git rev-list --count HEAD)" \
    "$(git rev-parse --short HEAD)"
}

# Simpler tag-based
pkgver() {
  cd "$srcdir/${pkgname}"
  git describe --tags | sed 's/^v//'
}

# Date-based versioning
pkgver() {
  cd "$srcdir/${pkgname}"
  date +%Y%m%d
}
```

#### Subversion Examples
```bash
pkgver() {
  cd "$srcdir/${pkgname}"
  printf "r%s" "$(svn info | grep Revision | awk '{print $2}')"
}
```

#### Mercurial Examples
```bash
pkgver() {
  cd "$srcdir/${pkgname}"
  printf "r%s" "$(hg identify -n)"
}
```

## Source Array

### Git Sources
```bash
# Clone specific branch (use fragment, not query)
source=("${pkgname}::git+https://github.com/user/repo.git#branch=main")

# Clone specific tag (use fragment)
source=("${pkgname}::git+https://github.com/user/repo.git#tag=v1.0.0")

# Clone at specific commit (use fragment)
source=("${pkgname}::git+https://github.com/user/repo.git#commit=abc123")

# PGP-signed revision
source=("${pkgname}::git+https://github.com/user/repo.git?signed#branch=main")

# With submodules (use prepare())
source=("${pkgname}::git+https://github.com/user/repo.git")
options=('!emptydirs')
```

### Subversion Sources
```bash
source=("svn+svn://svn.example.com/repo/trunk")
```

### Mercurial Sources
```bash
source=("hg+https://bitbucket.org/user/repo")
```

**Note:** Use fragments (#) for branches/tags/commits, not query strings (?). Query (?) is reserved for signed revisions.

## .SRCINFO for VCS

```bash
pkgbase = package-name-git
	pkgdesc = Description
	url = https://github.com/user/repo
	makedepends = git
	provides = package-name=1.2.3.r123.gabcdef
	conflicts = package-name
	arch = x86_64
	license = MIT

pkgname = package-name-git
	pkgver = 1.2.3.r123.gabcdef
	pkgrel = 1
	depends = some-dep
```

**Important:** Keep .SRCINFO in sync with PKGBUILD. If using versioned provides in PKGBUILD (`provides=("package-name=${pkgver}")`), the .SRCINFO must also include the version to avoid metadata mismatches on the AUR web interface.

## Updating VCS Packages

### Manual Update
```bash
# Clone the repository
git clone ssh://aur@aur.archlinux.org/package-name-git.git
cd package-name-git

# Pull latest changes
git pull

# Run pkgver to test
makepkg -o

# Update checksums (if needed)
updpkgsums

# Build and test
makepkg -s

# Regenerate .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# Only commit if there are structural PKGBUILD changes:
# - New dependencies
# - Build system changes
# - Not just pkgver bumps!

git add PKGBUILD .SRCINFO
git commit -m "Add new dependency or fix build"
git push
```

**Important:** Do not commit mere pkgver bumps. VCS packages are not considered "out of date" simply because upstream has new commits.

### Automatic pkgver

The pkgver function runs automatically during build:
```bash
makepkg -s
# pkgver() is called automatically
```

## Common Patterns

### Git with autogen/autoconf
```bash
build() {
  cd "$srcdir/${pkgname}"
  [[ -f configure ]] || autoreconf -fi
  ./configure --prefix=/usr
  make
}
```

### Git with meson/ninja
```bash
build() {
  cd "$srcdir/${pkgname}"
  meson setup build --prefix=/usr
  ninja -C build
}

package() {
  cd "$srcdir/${pkgname}"
  DESTDIR="$pkgdir" ninja -C build install
}
```

### Git with CMake
```bash
build() {
  cd "$srcdir/${pkgname}"
  cmake -B build -DCMAKE_INSTALL_PREFIX=/usr
  cmake --build build
}

package() {
  cd "$srcdir/${pkgname}"
  DESTDIR="$pkgdir" cmake --install build
}
```

## Branch vs Tag Packages

### Branch Package (-git)
Tracks the latest commit on a branch:
```bash
pkgname=package-name-git
source=("${pkgname}::git+https://github.com/user/repo.git#branch=main")
```

### Tag Package
Tracks specific releases:
```bash
pkgname=package-name
source=("${pkgname}::git+https://github.com/user/repo.git#tag=v1.0.0")
```

## Best Practices

### Naming
- Use `-git`, `-svn`, `-hg` suffix for VCS packages
- Use versioned provides: `provides=("package-name=${pkgver}")`
- Provide stable release package without suffix
- Check for existing packages before creating

### pkgver
- **Always use r delimiter** (e.g., `1.2.3.r123`) for version monotonicity
- Include commit count and hash for git
- Use meaningful version format
- Don't bump pkgrel for VCS updates (just pkgver)
- **Do NOT commit mere pkgver bumps** - VCS packages are not "out of date" just because upstream has new commits. Only commit when there are structural changes to the PKGBUILD (new deps, build changes, etc.)

### Sources
- Use HTTPS when possible
- Specify branch or tag when known (use fragment syntax: `#branch=main`)
- Use unique source names with `::` syntax to avoid SRCDEST conflicts
- Use SKIP for checksums (git provides integrity)
- **Never use shallow clones** - not supported by Arch

### Maintenance
- Test builds regularly
- Set up aur-keep or similar for automatic updates
- Consider using maintainer scripts
- Regenerate .SRCINFO whenever metadata changes

## Common Issues

### Large Repository
```bash
# Note: Shallow clones (#depth=1) are NOT supported by Arch
# Build will fail if upstream rebases history

# Use git-fetch-submodules for large repos
source=("${pkgname}::git+https://github.com/user/repo.git")
options=('!emptydirs')
```

### Submodules
```bash
# Add submodule URLs directly to source array (recommended)
source=("${pkgname}::git+https://github.com/user/repo.git"
        "git+https://github.com/user/submodule1.git"
        "git+https://github.com/user/submodule2.git")
sha256sums=('SKIP' 'SKIP' 'SKIP')

prepare() {
  cd "$srcdir/${pkgname}"
  git submodule update --init --recursive
}
```

### Detached HEAD
```bash
prepare() {
  cd "$srcdir/${pkgname}"
  git checkout master  # or main
}
```

## Verification Commands

```bash
# Check VCS sources are valid
makepkg --verifysource

# Build package
makepkg -s

# Update version
makepkg -o
pkgver

# Generate .SRCINFO
makepkg --printsrcinfo > .SRCINFO
```

## Related Skills

- **aur-guides** - Main dispatcher
- **aur-pkgbuild** - PKGBUILD creation
- **aur-submission** - AUR submission
- **aur-makepkg** - Building
- **aur-audit** - Validation
