#!/bin/bash

set -x

# Apps
xcodebuild clean build analyze -quiet -project Criollo.xcodeproj -scheme "Criollo macOS App"
xcodebuild clean build analyze -quiet -project Criollo.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 8' -scheme "Criollo iOS App"
xcodebuild clean build analyze -quiet -project Criollo.xcodeproj -destination 'platform=tvOS Simulator,name=Apple TV' -scheme "Criollo tvOS App"


xcodebuild clean build analyze -quiet -project Criollo.xcodeproj -scheme "Criollo SPM"
