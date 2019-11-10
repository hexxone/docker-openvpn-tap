#!/bin/sh

# the tap interface name is passed as first argument
tap=$1
br="br0"
eth="eth0"
eth_ip="172.17.0.6"
eth_netmask="255.255.0.0"
eth_broadcast="172.17.255.255"
eth_gateway="172.17.0.1"

#openvpn --mktun --dev $tap

brctl addbr $br
brctl addif $br $eth
brctl addif $br $tap

ifconfig $tap 0.0.0.0 promisc up

iptables -A INPUT -i $tap -j ACCEPT
iptables -A INPUT -i $br -j ACCEPT
iptables -A FORWARD -i $br -j ACCEPT

ifconfig $eth 0.0.0.0 promisc up

ifconfig $br $eth_ip netmask $eth_netmask broadcast $eth_broadcast

route add default gw $eth_gateway $br