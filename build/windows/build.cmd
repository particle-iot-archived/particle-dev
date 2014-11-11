@ECHO OFF

set BUILD=%CD%
pushd %BUILD%\..\common
set COMMON=%CD%
popd
pushd %BUILD%\..\..
set ROOT=%CD%
popd
set TARGET=%ROOT%\dist\windows
set APP_NAME=Spark Dev
set SPARK_DEV_VERSION=0.0.15
set ATOM_VERSION=v0.144.0
set ATOM_NODE_VERSION=0.19.1

call :GETTEMPDIR
mkdir %TEMP_DIR%

if exist "%TARGET%" DEL /Q %TARGET%
mkdir %TARGET%
cd %TEMP_DIR%
echo "Working directory is %TEMP_DIR%"
wget https://github.com/atom/atom/archive/%ATOM_VERSION%.tar.gz -O - | tar -xz --strip-components=1

echo "Copy resources"
copy %BUILD%\sparkide.ico %TEMP_DIR%\resources\win\atom.ico
copy %BUILD%\atom.png %TEMP_DIR%\resources\atom.png

cd %TEMP_DIR%

echo "Appending 3rd party packages to package.json"
node %COMMON%\append-package %TEMP_DIR%\package.json language-arduino "0.2.0"
node %COMMON%\append-package %TEMP_DIR%\package.json file-type-icons "0.4.4"
node %COMMON%\append-package %TEMP_DIR%\package.json switch-header-source "0.8.0"
rem Disabled due to errors in cson
::node %COMMON%\append-package %TEMP_DIR%\package.json resize-panes "0.1.0"
node %COMMON%\append-package %TEMP_DIR%\package.json maximize-panes "0.1.0"
node %COMMON%\append-package %TEMP_DIR%\package.json move-panes "0.1.2"
node %COMMON%\append-package %TEMP_DIR%\package.json swap-panes "0.1.0"
node %COMMON%\append-package %TEMP_DIR%\package.json toolbar "0.0.9"
node %COMMON%\append-package %TEMP_DIR%\package.json monokai "0.8.0"
node %COMMON%\append-package %TEMP_DIR%\package.json welcome
node %COMMON%\append-package %TEMP_DIR%\package.json feedback
${COMMON}/append-package ${TEMP_DIR}/package.json release-notes

echo "Bootstrap Atom"
call script/bootstrap

echo "Installing Spark Dev package"
git clone git@github.com:spark/spark-dev.git node_modules\spark-dev
cd node_modules\spark-dev
git checkout tags/%SPARK_DEV_VERSION%
node -e "console.log('-> Atom ', process.env.ATOM_NODE_VERSION);"
call ..\..\apm\node_modules\atom-package-manager\bin\apm.cmd install . --verbose
ls node_modules\serialport\build\serialport\v1.4.6\Release\

cd ..\..
node %COMMON%\append-package %TEMP_DIR%\package.json spark-dev "%SPARK_DEV_VERSION%"

echo "Installing Spark welcome package"
git clone git@github.com:spark/welcome-spark.git node_modules/welcome-spark
node %COMMON%\append-package %TEMP_DIR%\package.json welcome-spark "0.19.0"

echo "Installing Spark feedback package"
git clone git@github.com:spark/feedback-spark.git node_modules/feedback-spark
node %COMMON%\append-package %TEMP_DIR%\package.json feedback-spark "0.34.0"

echo "Installing Spark release-notes-spark package"
git clone git@github.com:spark/release-notes-spark.git node_modules/release-notes-spark
node %COMMON%\append-package %TEMP_DIR%\package.json release-notes-spark "0.36.0"

echo "Installing Spark language-spark package"
git clone git@github.com:spark/language-spark.git node_modules/language-spark
node %COMMON%\append-package %TEMP_DIR%\package.json language-spark "0.3.0"

echo "Patching code"
patch %TEMP_DIR%\src\browser\atom-application.coffee < %COMMON%\atom-application.patch
patch %TEMP_DIR%\src\atom.coffee < %COMMON%\atom.patch
patch %TEMP_DIR%\.npmrc < %COMMON%\npmrc.patch
patch %TEMP_DIR%\src\browser\auto-update-manager.coffee < %COMMON%\auto-update-manager.patch
patch %TEMP_DIR%\build\tasks\codesign-task.coffee < %COMMON\%codesign-task.patch
:: Window title
patch %TEMP_DIR%\src\browser\atom-window.coffee < %COMMON%\atom-window.patch
patch %TEMP_DIR%\src/workspace.coffee < %COMMON%\workspace.patch
:: Menu items
patch %TEMP_DIR%\menus\darwin.cson < %COMMON%\darwin.patch
patch %TEMP_DIR%\menus\linux.cson < %COMMON%\linux.patch
patch %TEMP_DIR%\menus\win32.cson < %COMMON%\win32.patch
:: Settings package
patch %TEMP_DIR%\node_modules\settings-view\lib\settings-view.coffee < %COMMON%\settings-view.patch
copy %COMMON%\atom.png %TEMP_DIR%\node_modules\settings-view\images\atom.png
:: Exception Reporting package
patch %TEMP_DIR%\node_modules\exception-reporting\lib\reporter.coffee < %COMMON%\reporter.patch
:: App version
node %COMMON%\set-version %TEMP_DIR%\package.json %SPARK_DEV_VERSION%

echo "Building app"
call build\node_modules\.bin\grunt --gruntfile build\Gruntfile.coffee --install-dir "%TARGET%\%APP_NAME%"

echo "Building installer"
makensis /DSOURCE="%TARGET%\%APP_NAME%" /DOUT_FILE="%TARGET%\InstallSparkDev.exe" %BUILD%\installer.nsi

goto :EOF

:GETTEMPDIR
set TEMP_DIR=%BUILD%\tmp-%RANDOM%-%TIME:~6,2%.tmp
if exist "%TEMP_DIR%" GOTO :GETTEMPDIR

:EOF
