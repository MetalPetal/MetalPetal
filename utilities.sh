#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

cd "$BASEDIR/Utilities"

PS3="Run: "
options=("Generate Boilerplate" "Generate Umbrella Headers" "Generate Swift Package Sources" "Update Podspec" "All" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Generate Boilerplate")
            swift run main boilerplate-generator "$BASEDIR"
            break
            ;;
        "Generate Umbrella Headers")
            swift run main umbrella-header-generator "$BASEDIR"
            break
            ;;
        "Generate Swift Package Sources")
            swift run main swift-package-generator "$BASEDIR"
            break
            ;;
        "Update Podspec")
            swift run main podspec-generator "$BASEDIR"
            break
            ;;
        "All")
            swift run main boilerplate-generator "$BASEDIR"
            swift run main umbrella-header-generator "$BASEDIR"
            swift run main swift-package-generator "$BASEDIR"
            swift run main podspec-generator "$BASEDIR"
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done
