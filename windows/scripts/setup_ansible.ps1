# Setup Ansible
choco feature disable -n=showDownloadProgress
choco install python -y
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\\ConfigureRemotingForAnsible.ps1"
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file