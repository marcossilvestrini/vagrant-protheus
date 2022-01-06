#!/bin/bash
cd /etc/init.d

echo 'stop License Server'
./totvslicense stop

echo 'stop DBAccess Server'
./totvsdbaccess stop

echo 'stop Broker Server'
cd /totvs/bin/appserver/broker
./app_broker -balance_smart_client_desktop -o

cd /etc/init.d

echo 'stop Slave01'
./totvslave01 stop

echo 'stop Slave02'
./totvslave02 stop

echo 'stop Soap'
./totvssoap stop

echo 'stop Rest'
./totvsrest stop

echo 'stop Lock Server'
./totvslockserver stop
