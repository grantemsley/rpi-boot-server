#!/bin/bash
set -euo pipefail

# Get a list of all RPis that have recently tried to boot by looking for them requesting start.elf from the tftp server
# Extract the serial number of the RPi from the request.

PISERIALS=($(cat syslog | sed -n -e 's#.*/srv/tftp/\(.*\)/start.elf.*#\1#p' | sort | uniq))

# Remove any serials that have already been assigned (have a symlink in /srv/tftp)
UNASSIGNEDSERIALS=()

for i in ${PISERIALS[@]}; do
	if [ ! -e "/srv/tftp/$i" ]; then
		UNASSIGNEDSERIALS+=($i)
	fi
done

# Show the actual logs to make it easier to match up a PI trying to boot to a serial number
echo "-----------------------------"
echo "Recent network boot attempts:"
echo "-----------------------------"
cat syslog | grep '/srv/tftp/.*/start.elf'
echo
echo

COLUMNS=1
PS3="Select the PI serial number to assign or Q to quit:"
select SERIAL in ${UNASSIGNEDSERIALS[*]}
do
    if [[ "${REPLY,,}" == "q" ]]; then
        echo "Quitting"
        exit 1
    fi

    if [[ "$SERIAL" == "" ]]; then
        echo "'$REPLY' is not a valid number."
        continue
    fi

    echo "Using RPi with serial number $SERIAL"
    break
done

# Now make a list of all the unassigned directories in /srv/nfs    
NFSROOTS=(/srv/nfs/*/)
echo "Directories found: ${NFSROOTS[@]}"


# Find all the assigned nfsroots
# find all the symlinks in /srv/tftp, use readlink to get the target of the link, parse out the directory part.
ASSIGNED=($(find /srv/tftp -type l -exec readlink -f {} \; | sed -n -e 's#/srv/nfs/\(.*\)/boot#\1#p'))
echo "Assigned directories found: ${ASSIGNED[@]}"



#for d in /srv/nfs/*/; do echo "$d"; done
#find /srv/tftp -type l
