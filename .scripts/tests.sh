#/bin/bash

set -x

# Frameworks Test
xcodebuild test -quiet -project Criollo.xcodeproj -scheme "Criollo macOS" CODE_SIGNING_REQUIRED=NO
xcodebuild test -quiet -destination 'platform=iOS Simulator,name=iPhone 11' -project Criollo.xcodeproj -scheme "Criollo iOS" CODE_SIGNING_REQUIRED=NO
xcodebuild test -quiet -destination 'platform=tvOS Simulator,name=Apple TV' -project Criollo.xcodeproj -scheme "Criollo tvOS" CODE_SIGNING_REQUIRED=NO
