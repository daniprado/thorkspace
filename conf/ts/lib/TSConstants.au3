; Thorkspace Constants
;
; Copyright (C) 2018 - Daniel Prado (dpradom@argallar.com)
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
; This file is written in AutoIT Script (https://www.autoitscript.com/autoit3/docs/)

#include-once

Const $ENV_WORKLETTER = "WORK_LETTER"
Const $ENV_WORKPATH = "WORK"
Const $ENV_NEWDEVS = "NEW_DEVS"
Const $ENV_NEWDRIVE = "NEW_DRIVE"
Const $ENV_ROOTPATH = "ROOTPATH"
Const $ENV_IDEPATH = "IDEPATH"
Const $ENV_DEVPATH = "DEVPATH"
Const $ENV_BINPATH = "BINPATH"
Const $ENV_ENVPATH = "ENVPATH"
Const $ENV_HOMEPATH = "HOMEPATH"
Const $ENV_CONFPATH = "CONFPATH"
Const $ENV_JAVAPATH = "JAVA_HOME"
Const $ENV_MAVENPATH = "MAVEN_HOME"
Const $ENV_TMPFILE = "TMP_FILE"
Const $ENV_INST = "PKG_INSTALL"
Const $ENV_UNINST = "PKG_UNINSTALL"
Const $ENV_UPDATER = "TS_UPDATER"
Const $ENV_NOTINSTALLED = "NOT_INSTALLED"

Const $CFG_ENV = "\conf\env.bat"
Const $CFG_TS = "\_ts"
Const $CFG_WSBASE = "\ws-base"
Const $CFG_TSBASE = "\ts-base"
Const $CFG_VERSION = "\.version_"

Const $GRP_REPO = ""
Const $PKG_REPO = "packages"
Const $GRP_REPOLAN = "xtra"
Const $PKG_REPOLAN = "NetTools"

Const $PATTERN_PKGFILE = "%PKG%%VER%%EXT%"
Const $PATTERN_PKGURI = "%GRP%/" & $PATTERN_PKGFILE
Const $PATTERN_PKGREPOPATH = "%GRP%\" & $PATTERN_PKGFILE
Const $PATTERN_UNINST = "*uninstall.*"

Const $WORKLETTER = EnvGet($ENV_WORKLETTER)
Const $PATH_TMPFILE = EnvGet($ENV_TMPFILE)
Const $PATH_ROOT = EnvGet($ENV_ROOTPATH)
Const $PATH_IDE = EnvGet($ENV_IDEPATH)
Const $PATH_DEV = EnvGet($ENV_DEVPATH)
Const $PATH_BIN = EnvGet($ENV_BINPATH)
Const $PATH_ENV = EnvGet($ENV_ENVPATH)
Const $PATH_HOME = EnvGet($ENV_HOMEPATH)
Const $PATH_CONF = EnvGet($ENV_CONFPATH)
Const $PATH_WORK = EnvGet($ENV_WORKPATH)
Const $PATH_JAVA = EnvGet($ENV_JAVAPATH)
Const $PATH_MAVEN = EnvGet($ENV_MAVENPATH)
Const $PATH_TS = $PATH_CONF & "\ts"
Const $PATH_STARTERBAT = $PATH_ROOT & "\start.bat"
Const $PATH_STARTERAU3 = $PATH_CONF & "\starter.au3"
Const $PATH_PKGINST = $PATH_TS & "\pkg"
Const $PATH_RUNVER = $PATH_TS & $CFG_VERSION
Const $PATH_VERSION = $PATH_TS & $CFG_VERSION & "*"
Const $PATH_PKGFILE = $PATH_ROOT & "\" & $PATTERN_PKGFILE
Const $PATH_REPO = $PATH_TS & "\repo"
Const $PATH_REPOLAN = $PATH_REPO & $PATTERN_PKGREPOPATH
Const $PATH_UPDATERTRIGGER = $PATH_CONF & "\packages"
Const $PATH_RESTARTTRIGGER = $PATH_CONF & "\newversion"
Const $PATH_OFFLINETRIGGER = $PATH_CONF & "\offline"

Const $CFG_PACKAGES = $PATH_CONF & "\packages.cfg"
Const $CFG_LAUNCHER = $PATH_CONF & "\launcher.cfg"

Const $GRP_BASE = "Base"
Const $GRP_IDE = "IDE"
Const $GRP_JAVA = "Java"
Const $GRP_XTRA = "Xtra"

Const $DIR_BASE = "base"
Const $DIR_IDE = "ide"
Const $DIR_JAVA = "java"
Const $DIR_XTRA = "xtra"
Const $DIR_DEV = "dev"
Const $DIR_APP = "app"
Const $DIR_DATA = "data"

Const $TAG_GRP = "%GRP%"
Const $TAG_PKG = "%PKG%"
Const $TAG_VER = "%VER%"
Const $TAG_EXT = "%EXT%"

Const $NEWDEVS = EnvGet($ENV_NEWDEVS)
Const $NEWDRIVE = EnvGet($ENV_NEWDRIVE)
Const $SCRIPT_INSTALL = $PATH_ROOT & "\%GRP%#%PKG%#%VER%_install.au3"
Const $SCRIPT_UNINSTALL = $PATH_PKGINST & "\%GRP%#%PKG%#%VER%_uninstall.au3"

Const $EXECUTE = '"' & @AutoItExe & '" /AutoIt3ExecuteScript '
Const $EXEC_UPDATER = $EXECUTE & '"' & $PATH_TS & '\TSUpdater.au3"'
Const $EXEC_SELECTOR = $EXECUTE & '"' & $PATH_TS & '\TSSelector.au3"'
Const $EXEC_CONFIGURER = $EXECUTE & '%' & $ENV_CONFPATH & '%\ts\TSConfigurer.au3'
Const $EXEC_TEMPAU3 = $EXECUTE & '%TMP_FILE%.au3'
Const $EXEC_STARTER = $EXECUTE &  '%' & $ENV_CONFPATH & '%\starter.au3'
Const $EXEC_REPOLAN = 'Run(EnvGet("' & $ENV_BINPATH & '") & "\' & $DIR_XTRA & '\' & $PKG_REPOLAN & '\hfs.exe -c start-minimized=yes\nlast-file-open=" & EnvGet("' & $ENV_CONFPATH & '") & "\repository.vfs\nreload-on-startup=yes")'

Const $TITLE_SELECTOR = "Thorkspace Selector"
Const $TITLE_LAUNCHER = "Thorkspace Launcher"
Const $TITLE_DEVCREATOR = "New Workspace"

Const $CBSTYLE = $PATH_TS & "\imx\modern 3 set.bmp"
Const $PATH_ICON = $PATH_TS & "\imx\logo.ico"
Const $FONT_TYPE = "Trebuchet MS"

Const $DRIVES = "T" ;"P|Q|R|S|T|U|V|W|X|Y|Z"
Const $CODEIMP = "FF"
Const $CHECKED = ";*"
Const $SEP = ";"
Const $SEP2 = "#"
Const $SEP3 = "&"
Const $SEP4 = "_"

Const $DAT_DRIVE = "drive="
Const $DAT_APP = "app="
Const $DAT_DEV = "ws="
Const $DAT_VER = "version="
Const $DAT_SERVER = "server="
Const $DAT_URL = "url="
Const $DAT_CRED = "cred="
Const $DAT_PROXY = "proxy="
Const $DAT_REPOLAN = "repo-lan="
Const $DAT_BRANCHCALC = "branch-calc="
Const $DAT_GITURL = "git_repo="
Const $DAT_GITPARMS = "git_params="
Const $DAT_CURLPARMS = "curl_params="

Const $SERV_ARTIFACTORY = "artifactory"
Const $SERV_LANREPO = "lan-repo"
Const $SERV_LOCAL = "local"

