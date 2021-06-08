#!/bin/bash

xcodebuild clean build -quiet -workspace LongRequest.xcworkspace -scheme LongRequest CODE_SIGNING_REQUIRED=NO
