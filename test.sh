#!/bin/bash

echo "------------------"
echo "Somke Test (macOS)"
echo "------------------"

swift build
swift test

echo "------------------"
echo "Somke Test (iOS Simulator)"
echo "------------------"

if hash xcpretty 2>/dev/null; then
    xcodebuild build -scheme MetalPetal -destination 'platform=iOS Simulator,name=iPhone 11' -workspace . | xcpretty
    xcodebuild test -scheme MetalPetal -destination 'platform=iOS Simulator,name=iPhone 11' -workspace . | xcpretty
else
    xcodebuild build -scheme MetalPetal -destination 'platform=iOS Simulator,name=iPhone 11' -workspace .
    xcodebuild test -scheme MetalPetal -destination 'platform=iOS Simulator,name=iPhone 11' -workspace .
fi
