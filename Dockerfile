FROM ubuntu:16.04
RUN apt update
ENV DEBIAN_INTERFACE=noninteractive
RUN apt install -y privoxy polipo netcat tor haproxy nodejs npm gcc g++ make cmake autoconf automake autogen clang build-essential
RUN apt install -y curl libcurl4-openssl-dev libpcap-dev masscan nmap wget unzip tcpdump squid3 dnsutils net-tools apt-transport-tor 
RUN apt install -y apt-transport-https python python-dev python-pip python3 python3-dev python3-pip ruby ruby-dev golang ufw
RUN pip install awscli
RUN mkdir -p /app/proxy
WORKDIR /app/proxy
COPY . .
RUN npm install http-to-socks-proxy
