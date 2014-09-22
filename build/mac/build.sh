#!/bin/bash

BUILD=$(cd "$(dirname "$0")"; pwd)
ROOT=$(cd "$(dirname "$0")"; cd ../..; pwd)
TARGET="${ROOT}/dist/mac"

install_package () {
  cd ${TARGET}/node_modules
  git clone --depth=1 $1 $2
  cd $2
  rm -rf .git
  npm install
}

if [ -d $TARGET ]; then rm -r $TARGET ; fi
mkdir -p $TARGET
cd $TARGET
git clone --depth=1 https://github.com/atom/atom.git .

# Copy resources
cp ${BUILD}/sparkide.icns ${TARGET}/resources/mac/atom.icns

# Patch code
patch ${TARGET}/resources/mac/atom-Info.plist < ${BUILD}/atom-Info.patch
patch ${TARGET}/src/browser/atom-application.coffee < ${BUILD}/atom-application.patch
patch ${TARGET}/src/atom.coffee < ${BUILD}/atom.patch
patch ${TARGET}/.npmrc < ${BUILD}/npmrc.patch
patch ${TARGET}/package.json < ${BUILD}/package.patch

cd $TARGET
script/build --install-dir="${TARGET}/Spark IDE.app"
