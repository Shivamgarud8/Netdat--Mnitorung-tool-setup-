#!/bin/bash

set -e

echo "Installing Netdata..."

wget -qO /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh

sudo bash /tmp/netdata-kickstart.sh --non-interactive --stable-channel

sudo systemctl enable netdata
sudo systemctl restart netdata

echo ""
echo "Netdata Status:"
sudo systemctl is-active netdata

echo ""
echo "Listening Port:"
sudo ss -tulpn | grep 19999 || true

echo ""
echo "Netdata installation completed."
echo "Open: http://SERVER_IP:19999
