#/bin/bash

set -x

# Frameworks Test

xcodebuild build-for-testing -derivedDataPath "./build/macOS" -quiet -destination "platform=macOS" -project Criollo.xcodeproj -scheme "Criollo macOS" CODE_SIGNING_REQUIRED=NO
xcodebuild test-without-building -xctestrun "$(set +x; ls -1 ./build/macOS/Build/Products/*.xctestrun|tail -n 1)" -destination "platform=macOS"

xcodebuild build-for-testing -derivedDataPath "./build/iOS" -quiet -destination "platform=iOS Simulator,name=iPhone 8" -project Criollo.xcodeproj -scheme "Criollo iOS" CODE_SIGNING_REQUIRED=NO
xcodebuild test-without-building -xctestrun "$(set +x; ls -1 ./build/iOS/Build/Products/*.xctestrun|tail -n 1)" -destination "platform=iOS Simulator,name=iPhone 8"

xcodebuild build-for-testing -derivedDataPath "./build/tvOS" -quiet -destination "platform=tvOS Simulator,name=Apple TV" -project Criollo.xcodeproj -scheme "Criollo tvOS" CODE_SIGNING_REQUIRED=NO
xcodebuild test-without-building -xctestrun "$(set +x; ls -1 ./build/tvOS/Build/Products/*.xctestrun|tail -n 1)" -destination "platform=tvOS Simulator,name=Apple TV"

rm -rf "./build"
