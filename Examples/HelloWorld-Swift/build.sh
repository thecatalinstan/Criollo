#!/bin/bash

xcodebuild clean build -quiet -workspace HelloWorld-Swift.xcworkspace -scheme HelloWorld-Swift CODE_SIGNING_REQUIRED=NO
