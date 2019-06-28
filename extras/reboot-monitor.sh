#!/bin/sh
# Start this script in /etc/rc.local
# Then you can do "touch /srv/nfs/<hostname>/reboot" to force a client to reboot.
while true; do
	if [ -e "/reboot" ]; then
		echo "Rebooting..."
		rm /reboot
		reboot now
	else
		sleep 5
	fi
done
