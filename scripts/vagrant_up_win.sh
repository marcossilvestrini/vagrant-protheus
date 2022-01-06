#!/bin/bash
cd ~/vagrant-protheus/windows
vagrant status
vagrant up
vagrant winrm protheus_app -c "Get-Service -name *dbaccess*|Start-Service;Get-Service -name *dbaccess*"
vagrant ssh protheus_app