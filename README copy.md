# Open5GS and TLS Tunnel using PQ certificates

## Initial setup

**Create three VMs with the following config:**

* OS: Ubuntu 20.04
* CPU: 6
* RAM: 16 GB
* Disk: 40GB

You can downgrade this later on. This is only to enable oqs in your ubuntu environment. Run all the commands below for all the vms.


<!-- PHASE 1 -->
## Install everything

```bash
apt update 
apt-get install python3 python3-pip build-essential checkinstall zlib1g-dev cmake gcc libtool libssl-dev make ninja-build git astyle cmake gcc ninja-build libssl-dev python3-pytest python3-pytest-xdist unzip xsltproc doxygen graphviz python3-yaml valgrind wireshark net-tools traceroute iproute2 snapd -y
```

```bash
  pip3 install python-pytun
```

```bash
git clone https://github.com/dpinedaa/5G_PQ.git
```

<!-- PHASE 2 -->
## Deploy Open5GS

* Unzip Open5GS for the client and server vm

```bash
cd 5G_PQ
unzip open5gs.zip
```



### Building Open5GS from Sources 

#### Getting MongoDB


* Import the public key used by the package management system.

```bash
  apt update
  apt install gnupg curl -y
```

```bash
curl -fsSL https://pgp.mongodb.com/server-6.0.asc |   gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
```

* Create the list file /etc/apt/sources.list.d/mongodb-org-6.0.list for your version of Ubuntu.

```bash
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" |   tee /etc/apt/sources.list.d/mongodb-org-6.0.list
```

* Install the MongoDB packages.


```bash 
  apt update
```

```bash 
  apt install -y mongodb-org
```
```bash 
  systemctl start mongod
```

```bash 
  systemctl enable mongod
```



#### Setting up TUN device (not persistent after rebooting)

* Create the TUN device with the interface name ogstun.

```bash
  ip tuntap add name ogstun mode tun
```

```bash
  ip addr add 10.45.0.1/16 dev ogstun
```

```bash
  ip link set ogstun up
```



#### Building Open5GS

* Install the dependencies for building the source code.

```bash
  apt install python3-pip python3-setuptools python3-wheel ninja-build build-essential flex bison git cmake libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev libyaml-dev libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev libnghttp2-dev libtins-dev libtalloc-dev meson -y 
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







#### Building the WebUI of Open5GS

* Node.js is required to build WebUI of Open5GS

* Download and import the Nodesource GPG key


```bash
  apt update
```

```bash
  apt install -y ca-certificates curl gnupg
```

```bash
  mkdir -p /etc/apt/keyrings
```

```bash
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |   gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
```

* Create deb repository

```bash
NODE_MAJOR=20
```

```bash
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" |   tee /etc/apt/sources.list.d/nodesource.list
```

# Run Update and Install


```bash
  apt update
```

```bash
  apt install nodejs -y
```

* Install the dependencies to run WebUI

```bash
cd webui
npm ci
```



## Deploy UERANSIM 

```bash
  apt update &&   apt upgrade -y 
```

* Unzip UERANSIM 

```bash 
cd ~/5G_PQ
unzip UERANSIM
cd UERANSIM
```

* Install the required dependencies 

```bash 
  apt remove cmake -y
  apt install make gcc g++ libsctp-dev lksctp-tools iproute2 build-essential -y
```

```bash
cd ~/5G_PQ
tar -zxvf cmake-3.21.3.tar.gz
cd cmake-3.21.3
./bootstrap
make
make install
cmake --version

```


## Build UERANSIM

```bash 
make
```



## OQS in Ubuntu 

* Install OQS in the system 

```bash
cd ..
  chmod +x oqs.sh
./oqs.sh
```
























































## Setup NRF VM


### Set Up VPN over TLS

In this case the nrf will have the tls server

* Unzip vpn_over_tls-multiclient

```bash
unzip vpn_over_tls-multiclient.zip
cd vpn_over_tls-multiclient/vpn_over_tls-multiclient/src
```

* Modify the server config 

```bash
nano server/config.py
```

You can modify the TUN_ADDRESS if you want and certificates.

```diff
config = {
        "TUN_ADDRESS": "10.0.0.1",
        "TUN_NETMASK": "255.255.255.0",
        "LISTEN_ADDRESS": "0.0.0.0",
        "LISTEN_PORT": 443,
        "TUN_NAME": "tun0",
        "TUN_MTU": 1500,
        "BUFFER_SIZE": 1500,
        "CERTIFICATE_CHAIN": "./certificates/certchain.pem",
        "PRIVATE_KEY": "./certificates/private.pem",
        "SALT": "WH!{*ewP]x}0RHoP9k|nu_L(R9jm*/:i"
}
```



* Start the TLS tunnel server

```bash
  python3 server/server.py
```

This will create an interface in your machine called tun0 which Ip address is 10.0.0.1.


### Setup Open5GS NRF

* Modify the config file using a new terminal 

```bash
cd 5G_PQ/open5gs/open5gs/
nano install/etc/open5gs/nrf.yaml
```

* Replace the ip for the tunnel IP. In this case each IP represents what we have below:

NRF TLS Tunnel IP: 10.0.0.1
SCP TLS Tunnel IP: 10.0.0.2 (In the CP VM)

```diff
nrf:
    sbi:
      - addr:
-        - 127.0.0.10
+        - 10.0.0.1
-        - ::1
+        #- ::1
        port: 7777


#.......


scp:
    sbi:
-        - 127.0.1.10
+        - 10.0.0.2
        port: 7777


```

* Start NRF

```bash
./install/bin/open5gs-nrfd
```

**Expected output**

```output
nrf@nrf:~/5G_PQ/open5gs/open5gs$ ./install/bin/open5gs-nrfd
Open5GS daemon v2.4.9-268-g739cb59+

04/29 16:52:16.303: [app] INFO: Configuration: '/home/nrf/5G_PQ/open5gs/open5gs/install/etc/open5gs/nrf.yaml' (../lib/app/ogs-init.c:126)
04/29 16:52:16.303: [app] INFO: File Logging: '/home/nrf/5G_PQ/open5gs/open5gs/install/var/log/open5gs/nrf.log' (../lib/app/ogs-init.c:129)
04/29 16:52:16.311: [sbi] INFO: nghttp2_server() [http://10.0.0.1]:7777 (../lib/sbi/nghttp2-server.c:238)
04/29 16:52:16.312: [app] INFO: NRF initialize...done (../src/nrf/app.c:31)
```




























## Setup CP VM

### Set Up VPN over TLS Server

In this case the CP VM will have a TLS client and a TLS server. The client will communicate with the NRF while the server will be designated for the UERANSIM gNB.

* Unzip vpn_over_tls-multiclient

```bash
unzip vpn_over_tls-multiclient.zip
cd vpn_over_tls-multiclient/vpn_over_tls-multiclient/src
```

* Modify the server config. In this case the Tunel Address has to be different. For this case, it will be 10.0.1.1

```bash
nano server/config.py
```

You can modify the TUN_ADDRESS if you want and certificates.

```diff
config = {
-        "TUN_ADDRESS": "10.0.0.1",
+        "TUN_ADDRESS": "10.0.1.1",        
        "TUN_NETMASK": "255.255.255.0",
-        "LISTEN_ADDRESS": "0.0.0.0",
+        "LISTEN_ADDRESS": "192.168.122.105",
        "LISTEN_PORT": 443,
        "TUN_NAME": "tun0",
        "TUN_MTU": 1500,
        "BUFFER_SIZE": 1500,
        "CERTIFICATE_CHAIN": "./certificates/certchain.pem",
        "PRIVATE_KEY": "./certificates/private.pem",
        "SALT": "WH!{*ewP]x}0RHoP9k|nu_L(R9jm*/:i"
}
```


* Start the TLS tunnel server

```bash
  python3 server/server.py
```

This will create an interface in your machine called tun0 which Ip address is 10.0.1.1

**Expected output**

```output
cp@cp:~/5G_PQ/vpn_over_tls-multiclient/vpn_over_tls-multiclient/src$   python3 server/server.py
[ ] password for cp:
net.ipv4.ip_forward = 1
Reading from TUN
Got data on tun interface
b'\x00\x00\x86\xdd`\x00\x00\x00\x00\x08:\xff\xfe\x80\x00\x00\x00\x00\x00\x00\xc0<\xfc\xb4\xab|T\xd5\xff\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x85\x00\xbf\xf3\x00\x00\x00\x00'
b'000086dd6000000000083afffe80000000000000c03cfcb4ab7c54d5ff0200000000000000000000000000028500bff300000000'
192.60.252.180
```



### Set Up VPN over TLS Client 

* Open a New terminal 

```bash
cd ~/5G_PQ/vpn_over_tls-multiclient/vpn_over_tls-multiclient/src

```




* Modify the client config. Match the Ip addresses based on your case. 


```bash
nano client/config.py
```

In this case:
192.168.122.238 is the NRF IP address 
192.168.122.91 is the CP Ip address
Modify accordingly


```diff
config = {
-        "SERVER_IP": "192.168.122.238",
+        "SERVER_IP": "192.168.122.205",      
        "SERVER_PORT": 443,
        "USERNAME": "dmitriy",
        "PASSWORD": "test",
        "TUN_NAME": "tun1",
        "SERVER_HOSTNAME": "strangebit.com",
        "CA_CERTIFICATE": "./certificates/certchain.pem",
        "BUFFER_SIZE": 1500,
-        "DEFAULT_GW": "192.168.122.238",
-        "DNS_SERVER": "192.168.122.91"
+        "DEFAULT_GW": "192.168.122.205",
+        "DNS_SERVER": "192.168.122.124"
}
```


* Start the TLS tunnel client 

```bash
  python3 client/client.py
```


**Expected output**

```output
Sending authentication data...
Authentication succeeded...
Got configuration packet...
Starting to read from TLS socket...
Starting to read from tun device....
```




### Setup Open5GS CP Components

* Modify the config file using a new terminal 

#### SCP

```bash
cd 5G_PQ/open5gs/open5gs/
nano install/etc/open5gs/scp.yaml
```



```diff
scp:
    sbi:
-      - addr: 127.0.1.10
+      - addr: 10.0.0.2
        port: 7777


#...........

nrf:
    sbi:
      - addr:
-          - 127.0.0.10
-          - ::1
+          - 10.0.0.1
+          #- ::1

        port: 7777

```


* Run SCP

```bash
./install/bin/open5gs-scpd
```



#### AMF


```bash
nano install/etc/open5gs/amf.yaml
```

**REPLACE 127.0.0.5 WITHT YOUR MACHINE IP ADDRESS**

```diff
amf:
    sbi:
      - addr: 127.0.0.5
        port: 7777
    ngap:
-      - addr: 127.0.0.5
+      - addr: 10.0.1.1
    metrics:
      - addr: 127.0.0.5
        port: 9090
    guami:
      - plmn_id:
-          mcc: 999
-          mnc: 70
+          mcc: 001
+          mnc: 01
        amf_id:
          region: 2
          set: 1
    tai:
      - plmn_id:
-          mcc: 999
-          mnc: 70
+          mcc: 001
+          mnc: 01
+        tac: 1
    plmn_support:
      - plmn_id:
-          mcc: 999
-          mnc: 70
+          mcc: 001
+          mnc: 01
        s_nssai:
          - sst: 1
    security:
        integrity_order : [ NIA2, NIA1, NIA0 ]
        ciphering_order : [ NEA0, NEA1, NEA2 ]
    network_name:
        full: Open5GS
    amf_name: open5gs-amf0

#.................

    scp:
    sbi:

-      - addr: 127.0.1.10
+      - addr: 10.0.0.2
        port: 7777

```

* Start AMF

```bash
./install/bin/open5gs-amfd
```





#### SMF


```bash
nano install/etc/open5gs/smf.yaml
```

**REPLACE 127.0.0.4 WITHT YOUR MACHINE IP ADDRESS**

```diff
smf:
    sbi:
      - addr: 127.0.0.4
        port: 7777
    pfcp:
-      - addr: 127.0.0.4
-      - addr: ::1
+      - addr: 192.168.122.190
+      #- addr: ::1
    gtpc:
      - addr: 127.0.0.4
-      - addr: ::1
+      #- addr: ::1
    gtpu:
      - addr: 127.0.0.4
-      - addr: ::1
+      #- addr: ::1
    metrics:
      - addr: 127.0.0.4
        port: 9090
    subnet:
      - addr: 10.45.0.1/16
      - addr: 2001:db8:cafe::1/48
    dns:
      - 8.8.8.8
      - 8.8.4.4
      - 2001:4860:4860::8888
      - 2001:4860:4860::8844
    mtu: 1400
    ctf:
      enabled: auto
    freeDiameter: /home/cp/open5gs/install/etc/freeDiameter/smf.conf




upf:
    pfcp:
-      - addr: 127.0.0.7
+      - addr: 192.168.122.167



#.................

    scp:
    sbi:

-      - addr: 127.0.1.10
+      - addr: 10.0.0.2
        port: 7777

```

* Start SMF

```bash
./install/bin/open5gs-smfd
```







### UPF

```bash
nano install/etc/open5gs/upf.yaml
```

**REPLACE 127.0.0.7 WITHT YOUR MACHINE IP ADDRESS**




```diff
upf:
    pfcp:
-      - addr: 127.0.0.7
+      - addr: 192.168.122.167
    gtpu:
-      - addr: 127.0.0.7
+      - addr: 192.168.122.167
    subnet:
      - addr: 10.45.0.1/16
      - addr: 2001:db8:cafe::1/48
    metrics:
      - addr: 127.0.0.7
        port: 9090
```

* Start NF 

```bash
cd ~/5G_PQ/open5gs
./install/bin/open5gs-upfd
```


* Modify all the configs using the command below

```bash
cd ~/5G_PQ/open5gs/open5gs
find install/etc/open5gs -type f -exec sed -i 's/127\.0\.1\.10/10\.0\.0\.2/g' {} +
```


* Start all the other network functions 


```bash
./install/bin/open5gs-ausfd 
./install/bin/open5gs-udmd 
./install/bin/open5gs-pcfd 
./install/bin/open5gs-nssfd 
./install/bin/open5gs-bsfd 
./install/bin/open5gs-udrd 
```








**NO TLS**

```bash
find open5gs/install/etc/open5gs -type f -exec sed -i 's/10\.0\.0\.2/192\.168\.122\.97/g' {} +
find open5gs/install/etc/open5gs -type f -exec sed -i 's/10\.0\.0\.1/192\.168\.122\.238/g' {} +
```





* Modify the config files to set the corresponding ip

Directory 

```bash
install/etc/open5gs
```















































### Setup VPN over TLS









<!-- PHASE 3 -->
## Setup VPN over TLS



### Server 

* Unzip Server

```bash
cd 5G_PQ
unzip server.zip
```




* Run the server 

```bash
cd vpn_over_tls/src
  python3 server/server.py
```



### Client 

* Unzip client 

```bash
cd 5G_PQ
unzip client.zip
```

* Modify the config file 

```bash
cd client/vpn_over_tls/src/client/
nano config.py
```

**REPLACE THE SERVER_IP BASED ON YOUR OWN ENVIRONMENT**
**Client IP:** 192.168.122.91
**Server IP:** 192.168.122.238

```diff 
config = {
-	"SERVER_IP": "192.168.122.89",
+    "SERVER_IP": "192.168.122.238",
	"SERVER_PORT": 443,
	"USERNAME": "dmitriy",
	"PASSWORD": "test",
	"TUN_NAME": "tun1",
	"SERVER_HOSTNAME": "strangebit.com",
    "CA_CERTIFICATE": "./certificates/certchain.pem",
	"BUFFER_SIZE": 1500,
-   "DEFAULT_GW": "192.168.122.117",
-	"DNS_SERVER": "192.168.122.89"
+	"DEFAULT_GW": "192.168.122.91",
+	"DNS_SERVER": "192.168.122.238"
}
```


* Install OQS in the system 

```bash
  chmod +x oqs.sh
./oqs.sh
```




* Run the server 

```bash
cd vpn_over_tls/src
  python3 client/client.py
```




## Configure Open5GS

### Server VM


* Modify the config files 

#### NRF


```bash
nano ~/5G_PQ/open5gs/install/etc/open5gs/nrf.yaml
```





### Client VM

* Modify the config files 


