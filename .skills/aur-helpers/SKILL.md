---
name: aur-helpers
description: Comprehensive guide for using AUR helper tools like yay, paru, pikaur, and aura for automating package management.
---

# Skill: aur-helpers

## Purpose

Comprehensive guide for using AUR helper tools (yay, paru, pikaur, aura, etc.). Covers installation, configuration, workflows, and comparisons to help AI agents assist users with AUR package management using their preferred helper.

## When to Use This Skill

This skill should be used when:
- Installing or configuring an AUR helper
- Managing AUR packages using a helper
- Troubleshooting AUR helper issues
- Choosing an AUR helper for a user
- Migrating between AUR helpers

## When NOT to Use This Skill

- For building packages manually (use aur-makepkg skill)
- For official repo packages (use pacman directly)
- When you prefer manual AUR workflow

## Overview

AUR helpers automate the process of finding, building, and installing packages from the AUR. They handle dependency resolution, PKGBUILD cloning, building, and installation.

### Common Features
- Search AUR and repositories
- Automatic dependency resolution
- PKGBUILD viewing/editing
- Package building
- AUR comment interaction

## yay

### Installation
```bash
# From AUR
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Or from official repos (if available)
pacman -S yay
```

### Basic Usage
```bash
# Upgrade all packages (including AUR)
yay -Syu

# Install package
yay -S package-name

# Search AUR
yay -Ss search-term

# Remove package
yay -R package-name

# Clean cache
yay -Scc
```

### Configuration
```bash
# Edit config
yay --editmenu      # Edit PKGBUILD before build
yay --nodiffmenu    # Skip diff menu
yay --useask        # Use pacman confirmation

# Options in yay.conf
--aur
--repo
--both (default)
```

### Search
```bash
# Search AUR only
yay -Ss term

# Search with details
yay -Si package-name

# Search both repos and AUR
yay -s term
```

## paru

### Installation
```bash
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

### Basic Usage
```bash
# Upgrade everything
paru -Syu

# Install package
paru -S package-name

# Search AUR
paru -Ss term

# View PKGBUILD
paru -Sp package-name

# Clean cache
paru -Scc
```

### Features
- Colorized output
- Better git support
- News reading (pacnews)
- Bin mirror list

### Configuration
```bash
# ~/.config/paru/paru.conf
[options]
# AUR-only by default
AUROnly

# Skip PKGBUILD review
NoEditMenu

# Remove unneeded deps
RemoveUnrequired
```

## pikaur

### Installation
```bash
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -fsi
```

### Basic Usage
```bash
# Sync everything
pikaur -Syu

# Install package
pikaur -S package-name

# Search
pikaur -Ss term

# Interactive install
pikaur -Sgi package-name
```

### Features
- Native Rust implementation
- Dynamic dependency resolution
- AUR voting
- pkgbuild editing

## aura

### Installation
```bash
git clone https://aur.archlinux.org/aura.git
cd aura
makepkg -si
```

### Basic Usage
```bash
# Full system upgrade
aura -Syu

# Install package
aura -S package-name

# Search
aura -Ss term

# Orphans
aura -A
```

### Features
- Haskell implementation
- Official repo and AUR support
- Package downgrade
- ABS support

## Comparison

| Feature | yay | paru | pikaur | aura |
|---------|-----|------|--------|------|
| Language | Go | Rust | Rust | Haskell |
| Speed | Fast | Fast | Fast | Medium |
| Dependencies | Low | Low | Low | High |
| AUR Only | No | No | No | Yes |
| Features | Good | Excellent | Good | Good |

### Choosing a Helper

**yay** - Best for:
- Users familiar with pacman syntax
- Need AUR + official repos
- Good balance of features

**paru** - Best for:
- Maximum features
- Modern UI
- Fast Rust implementation

**pikaur** - Best for:
- Dynamic dependency resolution
- AUR voting integration

**aura** - Best for:
- Haskell preference
- Need ABS support

## Configuration Files

### yay (~/.config/yay/config.json)
```json
{
  "aururl": "https://aur.archlinux.org",
  "cloneDir": "~/AUR",
  "buildDir": "~/AUR",
  "absDir": "~/ABS",
  "editor": "vim",
  "pacman": "sudo pacman",
  "makepkg": "makepkg",
  "novelUpdate": false,
  "bottomup": true,
  "sudevel": false,
  "singlelineresults": false,
  "develcheck": false,
  "upgrade": true,
  "cleanAfterInstall": false
}
```

### paru (~/.config/paru/paru.conf)
```ini
[options]
PgpFetch
Devel
UpgradeMenu
NewsOnUpgrade
BottomUp
UseAsk
PkgListsByOrigin

[bin]
Shower
```

## Workflow Examples

### Install New Package
```bash
# Using yay
yay -S package-name

# Using paru
paru -S package-name

# Using pikaur
pikaur -S package-name

# Using aura
aura -S package-name
```

### System Upgrade
```bash
# yay - include AUR upgrades
yay -Syu

# paru - same interface
paru -Syu

# pikaur
pikaur -Syu

# aura
aura -Syu
```

### Search Packages
```bash
# Search AUR
yay -Ss search-term
paru -Ss search-term
pikaur -Ss search-term

# Search official repos
yay -Ss ^term
paru -Ss ^term
```

### Remove Package
```bash
# Remove with dependencies
yay -Rs package-name
paru -Rs package-name

# Remove completely
yay -Rns package-name
paru -Rns package-name
```

## AUR-Specific Operations

### View PKGBUILD
```bash
# yay
yay -Sp package-name

# paru
paru -Sp package-name

# pikaur
pikaur -Sp package-name
```

### Edit PKGBUILD
```bash
# yay - automatic
yay -S package-name --editmenu

# paru - automatic
paru -S package-name --editmenu
```

### View AUR Comments
```bash
# yay
yay -C package-name

# Direct URL
xdg-open https://aur.archlinux.org/packages/package-name/
```

### AUR Vote
```bash
# pikaur - vote from CLI
pikaur --vote package-name
```

## Troubleshooting

### Key Issues
```bash
# Refresh keys
yay --refresh --gpgdir /etc/pacman.d/gnupg

# Or use pacman directly
pacman-key --refresh-keys
```

### Cache Issues
```bash
# Clean cache
yay -Scc
paru -Scc
pikaur -Scc
```

### Build Failures
```bash
# Rebuild from scratch
yay -S package-name --rebuild

# Clean build
yay -Scc && yay -S package-name
```

### Dependency Issues
```bash
# Skip dependency check
yay -S package-name --nodepcheck

# Install deps only
makepkg -s
```

## Security Considerations

### Always Review PKGBUILD
```bash
# Always view before install
yay -S package-name --editmenu
paru -S package-name --editmenu
```

### Signature Verification
```bash
# Enable checking
yay --pgpfetch
paru --pgpfetch
```

### Trusted Users
- Only install PKGBUILDs from trusted sources
- Check package comments
- Review source URLs

## Common Commands by Helper

| Action | yay | paru | pikaur |
|--------|-----|------|--------|
| Upgrade | -Syu | -Syu | -Syu |
| Install | -S | -S | -S |
| Search | -Ss | -Ss | -Ss |
| Remove | -R | -R | -R |
| Clean | -Scc | -Scc | -Scc |
| View PKGBUILD | -Sp | -Sp | -Sp |

## Related Skills

- **aur-guides** - Main dispatcher
- **aur-pkgbuild** - PKGBUILD creation
- **aur-submission** - AUR submission
- **aur-makepkg** - Building
- **aur-pacman** - Pacman usage
- **aur-audit** - Validation
