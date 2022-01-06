#!/bin/bash

# STOP STACK
SCRIPT_DOWN_STACK="/totvs/scripts/down-stack.sh"
. "$SCRIPT_DOWN_STACK"

cd /etc/init.d

echo '[Start Lock Server]'
./totvslockserver start
sleep 5

echo '[Start License Server]'
./totvslicense start
sleep 2

echo '[Start DBAccess Server]'
./totvsdbaccess start
sleep 2

echo '[Start Slave01]'
./totvslave01 start