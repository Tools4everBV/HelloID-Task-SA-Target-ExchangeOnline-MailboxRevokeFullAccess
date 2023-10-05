# HelloID-Task-SA-Target-ExchangeOnline-MailboxRevokeFullAccess
###############################################################
# Form mapping
$formObject = @{
    MailboxIdentity = $form.MailboxIdentity
    UsersToRemove    = $form.UsersToRemove
}

[bool]$IsConnected = $false

try {
    $null = Import-Module ExchangeOnlineManagement -ErrorAction Stop
    $securePassword = ConvertTo-SecureString $ExchangeOnlineAdminPassword -AsPlainText -Force
    $credential = [System.Management.Automation.PSCredential]::new($ExchangeOnlineAdminUsername, $securePassword)

    $null = Connect-ExchangeOnline -Credential $credential -ShowBanner:$false -ShowProgress:$false -ErrorAction Stop
    $IsConnected = $true

    foreach ($user in $formObject.UsersToRemove){
        try {
            Write-Information "Executing ExchangeOnline action: [MailboxRevokeFullAccess] for: [$($user.id)] on mailbox: [$($formObject.MailboxIdentity)]"
            $splatParams = @{
                Identity        = $formObject.MailboxIdentity
                AccessRights    = 'FullAccess'
                InheritanceType = 'All'
                User            = $user.Id
                AutoMapping     = $true
            }
            $null = Remove-MailboxPermission @splatParams -ErrorAction Stop
            $auditLog = @{
                Action            = 'UpdateResource'
                System            = 'ExchangeOnline'
                TargetIdentifier  = $($user.Id)
                TargetDisplayName = $($user.DisplayName)
                Message           = "ExchangeOnline action: [MailboxRevokeFullAccess] for: [$($user.id)] on mailbox: [$($formObject.MailboxIdentity)] executed successfully"
                IsError           = $false
            }
            Write-Information -Tags 'Audit' -MessageData $auditLog
            Write-Information $auditLog.Message
        } catch {
            throw $_
        }
    }
} catch {
    $ex = $_
    $auditLog = @{
        Action            = 'UpdateResource'
        System            = 'ExchangeOnline'
        TargetIdentifier  = $($user.Id)
        TargetDisplayName = $($user.DisplayName)
        Message           = "Could not execute ExchangeOnline action: [MailboxRevokeFullAccess] for: [$($formObject.DisplayName)] on mailbox: [$($formObject.MailboxDistinguishedName)], error: $($ex.Exception.Message), Details : $($_.Exception.ErrorDetails)"
        IsError           = $true
    }
    Write-Information -Tags 'Audit' -MessageData $auditLog
    Write-Error $auditLog.Message
} finally {
    if ($IsConnected){
        $exchangeSessionEnd = Disconnect-ExchangeOnline -Confirm:$false -Verbose:$false
    }
}
###############################################################
