#!/bin/sh
set -e      # Abort upon error
set -u      # Abort upon udefined variable
#set -x     # Print every command

#######################################
#   Description:
#       Ban IPs after three failed SSH login attempts
#       Tested on Linux and OpenBSD
#   Usage:
#       ./miniban.sh
#   Arguments:
#        None!
#   Returns:
#       0 upon success
#       >=1 upon error
#######################################
main() {
    # Check if $USAGE is respected
    readonly USAGE='Usage: $0'
    [ "$#" -eq 0 ] || { err "Error: 0 argument(s) expected, $# received" && err "$USAGE" && return 1; }
    [ "$(id -u)" -eq 0 ] || { err "Run as root" && return 2; }

    # Constants
    readonly log_file='/tmp/miniban_ip.log'
    readonly whitelist_db='miniban.whitelist'
    readonly ban_db='/tmp/miniban.db'

    # Run unban in the background every minute
    ( while true; do ./unban.sh "$ban_db"; sleep 60; done ) &

    # Authlog is located at auth.log on most systems, except on Open- and NetBSD
    uname | grep -qx -E 'OpenBSD|NetBSD' \
        && readonly auth_log='/var/log/authlog' \
        || readonly auth_log='/var/log/auth.log'

    # Extract IPs from failed logins
    tail -f "$auth_log" \
        | grep --line-buffered sshd \
        | grep --line-buffered -E 'failure|Failed password' \
        | grep --line-buffered -o -E 'rhost=.* |m .* p' \
        | sed -u 's/rhost=//;s/m\ //;s/\ p//' \
    | while read ip; do
        # If address is whitelisted, do not ban
        grep -qx "$ip" "$whitelist_db" && continue || true

        # Register failed login
        echo "$ip" >> $log_file

        # Ban ip if it has been registred three times already
        has_failed_three_times "$log_file" "$ip" \
            && ./ban.sh "$ban_db" "$ip" \
            || continue
    done
}

has_failed_three_times() {
    count="$(grep "$2" "$1" | wc -l)"
    [ "$count" -ge 3 ] && return 0 || return 1
}

#######################################
#   Print error message to stderr
#   https://google.github.io/styleguide/shellguide.html
#######################################
err() { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2; }

main "$@"; exit

