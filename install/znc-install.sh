#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: peterder72
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://znc.in/ | Github: https://github.com/znc/znc

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

if [[ -f /var/lib/znc/configs/znc.conf ]]; then
  msg_error "Existing ZNC configuration found at /var/lib/znc/configs/znc.conf"
  exit 1
fi

msg_info "Installing ZNC"
install_packages_with_retry "znc"
msg_ok "Installed ZNC"

msg_info "Configuring ZNC"
get_lxc_ip
ZNC_CONF="/var/lib/znc/configs/znc.conf"
ADMIN_USER="admin"
ADMIN_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)"

install -d -m 700 -o _znc -g _znc /var/lib/znc/configs

printf '%s\n' \
  "8443" \
  "yes" \
  "no" \
  "${ADMIN_USER}" \
  "${ADMIN_PASS}" \
  "${ADMIN_PASS}" \
  "${ADMIN_USER}" \
  "${ADMIN_USER}_" \
  "${ADMIN_USER}" \
  "" \
  "" \
  "no" | sudo -u _znc -H env ZNC_NO_LAUNCH_AFTER_MAKECONF=1 /usr/bin/znc --datadir=/var/lib/znc --makeconf

tmp_file="$(mktemp)"
awk '
  BEGIN {
    in_listener = 0
    listener_replaced = 0
  }
  !listener_replaced && $0 == "<Listener l>" {
    print "<Listener web>"
    print "\tPort = 8443"
    print "\tIPv4 = true"
    print "\tIPv6 = false"
    print "\tSSL = true"
    print "\tAllowIRC = false"
    print "\tAllowWeb = true"
    print "</Listener>"
    print ""
    print "<Listener irc>"
    print "\tPort = 6697"
    print "\tIPv4 = true"
    print "\tIPv6 = false"
    print "\tSSL = true"
    print "\tAllowIRC = true"
    print "\tAllowWeb = false"
    print "</Listener>"
    in_listener = 1
    listener_replaced = 1
    next
  }
  in_listener {
    if ($0 == "</Listener>") {
      in_listener = 0
    }
    next
  }
  {
    print
  }
' "${ZNC_CONF}" >"${tmp_file}"
if ! grep -q "<Listener irc>" "${tmp_file}"; then
  rm -f "${tmp_file}"
  msg_error "Failed to update the ZNC listener configuration"
  exit 1
fi
mv "${tmp_file}" "${ZNC_CONF}"

chown -R _znc:_znc /var/lib/znc
chmod 600 "${ZNC_CONF}"

echo "${ADMIN_PASS}" >~/znc.creds
msg_ok "Configured ZNC"

msg_info "Starting Service"
systemctl enable -q --now znc
msg_ok "Started Service"

motd_ssh
customize
cleanup_lxc
