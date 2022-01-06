#!/bin/bash
cd /etc/init.d

echo '[status Lock Server]'
./totvslockserver status

echo '[status License Server]'
./totvslicense status

echo '[status DBAccess Server]'
./totvsdbaccess status

# echo '[status Broker Server]'
# cd /totvs/bin/appserver/broker
# ./app_broker -balance_smart_client_desktop -q

cd /etc/init.d

echo '[status Slave01]'
./totvslave01 status

echo '[status Slave02]'
./totvslave02 status

echo '[status Soap]'
./totvssoap status

echo '[status Rest]'
./totvsrest status
