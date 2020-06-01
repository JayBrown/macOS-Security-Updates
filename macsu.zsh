#!/bin/zsh
# shellcheck shell=bash

# macOS Security Updates (macSU)
# shell script: macsu.zsh / LaunchAgent: local.lcars.macOSSecurityUpdates
# v2.1.2
# Copyright (c) 2018–20 Joss Brown (pseud.)
# license: MIT+
# info: https://github.com/JayBrown/macOS-Security-Updates
# thanks to Howard Oakley: https://eclecticlight.co / https://github.com/hoakleyelc/updates

export LANG=en_US.UTF-8

macsuv="2.1.2"
macsumv="2"
scrname=$(basename "$0")
process="macOS Security"
account=$(id -u)

_sysbeep () {
	osascript -e "beep" &>/dev/null
}

_beep () {
	afplay "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Acknowledgement_ThumbsUp.caf" &>/dev/null
}

sysv=$(sw_vers -productVersion)
sysmv=$(echo "$sysv" | awk -F. '{print $2}')
if [[ "$sysmv" -lt 15 ]] ; then
	_sysbeep &
	osascript &>/dev/null << EOT
tell application "System Events"
	display notification "macOS 10.15 (Catalina) required!" with title "$process [" & "$account" & "]" subtitle "⚠️ Error: incompatible system!"
end tell
EOT
	echo -e "Error! Incompatible system.\n$scrname v$macsuv needs at least macOS 10.15 (Catalina).\n*** Exiting... ***" >&2
	exit 1
fi

icon_loc="/System/Library/PreferencePanes/Security.prefPane/Contents/Resources/FileVault.icns"

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

accountname=$(id -un)
HOMEDIR=$(eval echo "~$accountname")

# look for terminal-notifier (only on Yosemite and later)
tn=$(command -v terminal-notifier 2>/dev/null)
if ! [[ $tn ]] ; then
	tn_loc=$(mdfind \
		-onlyin /Applications/ \
		-onlyin "$HOMEDIR"/Applications/ \
		-onlyin /Developer/Applications/ \
		-onlyin "$HOMEDIR"/Developer/Applications/ \
		-onlyin /Network/Applications/ \
		-onlyin /Network/Developer/Applications/ \
		-onlyin /AppleInternal/Applications/ \
		-onlyin /usr/local/Cellar/terminal-notifier/ \
		-onlyin /opt/local/ \
		-onlyin /sw/ \
		-onlyin "$HOMEDIR"/.local/bin \
		-onlyin "$HOMEDIR"/bin \
		-onlyin "$HOMEDIR"/local/bin \
		"kMDItemCFBundleIdentifier == 'fr.julienxx.oss.terminal-notifier'" 2>/dev/null | LC_COLLATE=C sort | awk 'NR==1')
	if ! [[ $tn_loc ]] ; then
		tn_loc=$(mdfind \
			-onlyin /Applications/ \
			-onlyin "$HOMEDIR"/Applications/ \
			-onlyin /Developer/Applications/ \
			-onlyin "$HOMEDIR"/Developer/Applications/ \
			-onlyin /Network/Applications/ \
			-onlyin /Network/Developer/Applicationsv \
			-onlyin /AppleInternal/Applications/ \
			-onlyin /usr/local/Cellar/terminal-notifier/ \
			-onlyin /opt/local/ \
			-onlyin /sw/ \
			-onlyin "$HOMEDIR"/.local/bin \
			-onlyin "$HOMEDIR"/bin \
			-onlyin "$HOMEDIR"/local/bin \
			"kMDItemCFBundleIdentifier == 'nl.superalloy.oss.terminal-notifier'" 2>/dev/null | LC_COLLATE=C sort | awk 'NR==1')
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
		tn_loc=$(mdfind \
			-onlyin /Applications/ \
			-onlyin "$HOMEDIR"/Applications/ \
			-onlyin /Developer/Applications/ \
			-onlyin "$HOMEDIR"/Developer/Applications/ \
			-onlyin /Network/Applications/ \
			-onlyin /Network/Developer/Applications/ \
			-onlyin /AppleInternal/Applications/ \
			-onlyin /usr/local/Cellar/terminal-notifier/ \
			-onlyin /opt/local/ \
			-onlyin /sw/ \
			-onlyin "$HOMEDIR"/.local/bin \
			-onlyin "$HOMEDIR"/bin \
			-onlyin "$HOMEDIR"/local/bin \
			"kMDItemCFBundleIdentifier == 'fr.julienxx.oss.terminal-notifier'" 2>/dev/null | LC_COLLATE=C sort | awk 'NR==1')
		if ! [[ $tn_loc ]] ; then
			tn_loc=$(mdfind \
				-onlyin /Applications/ \
				-onlyin "$HOMEDIR"/Applications/ \
				-onlyin /Developer/Applications/ \
				-onlyin "$HOMEDIR"/Developer/Applications/ \
				-onlyin /Network/Applications/ \
				-onlyin /Network/Developer/Applications/ \
				-onlyin /AppleInternal/Applications/ \
				-onlyin /usr/local/Cellar/terminal-notifier/ \
				-onlyin /opt/local/ \
				-onlyin /sw/ \
				-onlyin "$HOMEDIR"/.local/bin \
				-onlyin "$HOMEDIR"/bin \
				-onlyin "$HOMEDIR"/local/bin \
				"kMDItemCFBundleIdentifier == 'nl.superalloy.oss.terminal-notifier'" 2>/dev/null | LC_COLLATE=C sort | awk 'NR==1')
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

echo "***********************************************"
echo "*** Starting macOS Security components scan ***"
echo "***********************************************"
echo "$process ($scrname v$macsuv)"
echo "Executing user: $accountname ($account)"
localdate=$(date)
echo "Local date: $localdate"

# check for cache directory
cachedir="$HOMEDIR/.cache/macSU"
if ! [[ -d "$cachedir" ]] ; then
	echo -e "macOS Security Updates initial run\nNo cache directory detected: creating..."
	if ! mkdir -p "$cachedir" &>/dev/null ; then
		_sysbeep &
		echo -e "Error creating cache directory: $cachedir\n*** Exiting... ***" >&2
		exit 1
	else
		echo -n "$macsumv" > "$cachedir/macsumv.txt"
		echo "Cache directory created"
	fi
fi
if ! [[ -f "$cachedir/macsumv.txt" ]] ; then
	if ! [[ -f "$cachedir/AppE-version.plist" ]] ; then
		find "$cachedir" -type f -exec rm -f {} \; 2>/dev/null
	fi
	echo -n "$macsumv" > "$cachedir/macsumv.txt"
fi

# list of components variables
read -d '' macsulist <<"EOF"
App Exceptions@/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/AppExceptions.bundle/version.plist@AppE-version.plist@CFBundleShortVersionString@/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/AppExceptions.bundle@/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/AppExceptions.bundle/Exceptions.plist@none
Compatibility Notification Data@/Library/Apple/Library/Bundles/CompatibilityNotificationData.bundle/Contents/version.plist@CND-version.plist@CFBundleShortVersionString@/Library/Apple/Library/Bundles/CompatibilityNotificationData.bundle@/Library/Apple/Library/Bundles/CompatibilityNotificationData.bundle/Contents/Resources/CompatibilityNotificationData.plist@none
Core LSKD (kdrl)@/usr/share/kdrl.bundle/version.plist@kdrl-version.plist@CFBundleShortVersionString@/usr/share/kdrl.bundle@/usr/share/kdrl.bundle/lskd.rl@none
Core Suggestions@/System/Library/PrivateFrameworks/CoreSuggestionsInternals.framework/Versions/A/Resources/Assets.suggestionsassets/version.plist@CS-version.plist@CFBundleShortVersionString@/System/Library/PrivateFrameworks/CoreSuggestionsInternals.framework@/System/Library/PrivateFrameworks/CoreSuggestionsInternals.framework/Versions/A/Resources/Assets.suggestionsassets/AssetData@none
Gatekeeper@/private/var/db/gkopaque.bundle/Contents/version.plist@GK-version.plist@CFBundleShortVersionString@/private/var/db/gkopaque.bundle@/private/var/db/gkopaque.bundle/Contents/Resources/gkopaque.db@none
Gatekeeper E@/private/var/db/gke.bundle/Contents/version.plist@GKE-version.plist@CFBundleShortVersionString@/private/var/db/gke.bundle@/private/var/db/gke.bundle/Contents/Resources/gk.db@none
Incompatible Apps@/Library/Apple/Library/Bundles/IncompatibleAppsList.bundle/Contents/version.plist@IncApps-version.plist@CFBundleShortVersionString@/Library/Apple/Library/Bundles/IncompatibleAppsList.bundle@/Library/Apple/Library/Bundles/IncompatibleAppsList.bundle/Contents/Resources/IncompatibleAppsList.plist@none
KEXT Exclusions@/Library/Apple/System/Library/Extensions/AppleKextExcludeList.kext/Contents/version.plist@KE-version.plist@CFBundleShortVersionString@/Library/Apple/System/Library/Extensions/AppleKextExcludeList.kext@/Library/Apple/System/Library/Extensions/AppleKextExcludeList.kext/Contents/Resources/ExceptionLists.plist@none
Malware Removal Tool@/Library/Apple/System/Library/CoreServices/MRT.app/Contents/version.plist@MRT-version.plist@CFBundleShortVersionString@/Library/Apple/System/Library/CoreServices/MRT.app@none@none
TCC@/Library/Apple/Library/Bundles/TCC_Compatibility.bundle/Contents/version.plist@TCC-version.plist@CFBundleShortVersionString@/Library/Apple/Library/Bundles/TCC_Compatibility.bundle@/Library/Apple/Library/Bundles/TCC_Compatibility.bundle/Contents/Resources/AllowApplicationsList.plist@none
XProtect@/Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/version.plist@XP-version.plist@CFBundleShortVersionString@/Library/Apple/System/Library/CoreServices/XProtect.bundle@none@none
EOF
# System Integrity Protection@/System/Library/Sandbox/Compatibility.bundle/Contents/version.plist@SIP-version.plist@CFBundleShortVersionString@/System/Library/Sandbox/Compatibility.bundle@none@none

# check for plist backups
while IFS='@' read -r cname cplpath cbname ckey cinfo cplpathalt ckeyalt
do
	if ! [[ -f "$cachedir/$cbname" ]] ; then
		if [[ $cplpathalt != "none" ]] ; then
			ipldate=$(stat -f %Sm -t %F" "%T "$cplpathalt")
		else
			ipldate=$(stat -f %Sm -t %F" "%T "$cplpath")
		fi
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
hwdata_raw=$(system_profiler SPHardwareDataType)
hwdata=$(echo "$hwdata_raw" | grep "Boot ROM Version")
if ! [[ -f "$cachedir/efiv.txt" ]] ; then
	efiv=$(echo "$hwdata" | awk '{print $4}')
	echo "Saving current EFI (Boot ROM) version: $efiv"
	echo -n "$efiv" > "$cachedir/efiv.txt"
fi
if ! [[ -f "$cachedir/ibridgev.txt" ]] ; then
	ibridgev=$(echo "$hwdata" | awk -F"[()]" '{print $2}' | awk -F"iBridge: " '{print $2}' | awk -F, '{print $1}')
	! [[ $ibridgev ]] && ibridgev="n/a"
	echo "Saving current iBridge version: $ibridgev"
	echo -n "$ibridgev" > "$cachedir/ibridgev.txt"
fi
if ! [[ -f "$cachedir/rootless.conf" ]] ; then
	echo "Backing up rootless.conf"
	cp /System/Library/Sandbox/rootless.conf "$cachedir/rootless.conf"
fi

# curl databases on https://github.com/hoakleyelc/updates
if ! [[ -d "$cachedir/tmp" ]] ; then
	mkdir -p "$cachedir/tmp" 2>/dev/null
fi
eclbaseurl="https://raw.githubusercontent.com/hoakleyelc/updates/master"
securl="$eclbaseurl/sysupdates.plist"
rcsec_tmp="$cachedir/tmp/sysupdates.plist"
rm -f "$rcsec_tmp" 2>/dev/null
echo "Trying to download sysupdates.plist..."
curl -L -s --connect-timeout 30 --max-time 30 "$securl" -o "$rcsec_tmp" &>/dev/null
rcsec="$cachedir/sysupdates.plist"
if [[ -f "$rcsec_tmp" ]] ; then
	echo "Success!"
	rm -f "$rcsec" 2>/dev/null
	mv "$rcsec_tmp" "$rcsec" 2>/dev/null
else
	echo "ERROR downloading sysupdates.plist!" >&2
fi
modelid=$(echo "$hwdata_raw" | grep "Model Identifier" | awk -F": " '{print $2}')
modelname=$(echo "$modelid" | tr -d '[:digit:]' | sed 's/,$//')
# modelnumber=$(echo "$modelid" | tr -d 'a-zA-Z')
hwurl="$eclbaseurl/$modelname.plist"
rchw_tmp="$cachedir/tmp/$modelname.plist"
rm -f "$rchw_tmp" 2>/dev/null
curl -L -s --connect-timeout 30 --max-time 30 "$hwurl" -o "$rchw_tmp" &>/dev/null
echo "Trying to download $modelname.plist..."
rchw="$cachedir/$modelname.plist"
if [[ -f "$rchw_tmp" ]] ; then
	echo "Success!"
	rm -f "$rchw" 2>/dev/null
	mv "$rchw_tmp" "$rchw" 2>/dev/null
else
	echo "ERROR downloading $modelname.plist!" >&2
fi

_version () {
	ver1="$1"
	ver2="$2"
	if ! [[ $ver1 ]] || ! [[ $ver2 ]] ; then
		echo "ERROR: incomplete input" >&2
		return
	fi

	ver1count=$(echo "$ver1" | grep -o "\." | wc -l)
	ver2count=$(echo "$ver2" | grep -o "\." | wc -l)
	if [[ $ver1count != "$ver2count" ]] ; then
		echo -e "ERROR: different formats\n$ver1 != $ver2" >&2
		return
	fi
	((ver1count++))
	vcounter=1

	major1=$(echo "$ver1" | awk -F\. '{print $1}')
	major2=$(echo "$ver2" | awk -F\. '{print $1}')
	if [[ $major1 -gt $major2 ]] ; then
		echo "greater"
		return
	elif [[ $major1 -lt $major2 ]] ; then
		echo "lesser"
		return
	fi
	if [[ $vcounter == "$ver1count" ]] ; then
		echo "same"
		return
	fi
	((vcounter++))

	minor1=$(echo "$ver1" | awk -F\. '{print $2}')
	minor2=$(echo "$ver2" | awk -F\. '{print $2}')
	if [[ $minor1 -gt $minor2 ]] ; then
		echo "greater"
		return
	elif [[ $minor1 -lt $minor2 ]] ; then
		echo "lesser"
		return
	fi
	if [[ $vcounter == "$ver1count" ]] ; then
		echo "same"
		return
	fi
	((vcounter++))

	patch1=$(echo "$ver1" | awk -F\. '{print $3}')
	patch2=$(echo "$ver2" | awk -F\. '{print $3}')
	if [[ $patch1 -gt $patch2 ]] ; then
		echo "greater"
		return
	elif [[ $patch1 -lt $patch2 ]] ; then
		echo "lesser"
		return
	fi
	if [[ $vcounter == "$ver1count" ]] ; then
		echo "same"
		return
	fi
	((vcounter++))

	majbuild1=$(echo "$ver1" | awk -F\. '{print $4}')
	majbuild2=$(echo "$ver2" | awk -F\. '{print $4}')
	if [[ $majbuild1 -gt $majbuild2 ]] ; then
		echo "greater"
		return
	elif [[ $majbuild1 -lt $majbuild2 ]] ; then
		echo "lesser"
		return
	fi
	if [[ $vcounter == "$ver1count" ]] ; then
		echo "same"
		return
	fi
	((vcounter++))

	minbuild1=$(echo "$ver1" | awk -F\. '{print $5}')
	minbuild2=$(echo "$ver2" | awk -F\. '{print $5}')
	if [[ $minbuild1 -gt $minbuild2 ]] ; then
		echo "greater"
		return
	elif [[ $minbuild1 -lt $minbuild2 ]] ; then
		echo "lesser"
		return
	fi
	if [[ $vcounter == "$ver1count" ]] ; then
		echo "same"
		return
	fi
	((vcounter++))

	pbuild1=$(echo "$ver1" | awk -F\. '{print $6}')
	pbuild2=$(echo "$ver2" | awk -F\. '{print $6}')
	if [[ $pbuild1 -gt $pbuild2 ]] ; then
		echo "greater"
		return
	elif [[ $pbuild1 -lt $pbuild2 ]] ; then
		echo "lesser"
		return
	fi
	if [[ $vcounter == "$ver1count" ]] ; then
		echo "same"
		return
	fi

	echo "Out of range" >&2
}

# check current EFI/iBridge versions
counter=0
while true
do
	dictmodel=$(/usr/libexec/PlistBuddy -c "Print :$counter:MacModel" "$cachedir/$modelname.plist" 2>/dev/null)
	if [[ $dictmodel ]] ; then
		if [[ $dictmodel == "$modelid" ]] ; then
			break
		fi
	fi
	((counter++))
done
fulldict=$(/usr/libexec/PlistBuddy -c "Print :$counter" "$cachedir/$modelname.plist" 2>/dev/null)
if [[ $fulldict ]] ; then
	efiv_current=$(echo "$fulldict" | awk -F"EFIversion$sysmv = " '{print $2}' | grep -v "^$")
	ibridgev_current=$(echo "$fulldict" | awk -F"iBridge$sysmv = " '{print $2}' | grep -v "^$")
else
	efiv_current="n/a"
	ibridgev_current="n/a"
fi

logbody=""
updated=false

# check auxiliary components
sysv_previous=$(cat "$cachedir/sysv.txt")
if [[ $sysv_previous == "$sysv" ]] ; then
	echo "System: unchanged ($sysv)"
else
	_beep &
	updated=true
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
	_beep &
	updated=true
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
	_beep &
	updated=true
	echo "EFI (Boot ROM): UPDATED from $efiv_previous to $efiv"
	logbody="$logbody\nEFI (Boot ROM): $efiv_previous > $efiv"
	echo -n "$efiv" > "$cachedir/efiv.txt"
	_notify "EFI (Boot ROM)" "$efiv_previous > $efiv"
fi
if [[ $efiv != "n/a" ]] ; then
	eficomp=$(_version "$efiv_current" "$efiv" 2>&1)
	if [[ $eficomp == "greater" ]] ; then
		echo "EFI (Boot ROM): a NEWER version is available: $efiv < $efiv_current"
		logbody="$logbody\nEFI (Boot ROM): out-of-date [available: $efiv_current]"
	elif [[ $eficomp == "same" ]] ; then
		echo "EFI (Boot ROM): the current version is installed"
		logbody="$logbody\nEFI (Boot ROM): current version installed"
	elif [[ $eficomp == "lesser" ]] ; then
		echo "EFI (Boot ROM): a newer version is already installed"
		logbody="$logbody\nEFI (Boot ROM): newer version already installed"
	else
		echo -e "ERROR comparing EFI (Boot ROM) versions!\n$eficomp" >&2
	fi
fi
ibridgev=$(echo "$hwdata" | awk -F"[()]" '{print $2}' | awk -F"iBridge: " '{print $2}' | awk -F, '{print $1}')
! [[ $ibridgev ]] && ibridgev="n/a"
ibridgev_previous=$(cat "$cachedir/ibridgev.txt")
if [[ $ibridgev_previous == "$ibridgev" ]] ; then
	echo "iBridge: unchanged ($ibridgev)"
else
	_beep &
	updated=true
	echo "iBridge: UPDATED from $ibridgev_previous to $ibridgev"
	logbody="$logbody\niBridge: $ibridgev_previous > $ibridgev"
	echo -n "$ibridgev" > "$cachedir/ibridgev.txt"
	_notify "iBridge" "$ibridgev_previous > $ibridgev"
fi
if [[ $ibridgev != "n/a" ]] ; then
	ibridgecomp=$(_version "$ibridgev_current" "$ibridgev" 2>&1)
	if [[ $ibridgecomp == "greater" ]] ; then
		echo "iBridge: a NEWER version is available: $ibridgev < $ibridgev_current"
		logbody="$logbody\niBridge: out-of-date [available: $ibridgev_current]"
	elif [[ $ibridgecomp == "same" ]] ; then
		echo "iBridge: the current version is installed"
		logbody="$logbody\niBridge: current version installed"
	elif [[ $ibridgecomp == "lesser" ]] ; then
		echo "iBridge: a newer version is already installed"
		logbody="$logbody\niBridge: newer version already installed"
	else
		echo -e "ERROR comparing iBridge versions!\n$ibridgecomp" >&2
	fi
fi

pldate=$(stat -f %Sm -t %F" "%T /System/Library/Sandbox/rootless.conf)
if [[ $(md5 -q /System/Library/Sandbox/rootless.conf) == $(md5 -q "$cachedir/rootless.conf") ]] ; then
	echo "SIP Configuration: unchanged [$pldate]"
else
	_beep &
	updated=true
	echo "SIP Configuration: rootless.conf UPDATED on $pldate"
	logbody="$logbody\nSIP Configuration (rootless.conf): $pldate"
	rm -f "$cachedir/rootless.conf" 2>/dev/null
	cp /System/Library/Sandbox/rootless.conf "$cachedir/rootless.conf" 2>/dev/null
	_notify "SIP Configuration" "$pldate"
fi

sysup=$(/usr/libexec/PlistBuddy -c "Print" "$cachedir/sysupdates.plist")

# check main components
while IFS='@' read -r cname cplpath cbname ckey cinfo cplpathalt ckeyalt
do
	if [[ $cplpathalt != "none" ]] ; then
		pldate=$(stat -f %Sm -t %F" "%T "$cplpathalt")
	else
		pldate=$(stat -f %Sm -t %F" "%T "$cplpath")
	fi
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
		_beep &
		updated=true
		echo "$cname: UPDATED from $oxpversion$oxpbuildstr to $nxpversion$nxpbuildstr [$pldate]"
		logbody="$logbody\n$cname: $oxpversion$oxpbuildstr > $nxpversion$nxpbuildstr [$pldate] ($cinfo)"
		_notify "$cname" "$oxpversion$oxpbuildstr > $nxpversion$nxpbuildstr [$pldate] "
		cp "$cplpath" "$cachedir/$cbname" 2>/dev/null
	fi
	if [[ $nxpversion != "n/a" ]] ; then
		skipcomp=false
		tonotify=true
		if [[ $cname == "Gatekeeper" ]] ; then
			sec_current=$(echo "$sysup" | awk -F"Gatekeeper = " '{print $2}')
		elif [[ $cname == "Gatekeeper E" ]] ; then
			tonotify=false
			sec_current=$(echo "$sysup" | awk -F"GatekeepDE = " '{print $2}')
		elif [[ $cname == "KEXT Exclusions" ]] ; then
			tonotify=false
			sec_current=$(echo "$sysup" | awk -F"KEXT$sysmv = " '{print $2}')
		elif [[ $cname == "Malware Removal Tool" ]] ; then
			sec_current=$(echo "$sysup" | awk -F"MRT = " '{print $2}')
		elif [[ $cname == "TCC" ]] ; then
			tonotify=false
			sec_current=$(echo "$sysup" | awk -F"TCC$sysmv = " '{print $2}')
		elif [[ $cname == "XProtect" ]] ; then
			sec_current=$(echo "$sysup" | awk -F"XProtect$sysmv = " '{print $2}')
		else
			skipcomp=true
		fi
		if ! $skipcomp ; then
			seccomp=$(_version "$sec_current" "$nxpversion" 2>&1)
			if [[ $seccomp == "greater" ]] ; then
				_sysbeep &
				echo "$cname: a NEWER version is available: $nxpversion < $sec_current"
				logbody="$logbody\n$cname: out-of-date [available: $sec_current]"
				$tonotify && _notify "$cname" "Out-of-date: v$sec_current available!"
			elif [[ $seccomp == "same" ]] ; then
				echo "$cname: the current version is installed"
			elif [[ $seccomp == "lesser" ]] ; then
				echo "$cname: a newer version is already installed"
				logbody="$logbody\n$cname: newer version already installed"
			else
				echo -e "ERROR comparing $cname version numbers!\n$seccomp" >&2
			fi
		fi
	fi
done < <(echo "$macsulist" | grep -v "^$")

# log results
if [[ -d "$HOMEDIR/Library/Logs/local.lcars.macOSSecurityUpdates" ]] ; then
	rm -rf "$HOMEDIR/Library/Logs/local.lcars.macOSSecurityUpdates" 2>/dev/null
fi
logloc="$HOMEDIR/Library/Logs/local.lcars.macOSSecurityUpdates.log"
if $updated ; then
	logbody=$(echo -e "$logbody" | grep -v "^$")
	logger -i -s -t "macOS Security Updates" "$logbody" 2>> "$logloc"
else
	logbody="No recent system updates"
	logger -i -s -t "macOS Security Updates" "$logbody" 2>> "$logloc"
fi

exit
