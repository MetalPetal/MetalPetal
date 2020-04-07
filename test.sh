#!/bin/bash

set -e
set -u
set -o pipefail

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

echo "------------------"
echo "Somke Test (macCatalyst)"
echo "------------------"

if hash xcpretty 2>/dev/null; then
    xcodebuild build -scheme MetalPetal -destination 'platform=macOS,variant=Mac Catalyst' -workspace . | xcpretty
    xcodebuild test -scheme MetalPetal -destination 'platform=macOS,variant=Mac Catalyst' -workspace . | xcpretty
else
    xcodebuild build -scheme MetalPetal -destination 'platform=macOS,variant=Mac Catalyst' -workspace .
    xcodebuild test -scheme MetalPetal -destination 'platform=macOS,variant=Mac Catalyst' -workspace .
fi

echo "------------------"
echo "Build (Generic iOS Device)"
echo "------------------"

if hash xcpretty 2>/dev/null; then
    xcodebuild build -scheme MetalPetal -destination generic/platform=iOS -workspace . | xcpretty
else
    xcodebuild build -scheme MetalPetal -destination generic/platform=iOS -workspace .
fi
