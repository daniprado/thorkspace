REM Thorkspace MinInstall.bat
REM
REM Copyright (C) 2018 - Daniel Prado (dpradom@argallar.com)
REM
REM This program is free software: you can redistribute it and/or modify
REM it under the terms of the GNU General Public License as published by
REM the Free Software Foundation, either version 3 of the License, or
REM (at your option) any later version.
REM
REM This program is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM GNU General Public License for more details.
REM
REM You should have received a copy of the GNU General Public License
REM along with this program.  If not, see <http://www.gnu.org/licenses/>.

FOR /F "tokens=1* delims==" %%A IN (%CONFPATH%\packages.cfg) DO (
    if "%%A"=="url" set PKG_URL=%%B
    if "%%A"=="git_repo" set GIT_URL=%%B
    if "%%A"=="curl_params" set PARMS_CURL=%%B
    if "%%A"=="git_params" set PARMS_GIT=%%B
)

mkdir %ROOTPATH%\data
mkdir %ROOTPATH%\dev
mkdir %ROOTPATH%\bin\ide
mkdir %ROOTPATH%\bin\java
mkdir %ROOTPATH%\bin\java\jdk
mkdir %ROOTPATH%\bin\xtra

ECHO *****************
ECHO Installing 7-Zip.
ECHO *****************
curl %PARMS_CURL% -o %ROOTPATH%\7-Zip.exe %PKG_URL%/7-Zip.exe
%ROOTPATH%\7-Zip.exe -o%ROOTPATH% -y
if "%ERRORLEVEL%"=="1" (
   exit 0
)
DEL %ROOTPATH%\7-Zip.exe

ECHO ******************
ECHO Installing AutoIt.
ECHO ******************
curl %PARMS_CURL% -o %ROOTPATH%\AutoIt.7z %PKG_URL%/AutoIt.7z
%ROOTPATH%\bin\base\7-Zip16.04\7z.exe x %ROOTPATH%\AutoIt.7z -o%ROOTPATH% -y
if "%ERRORLEVEL%"=="1" (
   exit 0
)
DEL %ROOTPATH%\AutoIt.7z

ECHO ******************
ECHO Installing MinGit.
ECHO ******************
curl %PARMS_CURL% -o %ROOTPATH%\MinGit.7z %PKG_URL%/MinGit.7z
%ROOTPATH%\bin\base\7-Zip16.04\7z.exe x %ROOTPATH%\MinGit.7z -o%ROOTPATH% -y
if "%ERRORLEVEL%"=="1" (
   exit 0
)
DEL %ROOTPATH%\MinGit.7z

ECHO **********************
ECHO Minimun install done!!
ECHO **********************

if not exist %ROOTPATH%\.git (
   ECHO ***********************************
   ECHO Joining main thorkspace GIT repo...
   ECHO ***********************************
   git clone %PARMS_GIT% %GIT_URL% %TEMP%\ts
   xcopy /s /i %TEMP%\ts\.git %ROOTPATH%\.git
   RD /s /q %TEMP%\ts
   git checkout .
   git reset
)

