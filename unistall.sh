#!/bin/bash

wget -O /tmp/netdata-uninstaller.sh https://raw.githubusercontent.com/netdata/netdata/master/packaging/installer/netdata-uninstaller.sh

sudo bash /tmp/netdata-uninstaller.sh --yes
