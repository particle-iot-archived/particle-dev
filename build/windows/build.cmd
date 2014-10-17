@ECHO OFF

set BUILD=%CD%
pushd %BUILD%\..\common
set COMMON=%CD%
popd
pushd %BUILD%\..\..
set ROOT=%CD%
popd
set TARGET=%ROOT%\dist\windows
set APP_NAME=SparkIDE

call :GETTEMPDIR
mkdir %TEMP_DIR%

if exist "%TARGET%" DEL /Q %TARGET%
mkdir %TARGET%
cd %TEMP_DIR%
echo "Working directory is %TEMP_DIR%"
git clone --depth=1 https://github.com/atom/atom.git .

rem Copy resources
copy %BUILD%\sparkide.ico %TEMP_DIR%\resources\win\atom.ico
rem TODO: replace with 1024px image
copy %BUILD%\atom.png %TEMP_DIR%\resources\atom.png

echo "Patching code"
patch %TEMP_DIR%\src\browser\atom-application.coffee < %COMMON%\atom-application.patch
patch %TEMP_DIR%\src\atom.coffee < %COMMON%\atom.patch
patch %TEMP_DIR%\.npmrc < %COMMON%\npmrc.patch

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

echo "Bootstrap Atom"
call script/bootstrap

echo "Installing Spark IDE package"
git clone --depth=1 git@github.com:spark/spark-ide.git node_modules\spark-ide
cd node_modules\spark-ide
call ..\..\apm\node_modules\atom-package-manager\bin\apm.cmd install .
ls node_modules\serialport\build\serialport\v1.4.6\Release\
cd ..\..
node %COMMON%\append-package %TEMP_DIR%\package.json spark-ide "0.0.9"

echo "Build app"
call build\node_modules\.bin\grunt --gruntfile build\Gruntfile.coffee --install-dir "%TARGET%/%APP_NAME%"

echo "Build installer"
makensis /DSOURCE="%TARGET%\%APP_NAME%" /DOUT_FILE="%TARGET%\install.exe" %BUILD%\installer.nsi

goto :EOF

:GETTEMPDIR
set TEMP_DIR=%BUILD%\tmp-%RANDOM%-%TIME:~6,2%.tmp
if exist "%TEMP_DIR%" GOTO :GETTEMPDIR

:EOF
