#!/bin/bash

# Get the directory path of running script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Load list of servers into an array
OLDIFS="$IFS"
IFS=$'\r\n' GLOBIGNORE='*' command eval  'Servers=($(cat $DIR/Servers.txt))'

# Define the rsync process with some logging data
Synchronize () {

    # Get the directory path of running script, added '2' to not confuse the script... potentially.
    DIR2="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    # Location of directory containing .NBI files
    syncFolder="$DIR2/StoreNBIs/"
    # Find OS version
    OSXVersion=$(sw_vers -buildVersion)
    # Administrator password for `sudo` commands
    adminPass="PASSWORD"

    start=$(date +%s)
    echo -e "\n#####################################################################"
    echo -e "============= $(date) ============="
    echo -e "============= Syncing to $1  =============\n"

    # Actual `rsync` command, designed with rsync v3.1.2 in mind
    /usr/local/bin/rsync \
        -aHAXxv \
        -e 'ssh -i /Users/localadmin/.ssh/id_rsa -T -o Compression=no -x' \
        --exclude '.DS_Store' \
        --rsync-path="/usr/local/bin/rsync" \
        "$syncFolder" \
        admin@$1

    # Determine location of the `serveradmin` binary
    if [[ "$OSXVersion" < "12A" ]]; then
        ServerAdminPath="$4/usr/sbin/serveradmin"
    else
        ServerAdminPath="$4/Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin"
    fi
    if [ ! -e "$ServerAdminPath" ]; then
        echo "ERROR: Unable to find 'serveradmin' tool. Is Server.app in the Applications folder?"
    fi

    # Cycle the NetBoot Service
    ssh -i /Users/localadmin/.ssh/id_rsa admin@$1 "echo $(echo $adminPass | base64 -D) | sudo -S $ServerAdminPath stop netboot"
    ssh -i /Users/localadmin/.ssh/id_rsa admin@$1 "echo $(echo $adminPass | base64 -D) | sudo -S $ServerAdminPath start netboot"

    end=$(date +%s)
    # Compare $start and $end to get total time in minutes and seconds
    runtime=$(python -c "print '%u:%02u' % ((${end} - ${start})/60, (${end} - ${start})%60)")
    echo -e "\n============= Sync Completed ============="
    echo -e "============= Runtime was $runtime ============="
    echo -e "#####################################################################\n"
}

# Export the above function so `parallel` can use it.
export -f Synchronize

# Simultaneously sync to as many servers as there are cores in this server
/usr/local/bin/parallel Synchronize ::: "${Servers[@]}" >> "$DIR/rsync.log"
# Set IFS back to normal
IFS="$OLDIFS"
