#!/bin/bash

# macOS Security Updates (macSU)
# shell script: macsu.sh
# v1.0.0
# Copyright (c) 2018 Joss Brown (pseud.)
# license: MIT+
# info: https://github.com/JayBrown/macOS-Security-Updates

export LANG=en_US.UTF-8
export PATH=$PATH:/usr/local/bin:/opt/local/bin:/sw/bin

localdate=$(date)
account=$(id -un)
process="macOS Security"
icon_loc="/System/Library/PreferencePanes/Security.prefPane/Contents/Resources/FileVault.icns"

osversion=$(sw_vers -productVersion | awk -F. '{print $2}')
scrname=$(basename $0)
if [[ "$osversion" -le 7 ]] ; then
	echo -e "Error! Incompatible OS version.\n$scrname needs at least OS X 10.8.\n*** Exiting... ***" >&2
	exit
fi

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

_beep () {
	osascript -e "beep"
}

_digitaping () {
	dsaccess=true
	(( pings = 3 ))
	while [[ $pings -ne 0 ]]
	do
		ping -q -c 1 "digitasecurity.com" &>/dev/null
		rc=$?
		[[ $rc -eq 0 ]] && (( pings = 1 ))
		(( pings = pings - 1 ))
	done
	if [[ $rc -eq 0 ]] ; then
		echo "digitasecurity.com is online."
		dsaccess=true
	else
		echo "digitasecurity.com seems to be offline."
		dsaccess=false
	fi
}

_digitacheck () {
	sigdata=$(curl -s "https://digitasecurity.com/xplorer/signatures/" 2>/dev/null | grep -B2 "$nxpversion")
	extdata=$(curl -s "https://digitasecurity.com/xplorer/extensions/" 2>/dev/null | grep -B2 "$nxpversion")
	plgdata=$(curl -s "https://digitasecurity.com/xplorer/plugins/" 2>/dev/null | grep -B2 "$nxpversion")
	alldata="$sigdata\n$extdata\n$plgdata"
	loopdata=$(echo -e "$alldata" | grep "href=" | grep -v "^$")
	while read -r line
	do
		nerror=false
		udname=$(echo "$line" | awk -F'[><]' '{print $5}' | xargs)
		if [[ $udname == "" ]] ; then
			udname="n/a"
			nerror=true
		fi
		udref=$(echo "$line" | awk -F"href=" '{print $2}' | awk -F"/>" '{print $1}' | xargs)
		if [[ $udref == "" ]] ; then
			fullref="https://digitasecurity.com/xplorer/"
		else
			fullref="https://digitasecurity.com$udref"
		fi
		if $nerror ; then
			uddate="n/a"
		else
			uddate=$(echo "$alldata" | grep -A1 -F "$udname" | tail -1 | awk -F'[><]' '{print $3}' | xargs)
			uddate=$(date -j -f "%m.%d.%Y" "$uddate" +"%b %d %Y")
		fi
		echo "New XProtect entry: $udname"
		echo "Date: $uddate"
		echo "Info: $fullref"
		! $nerror && _notify "New XProtect entry: $uddate" "$udname"
		logbody="$logbody\nNew XProtect entry: $udname\nDate: $uddate\nInfo: $fullref"
	done < <(echo -e "$loopdata")
}

echo "***************************************************"
echo "*** Starting new macOS Security components scan ***"
echo "***************************************************"
echo "Local date: $localdate"
echo "Process run by: $account"

# check for cache directory
cachedir="$HOME/.cache/macSU"
if ! [[ -d "$cachedir" ]] ; then
	echo "macOS Security Updates initial run."
	echo "No cache directory detected." >&2
	echo "Creating cache directory..." >&2
	mkdir -p "$cachedir"
	echo "Cache directory created." >&2
else
	echo "Cache directory detected."
fi

# check for log directory
logdir="$HOME/Library/Logs/local.lcars.macOSSecurityUpdates"
if ! [[ -d "$logdir" ]] ; then
	echo "No macOS Security Updates log directory detected." >&2
	echo "Creating log directory..." >&2
	mkdir -p "$logdir"
	echo "Log directory created." >&2
else
	echo "macOS Security Updates log directory detected."
fi

# components parsing list
read -d '' macsulist <<"EOF"
Gatekeeper@/private/var/db/gkopaque.bundle/Contents/version.plist@GK-version.plist@CFBundleShortVersionString
System Integrity Protection@/System/Library/Sandbox/Compatibility.bundle/Contents/version.plist@SIP-version.plist@CFBundleShortVersionString
Malware Removal Tool@/System/Library/CoreServices/MRT.app/Contents/version.plist@MRT-version.plist@CFBundleShortVersionString
Core Suggestions@/System/Library/Intelligent Suggestions/Assets.suggestionsassets/Contents/version.plist@CS-version.plist@CFBundleShortVersionString
KEXT Exclusions@/System/Library/Extensions/AppleKextExcludeList.kext/Contents/version.plist@KE-version.plist@CFBundleShortVersionString
Chinese Word List@/usr/share/mecabra/updates/com.apple.inputmethod.SCIM.bundle/Contents/version.plist@CW-version.plist@CFBundleShortVersionString
Core LSKD (dkrl)@/usr/share/kdrl.bundle/info.plist@dkrl-info.plist@CFBundleVersion
XProtect@/System/Library/CoreServices/XProtect.bundle/Contents/Resources/XProtect.meta.plist@XProtect.meta.plist@Version
EOF

# check for plist backups
while IFS='@' read -r cname cplpath cbname ckey
do
	if ! [[ -f "$cachedir/$cbname" ]] ; then
		ipldate="n/a"
		ixpversion="n/a"
		echo "No $cname backup detected." >&2
		echo "Creating plist backup..." >&2
		ipldate=$(stat -f "%Sc" "$cplpath")
		ixpversion=$(defaults read "$cplpath" $ckey 2>/dev/null)
		[[ $ixpversion == "" ]] && ixpversion="n/a"
		echo "$cname version: v$ixpversion"
		echo "Updated: $ipldate"
		cp "$cplpath" "$cachedir/$cbname"
		echo "$cname plist backed up." >&2
	else
		echo "$cname backup detected."
	fi
done < <(echo "$macsulist" | grep -v "^$")

# search for terminal-notifier
tn=$(which terminal-notifier 2>/dev/null)
if [[ "$tn" == "" ]] || [[ "$tn" == *"not found" ]] ; then
	tn_loc=$(mdfind "kMDItemCFBundleIdentifier == 'fr.julienxx.oss.terminal-notifier'" 2>/dev/null | awk 'NR==1')
	if [[ "$tn_loc" == "" ]] ; then
		tn_loc=$(mdfind "kMDItemCFBundleIdentifier == 'nl.superalloy.oss.terminal-notifier'" 2>/dev/null | awk 'NR==1')
		if [[ "$tn_loc" == "" ]] ; then
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
		tn_loc=$(mdfind "kMDItemCFBundleIdentifier == 'fr.julienxx.oss.terminal-notifier'" 2>/dev/null | awk 'NR==1')
		if [[ "$tn_loc" == "" ]] ; then
			tn_loc=$(mdfind "kMDItemCFBundleIdentifier == 'nl.superalloy.oss.terminal-notifier'" 2>/dev/null | awk 'NR==1')
			if [[ "$tn_loc" == "" ]] ; then
				tn_status="osa"
			else
				tn_status="tn-app-old"
			fi
		else
			tn_status="tn-app-new"
		fi
	fi
fi

# check components
while IFS='@' read -r cname cplpath cbname ckey
do
	pldate=$(stat -f "%Sc" "$cplpath")
	nxpversion=$(defaults read "$cplpath" $ckey)
	[[ $nxpversion == "" ]] && nxpversion="n/a"
	if [[ $(md5 -q "$cplpath") == $(md5 -q "$cachedir/$cbname") ]] ; then
		echo "$cname status: unchanged"
		echo "$cname version: $nxpversion"
		echo "$cname updated: $pldate"
	else
		oxpversion=$(defaults read "$cachedir/$cbname" $ckey 2>/dev/null)
		[[ $oxpversion == "" ]] && oxpversion="n/a"
		logbody="New $cname update\nVersions: v$oxpversion > v$nxpversion\nDate: $pldate"
		_beep
		_notify "$cname" "v$oxpversion > v$nxpversion ($pldate)"
		if [[ "$cname" == "XProtect" ]] ; then
			_digitaping
			if $dsaccess && [[ $nxpversion != "n/a" ]] ; then
				_digitacheck
			fi
		fi
		logbody=$(echo -e "$logbody" | grep -v "^$")
		logger -i -s -t "macOS Security Updates" "$logbody" 2>> "$logdir/$cname.log"
		echo "Creating new $cname backup..."
		cp "$cplpath" "$cachedir/$cbname"
		echo "$cname plist backup created."
	fi
done < <(echo "$macsulist" | grep -v "^$")

echo "*** Exiting... ***"
exit
