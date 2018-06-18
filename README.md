![macsu-platform-macos](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![macsu-code-shell](https://img.shields.io/badge/code-shell-yellow.svg)
[![macsu-license](http://img.shields.io/badge/license-MIT+-blue.svg)](https://github.com/JayBrown/macOS-Security-Updates/blob/master/LICENSE)

# macOS Security Updates (macSU) <img src="https://github.com/JayBrown/macOS-Security-Updates/blob/master/img/jb-img.png" height="20px"/>

**macOS Security Updates (macSU) is a LaunchAgent and shell script. It will run a scan every four hours and notify the user if any of the following macOS Security components has been been updated:**
* **XProtect**
* **Gatekeeper**
* **System Integrity Protection (SIP)**
* **Malware Removal Tool (MRT)**
* **Core Suggestions**
* **Incompatible Kernel Extensions (KEXT Exclusions)**
* **Chinese Word List (SCIM)**
* **Core LSKD (dkrl)**

**For XProtect updates macSU also tries to get more information on the update from Digita Security's [Xplorer](https://digitasecurity.com/xplorer/).**

**If you only want to receive notifications about XProtect updates, you can use [XProtectUpdates](https://github.com/JayBrown/XProtectUpdates) instead.**

![screengrab](https://github.com/JayBrown/macOS-Security-Updates/blob/master/img/screengrab.jpg)

## Installation
* clone repo
* `chmod +x macsu.sh && ln -s macsu.sh /usr/local/bin/macsu.sh`
* `cp local.lcars.macOSSecurityUpdates.plist $HOME/Library/LaunchAgents/local.lcars.macOSSecurityUpdates.plist`
* `launchctl load $HOME/Library/LaunchAgents/local.lcars.macOSSecurityUpdates.plist`
* optional: install **[terminal-notifier](https://github.com/julienXX/terminal-notifier)**

### Testing
After running the LaunchAgent at least once, e.g. with `launchctl start local.lcars.macOSSecurityUpdates`, you can test the update notification functionality i.a. by entering the following command sequence:

`plutil -replace Version -integer 2098 "$HOME/.cache/macSU/XProtect.meta.plist" && launchctl start local.lcars.macOSSecurityUpdates`

### Notes
* The agent (and thereby the script) will run every 4 hours. If there has been an XProtect update, it's possible that Digita's **Xplorer** hasn't been updated yet, i.e. **macSU** will not return any useful information on the contents of the update. This obviously still needs some testing, but if you want to be on the safe side, you can change the agent's frequency by editing the plist key `StartInterval`, e.g. from 4 to 8 hours.
* **macSU** has only been tested on El Capitan (OS X 10.11) and High Sierra (macOS 10.13).
* **macSU** uses the macOS Notification Center, so the **minimum system requirement is OS X 10.8**.

## Uninstall
* `launchctl unload $HOME/Library/LaunchAgents/local.lcars.macOSSecurityUpdates.plist`
* remove the cloned `macOS-Security-Updates` GitHub repository
* `rm -f /usr/local/bin/macsu.sh`
* `rm -rf $HOME/.cache/macSU`
* `rm -rf $HOME/Library/Logs/local.lcars.macOSSecurityUpdates`
* `rm -f /tmp/local.lcars.macOSSecurityUpdates.stdout`
* `rm -f /tmp/local.lcars.macOSSecurityUpdates.stderr`
