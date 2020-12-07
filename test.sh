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
echo "Somke Test (tvOS Simulator)"
echo "------------------"

if hash xcpretty 2>/dev/null; then
    xcodebuild build -scheme MetalPetal -destination 'platform=tvOS Simulator,name=Apple TV' -workspace . | xcpretty
    xcodebuild test -scheme MetalPetal -destination 'platform=tvOS Simulator,name=Apple TV' -workspace . | xcpretty
else
    xcodebuild build -scheme MetalPetal -destination 'platform=tvOS Simulator,name=Apple TV' -workspace .
    xcodebuild test -scheme MetalPetal -destination 'platform=tvOS Simulator,name=Apple TV' -workspace .
fi

echo "------------------"
echo "Build (iOS Device)"
echo "------------------"

if hash xcpretty 2>/dev/null; then
    xcodebuild build -scheme MetalPetal -destination generic/platform=iOS -workspace . | xcpretty
else
    xcodebuild build -scheme MetalPetal -destination generic/platform=iOS -workspace .
fi

echo "------------------"
echo "Build (tvOS Device)"
echo "------------------"

if hash xcpretty 2>/dev/null; then
    xcodebuild build -scheme MetalPetal -destination generic/platform=tvOS -workspace . | xcpretty
else
    xcodebuild build -scheme MetalPetal -destination generic/platform=tvOS -workspace .
fi
