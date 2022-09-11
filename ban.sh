#!/bin/sh
set -e      # Abort upon error
set -u      # Abort upon udefined variable
#set -x     # Print every command

touch "$1"

# If ip is already banned, delete existing db entry
grep -qx "$2" "$1" && echo "/$2/d\nwq" | ed -s "$1" || true

# Ban
## BSD: Assuming table "badhosts" is pre-existing
uname | grep -qx 'BSD' \
    && pfctl -t badhosts -T add "$ip" \
    || iptables -I INPUT -s "$2" -j DROP

# Save ban in DB
echo "$2,$(date +'%s')" >> "$1"
