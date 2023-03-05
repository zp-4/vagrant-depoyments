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

config_named_forward_zone(){
echo -en """zone \"my-lab.local\" IN { 
    
      type master; // Primary DNS : master

     file \"/etc/bind/forward.my-lab.local\";

     allow-update { none; }; // Primary DNS set : \"none\" ;

};""" > /etc/bind/named.conf.local
}

config_named_reverse_zone(){
echo -en """zone \"56.168.192.in-addr.arpa\" IN { 
     type master; // Primary DNS : master

     file \"/etc/bind/reverse.my-lab.local\"; 

     allow-update { none; }; //Primary DNS set : \"none;\" ;
};""" >> /etc/bind/named.conf.local
}

Config_forward_lookup_file(){
echo -en """\$TTL	604800
@	IN	SOA	ns1.my-lab.local. root.my-lab.local. (
			3		; Serial
			604800		; Refresh
			86400		; Retry
			2419200	; Expire
			604800 )	; Negative Cache TTL
;--- Name Server Information

@	IN	NS	ns1.my-lab.local.

;--- IP address of Name Server

ns1	IN	A	192.168.56.199

;--- Mail Exchanger ( if exists )

;my-lab.local.	IN	MX 10	mail1.my-lab.local.

;--- A - Record HostName To Ip Address

;test	IN	A	192.168.56.101
;mail1	IN	A	192.168.56.102

;--- CNAME record

;www	IN	CNAME 	test.my-lab.local.
;ftp	IN	CNAME	test.my-lab.local.

""" > /etc/bind/forward.my-lab.local

}

Config_reverse_lookup_file(){
echo -en """\$TTL	604800
@	IN	SOA	my-lab.local. root.my-lab.local. (
			3	; Serial
			604800	; Refresh
			86400	; Retry
			2419200 ; Expire
			604800 ); Negative Cache TTL
;---Name Server Information

@	IN	NS	ns1.my-lab.local.

;---Reverse lookup for Name Server

199	IN	PTR	ns1.my-lab.local.

;---PTR Record IP address to HostName

;101	IN	PTR	test.my-lab.local.
;102	IN	PTR	mail1.my-lab.local.""" > /etc/bind/reverse.my-lab.local
}

config_resolv(){

echo """nameserver 192.168.56.199""" > /etc/resolv.conf
}

Config_dns(){
  config_named_forward_zone
  config_named_reverse_zone
  Config_forward_lookup_file
  Config_reverse_lookup_file
  config_resolv
  sudo systemctl restart bind9
}


main() {
  apt_install_prerequisites
  change_hosts
  Config_dns
}

# Allow custom modes via CLI args
if [ -n "$1" ]; then
  eval "$1"
else
  main
fi
exit 0
