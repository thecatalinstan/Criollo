#!/bin/bash

xcodebuild clean build -quiet -workspace HTTPAuthentication.xcworkspace -scheme HTTPAuthentication CODE_SIGNING_REQUIRED=NO
