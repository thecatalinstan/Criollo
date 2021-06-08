#!/bin/bash

set -x

# Frameworks Build
xcodebuild clean analyze -quiet -project Criollo.xcodeproj -scheme "Criollo macOS" CODE_SIGNING_REQUIRED=NO
xcodebuild clean analyze -quiet -destination 'platform=iOS Simulator,name=iPhone 8' -project Criollo.xcodeproj -scheme "Criollo iOS" CODE_SIGNING_REQUIRED=NO
xcodebuild clean analyze -quiet -destination 'platform=tvOS Simulator,name=Apple TV' -project Criollo.xcodeproj -scheme "Criollo tvOS" CODE_SIGNING_REQUIRED=NO
