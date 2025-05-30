#ps1_sysnative
# Hopefully that AWS keep uses Ethernet4 as the default interface
Set-DnsClientServerAddress -InterfaceAlias "Ethernet4" -ServerAddresses (${dns64_server_ipv6}, "") #This is the IPv6 address of the DNS64 server

# Disables duo so that RDP as onprem-jenkins can be used
regsvr32 /u "C:\Program Files\Duo Security\WindowsLogon\DuoCredProv.dll"
regsvr32 /u "C:\Program Files\Duo Security\WindowsLogon\DuoCredFilter.dll"


# Enable ping ipv6 through the firewall
New-NetFirewallRule -DisplayName "Allow IPv6 Ping" -Direction Inbound -Protocol ICMPv6 -Action Allow
