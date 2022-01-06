# Variables
$vmrun = "E:\VMWare\vmrun.exe"
$vmware = "E:\VMware\vmware.exe"
$vm = "E:\Servers\Linux\vagrant-ansible\vagrant-ansible.vmx"

# Close SHH connectio
Write-Host "Kill SSH Connections" -BackgroundColor White -ForegroundColor Black
Get-Process -name putty -ErrorAction SilentlyContinue |
Stop-Process -ErrorAction SilentlyContinue >$null

# Power Off Virtual Machine
Write-Host "Power Off Virtual Machine: [$($vm)]" -BackgroundColor White -ForegroundColor Black
& $vmrun stop $vm >$null

# Down vmware if Running
Write-Host "Down Vmware Workstation in path: [$($vmware)]" -BackgroundColor White -ForegroundColor Black
Get-Process -name vmware -ErrorAction SilentlyContinue |
Stop-Process -ErrorAction SilentlyContinue >$null
Get-Process -name vmware-vmx -ErrorAction SilentlyContinue |
Stop-Process -ErrorAction SilentlyContinue >$null

# Close VScode
Get-Process -name code | Stop-Process -Force