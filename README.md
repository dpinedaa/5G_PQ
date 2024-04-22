# Open5GS and TLS Tunnel using PQ certificates


<!-- PHASE 1 -->
## Install everything

```bash
sudo apt-get install python3 python3-pip build-essential checkinstall zlib1g-dev cmake gcc libtool libssl-dev make ninja-build git astyle cmake gcc ninja-build libssl-dev python3-pytest python3-pytest-xdist unzip xsltproc doxygen graphviz python3-yaml valgrind wireshark net-tools traceroute -y
```

```bash
sudo pip3 install python-pytun
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
sudo apt update
sudo apt install gnupg curl -y
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



### Server 

* Unzip Server

```bash
cd 5G_PQ
unzip server.zip
```

* Install OQS in the system 

```bash
sudo chmod +x oqs.sh
./oqs.sh
```


* Run the server 

```bash
cd vpn_over_tls/src
sudo python3 server/server.py
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
sudo chmod +x oqs.sh
./oqs.sh
```




* Run the server 

```bash
cd vpn_over_tls/src
sudo python3 client/client.py
```


## Configure Open5GS

### Server VM


* Modify the config files 

#### NRF


```bash
nano ~/5G_PQ/open5gs/install/etc/open5gs/nrf.yaml
```


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
cd ~/5G_PQ/open5gs
./install/bin/open5gs-nrfd
```



### Client VM

* Modify the config files 




#### AMF


```bash
nano ~/5G_PQ/open5gs/install/etc/open5gs/amf.yaml
```

**REPLACE 127.0.0.5 WITHT YOUR MACHINE IP ADDRESS**

```diff
amf:
    sbi:
      - addr: 127.0.0.5
        port: 7777
    ngap:
-      - addr: 127.0.0.5
+      - addr: 192.168.122.91
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
      - addr: 10.0.0.2
        port: 7777

```



























#### AMF


```bash
nano ~/5G_PQ/open5gs/install/etc/open5gs/amf.yaml
```

**REPLACE 127.0.0.5 WITHT YOUR MACHINE IP ADDRESS**

```diff
amf:
    sbi:
      - addr: 127.0.0.5
        port: 7777
    ngap:
-      - addr: 127.0.0.5
+      - addr: 192.168.122.91
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
      - addr: 10.0.0.2
        port: 7777

```






#### SMF


```bash
nano ~/5G_PQ/open5gs/install/etc/open5gs/smf.yaml
```

**REPLACE 127.0.0.5 WITHT YOUR MACHINE IP ADDRESS**

```diff
amf:
    sbi:
      - addr: 127.0.0.5
        port: 7777
    ngap:
-      - addr: 127.0.0.5
+      - addr: 192.168.122.91
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
      - addr: 10.0.0.2
        port: 7777

```