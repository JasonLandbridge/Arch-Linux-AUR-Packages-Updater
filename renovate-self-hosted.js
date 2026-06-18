module.exports = {
  platform: 'github',
  repositories: ['JasonLandbridge/Arch-Linux-AUR-Packages-Updater'],
  onboarding: false,
  requireConfig: 'required',
  branchPrefix: 'renovate-selfhosted/',
  gitAuthor: 'JasonLandbridge <15127381+JasonLandbridge@users.noreply.github.com>',
  username: 'JasonLandbridge',
  allowedCommands: ['^bash \\.github/scripts/renovate-refresh-aur-package\\.sh [A-Za-z0-9._/-]+$'],
  allowPostUpgradeCommandTemplating: true,
};
