#!/bin/zsh

# macOS Security Updates (macSU)
# shell script: macsu.zsh
# v2.0.0
# Copyright (c) 2018–20 Joss Brown (pseud.)
# license: MIT+
# info: https://github.com/JayBrown/macOS-Security-Updates

export LANG=en_US.UTF-8

localdate=$(date)
account=$(id -u)
process="macOS Security"
icon_loc="/System/Library/PreferencePanes/Security.prefPane/Contents/Resources/FileVault.icns"

sysv=$(sw_vers -productVersion)
sysmv=$(echo "$sysv" | awk -F. '{print $2}')
scrname=$(basename "$0")
if [[ "$sysmv" -lt 15 ]] ; then
	echo -e "Error! Incompatible system.\n$scrname needs at least macOS 10.15 (Catalina).\n*** Exiting... ***" >&2
	exit 1
fi

_beep () {
	osascript -e "beep" &>/dev/null
}

_notify () {
	if [[ "$tn_status" == "osa" ]] ; then
		osascript &>/dev/null << EOT
tell application "System Events"
	display notification "$2" with title "$process [" & "$account" & "]" subtitle "$1"
end tell
EOT
	elif [[ "$tn_status" == "tn-app-new" ]] || [[ "$tn_status" == "tn-app-old" ]] ; then
		"$tn_loc/Contents/MacOS/terminal-notifier" \
			-title "$process [$account]" \
			-subtitle "$1" \
			-message "$2" \
			-appIcon "$icon_loc" \
			>/dev/null
	elif [[ "$tn_status" == "tn-cli" ]] ; then
		"$tn" \
			-title "$process [$account]" \
			-subtitle "$1" \
			-message "$2" \
			-appIcon "$icon_loc" \
			>/dev/null
	fi
}

echo "***************************************************"
echo "*** Starting new macOS Security components scan ***"
echo "***************************************************"
echo "Local date: $localdate"
echo "Process executed by: $account"

# check for cache directory
cachedir="$HOME/.cache/macSU"
if ! [[ -d "$cachedir" ]] ; then
	echo "macOS Security Updates initial run"
	echo "No cache directory detected" >&2
	echo "Creating cache directory..." >&2
	mkdir -p "$cachedir"
	echo "Cache directory created" >&2
else
	echo "Cache directory detected"
fi

# list of components variables
read -d '' macsulist <<"EOF"
App Exceptions@/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/AppExceptions.bundle/version.plist@AppE-version.plist@CFBundleShortVersionString@/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/AppExceptions.bundle@none
Compatibility Notification Data@/Library/Apple/Library/Bundles/CompatibilityNotificationData.bundle/Contents/version.plist@CND-version.plist@CFBundleShortVersionString@/Library/Apple/Library/Bundles/CompatibilityNotificationData.bundle@none
Core LSKD (kdrl)@/usr/share/kdrl.bundle/version.plist@kdrl-version.plist@CFBundleShortVersionString@/usr/share/kdrl.bundle@none
Core Suggestions@/System/Library/PrivateFrameworks/CoreSuggestionsInternals.framework/Versions/A/Resources/Assets.suggestionsassets/version.plist@CS-version.plist@CFBundleShortVersionString@/System/Library/PrivateFrameworks/CoreSuggestionsInternals.framework@none
Gatekeeper@/private/var/db/gkopaque.bundle/Contents/version.plist@GK-version.plist@CFBundleShortVersionString@/private/var/db/gkopaque.bundle@none
Gatekeeper E@/private/var/db/gke.bundle/Contents/version.plist@GKE-version.plist@CFBundleShortVersionString@/private/var/db/gke.bundle@none
Incompatible Apps@/Library/Apple/Library/Bundles/IncompatibleAppsList.bundle/Contents/version.plist@IncApps-version.plist@CFBundleShortVersionString@/Library/Apple/Library/Bundles/IncompatibleAppsList.bundle@none
KEXT Exclusions@/Library/Apple/System/Library/Extensions/AppleKextExcludeList.kext/Contents/version.plist@KE-version.plist@CFBundleShortVersionString@/Library/Apple/System/Library/Extensions/AppleKextExcludeList.kext@none
Malware Removal Tool@/Library/Apple/System/Library/CoreServices/MRT.app/Contents/version.plist@MRT-version.plist@CFBundleShortVersionString@/Library/Apple/System/Library/CoreServices/MRT.app@none
TCC@/Library/Apple/Library/Bundles/TCC_Compatibility.bundle/Contents/version.plist@TCC-version.plist@CFBundleShortVersionString@/Library/Apple/Library/Bundles/TCC_Compatibility.bundle@none
XProtect@/Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/version.plist@XP-version.plist@CFBundleShortVersionString@/Library/Apple/System/Library/CoreServices/XProtect.bundle@none
EOF
# System Integrity Protection@/System/Library/Sandbox/Compatibility.bundle/Contents/version.plist@SIP-version.plist@CFBundleShortVersionString@/System/Library/Sandbox/Compatibility.bundle@none

# check for plist backups
while IFS='@' read -r cname cplpath cbname ckey cinfo ckeyalt
do
	if ! [[ -f "$cachedir/$cbname" ]] ; then
		ipldate=$(stat -f "%Sc" "$cplpath")
		ixpversion=$(defaults read "$cplpath" "$ckey" 2>/dev/null)
		! [[ $ixpversion ]] && ixpversion="n/a"
		if [[ $ckeyalt != "none" ]] ; then
			build=$(defaults read "$cplpath" "$ckeyalt" 2>/dev/null)
			! [[ $build ]] && build="n/a"
			buildstr=" ($build)"
		else
			buildstr=""
		fi
		echo "Backing up $cname: $ixpversion$buildstr [$ipldate]"
		cp "$cplpath" "$cachedir/$cbname"
	else
		echo "$cname backup detected"
	fi
done < <(echo "$macsulist" | grep -v "^$")

# check for initial system data backups
if ! [[ -f "$cachedir/sysv.txt" ]] ; then
	echo "Saving current system version: $sysv"
	echo -n "$sysv" > "$cachedir/sysv.txt"
fi
if ! [[ -f "$cachedir/sysbuildv.txt" ]] ; then
	sysbuildv=$(sw_vers -buildVersion)
	echo "Saving current system build version: $sysbuildv"
	echo -n "$sysbuildv" > "$cachedir/sysbuildv.txt"
fi
hwdata=$(system_profiler SPHardwareDataType | grep "Boot ROM Version")
if ! [[ -f "$cachedir/efiv.txt" ]] ; then
	efiv=$(echo "$hwdata" | awk '{print $4}')
	echo "Saving current EFI (Boot ROM) version: $efiv"
	echo -n "$efiv" > "$cachedir/efiv.txt"
fi
if ! [[ -f "$cachedir/ibridgev.txt" ]] ; then
	ibridgev=$(echo "$hwdata" | awk -F"[()]" '{print $2}' | awk -F"iBridge: " '{print $2}')
	! [[ $ibridgev ]] && ibridgev="n/a"
	echo "Saving current iBridge version: $ibridgev"
	echo -n "$ibridgev" > "$cachedir/ibridgev.txt"
fi
if ! [[ -f "$cachedir/rootless.conf" ]] ; then
	echo "Backing up rootless.conf"
	cp /System/Library/Sandbox/rootless.conf "$cachedir/rootless.conf"
fi

# search for terminal-notifier ###
tn=$(command -v terminal-notifier 2>/dev/null)
if ! [[ $tn ]] ; then
	tn_loc=$(mdfind -onlyin / "kMDItemCFBundleIdentifier == 'fr.julienxx.oss.terminal-notifier'" 2>/dev/null | awk 'NR==1')
	if ! [[ $tn_loc ]] ; then
		tn_loc=$(mdfind -onlyin / "kMDItemCFBundleIdentifier == 'nl.superalloy.oss.terminal-notifier'" 2>/dev/null | awk 'NR==1')
		if ! [[ $tn_loc ]] ; then
			tn_status="osa"
		else
			tn_status="tn-app-old"
		fi
	else
		tn_status="tn-app-new"
	fi
else
	tn_vers=$("$tn" -help | head -1 | awk -F'[()]' '{print $2}' | awk -F. '{print $1"."$2}')
	if (( $(echo "$tn_vers >= 1.8" | bc -l) )) && (( $(echo "$tn_vers < 2.0" | bc -l) )) ; then
		tn_status="tn-cli"
	else
		tn_loc=$(mdfind -onlyin / "kMDItemCFBundleIdentifier == 'fr.julienxx.oss.terminal-notifier'" 2>/dev/null | awk 'NR==1')
		if ! [[ $tn_loc ]] ; then
			tn_loc=$(mdfind -onlyin / "kMDItemCFBundleIdentifier == 'nl.superalloy.oss.terminal-notifier'" 2>/dev/null | awk 'NR==1')
			if ! [[ $tn_loc ]] ; then
				tn_status="osa"
			else
				tn_status="tn-app-old"
			fi
		else
			tn_status="tn-app-new"
		fi
	fi
fi

logbody=""

# check auxiliary components
sysv_previous=$(cat "$cachedir/sysv.txt")
if [[ $sysv_previous == "$sysv" ]] ; then
	echo "System: unchanged ($sysv)"
else
	_beep
	echo "System: UPDATED from $sysv_previous to $sysv"
	logbody="$logbody\nSystem: $sysv_previous > $sysv"
	echo -n "$sysv" > "$cachedir/sysv.txt"
	_notify "System" "$sysv_previous > $sysv"
fi
sysbuildv=$(sw_vers -buildVersion)
sysbuildv_previous=$(cat "$cachedir/sysbuildv.txt")
if [[ $sysbuildv_previous == "$sysbuildv" ]] ; then
	echo "System build: unchanged ($sysbuildv)"
else
	_beep
	echo "System build: UPDATED from $sysbuildv_previous to $sysbuildv"
	logbody="$logbody\nSystem build: $sysbuildv_previous > $sysbuildv"
	echo -n "$sysbuildv" > "$cachedir/sysbuildv.txt"
	_notify "System build" "$sysbuildv_previous > $sysbuildv"
fi
efiv=$(echo "$hwdata" | awk '{print $4}')
efiv_previous=$(cat "$cachedir/efiv.txt")
if [[ $efiv_previous == "$efiv" ]] ; then
	echo "EFI (Boot ROM): unchanged ($efiv)"
else
	_beep
	echo "EFI (Boot ROM): UPDATED from $efiv_previous to $efiv"
	logbody="$logbody\nEFI (Boot ROM): $efiv_previous > $efiv"
	echo -n "$efiv" > "$cachedir/efiv.txt"
	_notify "EFI (Boot ROM)" "$efiv_previous > $efiv"
fi
ibridgev=$(echo "$hwdata" | awk -F"[()]" '{print $2}' | awk -F"iBridge: " '{print $2}')
! [[ $ibridgev ]] && ibridgev="n/a"
ibridgev_previous=$(cat "$cachedir/ibridgev.txt")
if [[ $ibridgev_previous == "$ibridgev" ]] ; then
	echo "iBridge: unchanged ($ibridgev)"
else
	_beep
	echo "iBridge: UPDATED from $ibridgev_previous to $ibridgev"
	logbody="$logbody\niBridge: $ibridgev_previous > $ibridgev"
	echo -n "$ibridgev" > "$cachedir/ibridgev.txt"
	_notify "iBridge" "$ibridgev_previous > $ibridgev"
fi
pldate=$(stat -f "%Sc" /System/Library/Sandbox/rootless.conf)
if [[ $(md5 -q /System/Library/Sandbox/rootless.conf) == $(md5 -q "$cachedir/rootless.conf") ]] ; then
	echo "SIP Configuration: unchanged [$pldate]"
else
	_beep
	echo "SIP Configuration: rootless.conf UPDATED on $pldate"
	logbody="$logbody\nSIP Configuration (rootless.conf): $pldate"
	rm -f "$cachedir/rootless.conf" 2>/dev/null
	cp /System/Library/Sandbox/rootless.conf "$cachedir/rootless.conf" 2>/dev/null
	_notify "SIP Configuration" "$pldate"
fi

# check main components
while IFS='@' read -r cname cplpath cbname ckey cinfo ckeyalt
do
	pldate=$(stat -f "%Sc" "$cplpath")
	nxpversion=$(defaults read "$cplpath" "$ckey" 2>/dev/null)
	! [[ $nxpversion ]] && nxpversion="n/a"
	if [[ $ckeyalt != "none" ]] ; then
		nxpbuild=$(defaults read "$cplpath" "$ckeyalt" 2>/dev/null)
		! [[ $nxpbuild ]] && nxpbuild="n/a"
		nxpbuildstr=" ($nxpbuild)"
	else
		nxpbuildstr=""
	fi
	if [[ $(md5 -q "$cplpath") == $(md5 -q "$cachedir/$cbname") ]] ; then
		echo "$cname: unchanged ($nxpversion$nxpbuildstr) [$pldate]"
	else
		oxpversion=$(defaults read "$cachedir/$cbname" "$ckey" 2>/dev/null)
		! [[ $oxpversion ]] && oxpversion="n/a"
		if [[ $ckeyalt != "none" ]] ; then
			oxpbuild=$(defaults read "$cplpath" "$ckeyalt" 2>/dev/null)
			! [[ $oxpbuild ]] && oxpbuild="n/a"
			oxpbuildstr=" ($oxpbuild)"
		else
			oxpbuildstr=""
		fi
		_beep
		echo "$cname: UPDATED from $oxpversion$oxpbuildstr to $nxpversion$nxpbuildstr on $pldate"
		logbody="$logbody\n$cname: $oxpversion$oxpbuildstr > $nxpversion$nxpbuildstr [$pldate] ($cinfo)"
		_notify "$cname" "$oxpversion$oxpbuildstr > $nxpversion$nxpbuildstr [$pldate] "
		cp "$cplpath" "$cachedir/$cbname" 2>/dev/null
	fi
done < <(echo "$macsulist" | grep -v "^$")

if [[ -d "$HOME/Library/Logs/local.lcars.macOSSecurityUpdates" ]] ; then
	rm -rf "$HOME/Library/Logs/local.lcars.macOSSecurityUpdates" 2>/dev/null
fi
logloc="$HOME/Library/Logs/local.lcars.macOSSecurityUpdates.log"
logbody=$(echo -e "$logbody" | grep -v "^$")
logger -i -s -t "macOS Security Updates" "$logbody" 2>> "$logloc"

exit
