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
