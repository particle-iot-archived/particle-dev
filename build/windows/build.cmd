@ECHO OFF

set BUILD=%CD%
set ROOT=%BUILD%\..\..\
set TARGET=%ROOT%\dist\windows\
set APP_NAME=Spark IDE
call :GETTEMPDIR
rem mkdir %TEMP_DIR%
set TEMP_DIR=C:\Users\Wojtek\Documents\GitHub\spark-ide\build\windows\tmp-7856-25.tmp

rem if exist "%TARGET%" DEL /Q %TARGET%
rem mkdir %TARGET%
rem cd %TEMP_DIR%
echo "Working directory is %TEMP_DIR%"
rem git clone --depth=1 https://github.com/atom/atom.git .

rem Copy resources
copy %BUILD%\sparkide.ico %TEMP_DIR%\resources\win\atom.ico

rem Patch code
patch %TEMP_DIR%\src\browser\atom-application.coffee < %BUILD%\..\mac\atom-application.patch
patch %TEMP_DIR%\src\atom.coffee < %BUILD%\..\mac\atom.patch
patch %TEMP_DIR%\.npmrc < %BUILD%\..\mac\npmrc.patch

cd %TEMP_DIR%
rem script\build --install-dir="%TARGET%/%APP_NAME%.exe"

goto :EOF

:GETTEMPDIR
set TEMP_DIR=%BUILD%\tmp-%RANDOM%-%TIME:~6,2%.tmp
if exist "%TEMP_DIR%" GOTO :GETTEMPDIR

:EOF
