<powershell>
# ==============================================================================
# Windows domain member — joins mcloud.mikecloud.com and seeds the directory
# with the lab's groups and users (AWS Managed AD gives no shell on a DC, so a
# member server with RSAT does it). Rendered by Terraform templatefile().
# Idempotent: every step tolerates "already done", and it reboots only when
# this run performed the join.
# ==============================================================================
$ErrorActionPreference = 'Stop'
$ProgressPreference   = 'SilentlyContinue'

$Log = 'C:\ProgramData\userdata.log'
New-Item -Path $Log -ItemType File -Force | Out-Null
Start-Transcript -Path $Log -Append -Force

try {
    Write-Output "Starting user-data at $(Get-Date -Format o)"

    # --------------------------------------------------------------------------
    # RSAT — the AD cmdlets below, plus the consoles for the RDP demo
    # --------------------------------------------------------------------------
    Write-Output "Installing AD management features"
    Install-WindowsFeature -Name `
        GPMC,RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-DNS-Server |
        Out-Null

    # --------------------------------------------------------------------------
    # AWS CLI — needed to read the passwords from Secrets Manager
    # --------------------------------------------------------------------------
    $AwsExe = 'C:\Program Files\Amazon\AWSCLIV2\aws.exe'

    if (-not (Test-Path $AwsExe)) {
        Write-Output "Installing AWS CLI v2"
        Invoke-WebRequest https://awscli.amazonaws.com/AWSCLIV2.msi `
            -OutFile C:\Users\Administrator\AWSCLIV2.msi
        Start-Process "msiexec" `
            -ArgumentList "/i C:\Users\Administrator\AWSCLIV2.msi /qn" `
            -Wait -NoNewWindow
    }

    # The installer updates the machine PATH, not this running session's.
    $env:Path += ";C:\Program Files\Amazon\AWSCLIV2"

    # --------------------------------------------------------------------------
    # Domain join
    # --------------------------------------------------------------------------
    Write-Output "Retrieving domain credentials"
    $secretValue  = aws secretsmanager get-secret-value `
        --secret-id ${admin_secret} --query SecretString --output text
    $secretObject = $secretValue | ConvertFrom-Json
    $password     = $secretObject.password |
        ConvertTo-SecureString -AsPlainText -Force
    $cred         = New-Object System.Management.Automation.PSCredential `
        ($secretObject.username, $password)

    $didJoin = $false
    $cs = Get-CimInstance Win32_ComputerSystem

    if ($cs.PartOfDomain -and $cs.Domain -ieq "${domain_fqdn}") {
        Write-Output "Already joined to ${domain_fqdn}"
    }
    else {
        Write-Output "Joining domain ${domain_fqdn}"
        Add-Computer -DomainName "${domain_fqdn}" -Credential $cred `
            -Force -OUPath "${computers_ou}"
        $didJoin = $true
    }

    # --------------------------------------------------------------------------
    # Groups — gidNumber lets SSSD on the Linux host use these IDs directly.
    # Create-and-catch rather than Get-ADGroup first: the lookup is unreliable
    # before the post-join reboot.
    # --------------------------------------------------------------------------
    function New-AdGroupIfMissing {
        param ($Name, $Gid)

        try {
            New-ADGroup -Name $Name -GroupCategory Security `
                -GroupScope Universal -Credential $cred `
                -OtherAttributes @{ gidNumber = $Gid } `
                -ErrorAction Stop | Out-Null
            Write-Output "Created group: $Name"
        }
        catch {
            if ($_.Exception.Message -match "already exists") {
                Write-Output "Group already exists: $Name"
            }
            else { throw }
        }
    }

    Write-Output "Ensuring AD groups exist"
    New-AdGroupIfMissing "mcloud-users" "10001"
    New-AdGroupIfMissing "india"        "10002"
    New-AdGroupIfMissing "us"           "10003"
    New-AdGroupIfMissing "linux-admins" "10004"

    # --------------------------------------------------------------------------
    # Users — passwords come from each user's own secret; every user's primary
    # group is mcloud-users (10001), uidNumbers count up from 10001
    # --------------------------------------------------------------------------
    $global:uidCounter = 10000

    function New-AdUserFromSecretIfMissing {
        param ($SecretId, $GivenName, $Surname, $DisplayName, $Email,
               $Username, $Groups)

        # Counted even for existing users so each name keeps the same uid.
        $global:uidCounter++
        $uidNumber = $global:uidCounter

        $userSecret   = aws secretsmanager get-secret-value `
            --secret-id $SecretId --query SecretString --output text
        $userPassword = ($userSecret | ConvertFrom-Json).password |
            ConvertTo-SecureString -AsPlainText -Force

        try {
            New-ADUser -Name $Username `
                -GivenName $GivenName `
                -Surname $Surname `
                -DisplayName $DisplayName `
                -EmailAddress $Email `
                -UserPrincipalName "$Username@${domain_fqdn}" `
                -SamAccountName $Username `
                -AccountPassword $userPassword `
                -Enabled $true `
                -Credential $cred `
                -PasswordNeverExpires $true `
                -OtherAttributes @{ gidNumber = '10001'; uidNumber = $uidNumber } `
                -ErrorAction Stop | Out-Null
            Write-Output "Created user: $Username"
        }
        catch {
            if ($_.Exception.Message -match "already exists") {
                Write-Output "User already exists: $Username"
            }
            else { throw }
        }

        foreach ($group in $Groups) {
            try {
                Add-ADGroupMember -Identity $group -Members $Username `
                    -Credential $cred -ErrorAction Stop
            }
            catch {
                if ($_.Exception.Message -match "already a member") {
                    Write-Output "$Username already in $group"
                }
                else { throw }
            }
        }
    }

    Write-Output "Ensuring AD users exist"

    New-AdUserFromSecretIfMissing "jsmith_ad_credentials_ws" "John" "Smith" `
        "John Smith" "jsmith@mikecloud.com" "jsmith" `
        @("mcloud-users", "us", "linux-admins")

    New-AdUserFromSecretIfMissing "edavis_ad_credentials_ws" "Emily" "Davis" `
        "Emily Davis" "edavis@mikecloud.com" "edavis" `
        @("mcloud-users", "us")

    New-AdUserFromSecretIfMissing "rpatel_ad_credentials_ws" "Raj" "Patel" `
        "Raj Patel" "rpatel@mikecloud.com" "rpatel" `
        @("mcloud-users", "india", "linux-admins")

    New-AdUserFromSecretIfMissing "akumar_ad_credentials_ws" "Amit" "Kumar" `
        "Amit Kumar" "akumar@mikecloud.com" "akumar" `
        @("mcloud-users", "india")

    # --------------------------------------------------------------------------
    # RDP for domain users. Deliberately non-fatal: a throw here would skip
    # the reboot below and leave the domain join unfinished.
    # --------------------------------------------------------------------------
    Write-Output "Granting RDP access to mcloud-users"
    try {
        Add-LocalGroupMember -Group "Remote Desktop Users" `
            -Member "MCLOUD\mcloud-users" -ErrorAction Stop
    }
    catch {
        if ($_.Exception.Message -match "already a member") {
            Write-Output "mcloud-users already in Remote Desktop Users"
        }
        else {
            Write-Warning "RDP grant failed: $($_.Exception.Message)"
        }
    }

    # The join only takes effect after a restart.
    if ($didJoin) {
        Write-Output "Rebooting to finalize domain join"
        shutdown /r /t 5 /c "Initial EC2 reboot to join domain" /f /d p:4:1
    }
}
finally {
    Write-Output "User-data finished at $(Get-Date -Format o)"
    Stop-Transcript | Out-Null
}
</powershell>
