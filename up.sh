#!/bin/sh

#brctl addbr br0
#brctl addif br0 eth0
#ip link set dev br0 up
#ifup br0
#bridge=br0
#brctl addif "$bridge" "$1"

# the tap interface name is passed as first argument
tap=$1
br="br0"
eth="eth0"
eth_ip="192.168.255.254"
eth_netmask="255.255.255.0"
eth_broadcast="192.168.255.255"

openvpn --mktun --dev $tap

brctl addbr $br
brctl addif $br $eth
brctl addif $br $tap

ifconfig $tap 0.0.0.0 promisc up

ifconfig $eth 0.0.0.0 promisc up

ifconfig $br $eth_ip netmask $eth_netmask broadcast $eth_broadcast