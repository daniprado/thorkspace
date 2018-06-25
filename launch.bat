@echo off
REM Thorkspace Launch
REM
REM Copyright (C) 2017-2018 - Daniel Prado (dpradom@argallar.com)
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
:RESTART

SET TMP_FILE=%TMP%\thorkspace
SET ROOTPATH=%CD%

SET HOMEPATH=%ROOTPATH%\data
SET CONFPATH=%ROOTPATH%\conf
SET DEVPATH=%ROOTPATH%\dev
SET BINPATH=%ROOTPATH%\bin
SET IDEPATH=%ROOTPATH%\bin\ide
SET PATH=%BINPATH%\base\AutoIt-v3;%BINPATH%\base\7-Zip16.04;%BINPATH%\base\curl-7.59.0;%BINPATH%\base\MinGit-2.16.3\cmd;%BINPATH%\base\ApacheSubversion-1.9.7\bin;%PATH%

if not exist %BINPATH%\base\AutoIt-v3 (
   SET NOT_INSTALLED=1
   ECHO Installing 7-Zip, AutoIt y MinGit to get minimun install...
   CALL %CONFPATH%\ts\TSMinInstall.bat
   if "%ERRORLEVEL%"=="1" (
      exit 0
   )
   
:SELECTOR
   ECHO We need some software...
   CALL AutoIt3_x64.exe %CONFPATH%\ts\TSSelector.au3
   if "%ERRORLEVEL%"=="1" (
      exit 0
   )
   if exist %CONFPATH%\newversion (
      DEL %CONFPATH%\newversion
      GOTO RESTART
   )
   if exist %CONFPATH%\packages (
      CALL AutoIt3_x64.exe %CONFPATH%\ts\TSUpdater.au3
      if "%ERRORLEVEL%"=="1" (
         exit 0
      )
   )
)

ECHO Starting Thorkspace Launcher!
CALL AutoIt3_x64.exe %CONFPATH%\ts\TSLauncher.au3
if "%ERRORLEVEL%"=="1" (
   exit 0
)

if exist %CONFPATH%\packages (
   GOTO SELECTOR
)

ECHO Launching selected programs...
CALL %TMP_FILE%.bat

@echo on
