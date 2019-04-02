#/bin/bash

set -x

# Frameworks Build & Test
xcodebuild clean build -quiet -project Criollo.xcodeproj -scheme "Criollo macOS" CODE_SIGNING_REQUIRED=NO
xcodebuild test -quiet -project Criollo.xcodeproj -scheme "Criollo macOS" CODE_SIGNING_REQUIRED=NO

xcodebuild clean build -quiet -project Criollo.xcodeproj -scheme "Criollo iOS" CODE_SIGNING_REQUIRED=NO
xcodebuild test -quiet -destination 'platform=iOS Simulator,name=iPhone X' -project Criollo.xcodeproj -scheme "Criollo iOS" CODE_SIGNING_REQUIRED=NO

xcodebuild clean build -quiet -project Criollo.xcodeproj -scheme "Criollo tvOS" CODE_SIGNING_REQUIRED=NO
xcodebuild test -quiet -destination 'platform=tvOS Simulator,name=Apple TV' -project Criollo.xcodeproj -scheme "Criollo tvOS" CODE_SIGNING_REQUIRED=NO


# Apps
xcodebuild clean build -quiet -project Criollo.xcodeproj -scheme "Criollo macOS App" CODE_SIGNING_REQUIRED=NO
xcodebuild clean build -quiet -project Criollo.xcodeproj -destination 'platform=iOS Simulator,name=iPhone X' -scheme "Criollo iOS App" CODE_SIGNING_REQUIRED=NO
xcodebuild clean build -quiet -project Criollo.xcodeproj -destination 'platform=tvOS Simulator,name=Apple TV' -scheme "Criollo tvOS App" CODE_SIGNING_REQUIRED=NO

# Update cocoapods master repo
pod repo update --silent

# Examples
cd Examples

cd HelloWorld
pod install --silent
xcodebuild clean build -quiet -workspace HelloWorld.xcworkspace -scheme "HelloWorld" CODE_SIGNING_REQUIRED=NO || exit $PIPESTATUS
cd ../

cd HelloWorld-MultiTarget
pod install --silent
xcodebuild clean build -quiet -workspace HelloWorld.xcworkspace -scheme "HelloWorld" CODE_SIGNING_REQUIRED=NO || exit $PIPESTATUS
xcodebuild clean build -quiet -workspace HelloWorld.xcworkspace -scheme "HelloWorld-Cocoa" CODE_SIGNING_REQUIRED=NO || exit $PIPESTATUS
xcodebuild clean build -quiet -destination 'platform=iOS Simulator,name=iPhone X' -workspace HelloWorld.xcworkspace -scheme "HelloWorld-iOS" CODE_SIGNING_REQUIRED=NO || exit $PIPESTATUS
xcodebuild clean build -quiet -destination 'platform=tvOS Simulator,name=Apple TV' -workspace HelloWorld.xcworkspace -scheme "HelloWorld-tvOS" CODE_SIGNING_REQUIRED=NO || exit $PIPESTATUS
cd ../

cd HelloWorld-ObjC
pod install --silent
xcodebuild clean build -quiet -workspace HelloWorld-ObjC.xcworkspace -scheme "HelloWorld-ObjC" CODE_SIGNING_REQUIRED=NO || exit $PIPESTATUS
cd ../

cd HelloWorld-Swift
pod install --silent
xcodebuild clean build -quiet -workspace HelloWorld-Swift.xcworkspace -scheme "HelloWorld-Swift" CODE_SIGNING_REQUIRED=NO || exit $PIPESTATUS
cd ../

cd LongRequest
pod install --silent
xcodebuild clean build -quiet -workspace LongRequest.xcworkspace -scheme "LongRequest" CODE_SIGNING_REQUIRED=NO || exit $PIPESTATUS
cd ../

cd SecureHTTPServer
pod install --silent
xcodebuild clean build -quiet -destination 'platform=iOS Simulator,name=iPhone X' -workspace SecureHTTPServer.xcworkspace -scheme "SecureHTTPServer" CODE_SIGNING_REQUIRED=NO || exit $PIPESTATUS
cd ../

cd ServerStats
pod install --silent
xcodebuild clean build -quiet -workspace CriolloServerStats.xcworkspace -scheme "CriolloServerStats" CODE_SIGNING_REQUIRED=NO || exit $PIPESTATUS
cd ../

cd ../
