##########################################################################
# If not stated otherwise in this file or this component's Licenses.txt
# file the following copyright and licenses apply:
#
# Copyright 2017 RDK Management
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

#!/bin/sh

BINPATH="/usr/bin"
GET="dmcli simu getv"
SET=""

#PARODUS_IP=`grep "ARM_INTERFACE_IP" /etc/device.properties | cut -f 2 -d"="`
#export PARODUS_SERVICE_URL=tcp://$PARODUS_IP:6666

#echo "PARODUS_SERVICE_URL="$PARODUS_SERVICE_URL

echo "Check parodusCmd.cmd in /tmp"

if [ -e /tmp/parodusCmd.cmd ]; then
 #echo "[`getDateTime`] parodusCmd.cmd exists in tmp"
 parodusCmd=`cat /tmp/parodusCmd.cmd`
 #start parodus
 $parodusCmd &
else
 echo "parodusCmd.cmd does not exist in tmp"
 echo "Fetching PAM Health status "

  while [ 1 ]
  do
     pamState=`$GET com.cisco.spvtg.ccsp.pam.Health | grep value| tr -s ' ' |cut -f5 -d" "`
     if [ "$pamState" = "Green" ]; then
          break
     else
        echo "Waiting for PAM to come up"
     fi
     sleep 10
  done

  echo "Fetching CMAgent Health status "


  echo "Fetching values to form parodus command line arguments"

  ModelName=`$GET Device.DeviceInfo.ModelName | grep value| tr -s ' ' |cut -f5 -d" "`
  SerialNumber=`$GET Device.DeviceInfo.SerialNumber | grep value| tr -s ' ' |cut -f5 -d" "`
  Manufacturer=`$GET Device.DeviceInfo.Manufacturer | grep value| tr -s ' ' |cut -f5 -d" "`
  HW_MAC=`$GET Device.X_CISCO_COM_CableModem.MACAddress | grep value| tr -s ' ' |cut -f5 -d" "`
  HW_MAC=`ifconfig eth0 | grep HWaddr | tr -s ' ' | cut -d ' ' -f5`
  LastRebootReason=`$GET Device.DeviceInfo.X_RDKCENTRAL-COM_LastRebootReason | grep value| tr -s ' ' |cut -f5 -d" "`
  FirmwareName=`$GET Device.DeviceInfo.X_CISCO_COM_FirmwareName | grep value| tr -s ' ' |cut -f5 -d" "`
  BootTime=`$GET Device.DeviceInfo.X_RDKCENTRAL-COM_BootTime | grep value| tr -s ' ' |cut -f5 -d" "`
  MaxPingWaitTimeInSec=180;
  DeviceNetworkInterface=eth0;
  ServerURL=fabric.webpa.comcast.net;
  BackOffMax=9;

  echo "Framing command for parodus"

  command="/usr/bin/parodus --hw-model=$ModelName --hw-serial-number=$SerialNumber --hw-manufacturer=$Manufacturer --hw-mac=$HW_MAC --hw-last-reboot-reason=$LastRebootReason --fw-name=$FirmwareName --boot-time=$BootTime --webpa-ping-time=$MaxPingWaitTimeInSec --webpa-inteface-used=$DeviceNetworkInterface --webpa-url=$ServerURL --webpa-backoff-max=$BackOffMax"

  echo $command >/tmp/parodusCmd.cmd

  echo "Starting parodus with the following arguments"
  echo "ModelName=$ModelName  SerialNumber=$SerialNumber  Manufacturer=$Manufacturer  HW_MAC=$HW_MAC  LastRebootReason=$LastRebootReason  FirmwareName=$FirmwareName  BootTime=$BootTime  MaxPingWaitTimeInSec=$MaxPingWaitTimeInSec   DeviceNetworkInterface=$DeviceNetworkInterface  ServerURL=$ServerURL BackOffMax=$BackOffMax"

  $command &
fi