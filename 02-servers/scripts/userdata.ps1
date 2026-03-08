<powershell>
$ErrorActionPreference = 'Stop'
$ProgressPreference   = 'SilentlyContinue'

$Log = 'C:\ProgramData\userdata.log'
New-Item -Path $Log -ItemType File -Force | Out-Null
Start-Transcript -Path $Log -Append -Force

try {

Write-Output "Starting user-data at $(Get-Date -Format o)"

Write-Output "Installing AD management features"
Install-WindowsFeature -Name GPMC,RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-DNS-Server

Write-Output "Downloading AWS CLI"
Invoke-WebRequest https://awscli.amazonaws.com/AWSCLIV2.msi -OutFile C:\Users\Administrator\AWSCLIV2.msi

Write-Output "Installing AWS CLI"
Start-Process "msiexec" -ArgumentList "/i C:\Users\Administrator\AWSCLIV2.msi /qn" -Wait -NoNewWindow

$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
Write-Output "AWS CLI path: $((Get-Command aws -ErrorAction SilentlyContinue).Source)"

Write-Output "Retrieving domain credentials"
$secretValue  = aws secretsmanager get-secret-value --secret-id ${admin_secret} --query SecretString --output text
$secretObject = $secretValue | ConvertFrom-Json
$password     = $secretObject.password | ConvertTo-SecureString -AsPlainText -Force
$cred         = New-Object System.Management.Automation.PSCredential ($secretObject.username,$password)

Write-Output "Joining domain ${domain_fqdn}"
Add-Computer -DomainName "${domain_fqdn}" -Credential $cred -Force -OUPath "${computers_ou}"

Write-Output "Ensuring AD groups"

if (-not (Get-ADGroup -Filter "Name -eq 'mcloud-users'" -ErrorAction SilentlyContinue)) {
New-ADGroup -Name "mcloud-users" -GroupCategory Security -GroupScope Universal -Credential $cred -OtherAttributes @{gidNumber='10001'}
}

if (-not (Get-ADGroup -Filter "Name -eq 'india'" -ErrorAction SilentlyContinue)) {
New-ADGroup -Name "india" -GroupCategory Security -GroupScope Universal -Credential $cred -OtherAttributes @{gidNumber='10002'}
}

if (-not (Get-ADGroup -Filter "Name -eq 'us'" -ErrorAction SilentlyContinue)) {
New-ADGroup -Name "us" -GroupCategory Security -GroupScope Universal -Credential $cred -OtherAttributes @{gidNumber='10003'}
}

if (-not (Get-ADGroup -Filter "Name -eq 'linux-admins'" -ErrorAction SilentlyContinue)) {
New-ADGroup -Name "linux-admins" -GroupCategory Security -GroupScope Universal -Credential $cred -OtherAttributes @{gidNumber='10004'}
}

$uidCounter = 10000

function Create-ADUserFromSecret {

param (
[string]$SecretId,
[string]$GivenName,
[string]$Surname,
[string]$DisplayName,
[string]$Email,
[string]$Username,
[array]$Groups
)

$userExists = Get-ADUser -Filter "SamAccountName -eq '$Username'" -ErrorAction SilentlyContinue

if (-not $userExists) {

$global:uidCounter++
$uidNumber = $global:uidCounter

$secretValue  = aws secretsmanager get-secret-value --secret-id $SecretId --query SecretString --output text
$secretObject = $secretValue | ConvertFrom-Json
$password     = $secretObject.password | ConvertTo-SecureString -AsPlainText -Force

Write-Output "Creating user $Username"

New-ADUser -Name $Username `
-GivenName $GivenName `
-Surname $Surname `
-DisplayName $DisplayName `
-EmailAddress $Email `
-UserPrincipalName "$Username@${domain_fqdn}" `
-SamAccountName $Username `
-AccountPassword $password `
-Enabled $true `
-Credential $cred `
-PasswordNeverExpires $true `
-OtherAttributes @{gidNumber='10001'; uidNumber=$uidNumber}
}

foreach ($group in $Groups) {
Add-ADGroupMember -Identity $group -Members $Username -Credential $cred -ErrorAction SilentlyContinue
}
}

Write-Output "Creating AD users"

Create-ADUserFromSecret "jsmith_ad_credentials_ws" "John" "Smith" "John Smith" "jsmith@mikecloud.com" "jsmith" @("mcloud-users","us","linux-admins")
Create-ADUserFromSecret "edavis_ad_credentials_ws" "Emily" "Davis" "Emily Davis" "edavis@mikecloud.com" "edavis" @("mcloud-users","us")
Create-ADUserFromSecret "rpatel_ad_credentials_ws" "Raj" "Patel" "Raj Patel" "rpatel@mikecloud.com" "rpatel" @("mcloud-users","india","linux-admins")
Create-ADUserFromSecret "akumar_ad_credentials_ws" "Amit" "Kumar" "Amit Kumar" "akumar@mikecloud.com" "akumar" @("mcloud-users","india")

Write-Output "Granting RDP access"

Add-LocalGroupMember -Group "Remote Desktop Users" -Member "mcloud-users" -ErrorAction SilentlyContinue

Write-Output "Rebooting system"

shutdown /r /t 5 /c "Initial EC2 reboot to join domain" /f /d p:4:1

}
finally {

Write-Output "User-data finished at $(Get-Date -Format o)"
Stop-Transcript | Out-Null

}
</powershell>