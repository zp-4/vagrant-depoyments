#! /usr/bin/env bash
# shellcheck disable=SC1091,SC2129

# This is the script that is used to provision the P-DNS server host

export DEBIAN_FRONTEND=noninteractive
echo "apt-fast apt-fast/maxdownloads string 10" | debconf-set-selections
echo "apt-fast apt-fast/dlflag boolean true" | debconf-set-selections

apt_install_prerequisites() {
  echo "[$(date +%H:%M:%S)]: Adding apt repositories..."
  # Add repository for apt-fast
  add-apt-repository -y -n ppa:apt-fast/stable 
  echo "[$(date +%H:%M:%S)]: Running apt-get clean..."
  apt-get clean
  echo "[$(date +%H:%M:%S)]: Running apt-get update..."
  apt-get -qq update
  #echo "[$(date +%H:%M:%S)]: Running apt-get upgrade..."
  #apt-get -qq upgrade
  echo "[$(date +%H:%M:%S)]: Installing apt-fast..."
  apt-get -qq install -y apt-fast
  echo "[$(date +%H:%M:%S)]: Using apt-fast to install packages..."
  apt-fast install -y whois build-essential git htop net-tools bind9 bind9utils bind9-doc dnsutils

}

change_hosts(){
  echo """127.0.0.1	ns1.my-lab.local	ns1
127.0.1.1	ns1

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters""" > /etc/hosts
}

main() {
  apt_install_prerequisites
  change_hosts
}

# Allow custom modes via CLI args
if [ -n "$1" ]; then
  eval "$1"
else
  main
fi
exit 0
