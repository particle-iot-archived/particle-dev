#!/bin/bash

set BUILD=%CD%
set ROOT=%BUILD%/../../
set TARGET=%ROOT%/dist/windows/
set APP_NAME=Spark IDE
call :GETTEMPDIR
mkdir %TEMP_DIR%

if exist "%TARGET%" DEL %TARGET%
mkdir %TARGET%
cd %TEMP_DIR%
git clone --depth=1 https://github.com/atom/atom.git .
#
cd %TEMP_DIR%
script/build --install-dir="%TARGET%/%APP_NAME%.exe"

goto :EOF

:GETTEMPDIR
set TEMP_DIR=%BUILD%\tmp-%RANDOM%-%TIME:~6,5%.tmp
if exist "%TEMP_DIR%" GOTO :GETTEMPDIR

:EOF
