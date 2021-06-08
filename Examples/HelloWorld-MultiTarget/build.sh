#!/bin/bash

xcodebuild clean build -quiet -workspace HelloWorld.xcworkspace -scheme "HelloWorld" CODE_SIGNING_REQUIRED=NO
# xcodebuild analyze -quiet -workspace HelloWorld.xcworkspace -scheme "HelloWorld" CODE_SIGNING_REQUIRED=NO

xcodebuild clean build -quiet -workspace HelloWorld.xcworkspace -scheme "HelloWorld-Cocoa" CODE_SIGNING_REQUIRED=NO
# xcodebuild analyze -quiet -workspace HelloWorld.xcworkspace -scheme "HelloWorld-Cocoa" CODE_SIGNING_REQUIRED=NO

xcodebuild clean build -quiet -destination 'platform=iOS Simulator,name=iPhone 8' -workspace HelloWorld.xcworkspace -scheme "HelloWorld-iOS" CODE_SIGNING_REQUIRED=NO
# xcodebuild analyze -quiet -destination 'platform=iOS Simulator,name=iPhone 8' -workspace HelloWorld.xcworkspace -scheme "HelloWorld-iOS" CODE_SIGNING_REQUIRED=NO

xcodebuild clean build -quiet -destination 'platform=tvOS Simulator,name=Apple TV' -workspace HelloWorld.xcworkspace -scheme "HelloWorld-tvOS" CODE_SIGNING_REQUIRED=NO
# xcodebuild analyze -quiet -destination 'platform=tvOS Simulator,name=Apple TV' -workspace HelloWorld.xcworkspace -scheme "HelloWorld-tvOS" CODE_SIGNING_REQUIRED=NO
