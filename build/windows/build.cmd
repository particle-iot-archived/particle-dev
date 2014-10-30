@ECHO OFF

set BUILD=%CD%
set COMMON=%BUILD%\..\common
set ROOT=%BUILD%\..\..
set TARGET=%ROOT%\dist\windows
set APP_NAME=Spark IDE
set SPARK_IDE_VERSION=0.0.13

call :GETTEMPDIR
mkdir %TEMP_DIR%

if exist "%TARGET%" DEL /Q %TARGET%
mkdir %TARGET%
cd %TEMP_DIR%
echo "Working directory is %TEMP_DIR%"
git clone --depth=1 https://github.com/atom/atom.git .
DEL /Q .git

echo "Copy resources"
copy %BUILD%\sparkide.ico %TEMP_DIR%\resources\win\atom.ico
copy %BUILD%\atom.png %TEMP_DIR%\resources\atom.png

cd %TEMP_DIR%

echo "Appending 3rd party packages to package.json"
node %COMMON%\append-package %TEMP_DIR%\package.json language-arduino "0.2.0"
node %COMMON%\append-package %TEMP_DIR%\package.json file-type-icons "0.4.4"
node %COMMON%\append-package %TEMP_DIR%\package.json switch-header-source "0.8.0"
node %COMMON%\append-package %TEMP_DIR%\package.json resize-panes "0.1.0"
node %COMMON%\append-package %TEMP_DIR%\package.json maximize-panes "0.1.0"
node %COMMON%\append-package %TEMP_DIR%\package.json move-panes "0.1.2"
node %COMMON%\append-package %TEMP_DIR%\package.json swap-panes "0.1.0"
node %COMMON%\append-package %TEMP_DIR%\package.json toolbar "0.0.9"
node %COMMON%\append-package %TEMP_DIR%\package.json monokai "0.8.0"
node %COMMON%\append-package %TEMP_DIR%\package.json welcome
node %COMMON%\append-package %TEMP_DIR%\package.json feedback

echo "Bootstrap Atom"
script/bootstrap

echo "Installing Spark IDE package"
git clone git@github.com:spark/spark-ide.git node_modules\spark-ide
cd node_modules\spark-ide
git checkout tags/%SPARK_IDE_VERSION%
..\..\apm\node_modules\atom-package-manager\bin\apm.cmd install . --verbose
ls -lha node_modules\serialport\build\serialport\v1.4.6\Release\
cd ..\..
node %COMMON%\append-package %TEMP_DIR%\package.json spark-ide "%SPARK_IDE_VERSION%"

echo "Installing Spark IDE welcome package"
git clone git@github.com:spark/welcome-spark-ide.git node_modules/welcome-spark-ide
node %COMMON%\append-package %TEMP_DIR%\package.json welcome-spark-ide "0.19.0"

echo "Installing Spark IDE feedback package"
git clone git@github.com:spark/feedback-spark-ide.git node_modules/feedback-spark-ide
node %COMMON%\append-package %TEMP_DIR%\package.json feedback-spark-ide "0.34.0"

echo "Patching code"
patch %TEMP_DIR%\src\browser\atom-application.coffee < %COMMON%\atom-application.patch
patch %TEMP_DIR%\src\atom.coffee < %COMMON%\atom.patch
patch %TEMP_DIR%\.npmrc < %COMMON%\npmrc.patch
patch %TEMP_DIR%\src\browser\auto-update-manager.coffee < %COMMON%\auto-update-manager.patch
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
:: App version
node %COMMON%\set-version %TEMP_DIR%\package.json %SPARK_IDE_VERSION%

echo "Building app"
build\node_modules\.bin\grunt --gruntfile build\Gruntfile.coffee --install-dir "%TARGET%/%APP_NAME%"

echo "Build installer"
makensis /DSOURCE="%TARGET%/%APP_NAME%" /DOUT_FILE="%TARGET%/install.exe" %BUILD%/installer.nsi

goto :EOF

:GETTEMPDIR
set TEMP_DIR=%BUILD%\tmp-%RANDOM%-%TIME:~6,2%.tmp
if exist "%TEMP_DIR%" GOTO :GETTEMPDIR

:EOF
