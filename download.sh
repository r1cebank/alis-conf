#!/usr/bin/env bash
set -e

# Install wget dependency
pacman -Sy --noconfirm wget

rm -f alis_custom.conf
rm -f alis_package_custom.sh
rm -f configure.sh

wget https://raw.githubusercontent.com/r1cebank/alis-conf/main/alis_custom.conf
wget https://raw.githubusercontent.com/r1cebank/alis-conf/main/alis_packages_custom.conf
wget https://raw.githubusercontent.com/r1cebank/alis-conf/main/configure.sh

chmod +x alis_custom.sh
chmod +x alis-alis_package_custom.sh
chmod +x configure.sh
