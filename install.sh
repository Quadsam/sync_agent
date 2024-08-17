#!/usr/bin/env bash

if [[ $(id -u) -ne 0 ]]; then
	printf 'ERROR: Run as root!\n'
	exit 1
fi

install -vDm0755 "sync_agent.sh"   "/usr/local/bin/sync_agent"
install -vDm0644 "systemd.service" "/usr/lib/systemd/system/sync_agent.service"

systemctl enable "sync_agent.service"
