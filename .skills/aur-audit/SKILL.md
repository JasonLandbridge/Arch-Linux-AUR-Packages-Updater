---
name: aur-audit
description: Comprehensive guide for auditing and validating Arch Linux packages and PKGBUILDs using automated tools and manual verification.
---

# Skill: aur-audit

## Purpose

Comprehensive guide for auditing and validating Arch Linux packages and PKGBUILDs. Covers automated tools (namcap, shellcheck), manual verification, common issues, and security checks to ensure packages meet Arch Linux standards before submission.

## When to Use This Skill

This skill should be used when:
- Validating a PKGBUILD before submission
- Auditing a built package
- Troubleshooting build issues
- Checking for security vulnerabilities
- Verifying dependency correctness
- Following code quality standards

## When NOT to Use This Skill

- For official Arch packages (they have separate review process)
- For packages that don't need validation before submission
- For pre-built binary packages

## Namcap

### Installation
```bash
pacman -S namcap
```

### Basic Usage
```bash
# Check PKGBUILD
namcap PKGBUILD

# Check built package
namcap package-1.0.0-1-x86_64.pkg.tar.zst

# Check with info messages
namcap -i PKGBUILD

# Machine-readable output
namcap -m PKGBUILD
```

### Output Tags

| Tag Type | Prefix | Meaning |
|----------|--------|---------|
| Error | `E:` | Must fix - something is wrong |
| Warning | `W:` | Should fix - potential issue |
| Info | `I:` | Optional - helpful hints |

### Common Error Messages

**Missing Dependencies**
```
E: Dependency gcc not satisfied
```
**Fix:** Add missing package to depends/makedepends

**Redundant Dependencies**
```
W: Dependency foo included and not needed
```
**Fix:** Remove unnecessary dependency

**Permission Issues**
```
E: Package contains world-writable file
E: Unnecessary permission change
```
**Fix:** Check file permissions in package()

**Missing License**
```
E: Missing custom license file
```
**Fix:** Add LICENSE file with license text

**Empty Directories**
```
W: Package contains empty directory
```
**Fix:** Remove empty dirs or add to options

### Running Namcap Effectively

```bash
# 1. Build the package first
makepkg

# 2. Check PKGBUILD
namcap PKGBUILD

# 3. Check built package
namcap *.pkg.tar.zst

# 4. Use info flag for suggestions
namcap -i PKGBUILD *.pkg.tar.zst
```

## ShellCheck

### Installation
```bash
pacman -S shellcheck
```

### Basic Usage
```bash
# Check PKGBUILD
shellcheck --shell=bash PKGBUILD

# Exclude common false positives
shellcheck --shell=bash \
  --exclude=SC2034 \
  --exclude=SC2154 \
  --exclude=SC2164 \
  PKGBUILD
```

### Common Warnings

| Code | Issue | Example |
|------|-------|---------|
| SC2034 | Unused variable | `epoch=` with no use |
| SC2154 | Referenced but not assigned | `$srcdir` in wrong function |
| SC2164 | cd fails without check | `cd "$srcdir"` without error check |

### Ignoring Warnings
```bash
# Add to PKGBUILD to ignore specific warnings
# shellcheck disable=SC2034
epoch=
# shellcheck enable=SC2034
```

## Manual Verification

### Dependency Check

```bash
# Find library dependencies
ldd /path/to/binary

# Find undefined symbols
readelf -d /path/to/binary | grep NEEDED

# List provided libraries
find "$pkgdir/usr/lib" -name "*.so*"

# Check for script shebangs
grep -r "^#!" "$pkgdir" | head -20
```

**Important:** namcap may miss runtime-loaded libraries via `dlopen()` or obscure links. Always verify manually with `ldd` and `readelf`.

### File Permission Check

```bash
# Check for dangerous permissions
find "$pkgdir" -perm -4000 -ls   # SUID
find "$pkgdir" -perm -2000 -ls   # SGID
find "$pkgdir" -perm -002 -ls    # World-writable

# Check for strange ownership
find "$pkgdir" -user root -group root
```

### Conflicts and Provides

```bash
# Check what's provided
pacman -Q | grep package-name

# Check conflicts
pacman -Si package-name
```

## Security Checks

### Source Verification

1. **HTTPS only** - No HTTP sources
2. **Checksums present** - b2 or sha512 preferred
3. **PGP signatures** - Use when available
4. **validpgpkeys** - Specify trusted keys

### Dangerous Patterns

```bash
# NEVER do this - security risk!
source=("http://example.com/file.tar.gz")  # HTTP!

# Always use HTTPS
source=("https://example.com/file.tar.gz")

# Verify checksums exist
sha256sums=('abc123...')  # Not SKIP or empty

# Use signatures when available
source=('file.tar.gz.asc')
validpgpkeys=('KEYFINGERPRINT')
```

### Malicious Code Detection

Watch for:
- Network calls in package() function
- Suspicious file modifications
- Hidden commands
- Downloaded executables without verification

### Namcap Limitations

namcap is powerful but not perfect. Remember:
- It may fail to detect libraries loaded at runtime via `dlopen()`
- It may miss "obscure links" where only a small part of a package requires a dependency
- **You are smarter than namcap** - verify with `ldd` and `readelf`

### VCS Source Integrity

For VCS sources (git, svn, hg), checksums must be handled specially:
```bash
# VCS sources use SKIP - source changes with each commit
source=("git+https://github.com/user/repo.git?branch=main")
sha256sums=('SKIP')
```

### Unique Filenames

Always use `::` syntax for source URLs with generic filenames:
```bash
# Prevents conflicts in shared SRCDEST directory
source=("${pkgname}-${pkgver}.tar.gz::https://example.com/download")
```

## Build Verification

### Test Build Process
```bash
# Clean build
makepkg -cf

# Check build logs for warnings
makepkg 2>&1 | tee build.log

# CRITICAL: Never build as root
# PKGBUILD scripts can contain arbitrary commands
# If only root is available, use:
# runuser -u nobody -- makepkg -s
```

### Check Package Contents
```bash
# List all files
tar -tf package.pkg.tar.zst

# List only binaries
tar -tf package.pkg.tar.zst | grep usr/bin

# List libraries
tar -tf package.pkg.tar.zst | grep usr/lib

# Check for forbidden paths
tar -tf package.pkg.tar.zst | grep -E "^(etc/bin|etc/sbin|var/tmp|tmp)"
```

## Common Issues and Fixes

### Missing Dependencies
**Error:** `E: Dependency not found`
**Fix:** Add to depends/makedepends

### Redundant Dependencies
**Error:** `W: Redundant dependency`
**Fix:** Remove from depends if in makedepends or base-devel

### Permission Issues
**Error:** `E: Unnecessary permission change`
**Fix:** Check install commands, use -Dm644 not -m644

### Missing License
**Error:** `E: Missing license`
**Fix:** Add LICENSE file and install in package()

### Directory Issues
**Error:** `W: Empty directory`
**Fix:** Add '!emptydirs' to options or remove directories

## Pre-submission Checklist

Before submitting to AUR, run these checks:

```bash
# 1. Build package
makepkg -s

# 2. Check PKGBUILD with namcap
namcap PKGBUILD

# 3. Check package with namcap
namcap *.pkg.tar.zst

# 4. Run shellcheck
shellcheck --shell=bash PKGBUILD

# 5. Verify file list
tar -tf *.pkg.tar.zst | head -30

# 6. Check for forbidden paths
tar -tf *.pkg.tar.zst | grep -E "^(etc/bin|var/tmp)"

# 7. Verify LICENSE exists
ls LICENSE

# 8. Check .SRCINFO is generated
cat .SRCINFO
```

## Validation Commands Summary

| Command | Purpose |
|---------|---------|
| `namcap PKGBUILD` | Check PKGBUILD issues |
| `namcap *.pkg.tar.zst` | Check package issues |
| `namcap -i PKGBUILD` | Info-level checks |
| `shellcheck --shell=bash PKGBUILD` | Bash syntax check |
| `makepkg -g >> PKGBUILD` | Generate checksums |
| `updpkgsums PKGBUILD` | Update checksums |
| `makepkg --printsrcinfo > .SRCINFO` | Generate .SRCINFO |

## CI/Automated Testing

### GitHub Actions Example
```yaml
- name: Validate PKGBUILD
  run: |
    namcap PKGBUILD || true
    shellcheck --shell=bash --exclude=SC2034,SC2154,SC2164 PKGBUILD || true
```

### Local CI Script
```bash
#!/bin/bash
set -e

echo "Validating PKGBUILD..."
namcap PKGBUILD
shellcheck --shell=bash --exclude=SC2034,SC2154,SC2164 PKGBUILD

echo "Building package..."
makepkg -s

echo "Checking package..."
namcap *.pkg.tar.zst

echo "All checks passed!"
```

## Pre-Submission Rules (Avoid Package Deletion)

Before submitting to the AUR, verify these rules:

### 1. No Duplicates
- Check official repositories: `pacman -Ss package-name`
- Check AUR: https://aur.archlinux.org/packages/
- Do not submit if package already exists

### 2. Usefulness
- Package must be useful to more than just a few people

### 3. Architecture Support
- AUR only supports x86_64
- Packages must work on this architecture

### 4. Naming Suffixes
| Suffix | Use Case |
|--------|----------|
| `-git`, `-svn`, `-hg` | Development versions (trunk/latest) not tied to specific release |
| `-bin` | Prebuilt binaries when source is available (except Java) |
| None | Stable releases with specific version |

### 5. Licensing
- Use SPDX identifiers in PKGBUILD license field
- Include LICENSE file (0BSD for AUR repository)

### 6. Only Use replaces When Renaming
- Use `conflicts` and `provides` for alternate versions instead

## Best Practices Summary

1. **Always use namcap** - On PKGBUILD and package
2. **Run shellcheck** - Validate bash syntax
3. **Verify checksums** - Never skip verification
4. **Check dependencies** - Use ldd/readelf
5. **Verify permissions** - No dangerous perms
6. **Include license** - LICENSE file required
7. **Test before submit** - Full build test

## Related Skills

- **aur-guides** - Main dispatcher
- **aur-pkgbuild** - PKGBUILD creation
- **aur-package-guidelines** - Standards
- **aur-submission** - AUR submission
- **aur-makepkg** - Build process
