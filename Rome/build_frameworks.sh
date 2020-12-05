#!/bin/bash

set -e
set -u
set -o pipefail

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

echo "Working directory: ${BASEDIR}"

cd "${BASEDIR}"

if [ -d Products ]; then
  rm -rf Products
fi

mkdir Products

if [ -d build ]; then
  rm -rf build
fi

build_framework() {
  local config="$1"

  mkdir build

  cp "${config}.podfile" build/Podfile

  cd build

  pod install

  cd ..

  cp -r build/Rome Products/${config}

  if [ -d build/dSYM ]; then
    cp -r build/dSYM Products/${config}/dSYM
  fi

  rm -rf build
}

build_framework "iOS"
build_framework "iOS-Swift"
build_framework "macOS-Swift"
build_framework "tvOS-Swift"