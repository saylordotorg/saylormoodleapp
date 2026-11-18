#!/bin/bash

# The push plugin's Objective-C code imports "Moodle-Swift.h", a header Xcode names after
# the app. Now that the app is called "Saylor University" that header would be generated as
# "Saylor_University-Swift.h" and the iOS build fails, so keep the name the plugin expects.
# The setting goes on the app target only (next to its PRODUCT_NAME), not on the pods.

PROJECT="platforms/ios/App.xcodeproj/project.pbxproj"

if [[ -f "$PROJECT" ]] && ! grep -q "SWIFT_OBJC_INTERFACE_HEADER_NAME" "$PROJECT"; then
    echo "Setting Swift header name in $PROJECT"
    sed -i.bak -E 's/^([[:space:]]*)(PRODUCT_NAME = .*;)$/\1\2\
\1SWIFT_OBJC_INTERFACE_HEADER_NAME = "Moodle-Swift.h";/' "$PROJECT"
    rm -f "$PROJECT.bak"
fi

# The Firebase pods still declare iOS 9-11 as their minimum, which Xcode 27 refuses to build.
# Raise every pod target to the app's own minimum.

PODS="platforms/ios/Pods/Pods.xcodeproj/project.pbxproj"
OLD_TARGET='IPHONEOS_DEPLOYMENT_TARGET = (9|1[0-4])\.[0-9]+;'

if [[ -f "$PODS" ]] && grep -qE "$OLD_TARGET" "$PODS"; then
    echo "Raising pod deployment targets to iOS 15 in $PODS"
    sed -i.bak -E "s/$OLD_TARGET/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/" "$PODS"
    rm -f "$PODS.bak"
fi
