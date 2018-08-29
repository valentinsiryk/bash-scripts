#!/bin/bash -e

if [ $EUID -ne 0 ]; then
    echo "[ERROR] This script must be run as root" 1>&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

UBUNTU_VERSION="`lsb_release -r | awk '{print $2}'`"
MAJOR_VERSION="`echo $UBUNTU_VERSION | awk -F. '{print $1}'`"

if [ -e /etc/update-manager/release-upgrades ]; then
    echo '[INFO] Disabling release-upgrades'
    sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades
fi

if [ "$MAJOR_VERSION" -ge "16" ]; then
    echo '[INFO] Disabling systemd apt timers/services...'
    systemctl stop apt-daily.timer
    systemctl stop apt-daily-upgrade.timer
    systemctl disable apt-daily.timer
    systemctl disable apt-daily-upgrade.timer
    systemctl mask apt-daily.service
    systemctl mask apt-daily-upgrade.service
    systemctl daemon-reload
fi

echo '[INFO] Disabling periodic activities of apt...'
cat <<EOF >/etc/apt/apt.conf.d/10periodic
APT::Periodic::Enable "0";
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

echo '[INFO] Removing unattended-upgrades packege...'
rm -rf /var/log/unattended-upgrades
apt-get -y purge unattended-upgrades 1>/dev/null

echo '[OK] Done'
