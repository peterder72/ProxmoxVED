#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/peterder72/ProxmoxVED/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: peterder72
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://znc.in/ | Github: https://github.com/znc/znc

APP="ZNC"
var_tags="${var_tags:-irc}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /var/lib/znc/configs/znc.conf ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop znc
  msg_ok "Stopped Service"

  msg_info "Updating ${APP}"
  $STD apt-get update
  $STD apt-get install -y --only-upgrade znc
  msg_ok "Updated ${APP}"

  msg_info "Starting Service"
  systemctl start znc
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8443${CL}"
echo -e "${INFO}${YW} Username: ${BGN}admin${CL}"
echo -e "${INFO}${YW} IRC over TLS is available on:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:6697${CL}"
echo -e "${INFO}${YW} Add an IRC network in webadmin before using an IRC client.${CL}"
echo -e "${INFO}${YW} The password is stored at ${BGN}/root/znc.creds${CL}"
