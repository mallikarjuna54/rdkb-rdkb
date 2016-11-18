#!/bin/sh

sleep 20

########## Creating Interface and Waiting for interface to be up ####################
brctl addbr brlan0

############# Restoring DHCPv4 default values #######################
ROUTER=`cat /etc/udhcpd.conf | grep router | cut -d ' ' -f3`
SUBNETMASK=`cat /etc/udhcpd.conf | grep subnet | cut -d ' ' -f3`                                            
psmcli nosubsys set dmsb.dhcpv4.server.pool.0.IPRouters $ROUTER                                             
psmcli nosubsys set dmsb.dhcpv4.server.pool.0.SubnetMask $SUBNETMASK

WAN_IP=`route -n | grep UG | tr -s ' ' | cut -d ' ' -f2`
route del default gw $WAN_IP
route add default gw $WAN_IP eth0

count=`ifconfig | grep brlan0 | wc -l`
echo "brlan-count=$count"

sleep 5
count=`ifconfig | grep brlan0 | wc -l`
echo "brlan-count=$count"

if [ $count != 0 ];then
echo "brlan0 interface exists"
fi


count=`ifconfig | grep eth2 | wc -l`
echo "eth2-count=$count"

sleep 5
count=`ifconfig | grep eth2 | wc -l`

if [ $count != 0 ];then
echo "eth2 interface exists"
#ifconfig eth2 192.168.56.101 up
fi


count=`ifconfig | grep eth1 | wc -l`
echo "eth1count=$count"

sleep 5
count=`ifconfig | grep eth1 | wc -l`

if [ $count != 0 ];then
echo "eth1 interface exists"
##### Add Wired Interface to Bridge interface ##############################
#ifconfig eth1 192.168.1.115 up
brctl addif brlan0 eth1
fi

wifi=`ifconfig | grep wlan0 | wc -l`
echo "wlan0count=$wifi"

sleep 5
wifi=`ifconfig | grep wlan0 | wc -l`

if [ $wifi != 0 ];then
echo "wlan0 interface exists"
######### Add Wireless interface to Bridge interface ######################
#ifconfig wlan0 192.168.1.120 up
iw dev wlan0 set 4addr on
brctl addif brlan0 wlan0
fi

if [ $count ] || [ $wifi ];then
########### Set ip Address for Bridge interface for udhcpd server##########
INTERFACE=brlan0
DEFAULT_IP_ADDRESS=192.168.7.1
udhcpd_conf_file=/etc/udhcpd.conf
KEYWORD=router
#############################################################
#Set ipaddress for brlan0 interface
#############################################################


if [  -f $udhcpd_conf_file ];then
 echo "getting router ip address from $udhcpd_conf_file"
 router_ip_address=`grep $KEYWORD $udhcpd_conf_file | cut -d ' ' -f 3`
 echo "set ip address as $router_ip_address for $INTERFACE"
 ifconfig $INTERFACE $router_ip_address
else
 echo "set ip address as default $DEFAULT_IP_ADDRESS for $INTERFACE"
  ifconfig $INTERFACE $DEFAULT_IP_ADDRESS
fi

rm -f wifi_clients.txt

fi
###### Routing Table ##################################################### 
sh /lib/rdk/webgui.sh

################### Getting wlan0_0 mac Address(public wifi) #############
sh /lib/rdk/Getting_wlan0_0_mac.sh

############################ iptables-restore ########################     
#iptables-restore < /etc/iptables/rules.v4

