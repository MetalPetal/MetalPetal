#!/bin/bash

BASEDIR="$(dirname $0)"

SOURCE_DIR="$BASEDIR/Frameworks/MetalPetal/"

cd "$BASEDIR/BoilerplateGenerator"

swift run BoilerplateGenerator $SOURCE_DIR
