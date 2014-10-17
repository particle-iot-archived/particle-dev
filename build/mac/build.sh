#!/bin/bash

BUILD=$(cd "$(dirname "$0")"; pwd)
COMMON=$(cd "$(dirname "$0")"; cd ../common; pwd)
ROOT=$(cd "$(dirname "$0")"; cd ../..; pwd)
TARGET="${ROOT}/dist/mac"
APP_NAME="Spark IDE"
TEMP_DIR=`mktemp -d tmp.XXXXXXXXXX`
TEMP_DIR="${BUILD}/${TEMP_DIR}"
SPARK_IDE_VERSION="0.0.10"

if [ -d $TARGET ]; then rm -rf $TARGET ; fi
mkdir -p $TARGET
cd $TEMP_DIR
echo "Working directory is ${TEMP_DIR}"
git clone --depth=1 https://github.com/atom/atom.git .

# Copy resources
cp ${BUILD}/sparkide.icns ${TEMP_DIR}/resources/mac/atom.icns

# Patch code
patch ${TEMP_DIR}/resources/mac/atom-Info.plist < ${BUILD}/atom-Info.patch
patch ${TEMP_DIR}/src/browser/atom-application.coffee < ${COMMON}/atom-application.patch
patch ${TEMP_DIR}/.npmrc < ${COMMON}/npmrc.patch
patch ${TEMP_DIR}/src/atom.coffee < ${COMMON}/atom.patch

cd $TEMP_DIR

# Append 3rd party packages to package.json
${COMMON}/append-package ${TEMP_DIR}/package.json language-arduino "0.2.0"
${COMMON}/append-package ${TEMP_DIR}/package.json file-type-icons "0.4.4"
${COMMON}/append-package ${TEMP_DIR}/package.json switch-header-source "0.8.0"
${COMMON}/append-package ${TEMP_DIR}/package.json resize-panes "0.1.0"
${COMMON}/append-package ${TEMP_DIR}/package.json maximize-panes "0.1.0"
${COMMON}/append-package ${TEMP_DIR}/package.json move-panes "0.1.2"
${COMMON}/append-package ${TEMP_DIR}/package.json swap-panes "0.1.0"

# Bootstrap Atom
script/bootstrap

echo "Installing Spark IDE package"
git clone git@github.com:spark/spark-ide.git node_modules/spark-ide
cd node_modules/spark-ide
git checkout tags/${SPARK_IDE_VERSION}
../../apm/node_modules/atom-package-manager/bin/apm install .
ls -lha node_modules/serialport/build/serialport/v1.4.6/Release/
cd ../..
${COMMON}/append-package ${TEMP_DIR}/package.json spark-ide ${SPARK_IDE_VERSION}

build/node_modules/.bin/grunt --gruntfile build/Gruntfile.coffee --install-dir "${TARGET}/${APP_NAME}.app"

# rm -rf $TEMP_DIR

# Build DMG
TEMPLATE="${HOME}/tmp/template.dmg"
WC_DMG="${TARGET}/image.dmg"
MASTER_DMG="${TARGET}/Spark IDE.dmg"
WC_DIR="${TARGET}/image"
cp $TEMPLATE $WC_DMG
mkdir -p $WC_DIR
hdiutil attach $WC_DMG -noautoopen -quiet -mountpoint $WC_DIR
rm -rf "${WC_DIR}/${APP_NAME}.app"
ditto -rsrc "${TARGET}/${APP_NAME}.app" "${WC_DIR}/${APP_NAME}.app"
WC_DEV=`hdiutil info | grep "${WC_DIR}" | grep "/dev/disk" | awk '{print $1}'`
hdiutil detach $WC_DEV -quiet -force
rm -f $MASTER_DMG
hdiutil convert "${WC_DMG}" -quiet -format UDZO -imagekey zlib-level=9 -o "${MASTER_DMG}"
rm -rf $WC_DIR
rm -f $WC_DMG
