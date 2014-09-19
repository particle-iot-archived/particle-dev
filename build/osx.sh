#!/bin/bash

ROOT=`realpath ../`
TARGET="${ROOT}dist/osx"

if [ -d $TARGET ]; then rm -r $TARGET ; fi
mkdir -p $TARGET
cd $TARGET
git clone https://github.com/atom/atom.git .
script/build --install-dir=${TARGET}/Applications/SparkIDE.app
