#!/bin/bash

# Find default route subnet
gatewayIP=$(/sbin/route get default | /usr/bin/grep gateway | /usr/bin/awk '{print $2}' | cut -d"." -f1-3)
# Add '.2' to set the Imagr Server IP
serverIP="${gatewayIP}.2"

# Write new Imagr Server URL
/usr/bin/defaults write /var/root/Library/Preferences/com.grahamgilbert.Imagr.plist serverurl "http://${serverIP}/imagr/config/imagr_config.plist" 

# Read the newely written value
/usr/bin/defaults read /var/root/Library/Preferences/com.grahamgilbert.Imagr.plist

exit 0