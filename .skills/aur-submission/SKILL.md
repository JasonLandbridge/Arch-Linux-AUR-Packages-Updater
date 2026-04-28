---
name: aur-submission
description: Comprehensive guide for submitting packages to the AUR, maintaining existing packages, and managing the complete AUR package lifecycle.
---

# Skill: aur-submission

## Purpose

Comprehensive guide for submitting packages to the Arch User Repository (AUR), maintaining existing packages, and managing the complete AUR package lifecycle. Covers submission rules, Git workflows, package maintenance, and request types.

## When to Use This Skill

This skill should be used when:
- Submitting a new package to the AUR
- Updating an existing AUR package
- Maintaining AUR packages
- Transferring package ownership
- Requesting package deletion or merge
- Setting up SSH access for AUR

## When NOT to Use This Skill

- For submitting to official Arch repos (uses different workflow via Package Maintainers)
- For packages already in official repositories
- For packages that violate AUR submission rules

## AUR Overview

The AUR (Arch User Repository) is a community-driven repository for PKGBUILDs. Unlike official packages, AUR packages are unofficial and user-maintained.

### Key Points
- No binary packages - only source files (PKGBUILD, .SRCINFO, patches)
- Community maintained - use at your own risk
- Git-based workflow for submissions
- Requires SSH key for write access

## Submission Rules

### Absolute Requirements
1. **Not in official repos** - Package must not exist in core/extra/community
2. **Useful** - Must have some demand
3. **x86_64 architecture** - AUR only supports x86_64
4. **Unique** - No duplicate packages
5. **Licensed** - Include LICENSE file (0BSD recommended)

### Prohibited
- Packages already in official repos (unless adding extra features/patches - see below)
- Prebuilt binaries (use -bin suffix if source available)
- Packages that break systems
- Malicious or harmful software

### Exception for Modified Official Packages
If you want to submit a package that exists in official repos but includes extra features or patches:
- Use a different pkgname (e.g., `screen-sidebar`)
- Add `conflicts=('screen')` and `provides=('screen')`
- Document the differences in the PKGBUILD

### Naming Requirements
- Follow Arch naming conventions
- Use appropriate suffixes (-git, -bin, etc.)
- Check for existing packages first
- Use SPDX license identifiers (e.g., GPL-3.0-or-later, MIT)

### Multiple Licenses
If a package uses multiple licenses, use the single-string SPDX syntax:
```bash
license=('GPL-2.0-or-later OR LGPL-2.1-or-later')
```

### Allowed Suffixes
- `-git`, `-svn`, `-hg`, etc. - VCS packages (must use appropriate suffix)
- `-bin` - Prebuilt binaries (when source available)
- Version numbers in name generally avoided, but permitted for major versions of software that cannot trivially roll along with dependencies (e.g., `gtk2`, `qt5`)

## Before Submission

### Pre-flight Checklist

1. **Verify package doesn't exist in official repos**
   ```bash
   pacman -Ss package-name
   https://archlinux.org/packages/
   ```

2. **Check AUR for duplicates**
   ```bash
   https://aur.archlinux.org/packages/
   ```

3. **Test build locally**
   ```bash
   makepkg -s
   ```

4. **Run validation**
   ```bash
   # Check PKGBUILD for issues
   namcap PKGBUILD
   
   # Shellcheck with recommended exclusions for standard packaging variables
   shellcheck --shell=bash --exclude=SC2034,SC2154,SC2164 PKGBUILD
   
   # Also check the built package
   namcap *.pkg.tar.zst
   ```

5. **Generate .SRCINFO**
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

6. **Verify LICENSE file exists**
   - Use 0BSD license for your PKGBUILD and helper files (recommended)
   - SPDX license identifiers required in PKGBUILD (e.g., GPL-3.0-or-later, MIT)
   - Packages missing a license or without 0BSD are not eligible for promotion to official repositories

## SSH Setup

### Generate SSH Key
```bash
ssh-keygen -t ed25519 -C "aur@archlinux.org"
```

### Configure SSH
```bash
# ~/.ssh/config
Host aur.archlinux.org
  User aur
  IdentityFile ~/.ssh/aur
  # Optional: specific key type
  # IdentityFile ~/.ssh/aur_ed25519
```

### Add Key to AUR
1. Go to https://aur.archlinux.org/account/
2. Add public key to "SSH Public Key" field
3. Test connection: `ssh aur@aur.archlinux.org`

## Git Workflow

### Initial Setup (New Package)

```bash
# Clone empty repository
git -c init.defaultBranch=master clone ssh://aur@aur.archlinux.org/pkgname.git

# Add files
cp /path/to/PKGBUILD .
cp /path/to/.SRCINFO .
cp /path/to/LICENSE .
# Add any patches or install files

# Commit (include at least PKGBUILD, .SRCINFO, and LICENSE)
git add PKGBUILD .SRCINFO LICENSE
git commit -m "Initial package release"

# Push
git push origin master
```

**Note:** You are strongly encouraged to license your submission (PKGBUILD and helper files) under the 0BSD license. Packages without a license or with non-0BSD licenses are not eligible for promotion to official repositories.

### Updating Existing Package

```bash
# Clone existing package
git clone ssh://aur@aur.archlinux.org/pkgname.git
cd pkgname

# Update PKGBUILD
$EDITOR PKGBUILD

# Regenerate .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# Update checksums if needed
updpkgsums PKGBUILD

# Commit with meaningful message (include PKGBUILD, .SRCINFO, LICENSE)
git add PKGBUILD .SRCINFO LICENSE
git commit -m "Update to version 2.0.0"

# Push
git push
```

### Important Notes
- Always push to `master` branch
- Use meaningful commit messages
- Include version updates in commit message
- Don't commit mere pkgver bumps for VCS packages

## Maintainer Attribution

### Format (top of PKGBUILD)
```bash
# Maintainer: Your Name <you at example dot com>
# Contributor: Original Submitter <author at example dot com>
```

### Adopting a Package
When adopting a package, move the previous maintainer(s) to Contributors:
```bash
# Maintainer: Your Name <you at example dot com>
# Contributor: Previous Maintainer <old at example dot com>
```

### Email Obfuscation (Recommended)

To protect maintainers and contributors from spam while allowing contact through the AUR web interface, write the email in a human-readable but bot-resistant format:

**Standard Format (as per AUR guidelines):**
```bash
# Maintainer: Your Name <you at example dot com>
```

This format:
- Uses the phrase "at" and "dot" to obfuscate the email
- Appears in AUR comments for users to contact
- Prevents simple email harvesting while remaining understandable
- Is the recommended format by AUR submission guidelines

**Alternative: AUR Web Interface Contact**
```bash
# Maintainer: Your Name <username at aur dot archlinux dot org>
```
- Users can contact you through the AUR package page
- No personal email exposed
- Most privacy-conscious option

### Rules
- Include at least Maintainer line
- Use "at dot" format for email obfuscation
- Add Contributors for previous maintainers
- Update when taking over maintenance
- Consider using AUR web interface contact instead of real email

## .SRCINFO

### Purpose
Provides package metadata to AUR web interface without parsing PKGBUILD.
**Mandatory:** Must be regenerated whenever PKGBUILD metadata changes, otherwise the AUR web interface will fail to display correct version numbers.

### Generation
```bash
makepkg --printsrcinfo > .SRCINFO
```

### When to Regenerate
- Version updates
- Dependency changes
- Any PKGBUILD metadata change
- Always regenerate before pushing to AUR

## Package Maintenance

### Responsibilities
1. **Respond to comments** - Help users with issues
2. **Update regularly** - Don't abandon packages (or actively disown)
3. **Fix build failures** - Address issues promptly
4. **Improve PKGBUILD** - Incorporate user suggestions
5. **Check for updates** - Monitor upstream for changes
6. **Don't "submit and forget"** - Maintainers must actively maintain their packages

### Disowning Packages
If you can no longer maintain a package:
1. Post to AUR comments that you're disowning
2. Use web interface to disown
3. Or email aur-general@lists.archlinux.org
4. Do not simply abandon packages - actively disown so others can adopt

### Orphan Request
If a package has no active maintainer:
- Comment on package asking to adopt
- Submit orphan request via web interface
- Wait 2 weeks before automatic orphaning
- **Auto-accept:** If package has been flagged out-of-date for at least 180 days, orphan requests are automatically accepted

## Request Types

### Deletion Request
When to use:
- Package is broken beyond repair
- Already in official repos
- License issues

How to request:
1. Click "Submit Request" on package page
2. Select "Deletion"
3. Provide reason

### Merge Request
When to use:
- Package renamed
- Absorbed by another package

How to request:
1. Click "Submit Request" on package page
2. Select "Merge"
3. Specify target package

### Orphan Request
When to use:
- Maintainer unresponsive
- Package abandoned

How to request:
1. Click "Submit Request" on package page
2. Select "Orphan"

## Common Issues

### Push Rejected
- Check SSH configuration
- Verify public key in AUR account
- Ensure pushing to master branch

### Version Not Updating
- Did you regenerate .SRCINFO? (Mandatory - AUR web interface won't show correct version without it)
- Did you commit changes?
- Did you push to remote?

### VCS Package Updates
- Do NOT commit mere pkgver bumps for VCS packages (e.g., -git)
- Only commit when there are structural changes to the PKGBUILD (new dependencies, build changes, etc.)
- VCS packages are not "out of date" just because upstream has new commits

### Missing Dependencies
- Run `makepkg -s` to install deps
- Check PKGBUILD for typos

### Build Failures
- Test locally first
- Check for updated dependencies
- Look at comments on similar packages

## AUR vs Official Repos

### Differences
| Aspect | AUR | Official |
|--------|-----|----------|
| Review | None | Yes (Package Maintainers) |
| Support | Community | Package Maintainers |
| Stability | Varies | Tested |
| Updates | Manual | Automatic |
| Packages | Source only | Binary |

### When to Use AUR
- Package not in official repos
- Modified version of official package (with different pkgname and conflicts)
- Development version (VCS)
- Personal packages

### Voting and Promotion
- **Voting:** Community members can vote for packages; voting indicates interest and helps prioritize packages for promotion
- **Promotion to Extra:** Popular AUR packages (often those with at least 10 votes) may be moved to the official extra repository if a Package Maintainer is willing to support them

## Best Practices Summary

1. **Test locally** before pushing
2. **Validate** with namcap
3. **Generate .SRCINFO** before push
4. **Include LICENSE**
5. **Use meaningful commits**
6. **Respond to users**
7. **Update regularly** or disown
8. **Don't submit duplicates**

## Related Skills

- **aur-guides** - Main dispatcher
- **aur-pkgbuild** - PKGBUILD creation
- **aur-package-guidelines** - Standards
- **aur-audit** - Validation
- **aur-makepkg** - Building
