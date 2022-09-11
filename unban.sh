#!/bin/sh
set -e      # Abort upon error
set -u      # Abort upon udefined variable
#set -x     # Print every command

touch "$1"
readonly now="$(date +'%s')"
readonly file_old_content="$(cat "$1")"

# Loop through file content and remove/unban old entries
IFS=','
echo "$file_old_content" | while read ip timestamp; do
    if [ $now -le $(echo "$timestamp + 10*60" | bc) ]; then
        # Remove existing rules
        uname | grep -qx 'BSD' \
            && pfctl -t badhosts -T delete "$ip" \
            || iptables -D INPUT -s "$ip" -j REJECT

        # Remove from ban db
        echo "/$ip/d\nwq" | ed -s "$1" || true
    fi
done
