#!/bin/bash

xcodebuild clean build -quiet -destination "platform=iOS Simulator,name=iPhone 8" -workspace SecureHTTPServer.xcworkspace -scheme SecureHTTPServer CODE_SIGNING_REQUIRED=NO
