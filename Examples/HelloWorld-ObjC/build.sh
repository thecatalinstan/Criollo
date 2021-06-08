#!/bin/bash

xcodebuild clean build -quiet -workspace HelloWorld-ObjC.xcworkspace -scheme HelloWorld-ObjC CODE_SIGNING_REQUIRED=NO
