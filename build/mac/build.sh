#!/bin/bash

BUILD=$(cd "$(dirname "$0")"; pwd)
ROOT=$(cd "$(dirname "$0")"; cd ../..; pwd)
TARGET="${ROOT}/dist/mac"
APP_NAME="Spark IDE"
TEMP_DIR=`mktemp -d tmp.XXXXXXXXXX`
TEMP_DIR="${BUILD}/${TEMP_DIR}"

install_package () {
  cd ${TARGET}/node_modules
  git clone --depth=1 $1 $2
  cd $2
  rm -rf .git
  npm install
}

if [ -d $TARGET ]; then rm -rf $TARGET ; fi
mkdir -p $TARGET
cd $TEMP_DIR
echo "Working directory is ${TEMP_DIR}"
git clone --depth=1 https://github.com/atom/atom.git .

# Copy resources
cp ${BUILD}/sparkide.icns ${TEMP_DIR}/resources/mac/atom.icns

# Patch code
patch ${TEMP_DIR}/resources/mac/atom-Info.plist < ${BUILD}/atom-Info.patch
patch ${TEMP_DIR}/src/browser/atom-application.coffee < ${BUILD}/atom-application.patch
patch ${TEMP_DIR}/src/atom.coffee < ${BUILD}/atom.patch
patch ${TEMP_DIR}/.npmrc < ${BUILD}/npmrc.patch

cd $TEMP_DIR
# Bootstrap Atom
script/bootstrap

echo "Installing 3rd party packages"
export ATOM_HOME=$TEMP_DIR
./apm/node_modules/atom-package-manager/bin/apm install language-arduino
./apm/node_modules/atom-package-manager/bin/apm install file-type-icons
./apm/node_modules/atom-package-manager/bin/apm install switch-header-source
./apm/node_modules/atom-package-manager/bin/apm install resize-panes
./apm/node_modules/atom-package-manager/bin/apm install maximize-panes
./apm/node_modules/atom-package-manager/bin/apm install move-panes
./apm/node_modules/atom-package-manager/bin/apm install swap-panes
mv packages/* node_modules/
unset ATOM_HOME

echo "Installing Spark IDE package"
git clone --depth=1 git@github.com:spark/spark-ide.git node_modules/spark-ide
cd node_modules/spark-ide
export ATOM_NODE_VERSION="0.17.1"
../../apm/node_modules/atom-package-manager/bin/apm install .
unset ATOM_NODE_VERSION
cd ../..

script/build --install-dir="${TARGET}/${APP_NAME}.app"
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
