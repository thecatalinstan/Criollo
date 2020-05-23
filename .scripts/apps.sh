#/bin/bash

set -x

# Apps
xcodebuild clean build analyze -quiet -project Criollo.xcodeproj -scheme "Criollo macOS App" CODE_SIGNING_REQUIRED=NO
xcodebuild clean build analyze -quiet -project Criollo.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 8' -scheme "Criollo iOS App" CODE_SIGNING_REQUIRED=NO
xcodebuild clean build analyze -quiet -project Criollo.xcodeproj -destination 'platform=tvOS Simulator,name=Apple TV' -scheme "Criollo tvOS App" CODE_SIGNING_REQUIRED=NO
