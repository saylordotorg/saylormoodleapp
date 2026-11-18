#!/bin/sh

# Xcode Cloud only looks for its scripts in a ci_scripts folder next to the workspace.
# The workspace itself is generated, so this stub is the one committed file in platforms/ios.
# The real work is in scripts/xcode-cloud/ci_post_clone.sh.

exec "$CI_PRIMARY_REPOSITORY_PATH/scripts/xcode-cloud/ci_post_clone.sh"
