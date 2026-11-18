#!/bin/bash
#
# Xcode Cloud post-clone step.
#
# platforms/ios (the Xcode workspace, the pods and the web bundle) is generated, not committed,
# so a fresh clone has nothing for Xcode Cloud to build. This script generates it the same way
# a local build does. Xcode Cloud reaches it through platforms/ios/ci_scripts/ci_post_clone.sh.
#
# It can be run by hand from a clean clone too. Note that it deletes and recreates platforms/ios.

set -euo pipefail

ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$ROOT"

export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ENV_HINTS=1
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 CI=true

echo "▶ Tools"
# The project needs Node 24 (see "engines" in package.json).
if ! node -v 2>/dev/null | grep -q '^v24\.'; then
    NODE24="$(brew --prefix)/opt/node@24/bin"
    [ -x "$NODE24/node" ] || brew install node@24
    export PATH="$NODE24:$PATH"
fi
command -v pod >/dev/null || brew install cocoapods
echo "node $(node -v), npm $(npm -v), pod $(pod --version)"

echo "▶ Dependencies"
npm ci

echo "▶ iOS project"
# In a clone this folder only holds the ci_scripts stub, and Cordova will not create the
# platform while the folder exists.
rm -rf platforms/ios
# Unattended, the Ionic CLI refuses to add a missing platform, so let Cordova create it (and
# install the plugins and pods) first. Cordova needs a www folder to recognise the project.
mkdir -p www
npx cordova prepare ios
NODE_ENV=production NODE_OPTIONS=--max-old-space-size=8192 \
    npx ionic cordova prepare ios --prod --no-interactive
git checkout -- platforms/ios/ci_scripts

# Xcode Cloud signs with the team that owns the workflow; the generated project names no team.
PROJECT="platforms/ios/App.xcodeproj/project.pbxproj"
if [ -n "${CI_TEAM_ID:-}" ] && ! grep -q "DEVELOPMENT_TEAM" "$PROJECT"; then
    echo "▶ Setting development team"
    sed -i.bak -E "s/^([[:space:]]*)(PRODUCT_NAME = .*;)\$/\\1\\2\\
\\1DEVELOPMENT_TEAM = ${CI_TEAM_ID};/" "$PROJECT"
    rm -f "$PROJECT.bak"
fi

test -d platforms/ios/App.xcworkspace
echo "✅ platforms/ios/App.xcworkspace is ready."
