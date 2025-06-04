#ps1_sysnative

$ssh_keys = @(
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGZx8IAu+Wki/2mmBDlj5ICeut+tsuPo8cu5tRC0tN4 tvy@cisco.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4BHU0dKBfL6sFaFHdqHeQOrzj9cmAwWpLMAvN0DCys sshahary@cisco.com"
)

$authorized_keys_path = "C:\Users\onprem-jenkins\.ssh\authorized_keys"
if (Test-Path $authorized_keys_path) {
    Write-Host "File exists, appending keys..."
    foreach ($key in $ssh_keys) {
        Add-Content -Path $authorized_keys_path -Value $key
    }
} else {
    Write-Host "File does not exist, creating file and adding keys..."
    New-Item -Path $authorized_keys_path -ItemType File -Force | Out-Null
    foreach ($key in $ssh_keys) {
        Add-Content -Path $authorized_keys_path -Value $key
    }
}

Restart-Service sshd
regsvr32 /u "C:\Program Files\Duo Security\WindowsLogon\DuoCredProv.dll"
regsvr32 /u "C:\Program Files\Duo Security\WindowsLogon\DuoCredFilter.dll"
