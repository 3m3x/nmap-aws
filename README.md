# Intro
Example:

**$ ./aws-nmap -v -A --top-port 100 -Pn webscantest.com**
```bash
Running in Lambda: nmap -v -A --top-port 100 -Pn webscantest.com

Starting Nmap 7.60 ( https://nmap.org ) at 2019-09-18 08:00 UTC
NSE: Failed to load '/var/task/scripts/http-favicon.nse'.
NSE: Failed to load '/var/task/scripts/ipv6-node-info.nse'.
NSE: Failed to load '/var/task/scripts/iscsi-info.nse'.
NSE: Failed to load '/var/task/scripts/mongodb-databases.nse'.
NSE: Failed to load '/var/task/scripts/mongodb-info.nse'.
NSE: Failed to load '/var/task/scripts/sip-methods.nse'.
NSE: Failed to load '/var/task/scripts/ssh-hostkey.nse'.
NSE: Loaded 139 scripts for scanning.
NSE: Script Pre-scanning.
Initiating NSE at 08:00
Completed NSE at 08:00, 0.00s elapsed
Initiating NSE at 08:00
Completed NSE at 08:00, 0.00s elapsed
Initiating Parallel DNS resolution of 1 host. at 08:00
Completed Parallel DNS resolution of 1 host. at 08:00, 0.04s elapsed
Initiating Connect Scan at 08:00
Scanning webscantest.com (69.164.223.208) [100 ports]
Discovered open port 80/tcp on 69.164.223.208
Discovered open port 443/tcp on 69.164.223.208
Discovered open port 8081/tcp on 69.164.223.208
Completed Connect Scan at 08:00, 1.21s elapsed (100 total ports)
Initiating Service scan at 08:00
Scanning 3 services on webscantest.com (69.164.223.208)
Completed Service scan at 08:00, 6.48s elapsed (3 services on 1 host)
NSE: Script scanning 69.164.223.208.
Initiating NSE at 08:00
Completed NSE at 08:01, 1.60s elapsed
Initiating NSE at 08:01
Completed NSE at 08:01, 0.00s elapsed
Nmap scan report for webscantest.com (69.164.223.208)
Host is up (0.019s latency).
rDNS record for 69.164.223.208: nb-69-164-223-208.newark.nodebalancer.linode.com
Not shown: 96 closed ports
PORT     STATE    SERVICE VERSION
25/tcp   filtered smtp
80/tcp   open     http    Apache httpd 2.4.7 ((Ubuntu))
| http-cookie-flags:
|   /:
|     TEST_SESSIONID:
|_      httponly flag not set
| http-methods:
|_  Supported Methods: GET HEAD POST OPTIONS
| http-robots.txt: 4 disallowed entries
|_/osrun/* /cal_endar/* /crawlsnags/* /static/*
|_http-server-header: Apache/2.4.7 (Ubuntu)
|_http-title: Test Site
443/tcp  open     ssl
|_ssl-date: TLS randomness does not represent time
8081/tcp open     http    Node.js Express framework
|_hadoop-datanode-info:
|_hadoop-jobtracker-info:
|_hadoop-tasktracker-info:
|_hbase-master-info:
| http-methods:
|_  Supported Methods: GET HEAD POST OPTIONS
|_http-title: Webscantest React v15

NSE: Script Post-scanning.
Initiating NSE at 08:01
Completed NSE at 08:01, 0.00s elapsed
Initiating NSE at 08:01
Completed NSE at 08:01, 0.00s elapsed
Read data files from: /var/task
Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 16.06 seconds
```


# Runtime
Nmap depends on a number of libraries not found in the Python Lambda runtime:

```
error while loading shared libraries: libpcre.so.3: cannot open shared object file: No such file or directory
error while loading shared libraries: libpcap.so.0.8: cannot open shared object file: No such file or directory
error while loading shared libraries: libssl.so.1.1: cannot open shared object file: No such file or directory
error while loading shared libraries: libcrypto.so.1.1: cannot open shared object file: No such file or directory
error while loading shared libraries: liblua5.3.so.0: cannot open shared object file: No such file or directory
/lib64/libc.so.6: version `GLIBC_2.25' not found (required by /var/task/lib/libcrypto.so.1.1)
```

Unfortunately, all but the last were able to be successfully loaded in the Lambda runtime. We can't use custom AMIs
for our lambda to get that pesky libc `.so` file into `/lib64` (the filesystem is read-only) so we just upload a statically
compiled nmap binary and call it a day. 

## Static nmap
To compile nmap statically the easiest route is to follow the instructions at https://github.com/andrew-d/static-binaries.git . I omitted including OpenSSL because compilation failed when including it and I just wanted to get a PoC going. The repeated failures to load .nse upon running nmap may very well [be explained](https://subscription.packtpub.com/book/networking_and_servers/9781849517485/1/ch01lvl1sec10/compiling-nmap-from-source-code) by the lack of OpenSSL support:

> Enabling it allows Nmap to access the functions of this library related to multiprecision integers, hashing, and encoding/decoding for service detection and Nmap NSE scripts.
