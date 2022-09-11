#!/bin/sh
set -e      # Abort upon error
set -u      # Abort upon udefined variable
#set -x     # Print every command

readonly now="$(date +'%s')"
readonly file_old_content="$(cat "$1")"

# Loop through file and save new db content to $new_db
echo "$file_old_content" | IFS=',' while read ip timestamp; do
    if [ $now -le $(echo "$timestamp + 10*60" | bc) ]; then
        # Remove existing rules
        uname | grep -qx 'BSD' \
            && pfctl -t badhosts -T delete "$ip" \
            || iptables -D INPUT -s "$ip" -j REJECT

        # Remove from ban db
        echo "/$ip/d\nwq" | ed -s "$1" || true
done
