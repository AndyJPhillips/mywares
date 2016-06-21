#!/bin/bash

# Script to verify certain cifs.audit options are set on the specified NetApp
# AndyP 20151118

print_usage() {
	printf "\n\nUsage is: ${0} <hostname of the NetApp running the groupshares vfiler>\n\n"
}

# Test if more than one command line argument has been passed to the script
if [ "$#" -ne 1 ]; then
	print_usage
	exit 3
fi

# Setup some variables and arrays
netapp=${1}
offsettings=()
onsettings=()

# Main script logic to test the cifs.audit options
cifs_audit_enable=`ssh ${netapp} vfiler run groupshares options cifs.audit.enable | grep -v groupshares | awk '{print $2}' | tail -1`	
if [ $? -ne 0 ]; then 
	printf "SERVICE STATUS: CRIT error accessing ${netapp} via ssh |;;;;"
	exit 2
fi
if [ "${cifs_audit_enable}" = "off" ]; then
	offsettings+=( cifs_audit_enable )
else
	onsettings+=( cifs_audit_enable )
fi

cifs_audit_file_access_events_enable=`ssh ${netapp} vfiler run groupshares options cifs.audit.file_access_events.enable | grep -v groupshares | awk '{print $2}' | tail -1`
if [ $? -ne 0 ]; then 
	printf "SERVICE STATUS: CRIT error accessing ${netapp} via ssh |;;;;"
	exit 2
fi
if [ "${cifs_audit_file_access_events_enable}" = "off" ]; then
        offsettings+=( cifs_audit_file_access_events_enable )
else
	onsettings+=( cifs_audit_file_access_events_enable )
fi

cifs_audit_liveview_enable=`ssh ${netapp} vfiler run groupshares options cifs.audit.liveview.enable | grep -v groupshares | awk '{print $2}' | tail -1`
if [ $? -ne 0 ]; then 
	printf "SERVICE STATUS: CRIT error accessing ${netapp} via ssh |;;;;"
	exit 2
fi
if [ "${cifs_audit_liveview_enable}" = "off" ]; then
        offsettings+=( cifs_audit_liveview_enable )
else
	onsettings+=( cifs_audit_liveview_enable )
fi

if [ "${#offsettings[@]}" -eq 0 ]; then
	printf "SERVICE STATUS: OK all important cifs.audit settings are on | cifs_audit=on cifs_audit_file_access_events_enable=on cifs_audit_liveview_enable=on;;;;"
	exit 0
else
	for setting in ${offsettings[@]}
	do
		perfdata=${perfdata}\ ${setting}=off
	done
	for setting in ${onsettings[@]}
        do
                perfdata=${perfdata}\ ${setting}=on
        done
	printf "SERVICE STATUS: CRIT these cifs.audit settings are off: ${offsettings[@]} |${perfdata};;;;"
	exit 2
fi
