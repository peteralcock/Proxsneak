
## PROXSNEAK

For sneakier sneakerbots and stealthier stealth modes, this provides one single endpoint for clients. Supports **[HAProxy](http://www.haproxy.org/)**, **socks** protocol and **http-proxy** servers: **[polipo](https://www.irif.fr/~jch/software/polipo/)**, **[privoxy](https://www.privoxy.org/)** and **[hpts](https://github.com/oyyd/http-proxy-to-socks)**.

In addition, you can **view** previously running **TOR** processes and create a **new identity** for all or selected processes.


## Introduction

`multitor` was created with the aim of initialize many **TOR** processes as quickly as possible. I could use many instances for my daily use programs (web browsers, messangers and other). In addition, I was looking for a tool that would increase anonymity when conducting penetration tests and testing the security of infrastructure.

Before using the `multitor` you need to remember:

- **TOR** does attempt to generate a bunch of streams for you already. From this perspective, it is already load balancing (and it's much smarter at it than **HAproxy**)
- the main goal is masking from where we get by sending requests to multiple streams. It is not so easy to locate where an attacker comes from. If you used http/https servers e.g. proxy servers, you will know what is going on but...
- using multiple **TOR** instances can increase the probability of using a compromised circuit
- `multitor` getting some bandwidth improvements just because it's a different way of connecting to **TOR** network
- in `multitor` configuration mostly **HAProxy** checks the local (syn, syn/ack) socket - not all **TOR** nodes (also exist nodes). If there is a problem with the socket it tries to send traffic to others available without touching what's next - it does not ensure that the data will arrive
- **TOR** network is a separate organism on which the `multitor` has no effect If one of the nodes is damaged and somehow the data can not leave the exit node, it is likely that a connection error will be returned or, at best, the data will be transferred through another local socket
- **HAProxy** load balance network traffic between local **TOR** or **http-proxy** processes - not nodes inside **TOR** network

> **TOR** is a fine security project and an excellent component in a strategy of defence in depth but it isn’t (sadly) a cloak of invisibility. When using the **TOR**, always remember about ssl (e.g. https) wherever it is possible.

Look also at **[Limitations](#limitations)**.

## How To Use

> :heavy_exclamation_mark: For a more detailed understanding of `multitor`, its parameters, functions and how it all works, see the **[Manual](https://github.com/trimstray/multitor/wiki/Manual)**.

It's simple:

```bash
# Clone this repository
git clone https://github.com/trimstray/multitor

# Go into the repository
cd multitor

# Install
./setup.sh install

# Run the app
multitor --init 2 --user debian-tor --socks-port 9000 --control-port 9900 --proxy privoxy --haproxy
```

> * symlink to `bin/multitor` is placed in `/usr/local/bin`
> * man page is placed in `/usr/local/man/man8`

## Parameters

Provides the following options:

```bash
  Usage:
    multitor <option|long-option>

  Examples:
    multitor --init 2 --user debian-tor --socks-port 9000 --control-port 9900
    multitor --init 10 --user debian-tor --socks-port 9000 --control-port 9900 --proxy socks
    multitor --show-id --socks-port 9000

  Options:
        --help                        show this message
        --debug                       displays information on the screen (debug mode)
        --verbose                     displays more information about TOR processes
    -i, --init <num>                  init new tor processes
    -k, --kill                        kill all multitor processes
    -s, --show-id                     show specific tor process id
    -n, --new-id                      regenerate tor circuit
    -u, --user <string>               set the user (only with -i|--init)
        --socks-port <port_num|all>   set socks port number
        --control-port <port_num>     set control port number
        --proxy <proxy_type>          set socks or http (polipo, privoxy, hpts) proxy server
        --haproxy                     set HAProxy as a frontend for http proxies (only with --proxy)
```

## Requirements

`multitor` uses external utilities to be installed before running:

- [tor](https://www.torproject.org/)
- [netcat](http://netcat.sourceforge.net/)
- [haproxy](https://www.haproxy.org/)
- [polipo](https://www.irif.fr/~jch/software/polipo/)
- [privoxy](https://www.privoxy.org/)
- [http-proxy-to-socks](https://github.com/peteralcock/proxsneak)

This tool working with:

- **GNU/Linux** (testing on Debian and CentOS)
- **[Bash](https://www.gnu.org/software/bash/)** (testing on 4.4.19)
- each **TOR**, **http-proxy** and **HAProxy** processes needs a certain number of memory. If the number of **TOR** processes is too big, the oldest one will be automatically killed by the system
- **Polipo** is no longer supported but it is still a very good and light proxy. In my opinion the best http-proxy solution is **Privoxy**
- I think this topic will be usefull for You before using `multitor` - [How to run multiple Tor processes at once with different exit IPs?](https://stackoverflow.com/questions/14321214/how-to-run-multiple-tor-processes-at-once-with-different-exit-ips)


Tested on **Ubuntu 18.04 Docker container**. The Dockerfile is a single line `FROM ubuntu:18.04`. Alternatively, you can simply run `docker run -it ubuntu:18.04 bash`.

NOTE: stopping services didn't work for me for some reason. That's why there is `kill $(pidof <service name>)` after each failed `service <service name> stop` to kill it.


## Steps

### 1. Install and check Tor status
```console
root@75f6721089f2:/# apt update
root@75f6721089f2:/# apt install -y tor
root@75f6721089f2:/# tor --version
Tor version 0.3.2.10 (git-0edaa32732ec8930).
root@75f6721089f2:/# service tor status
 * cannot read PID file /var/run/tor/tor.pid
 ```

### 2. Start Tor and check it's running
```console
root@75f6721089f2:/# service tor start
 * Starting tor daemon...          [ OK ] 
root@75f6721089f2:/# service tor status
 * tor is running
```

### 3. Try to Authenticate with nc (Netcat)
It's not possible to connect as `ControlPort` is not set yet.
```console
root@75f6721089f2:/# apt install -y netcat
root@75f6721089f2:/# echo -e 'AUTHENTICATE' | nc 127.0.0.1 9051
(UNKNOWN) [127.0.0.1] 9051 (?) : Connection refused
```

### 4. Stop/kill Tor, set ControlPort and start Tor again
```console
root@75f6721089f2:/# service tor stop
 * Stopping tor daemon...          [fail]
root@75f6721089f2:/#  kill $(pidof tor)
root@75f6721089f2:/# service tor status
 * tor is not running
root@75f6721089f2:/# echo "ControlPort 9051" >> /etc/tor/torrc
root@75f6721089f2:/# service tor start 
 * Starting tor daemon...          [ OK ] 
```

### 5. Try to Authenticate with nc again
It's possible to connect but Authentication fails.
```console
root@75f6721089f2:/# echo -e 'AUTHENTICATE' | nc 127.0.0.1 9051
515 Authentication failed: Wrong length on authentication cookie.
```

### 6. Stop/kill Tor, set and check `HashedControlPassword` then start Tor again

Make sure that you have something like `HashedControlPassword 16:ED2893D8EC97801C60DF4A72249CBCCD8B97B3B01A15C923DC49A0E500` (actual password hash can/will differ) in `/etc/tor/torrc`.
```console
root@75f6721089f2:/# service tor stop
 * Stopping tor daemon...          [fail]
root@75f6721089f2:/# kill $(pidof tor)
root@75f6721089f2:/# echo HashedControlPassword $(tor --hash-password "my password" | tail -n 1) >> /etc/tor/torrc
root@75f6721089f2:/# tail -n 2 /etc/tor/torrc
ControlPort 9051
HashedControlPassword 16:ED2893D8EC97801C60DF4A72249CBCCD8B97B3B01A15C923DC49A0E500
root@75f6721089f2:/# service tor start 
 * Starting tor daemon...          [ OK ] 
```

### 7. Try to Authenticate with nc again
Authentication passes with a correct password.
```console
# NOTE Use Ctrl+C to exit.
root@75f6721089f2:/# echo -e 'AUTHENTICATE' | nc 127.0.0.1 9051
515 Authentication failed: Password did not match HashedControlPassword *or* authentication cookie.
root@75f6721089f2:/# echo -e 'AUTHENTICATE "my password"' | nc 127.0.0.1 9051
250 OK
```

### 8. Check your public IP and currently used Tor ip
```console
root@75f6721089f2:/# apt install -y curl
root@75f6721089f2:/# curl http://icanhazip.com/
89.196.159.79
root@75f6721089f2:/# torify curl http://icanhazip.com/
185.220.101.17
```

### 9. Change and check Tor IP
```console
root@75f6721089f2:/# echo -e 'AUTHENTICATE "my password"\r\nsignal NEWNYM\r\nQUIT' | nc 127.0.0.1 9051
250 OK
250 OK
250 closing connection
root@75f6721089f2:/# torify curl http://icanhazip.com/
185.220.101.6
```

### 10. Change (with Python3) and check Tor IP
```console
root@75f6721089f2:/# apt install -y python3 python3-pip
root@75f6721089f2:/# python3 --version
Python 3.6.9
root@75f6721089f2:/# pip3 --version
pip 9.0.1 from /usr/lib/python3/dist-packages (python 3.6)
root@75f6721089f2:/# pip3 install stem==1.8.0
root@75f6721089f2:/# python3
```
```python
>>> from stem import Signal
>>> from stem.control import Controller
>>> 
>>> with Controller.from_port(port=9051) as controller:
...     controller.authenticate()
...     controller.signal(Signal.NEWNYM)
... 
>>> 
```
```console
root@75f6721089f2:/# torify curl http://icanhazip.com/
185.107.81.233
```

### 11. Install privoxy and check traffic is routed through Tor
Now that it's clear Tor is configured and works properly we can include `privoxy` to the loop.
```console
root@75f6721089f2:/# apt install -y privoxy
root@75f6721089f2:/# privoxy --version
Privoxy version 3.0.26 (https://www.privoxy.org/)
root@75f6721089f2:/# service privoxy status
 * privoxy is not running
root@75f6721089f2:/# echo "forward-socks5t / 127.0.0.1:9050 ." >> /etc/privoxy/config
root@75f6721089f2:/# service privoxy start
 * Starting filtering proxy server privoxy          [ fail ]
```

Privoxy is unable to start, let's inspect logs.
```console
root@ff788ea93ee0:/# cat /var/log/privoxy/logfile
2019-07-21 09:16:58.278 7f9c2c0e30c0 Fatal error: can't bind to ::1:8118: No such file or directory
```

The message means privoxy cannot use `IPv6`. Let's disable listening on an IPv6 address by commenting out the setting.
```console
root@ff788ea93ee0:/# sed -i "s/.*\[::1\]:8118/# &/" /etc/privoxy/config
```

Now we should be able to start and use privoxy
```console
root@75f6721089f2:/# service privoxy start
 * Starting filtering proxy server privoxy          [ OK ]
root@75f6721089f2:/# torify curl http://icanhazip.com/
176.10.99.200
root@75f6721089f2:/# curl -x 127.0.0.1:8118 http://icanhazip.com/
176.10.99.200
```

### 12. Change and check Tor IP with Python3
```console
root@75f6721089f2:/# pip3 install requests==2.26.0
root@75f6721089f2:/# python3
```
```python
>>> import requests
>>>
>>> from stem import Signal
>>> from stem.control import Controller
>>>
>>> response = requests.get('http://icanhazip.com/', proxies={'http': '127.0.0.1:8118'})
>>> response.text.strip()
'137.74.171.94'
>>> 
>>> with Controller.from_port(port=9051) as controller:
...     controller.authenticate(password='my password')
...     controller.signal(Signal.NEWNYM)
... 
>>> response = requests.get('http://icanhazip.com/', proxies={'http': '127.0.0.1:8118'})
>>> response.text.strip()
'87.118.92.43'
>>>
>>> response = requests.get('https://api.myip.com/', proxies={'https': '127.0.0.1:8118'})
>>> response.json()
{"ip": "87.118.92.43", "country": "Germany", "cc": "DE"}
>>> 
```


### 13. [bonus] Change and check Tor IP with [TorIpChanger](https://github.com/DusanMadar/TorIpChanger)
```console
root@75f6721089f2:/# pip3 install toripchanger==1.1.3
root@75f6721089f2:/# python3
```
```python
>>> from toripchanger import TorIpChanger
>>> 
>>> tor_ip_changer = TorIpChanger(tor_password='my password', tor_port=9051, local_http_proxy='127.0.0.1:8118')
>>> tor_ip_changer.get_new_ip()
'185.24.218.182'
>>> 
```
