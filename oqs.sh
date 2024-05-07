#!/bin/bash

#sudo apt update
#sudo apt install build-essential checkinstall zlib1g-dev -y

#sudo apt install cmake gcc libtool libssl-dev make ninja-build git -y
#sudo apt install astyle cmake gcc ninja-build libssl-dev python3-pytest python3-pytest-xdist unzip xsltproc doxygen graphviz python3-yaml valgrind -y


cd /usr/local/src

sudo git clone https://github.com/open-quantum-safe/openssl.git

sudo git clone --branch main https://github.com/open-quantum-safe/liboqs.git

cd liboqs
sudo mkdir build && cd build

sudo cmake -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local/src/openssl/oqs ..

sudo ninja
sudo ninja install

cd ..
cd ..
cd openssl

sudo ./Configure no-shared linux-x86_64 -lm --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib

sudo make -j
sudo make install

# Link libraries
sudo sh -c 'echo "/usr/local/ssl/lib" > /etc/ld.so.conf.d/openssl.conf'
sudo ldconfig -v

# Edit environment file
sudo sed -i '/^PATH/s/"$/:\n\/usr\/local\/ssl\/bin"/' /etc/environment


# Verify installation
source /etc/environment
echo "$PATH"
openssl version -a

echo "Configuration completed successfully."
