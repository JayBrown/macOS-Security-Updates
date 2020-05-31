![macsu-platform-macos](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![macsu-code-shell](https://img.shields.io/badge/code-shell-yellow.svg)
[![macsu-license](http://img.shields.io/badge/license-MIT+-blue.svg)](https://github.com/JayBrown/macOS-Security-Updates/blob/master/LICENSE)

# macOS Security Updates (macSU) <img src="https://github.com/JayBrown/macOS-Security-Updates/blob/master/img/jb-img.png" height="20px"/>

**macOS Security Updates (macSU) is a LaunchAgent and shell script for macOS 10.5 (Catalina). It will run a scan every four hours and notify the user if any of the following macOS Security components has been been updated:**
* **App Exceptions**
* **Compatibility Notification Data**
* **Core LSKD (kdrl)**
* **Core Suggestions**
* **Gatekeeper**
* **Gatekeeper E**
* **Incompatible Apps**
* **Incompatible Kernel Extensions (KEXT Exclusions)**
* **Malware Removal Tool (MRT)**
* **TCC**
* **XProtect**

**Plus:**
* **System**
* **System build**
* **EFI (Boot ROM)**
* **iBridge**
* **rootless.conf**

![screengrab](https://github.com/JayBrown/macOS-Security-Updates/blob/master/img/screengrab.jpg)

## Installation
* clone repo
* `chmod +x macsu.zsh && ln -s macsu.zsh /usr/local/bin/macsu.zsh`
* `cp local.lcars.macOSSecurityUpdates.plist $HOME/Library/LaunchAgents/local.lcars.macOSSecurityUpdates.plist`
* `launchctl load $HOME/Library/LaunchAgents/local.lcars.macOSSecurityUpdates.plist`
* optional: install **[terminal-notifier](https://github.com/julienXX/terminal-notifier)**

### Testing
**Execute `macsu.zsh` at least once**, e.g. by running the LaunchAgent with `launchctl start local.lcars.macOSSecurityUpdates`, or by calling the script directly: `./macsu.zsh`

Then you can test the update notification functionality i.a. by entering the following command sequence:

`plutil -replace CFBundleShortVersionString -integer 2098 "$HOME/.cache/macSU/XP-version.plist" && launchctl start local.lcars.macOSSecurityUpdates`

### Notes
* The agent (and thereby the script) will run every 4 hours.
* **macSU** is only compatible with macOS 10.15 (Catalina).

## Uninstall
* `launchctl unload $HOME/Library/LaunchAgents/local.lcars.macOSSecurityUpdates.plist`
* remove the cloned `macOS-Security-Updates` GitHub repository
* `rm -f /usr/local/bin/macsu.zsh`
* `rm -rf $HOME/.cache/macSU`
* `rm -f $HOME/Library/Logs/local.lcars.macOSSecurityUpdates.log`
* `rm -f /tmp/local.lcars.macOSSecurityUpdates.stdout`
* `rm -f /tmp/local.lcars.macOSSecurityUpdates.stderr`

## Future
* find a way to read the System Integrity Protection (SIP) version number on Catalina
