#/bin/bash

set -x

# Frameworks Test
xcodebuild clean test -project Criollo.xcodeproj -scheme "Criollo macOS" CODE_SIGNING_REQUIRED=NO
xcodebuild clean test -destination 'platform=iOS Simulator,name=iPhone 8' -project Criollo.xcodeproj -scheme "Criollo iOS" CODE_SIGNING_REQUIRED=NO
xcodebuild clean test -destination 'platform=tvOS Simulator,name=Apple TV' -project Criollo.xcodeproj -scheme "Criollo tvOS" CODE_SIGNING_REQUIRED=NO
