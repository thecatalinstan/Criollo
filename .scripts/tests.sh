#/bin/bash

set -x

# Frameworks Test
xcodebuild test -project Criollo.xcodeproj -scheme "Criollo macOS" CODE_SIGNING_REQUIRED=NO
xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 8' -project Criollo.xcodeproj -scheme "Criollo iOS" CODE_SIGNING_REQUIRED=NO
xcodebuild test -destination 'platform=tvOS Simulator,name=Apple TV' -project Criollo.xcodeproj -scheme "Criollo tvOS" CODE_SIGNING_REQUIRED=NO
