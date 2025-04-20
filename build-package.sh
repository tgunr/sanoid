#!/bin/bash
# This script builds and installs the Sanoid package from source on a Debian-based system.
# It assumes that the necessary dependencies are already installed.
# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi
# Update the package list
apt update
# Install necessary dependencies for building the package
apt install -y build-essential debhelper libcurl4-gnutls-dev libssl-dev pkg-config python3-dev

# Navigate to the source directory
cd /root/src/sanoid-master || exit

# Make sure we have the necessary symlink for the Debian build system
if [ ! -e debian ]; then
  ln -s packages/debian .
fi

# Build the package
dpkg-buildpackage -uc -us

# The package will be created in the parent directory
cd ..

# Install the package
apt install -y ./sanoid_*_all.deb

# If there are any dependency issues, resolve them
apt -f install

# Enable the services
systemctl daemon-reload
systemctl enable sanoid.timer syncoid-runner.timer syncoid-cleanup.timer
systemctl start sanoid.timer syncoid-runner.timer syncoid-cleanup.timer

# Verify services are running
systemctl status sanoid.timer syncoid-runner.timer syncoid-cleanup.timer