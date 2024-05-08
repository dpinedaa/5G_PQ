Diana Pineda Andrade is inviting you to a scheduled Zoom meeting.

Topic: Diana Pineda Andrade's Personal Meeting Room

Join Zoom Meeting
https://fiu.zoom.us/j/5641977519

# Open5GS and TLS Tunnel using PQ certificates


## DEPLOYING VMS

### Initial setup for VMs

**Create three VMs with the following config:**

* OS: Ubuntu 20.04
* CPU: 6
* RAM: 16 GB
* Disk: 40GB

You can downgrade this later on. This is only to enable oqs in your ubuntu environment. Run all the commands below for all the vms.


<!-- PHASE 1 -->
### Install everything

```bash
sudo apt-get install python3 python3-pip build-essential checkinstall zlib1g-dev cmake gcc libtool libssl-dev make ninja-build git astyle cmake gcc ninja-build libssl-dev python3-pytest python3-pytest-xdist unzip xsltproc doxygen graphviz python3-yaml valgrind wireshark net-tools traceroute systemd systemd-sysv dbus dbus-user-session -y
```

```bash
sudo pip3 install python-pytun
```

```bash
git clone https://github.com/dpinedaa/5G_PQ.git
```

<!-- PHASE 2 -->
### Deploy Open5GS

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
sudo ip link set ogstun up
```



#### Building Open5GS

* Install the dependencies for building the source code.

```bash
sudo apt install python3-pip python3-setuptools python3-wheel ninja-build build-essential flex bison git cmake libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev libyaml-dev libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev libnghttp2-dev libtins-dev libtalloc-dev meson -y 
```

* To compile with meson:

```bash
cd open5gs/open5gs
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

#### Run Update and Install Node JS


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



### Deploy UERANSIM 

```bash
sudo apt update && sudo apt upgrade -y 
```

* Unzip UERANSIM 

```bash 
cd ~/5G_PQ
unzip UERANSIM
cd UERANSIM
```

* Install the required dependencies 

```bash 
sudo apt remove cmake -y
sudo apt install make gcc g++ libsctp-dev lksctp-tools iproute2 build-essential -y
sudo snap install cmake --classic
```

#### Build UERANSIM

```bash 
make
```



### OQS in Ubuntu 

* Install OQS in the system 

```bash
cd ..
sudo chmod +x oqs.sh
./oqs.sh
```




















































### Setup NRF VM


#### Set Up VPN over TLS

In this case the nrf will have the tls server

* Unzip vpn_over_tls-master

```bash
unzip vpn_over_tls-master.zip
cd vpn_over_tls-master/vpn_over_tls-master/src
```

* Modify the server config 

```bash
nano server/config.py
```

You can modify the TUN_ADDRESS if you want and certificates.

```diff
config = {
-        "TUN_ADDRESS": "192.168.122.1",
+        "TUN_ADDRESS": "10.0.0.1",        
        "TUN_NETMASK": "255.255.255.0",
-        "LISTEN_ADDRESS": "0.0.0.0",
+        "LISTEN_ADDRESS": "192.168.122.117",        
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
sudo python3 server/server.py
```

This will create an interface in your machine called tun0 which Ip address is 10.0.0.1.


#### Setup Open5GS NRF

* Modify the config file using a new terminal 

```bash
cd ~/5G_PQ/open5gs/open5gs/
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




























### Setup CP VM

#### Set Up VPN over TLS Server

In this case the CP VM will have a TLS client and a TLS server. The client will communicate with the NRF while the server will be designated for the UERANSIM gNB.

* Unzip vpn_over_tls-master

```bash
unzip vpn_over_tls-master.zip
cd vpn_over_tls-master/vpn_over_tls-master/src
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
sudo python3 server/server.py
```

This will create an interface in your machine called tun0 which Ip address is 10.0.1.1

**Expected output**

```output
cp@cp:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src$ sudo python3 server/server.py
[sudo] password for cp:
net.ipv4.ip_forward = 1
```



#### Set Up VPN over TLS Client 

* Open a New terminal 

```bash
cd ~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src

```




* Modify the client config. Match the Ip addresses based on your case. 


```bash
nano client/config.py
```

In this case:
192.168.64.9 is the NRF IP address 
192.168.64.8 is the CP Ip address
Modify accordingly


```diff
config = {
-        "SERVER_IP": "192.168.64.9",
+        "SERVER_IP": "192.168.122.205",      
        "SERVER_PORT": 443,
        "USERNAME": "dmitriy",
        "PASSWORD": "test",
        "TUN_NAME": "tun1",
        "SERVER_HOSTNAME": "strangebit.com",
        "CA_CERTIFICATE": "./certificates/certchain.pem",
        "BUFFER_SIZE": 1500,
-        "DEFAULT_GW": "192.168.64.9",
-        "DNS_SERVER": "192.168.64.8"
+        "DEFAULT_GW": "192.168.122.205",
+        "DNS_SERVER": "192.168.122.124"
}
```


* Start the TLS tunnel client 

```bash
sudo python3 client/client.py
```


**Expected output**

```output
Sending authentication data...
Authentication succeeded...
Got configuration packet...
Starting to read from TLS socket...
Starting to read from tun device....
```




#### Setup Open5GS CP Components

* Modify the config file using a new terminal 

##### SCP

```bash
cd ~/5G_PQ/open5gs/open5gs/
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



##### AMF


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





##### SMF


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







##### UPF

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
find install/etc/open5gs -type f -exec sed -i 's/127\.0\.0\.10/10\.0\.0\.1/g' {} +
find . -type f -exec sed -i 's/- ::1/#- ::1/g' {} +


```


* Start all the other network functions 


```bash
./install/bin/open5gs-ausfd &
./install/bin/open5gs-udmd  & 
./install/bin/open5gs-pcfd 
./install/bin/open5gs-nssfd 
./install/bin/open5gs-bsfd 
./install/bin/open5gs-udrd 
```







##### Add Subscriber 

* Access the database 

```bash
mongosh mongodb://192.168.120.2:27017
```

*  Change database

```bash
use open5gs 
```

* Insert subscriber. Make sure that matches the UE config 

```bash
db.subscribers.insertOne({
  imsi: '001010000000001',
  msisdn: [],
  imeisv: '4301816125816151',
  mme_host: [],
  mme_realm: [],
  purge_flag: [],
  security: {
    k: '465B5CE8 B199B49F AA5F0A2E E238A6BC',
    op: null,
    opc: 'E8ED289D EBA952E4 283B54E8 8E6183CA',
    amf: '8000',
    sqn: NumberLong("513")
  },
  ambr: { downlink: { value: 1, unit: 3 }, uplink: { value: 1, unit: 3 } },
  slice: [
    {
      sst: 1,
      default_indicator: true,
      session: [
        {
          name: 'internet',
          type: 3,
          qos: { index: 9, arp: { priority_level: 8, pre_emption_capability: 1, pre_emption_vulnerability: 1 } },
          ambr: { downlink: { value: 1, unit: 3 }, uplink: { value: 1, unit: 3 } },
          ue: { addr: '10.45.0.3' },
          _id: ObjectId("6473fd45a07e473e0b5334ce"),
          pcc_rule: []
        }
      ],
      _id: ObjectId("6473fd45a07e473e0b5334cd")
    }
  ],
  access_restriction_data: 32,
  subscriber_status: 0,
  network_access_mode: 0,
  subscribed_rau_tau_timer: 12,
  __v: 0
})
```

**OUTPUT**

```output 
{
  acknowledged: true,
  insertedId: ObjectId('663b9854fdf51515222202d8')
}

```




### Setup gNB VM




#### Set Up VPN over TLS Server

In this case the gNB VM will have a TLS client and a TLS server. The client will communicate with the AMF while the server will be designated for the UERANSIM UE.





* Change directory to vpn_over_tls-master

```bash
cd ~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src/
```

* Modify the server config. In this case the Tunel Address has to be different. For this case, it will be 10.0.2.1

```bash
nano server/config.py
```

You can modify the TUN_ADDRESS if you want and certificates.

```diff
config = {
-        "TUN_ADDRESS": "192.168.120.177",
+        "TUN_ADDRESS": "10.0.2.1",        
        "TUN_NETMASK": "255.255.255.0",
-        "LISTEN_ADDRESS": "0.0.0.0",
+        "LISTEN_ADDRESS": "192.168.122.10",
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
python3 server/server.py &
```

This will create an interface in your machine called tun0 which Ip address is 10.0.2.1


**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 server/server.py &
[1] 34
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# net.ipv4.ip_forward = 1
```



#### Set Up VPN over TLS Client 




* Modify the client config. Match the Ip addresses based on your case. 


```bash
nano client/config.py
```

In this case:
192.168.64.9 is the AMF IP address 
192.168.64.8 is the gNB Ip address
Modify accordingly


```diff
config = {
-        "SERVER_IP": "192.168.64.9",
+        "SERVER_IP": "192.168.122.8",      
        "SERVER_PORT": 443,
        "USERNAME": "dmitriy",
        "PASSWORD": "test",
        "TUN_NAME": "tun1",
        "SERVER_HOSTNAME": "strangebit.com",
        "CA_CERTIFICATE": "./certificates/certchain.pem",
        "BUFFER_SIZE": 1500,
-        "DEFAULT_GW": "192.168.64.9",
-        "DNS_SERVER": "192.168.64.8"
+        "DEFAULT_GW": "192.168.122.8",
+        "DNS_SERVER": "192.168.122.9"
}
```


* Start the TLS tunnel client 

```bash
python3 client/client.py &
```


**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 client/client.py &
[2] 40
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# Sending authentication data...
Authentication succeeded...
Got configuration packet...
Starting to read from TLS socket...
Starting to read from tun device....

```




#### Setup gNB UERANSIM

* Modify the config file 

##### gNB

* Unzip UERANSIM

```bash
cd ~/5G_PQ
unzip UERANSIM.zip
cd UERANSIM
```


```bash
cd ~/5G_PQ/UERANSIM/config
cp open5gs-gnb.yaml open5gs-gnb1.yaml
nano open5gs-gnb1.yaml
```



```diff
-mcc: '999'          # Mobile Country Code value
+mcc: '001'          # Mobile Country Code value

-mnc: '70'           # Mobile Network Code value (2 or 3 digits)
+mnc: '01'           # Mobile Network Code value (2 or 3 digits)

nci: '0x000000010'  # NR Cell Identity (36-bit)
idLength: 32        # NR gNB ID length in bits [22...32]
tac: 1              # Tracking Area Code

-linkIp: 127.0.0.1   # gNB's local IP address for Radio Link Simulation (Usually same with local IP)
-ngapIp: 127.0.0.1   # gNB's local IP address for N2 Interface (Usually same with local IP)
-gtpIp: 127.0.0.1    # gNB's local IP address for N3 Interface (Usually same with local IP)

+linkIp: 10.0.2.1   # gNB's local IP address for Radio Link Simulation (Usually same with local IP)
+ngapIp: 10.0.1.2   # gNB's local IP address for N2 Interface (Usually same with local IP)
+gtpIp: 192.168.122.9   # gNB's local IP address for N3 Interface (Usually same with local IP)


# List of AMF address information
amfConfigs:
-  - address: 127.0.0.5
+  - address: 10.0.1.1
    port: 38412

# List of supported S-NSSAIs by this gNB
slices:
  - sst: 1

# Indicates whether or not SCTP stream number errors should be ignored.
ignoreStreamIds: true```


## Start using the gNB - UERANSIM 

After completing configurations and setups, now you can start using UERANSIM.
```

Run the following command to start the gNB:

```bash 
cd ..
./build/nr-gnb -c config/open5gs-gnb1.yaml &
```

























### Setup UE VM




#### Set Up VPN over TLS Client 

In this case the UE VM will have a TLS client  only. The client will communicate with the UERANSIM gNB.




* Change directory to vpn_over_tls-master

```bash
cd ~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src/
```



* Modify the client config. Match the Ip addresses based on your case. 


```bash
nano client/config.py
```

In this case:
192.168.64.9 is the gNB IP address 
192.168.64.8 is the UE Ip address
Modify accordingly


```diff
config = {
-        "SERVER_IP": "192.168.64.9",
+        "SERVER_IP": "192.168.120.8",      
        "SERVER_PORT": 443,
        "USERNAME": "dmitriy",
        "PASSWORD": "test",
        "TUN_NAME": "tun1",
        "SERVER_HOSTNAME": "strangebit.com",
        "CA_CERTIFICATE": "./certificates/certchain.pem",
        "BUFFER_SIZE": 1500,
-        "DEFAULT_GW": "192.168.64.9",
-        "DNS_SERVER": "192.168.64.8"
+        "DEFAULT_GW": "192.168.120.8",
+        "DNS_SERVER": "192.168.120.9"
}
```


* Start the TLS tunnel client 

```bash
python3 client/client.py &
```


**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 client/client.py &
[2] 40
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# Sending authentication data...
Authentication succeeded...
Got configuration packet...
Starting to read from TLS socket...
Starting to read from tun device....

```




#### Setup UE UERANSIM


* Unzip UERANSIM

```bash
cd ~/5G_PQ
unzip UERANSIM.zip
cd UERANSIM
```


* Modify the config file 

##### UE

```bash
cd ~/5G_PQ/UERANSIM/config
 cp open5gs-ue.yaml open5gs-ue1.yaml
nano open5gs-ue1.yaml
```



```diff
# IMSI number of the UE. IMSI = [MCC|MNC|MSISDN] (In total 15 digits)
-supi: 'imsi-999700000000001'
+supi: 'imsi-001010000000001'
# Mobile Country Code value of HPLMN
-mcc: '999'
+mcc: '001'
# Mobile Network Code value of HPLMN (2 or 3 digits)
-mnc: '70'
+mnc: '01'

# Permanent subscription key
key: '465B5CE8B199B49FAA5F0A2EE238A6BC'
# Operator code (OP or OPC) of the UE
op: 'E8ED289DEBA952E4283B54E88E6183CA'
# This value specifies the OP type and it can be either 'OP' or 'OPC'
opType: 'OPC'
# Authentication Management Field (AMF) value
amf: '8000'
# IMEI number of the device. It is used if no SUPI is provided
imei: '356938035643803'
# IMEISV number of the device. It is used if no SUPI and IMEI is provided
imeiSv: '4370816125816151'

# List of gNB IP addresses for Radio Link Simulation
gnbSearchList:
-  - 127.0.0.1
+  - 10.0.2.1

# UAC Access Identities Configuration
uacAic:
  mps: false
  mcs: false

# UAC Access Control Class
uacAcc:
  normalClass: 0
  class11: false
  class12: false
  class13: false
  class14: false
  class15: false

# Initial PDU sessions to be established
sessions:
  - type: 'IPv4'
    apn: 'internet'
    slice:
      sst: 1

# Configured NSSAI for this UE by HPLMN
configured-nssai:
  - sst: 1

# Default Configured NSSAI for this UE
default-nssai:
  - sst: 1
    sd: 1

# Supported integrity algorithms by this UE
integrity:
  IA1: true
  IA2: true
  IA3: true

# Supported encryption algorithms by this UE
ciphering:
  EA1: true
  EA2: true
  EA3: true

# Integrity protection maximum data rate for user plane
integrityMaxRate:
  uplink: 'full'
  downlink: 'full'

```



#### Start using the UE - UERANSIM 

After completing configurations and setups, now you can start using UERANSIM.

Run the following command to start the UE:

```bash 
cd ..
./build/nr-ue -c config/open5gs-ue1.yaml
```





































































































































## Setup for Docker Container 



### Setup Mongodb 

* Create network 

```bash
docker network create \
  --subnet=192.168.120.0/24 \
  --opt com.docker.network.bridge.enable_icc=true \
  --opt com.docker.network.bridge.enable_ip_masquerade=true \
  5g_pq
```
* Start mongodb with a specific ip address 

```bash
docker run -d -p 27017:27017 --ip 192.168.120.2 --network=5g_pq --name=mongo-container mongo:latest
```

* Test the db access from a different docker. (Remember to install mongodb)

```bash
mongosh mongodb://192.168.120.2:27017
```

```output 
root@9c67cfbd7adc:/# mongosh mongodb://192.168.120.2:27017
Current Mongosh Log ID: 663b8e0f7f703a0f192202d7
Connecting to:          mongodb://192.168.120.2:27017/?directConnection=true&appName=mongosh+2.2.5
Using MongoDB:          7.0.9
Using Mongosh:          2.2.5

For mongosh info see: https://docs.mongodb.com/mongodb-shell/

------
   The server generated these startup warnings when booting
   2024-05-08T14:32:24.867+00:00: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem
   2024-05-08T14:32:25.633+00:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
   2024-05-08T14:32:25.637+00:00: You are running on a NUMA machine. We suggest launching mongod like this to avoid performance problems: numactl --interleave=all mongod [other options]
   2024-05-08T14:32:25.638+00:00: vm.max_map_count is too low
------

root@9c67cfbd7adc:/#
```


### Setup NRF docker


#### Set Up VPN over TLS

In this case the nrf will have the tls server

* Initiate the docker container 

```bash
docker run -dit --privileged --cap-add=NET_ADMIN --name nrf --ip 192.168.120.3 --network 5g_pq nrf:latest bash
```


docker run -dit --privileged --cap-add=NET_ADMIN --name nrf --ip 192.168.120.3 --network 5g_pq ubuntu-5g:1.1 bash



* Access the docker container 

```bash
docker exec -ti nrf bash
```


* Change directory to vpn_over_tls-master

```bash
cd ~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src/
```

* Modify the server config 

```bash
nano server/config.py
```

You can modify the TUN_ADDRESS if you want and certificates.

```diff
config = {
-        "TUN_ADDRESS": "192.168.120.177",
+        "TUN_ADDRESS": "10.0.0.1",        
        "TUN_NETMASK": "255.255.255.0",
-        "LISTEN_ADDRESS": "0.0.0.0",
+        "LISTEN_ADDRESS": "192.168.120.3",        
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
python3 server/server.py &
```

This will create an interface in your machine called tun0 which Ip address is 10.0.0.1.


#### Setup Open5GS NRF

* Modify the config file using a new terminal 

```bash
cd ~/5G_PQ/open5gs/
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



 
* OR you can modify all the configs using the command below

```bash
cd ~/5G_PQ/open5gs/
find install/etc/open5gs -type f -exec sed -i 's/127\.0\.1\.10/10\.0\.0\.2/g' {} +
find install/etc/open5gs -type f -exec sed -i 's/127\.0\.0\.10/10\.0\.0\.1/g' {} +
find install/etc/ -name "*.yaml" -exec sed -i 's/- ::1/# - ::1/g' {} +
```



* Start NRF

```bash
./install/bin/open5gs-nrfd &
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




























### Setup CP docker

#### Set Up VPN over TLS Server

In this case the CP VM will have a TLS client and a TLS server. The client will communicate with the NRF while the server will be designated for the UERANSIM gNB.


* Initiate the docker container 

```bash
docker run -dit --privileged --cap-add=NET_ADMIN --name cp --ip 192.168.120.4 --network 5g_pq ubuntu-5g:1.1 bash
```

* Access the docker container 

```bash
docker exec -ti cp bash
```

* Add more IP addresses that will be used for AMF,SMF,UPF, and Client and Server TLS

```bash
ip addr add 192.168.120.5/16 dev eth0
ip addr add 192.168.120.6/16 dev eth0
ip addr add 192.168.120.7/16 dev eth0
ip addr add 192.168.120.8/16 dev eth0
```

AMF IP: 192.168.120.4
SMF IP: 192.168.120.5
UPF IP: 192.168.120.6
TLS Client: 192.168.120.7
TLS Server: 192.168.120.8



```output
root@e3eaeed2d469:/# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
116: eth0@if117: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:ac:11:00:04 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.120.4/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet 192.168.120.5/16 scope global secondary eth0
       valid_lft forever preferred_lft forever
    inet 192.168.120.6/16 scope global secondary eth0
       valid_lft forever preferred_lft forever
    inet 192.168.120.7/16 scope global secondary eth0
       valid_lft forever preferred_lft forever
    inet 192.168.120.8/16 scope global secondary eth0
       valid_lft forever preferred_lft forever
root@e3eaeed2d469:/#
```






* Change directory to vpn_over_tls-master

```bash
cd ~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src/
```

* Modify the server config. In this case the Tunel Address has to be different. For this case, it will be 10.0.1.1

```bash
nano server/config.py
```

You can modify the TUN_ADDRESS if you want and certificates.

```diff
config = {
-        "TUN_ADDRESS": "192.168.120.177",
+        "TUN_ADDRESS": "10.0.1.1",        
        "TUN_NETMASK": "255.255.255.0",
-        "LISTEN_ADDRESS": "0.0.0.0",
+        "LISTEN_ADDRESS": "192.168.120.8",
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
python3 server/server.py &
```

This will create an interface in your machine called tun0 which Ip address is 10.0.1.1

**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 server/server.py &
[1] 34
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# net.ipv4.ip_forward = 1
```



#### Set Up VPN over TLS Client 




* Modify the client config. Match the Ip addresses based on your case. 


```bash
nano client/config.py
```

In this case:
192.168.64.9 is the NRF IP address 
192.168.64.8 is the CP Ip address
Modify accordingly


```diff
config = {
-        "SERVER_IP": "192.168.64.9",
+        "SERVER_IP": "192.168.120.3",      
        "SERVER_PORT": 443,
        "USERNAME": "dmitriy",
        "PASSWORD": "test",
        "TUN_NAME": "tun1",
        "SERVER_HOSTNAME": "strangebit.com",
        "CA_CERTIFICATE": "./certificates/certchain.pem",
        "BUFFER_SIZE": 1500,
-        "DEFAULT_GW": "192.168.64.9",
-        "DNS_SERVER": "192.168.64.8"
+        "DEFAULT_GW": "192.168.120.3",
+        "DNS_SERVER": "192.168.120.7"
}
```


* Start the TLS tunnel client 

```bash
python3 client/client.py &
```


**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 client/client.py &
[2] 40
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# Sending authentication data...
Authentication succeeded...
Got configuration packet...
Starting to read from TLS socket...
Starting to read from tun device....

```




#### Setup Open5GS CP Components

* Run the interface script to create the tunnel for the UPF

```bash
cd ~/5G_PQ
./interface.sh
```

**Run this after reboot**


* Modify the config file 

#### SCP

```bash
cd ~/5G_PQ/open5gs/
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


* OR you can modify all the configs using the command below

```bash
cd ~/5G_PQ/open5gs/
find install/etc/open5gs -type f -exec sed -i 's/127\.0\.1\.10/10\.0\.0\.2/g' {} +
find install/etc/open5gs -type f -exec sed -i 's/127\.0\.0\.10/10\.0\.0\.1/g' {} +
find install/etc/ -name "*.yaml" -exec sed -i 's/- ::1/# - ::1/g' {} +
```


* Run SCP

```bash
./install/bin/open5gs-scpd &
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
./install/bin/open5gs-amfd &
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
+      - addr: 192.168.120.5
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
+      - addr: 192.168.120.6



#.................

    scp:
    sbi:

-      - addr: 127.0.1.10
+      - addr: 10.0.0.2
        port: 7777

```









#### UPF

```bash
nano install/etc/open5gs/upf.yaml
```

**REPLACE 127.0.0.7 WITHT YOUR MACHINE IP ADDRESS**




```diff
upf:
    pfcp:
-      - addr: 127.0.0.7
+      - addr: 192.168.120.6
    gtpu:
-      - addr: 127.0.0.7
+      - addr: 192.168.120.6
    subnet:
      - addr: 10.45.0.1/16
      - addr: 2001:db8:cafe::1/48
    metrics:
      - addr: 127.0.0.7
        port: 9090
```


* Modify all the configs using the command below

```bash
cd ~/5G_PQ/open5gs/
find install/etc/open5gs -type f -exec sed -i 's/127\.0\.1\.10/10\.0\.0\.2/g' {} +
find install/etc/open5gs -type f -exec sed -i 's/127\.0\.0\.10/10\.0\.0\.1/g' {} +
grep -rl "db_uri: mongodb://localhost/open5gs" install/etc/open5gs | xargs sed -i 's/db_uri: mongodb:\/\/localhost\/open5gs/db_uri: mongodb:\/\/192.168.120.2\/open5gs/g'
find install/etc/ -name "*.yaml" -exec sed -i 's/- ::1/# - ::1/g' {} +

```


* Start all the other network functions 

```bash
./install/bin/open5gs-smfd &
./install/bin/open5gs-upfd &
./install/bin/open5gs-ausfd &
./install/bin/open5gs-udmd  & 
./install/bin/open5gs-pcfd & 
./install/bin/open5gs-nssfd &
./install/bin/open5gs-bsfd  &
./install/bin/open5gs-udrd  &
```


##### Add Subscriber 

* Access the database 

```bash
mongosh mongodb://192.168.120.2:27017
```

*  Change database

```bash
use open5gs 
```

* Insert subscriber. Make sure that matches the UE config 

```bash
db.subscribers.insertOne({
  imsi: '001010000000001',
  msisdn: [],
  imeisv: '4301816125816151',
  mme_host: [],
  mme_realm: [],
  purge_flag: [],
  security: {
    k: '465B5CE8 B199B49F AA5F0A2E E238A6BC',
    op: null,
    opc: 'E8ED289D EBA952E4 283B54E8 8E6183CA',
    amf: '8000',
    sqn: NumberLong("513")
  },
  ambr: { downlink: { value: 1, unit: 3 }, uplink: { value: 1, unit: 3 } },
  slice: [
    {
      sst: 1,
      default_indicator: true,
      session: [
        {
          name: 'internet',
          type: 3,
          qos: { index: 9, arp: { priority_level: 8, pre_emption_capability: 1, pre_emption_vulnerability: 1 } },
          ambr: { downlink: { value: 1, unit: 3 }, uplink: { value: 1, unit: 3 } },
          ue: { addr: '10.45.0.3' },
          _id: ObjectId("6473fd45a07e473e0b5334ce"),
          pcc_rule: []
        }
      ],
      _id: ObjectId("6473fd45a07e473e0b5334cd")
    }
  ],
  access_restriction_data: 32,
  subscriber_status: 0,
  network_access_mode: 0,
  subscribed_rau_tau_timer: 12,
  __v: 0
})
```

**OUTPUT**

```output 
{
  acknowledged: true,
  insertedId: ObjectId('663b9854fdf51515222202d8')
}

```




### Setup gNB docker 




#### Set Up VPN over TLS Server

In this case the gNB docker will have a TLS client and a TLS server. The client will communicate with the AMF while the server will be designated for the UERANSIM UE.


* Initiate the docker container 

```bash
docker run -dit --privileged --cap-add=NET_ADMIN --name gnb --ip 192.168.120.9 --network 5g_pq ubuntu-5g:1.1 bash
```

* Access the docker container 

```bash
docker exec -ti gnb bash
```


* Add more IP addresses that will be used for AMF,SMF,UPF, and Client and Server TLS

```bash
ip addr add 192.168.120.10/16 dev eth0
```

TLS Client: 192.168.120.9
TLS Server: 192.168.120.10




* Change directory to vpn_over_tls-master

```bash
cd ~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src/
```

* Start the TLS tunnel server

```bash
python3 server/server.py &
```

This will create an interface in your machine called tun0 which Ip address is 10.0.2.1


**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 server/server.py &
[1] 34
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# net.ipv4.ip_forward = 1
```



#### Start VPN over TLS Client 



* Start the TLS tunnel client 

```bash
python3 client/client.py &
```


**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 client/client.py &
[2] 40
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# Sending authentication data...
Authentication succeeded...
Got configuration packet...
Starting to read from TLS socket...
Starting to read from tun device....

```




### Start gNB UERANSIM

Run the following command to start the gNB:

```bash 
cd ~/5G_PQ/UERANSIM/
./build/nr-gnb -c config/open5gs-gnb1.yaml &
```

























### Setup UE docker 




#### Set Up VPN over TLS Client 

In this case the UE docker will have a TLS client  only. The client will communicate with the UERANSIM gNB.


* Initiate the docker container 

```bash
docker run -dit --privileged --cap-add=NET_ADMIN --name ue --ip 192.168.120.11 --network 5g_pq ubuntu-5g:1.1 bash
```

* Access the docker container 

```bash
docker exec -ti ue bash
```






* Change directory to vpn_over_tls-master

```bash
cd ~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src/
```



* Modify the client config. Match the Ip addresses based on your case. 


```bash
nano client/config.py
```

In this case:
192.168.64.9 is the gNB IP address 
192.168.64.8 is the UE Ip address
Modify accordingly


```diff
config = {
-        "SERVER_IP": "192.168.64.9",
+        "SERVER_IP": "192.168.120.8",      
        "SERVER_PORT": 443,
        "USERNAME": "dmitriy",
        "PASSWORD": "test",
        "TUN_NAME": "tun1",
        "SERVER_HOSTNAME": "strangebit.com",
        "CA_CERTIFICATE": "./certificates/certchain.pem",
        "BUFFER_SIZE": 1500,
-        "DEFAULT_GW": "192.168.64.9",
-        "DNS_SERVER": "192.168.64.8"
+        "DEFAULT_GW": "192.168.120.8",
+        "DNS_SERVER": "192.168.120.9"
}
```


* Start the TLS tunnel client 

```bash
python3 client/client.py &
```


**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 client/client.py &
[2] 40
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# Sending authentication data...
Authentication succeeded...
Got configuration packet...
Starting to read from TLS socket...
Starting to read from tun device....

```




### Setup UE UERANSIM

* Modify the config file 

#### UE

```bash
cd ~/5G_PQ/UERANSIM/config
 cp open5gs-ue.yaml open5gs-ue1.yaml
nano open5gs-ue1.yaml
```



```diff
# IMSI number of the UE. IMSI = [MCC|MNC|MSISDN] (In total 15 digits)
-supi: 'imsi-999700000000001'
+supi: 'imsi-001010000000001'
# Mobile Country Code value of HPLMN
-mcc: '999'
+mcc: '001'
# Mobile Network Code value of HPLMN (2 or 3 digits)
-mnc: '70'
+mnc: '01'

# Permanent subscription key
key: '465B5CE8B199B49FAA5F0A2EE238A6BC'
# Operator code (OP or OPC) of the UE
op: 'E8ED289DEBA952E4283B54E88E6183CA'
# This value specifies the OP type and it can be either 'OP' or 'OPC'
opType: 'OPC'
# Authentication Management Field (AMF) value
amf: '8000'
# IMEI number of the device. It is used if no SUPI is provided
imei: '356938035643803'
# IMEISV number of the device. It is used if no SUPI and IMEI is provided
imeiSv: '4370816125816151'

# List of gNB IP addresses for Radio Link Simulation
gnbSearchList:
-  - 127.0.0.1
+  - 10.0.2.1

# UAC Access Identities Configuration
uacAic:
  mps: false
  mcs: false

# UAC Access Control Class
uacAcc:
  normalClass: 0
  class11: false
  class12: false
  class13: false
  class14: false
  class15: false

# Initial PDU sessions to be established
sessions:
  - type: 'IPv4'
    apn: 'internet'
    slice:
      sst: 1

# Configured NSSAI for this UE by HPLMN
configured-nssai:
  - sst: 1

# Default Configured NSSAI for this UE
default-nssai:
  - sst: 1
    sd: 1

# Supported integrity algorithms by this UE
integrity:
  IA1: true
  IA2: true
  IA3: true

# Supported encryption algorithms by this UE
ciphering:
  EA1: true
  EA2: true
  EA3: true

# Integrity protection maximum data rate for user plane
integrityMaxRate:
  uplink: 'full'
  downlink: 'full'

```



#### Start using the UE - UERANSIM 

After completing configurations and setups, now you can start using UERANSIM.

Run the following command to start the UE:

```bash 
cd ~/5G_PQ/UERANSIM/
./build/nr-ue -c config/open5gs-ue1.yaml
```


**NO TLS (JUST IN CASE)**

```bash
find open5gs/install/etc/open5gs -type f -exec sed -i 's/10\.0\.0\.2/192\.168\.122\.97/g' {} +
find open5gs/install/etc/open5gs -type f -exec sed -i 's/10\.0\.0\.1/192\.168\.122\.238/g' {} +
```














































































































































































## Use Docker Containers 


### Setup Mongodb 

* Create network 

```bash
docker network create \
  --subnet=192.168.120.0/24 \
  --opt com.docker.network.bridge.enable_icc=true \
  --opt com.docker.network.bridge.enable_ip_masquerade=true \
  5g_pq
```
* Start mongodb with a specific ip address 

```bash
docker run -d -p 27017:27017 --ip 192.168.120.2 --network=5g_pq --name=mongo-container mongo:latest
```

* Test the db access from a different docker. (Remember to install mongodb)

```bash
mongosh mongodb://192.168.120.2:27017
```

```output 
root@9c67cfbd7adc:/# mongosh mongodb://192.168.120.2:27017
Current Mongosh Log ID: 663b8e0f7f703a0f192202d7
Connecting to:          mongodb://192.168.120.2:27017/?directConnection=true&appName=mongosh+2.2.5
Using MongoDB:          7.0.9
Using Mongosh:          2.2.5

For mongosh info see: https://docs.mongodb.com/mongodb-shell/

------
   The server generated these startup warnings when booting
   2024-05-08T14:32:24.867+00:00: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem
   2024-05-08T14:32:25.633+00:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
   2024-05-08T14:32:25.637+00:00: You are running on a NUMA machine. We suggest launching mongod like this to avoid performance problems: numactl --interleave=all mongod [other options]
   2024-05-08T14:32:25.638+00:00: vm.max_map_count is too low
------

root@9c67cfbd7adc:/#
```


### Start NRF docker


#### Start Up VPN over TLS

In this case the nrf will have the tls server

* Initiate the docker container 

```bash
docker run -dit --privileged --cap-add=NET_ADMIN --name nrf --ip 192.168.120.3 --network 5g_pq nrf:latest bash
```


* Access the docker container 

```bash
docker exec -ti nrf bash
```


* Change directory to vpn_over_tls-master

```bash
cd ~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src/
```


* Start the TLS tunnel server

```bash
python3 server/server.py &
```

This will create an interface in your machine called tun0 which Ip address is 10.0.0.1.


#### Start Open5GS NRF


* Start NRF

```bash
cd ~/5G_PQ/open5gs/
./install/bin/open5gs-nrfd &
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




























### Start CP docker

#### Start VPN over TLS Server

In this case the CP docker will have a TLS client and a TLS server. The client will communicate with the NRF while the server will be designated for the UERANSIM gNB.


* Initiate the docker container 

```bash
docker run -dit --privileged --cap-add=NET_ADMIN --name cp --ip 192.168.120.4 --network 5g_pq cp:latest bash
```

* Access the docker container 

```bash
docker exec -ti cp bash
```

* Add more IP addresses that will be used for AMF,SMF,UPF, and Client and Server TLS

```bash
ip addr add 192.168.120.5/16 dev eth0
ip addr add 192.168.120.6/16 dev eth0
ip addr add 192.168.120.7/16 dev eth0
ip addr add 192.168.120.8/16 dev eth0
```

AMF IP: 192.168.120.4
SMF IP: 192.168.120.5
UPF IP: 192.168.120.6
TLS Client: 192.168.120.7
TLS Server: 192.168.120.8



```output
root@e3eaeed2d469:/# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
116: eth0@if117: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:ac:11:00:04 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.120.4/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet 192.168.120.5/16 scope global secondary eth0
       valid_lft forever preferred_lft forever
    inet 192.168.120.6/16 scope global secondary eth0
       valid_lft forever preferred_lft forever
    inet 192.168.120.7/16 scope global secondary eth0
       valid_lft forever preferred_lft forever
    inet 192.168.120.8/16 scope global secondary eth0
       valid_lft forever preferred_lft forever
root@e3eaeed2d469:/#
```






* Change directory to vpn_over_tls-master

```bash
cd ~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src/
```

* Start the TLS tunnel server

```bash
python3 server/server.py &
```

This will create an interface in your machine called tun0 which Ip address is 10.0.1.1

**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 server/server.py &
[1] 34
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# net.ipv4.ip_forward = 1
```



#### Start VPN over TLS Client 


* Start the TLS tunnel client 

```bash
python3 client/client.py &
```


**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 client/client.py &
[2] 40
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# Sending authentication data...
Authentication succeeded...
Got configuration packet...
Starting to read from TLS socket...
Starting to read from tun device....

```

#### Start Open5GS CP Components

* Run the interface script to create the tunnel for the UPF

```bash
cd ~/5G_PQ
./interface.sh
```

**Run this after reboot**


* Start all the other network functions 

```bash
cd ~/5G_PQ/open5gs
./install/bin/open5gs-scpd &
./install/bin/open5gs-amfd &
./install/bin/open5gs-smfd &
./install/bin/open5gs-upfd &
./install/bin/open5gs-ausfd &
./install/bin/open5gs-udmd  & 
./install/bin/open5gs-pcfd & 
./install/bin/open5gs-nssfd &
./install/bin/open5gs-bsfd  &
./install/bin/open5gs-udrd  &
```


##### Add Subscriber 

* Access the database 

```bash
mongosh mongodb://192.168.120.2:27017
```

*  Change database

```bash
use open5gs 
```

* Insert subscriber. Make sure that matches the UE config 

```bash
db.subscribers.insertOne({
  imsi: '001010000000001',
  msisdn: [],
  imeisv: '4301816125816151',
  mme_host: [],
  mme_realm: [],
  purge_flag: [],
  security: {
    k: '465B5CE8 B199B49F AA5F0A2E E238A6BC',
    op: null,
    opc: 'E8ED289D EBA952E4 283B54E8 8E6183CA',
    amf: '8000',
    sqn: NumberLong("513")
  },
  ambr: { downlink: { value: 1, unit: 3 }, uplink: { value: 1, unit: 3 } },
  slice: [
    {
      sst: 1,
      default_indicator: true,
      session: [
        {
          name: 'internet',
          type: 3,
          qos: { index: 9, arp: { priority_level: 8, pre_emption_capability: 1, pre_emption_vulnerability: 1 } },
          ambr: { downlink: { value: 1, unit: 3 }, uplink: { value: 1, unit: 3 } },
          ue: { addr: '10.45.0.3' },
          _id: ObjectId("6473fd45a07e473e0b5334ce"),
          pcc_rule: []
        }
      ],
      _id: ObjectId("6473fd45a07e473e0b5334cd")
    }
  ],
  access_restriction_data: 32,
  subscriber_status: 0,
  network_access_mode: 0,
  subscribed_rau_tau_timer: 12,
  __v: 0
})
```

**OUTPUT**

```output 
{
  acknowledged: true,
  insertedId: ObjectId('663b9854fdf51515222202d8')
}

```




### Start gNB docker 




#### Start VPN over TLS Server

In this case the gNB docker will have a TLS client and a TLS server. The client will communicate with the AMF while the server will be designated for the UERANSIM UE.


* Initiate the docker container 

```bash
docker run -dit --privileged --cap-add=NET_ADMIN --name gnb --ip 192.168.120.9 --network 5g_pq gnb:latest bash
```

* Access the docker container 

```bash
docker exec -ti gnb bash
```


* Add more IP addresses that will be used for AMF,SMF,UPF, and Client and Server TLS

```bash
ip addr add 192.168.120.10/16 dev eth0
```

TLS Client: 192.168.120.9
TLS Server: 192.168.120.10




* Change directory to vpn_over_tls-master

```bash
cd ~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src/
```

* Modify the server config. In this case the Tunel Address has to be different. For this case, it will be 10.0.2.1

```bash
nano server/config.py
```

You can modify the TUN_ADDRESS if you want and certificates.

```diff
config = {
-        "TUN_ADDRESS": "192.168.120.177",
+        "TUN_ADDRESS": "10.0.2.1",        
        "TUN_NETMASK": "255.255.255.0",
-        "LISTEN_ADDRESS": "0.0.0.0",
+        "LISTEN_ADDRESS": "192.168.120.10",
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
python3 server/server.py &
```

This will create an interface in your machine called tun0 which Ip address is 10.0.2.1


**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 server/server.py &
[1] 34
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# net.ipv4.ip_forward = 1
```



#### Start VPN over TLS Client 

* Start the TLS tunnel client 

```bash
python3 client/client.py &
```


**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 client/client.py &
[2] 40
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# Sending authentication data...
Authentication succeeded...
Got configuration packet...
Starting to read from TLS socket...
Starting to read from tun device....

```




#### Start gNB UERANSIM

Run the following command to start the gNB:

```bash 
cd ~/5G_PQ/UERANSIM
./build/nr-gnb -c config/open5gs-gnb1.yaml &
```

























### Start UE docker 




#### Start VPN over TLS Client 

In this case the UE docker will have a TLS client  only. The client will communicate with the UERANSIM gNB.


* Initiate the docker container 

```bash
docker run -dit --privileged --cap-add=NET_ADMIN --name ue --ip 192.168.120.11 --network 5g_pq ue:latest bash
```

* Access the docker container 

```bash
docker exec -ti ue bash
```






* Change directory to vpn_over_tls-master

```bash
cd ~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src/
```


* Start the TLS tunnel client 

```bash
python3 client/client.py &
```


**Expected output**

```output
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# python3 client/client.py &
[2] 40
root@e3eaeed2d469:~/5G_PQ/vpn_over_tls-master/vpn_over_tls-master/src# Sending authentication data...
Authentication succeeded...
Got configuration packet...
Starting to read from TLS socket...
Starting to read from tun device....

```




#### Start UE UERANSIM


##### Start using the UE - UERANSIM 

After completing configurations and setups, now you can start using UERANSIM.

Run the following command to start the UE:

```bash 
cd ~/5G_PQ/UERANSIM
./build/nr-ue -c config/open5gs-ue1.yaml &
```


**NO TLS (JUST IN CASE)**

```bash
find open5gs/install/etc/open5gs -type f -exec sed -i 's/10\.0\.0\.2/192\.168\.122\.97/g' {} +
find open5gs/install/etc/open5gs -type f -exec sed -i 's/10\.0\.0\.1/192\.168\.122\.238/g' {} +
```
























































