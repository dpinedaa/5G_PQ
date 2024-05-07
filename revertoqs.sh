#!/bin/bash

# Remove OpenSSL and OQS installations
sudo rm -rf /usr/local/ssl
sudo rm -rf /usr/local/src/openssl
sudo rm -rf /usr/local/src/liboqs

# Remove openssl.conf
sudo rm -f /etc/ld.so.conf.d/openssl.conf

# Restore original PATH in /etc/environment
sudo sed -i '/\/usr\/local\/ssl\/bin/d' /etc/environment

# Verify PATH change
source /etc/environment
echo "Reverted PATH: $PATH"

echo "Reverted changes successfully."
