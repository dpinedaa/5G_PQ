# Open5GS and TLS Tunnel using PQ certificates


<!-- PHASE 1 -->
## Install everything


```bash
sudo apt install wireshark -y && sudo apt install net-tools -y && sudo apt install traceroute -y 
```

```bash
sudo apt-get install python3 python3-pip build-essential checkinstall zlib1g-dev cmake gcc libtool libssl-dev make ninja-build git astyle cmake gcc ninja-build libssl-dev python3-pytest python3-pytest-xdist unzip xsltproc doxygen graphviz python3-yaml valgrind -y
```

```bash
sudo apt-get install python3-pip
```

```bash
sudo pip3 install python-pytun
```

```bash 
sudo apt-get install git -y
```

```bash
sudo apt update
sudo apt install build-essential checkinstall zlib1g-dev -y
```

```bash
sudo apt install cmake gcc libtool libssl-dev make ninja-build git -y
sudo apt install astyle cmake gcc ninja-build libssl-dev python3-pytest python3-pytest-xdist unzip xsltproc doxygen graphviz python3-yaml valgrind -y
```


<!-- PHASE 2 -->
## Deploy Open5GS

* Copy the zip open5gs.zip into the client and server vms

REPLACE IP ADDRESSES ACCORDINGLY 

**Client**

```bash
sudo scp open5gs.zip client@192.168.122.117:~/
```

**Server**
```bash
sudo scp open5gs.zip server@192.168.122.89:~/
```



* Unzip and change name to open5gs in the home directory 

```bash
unzip open5gs.zip
```


### Building Open5GS from Sources 

#### Getting MongoDB


* Import the public key used by the package management system.

```bash
sudo apt update
```

```bash
sudo apt install gnupg
```

```bash
sudo apt install curl -y
```

```bash
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
```

* Create the list file /etc/apt/sources.list.d/mongodb-org-6.0.list for your version of Ubuntu.

```bash
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
```

* Install the MongoDB packages.


```bash 
sudo apt update
```

```bash 
sudo apt install -y mongodb-org
```
```bash 
sudo systemctl start mongod
```

```bash 
sudo systemctl enable mongod
```



#### Setting up TUN device (not persistent after rebooting)

* Create the TUN device with the interface name ogstun.

```bash
sudo ip tuntap add name ogstun mode tun
```

```bash
sudo ip addr add 10.45.0.1/16 dev ogstun
```

```bash
sudo ip addr add 2001:db8:cafe::1/48 dev ogstun
```

```bash
sudo ip link set ogstun up
```



#### Building Open5GS

* Install the dependencies for building the source code.

```bash
sudo apt install python3-pip python3-setuptools python3-wheel ninja-build build-essential flex bison git cmake libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev libyaml-dev libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev libnghttp2-dev libtins-dev libtalloc-dev meson -y 
```

* To compile with meson:

```bash
cd open5gs
```

```bash
meson build --prefix=`pwd`/install
```

```bash
ninja -C build
```

* You need to perform the installation process.

```bash
cd build
ninja install
cd ../
```


* Modify the config files to set the corresponding ip

Directory 

```bash
install/etc/open5gs
```




#### Building the WebUI of Open5GS

* Node.js is required to build WebUI of Open5GS

* Download and import the Nodesource GPG key


```bash
sudo apt update
```

```bash
sudo apt install -y ca-certificates curl gnupg
```

```bash
sudo mkdir -p /etc/apt/keyrings
```

```bash
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
```

* Create deb repository

```bash
NODE_MAJOR=20
```

```bash
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
```

# Run Update and Install


```bash
sudo apt update
```

```bash
sudo apt install nodejs -y
```

* Install the dependencies to run WebUI

```bash
cd webui
npm ci
```




<!-- PHASE 3 -->
## Setup VPN over TLS

* Copy what we have to the client and server vm 

```bash
sudo scp -r vms/client/vpn_over_tls/ client@192.168.122.117:~/
```


```bash
sudo scp -r vms/server/vpn_over_tls/ server@192.168.122.89:~/
```


<!-- PHASE 4 -->
## Install OQS in the system 


<!-- PHASE 5 -->
## Test PQ algorithms



