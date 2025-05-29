# Hopefully that AWS keep uses Ethernet4 as the default interface
Set-DnsClientServerAddress -InterfaceAlias "Ethernet4" -ServerAddresses (${dns64_server_ipv6}, "") #This is the IPv6 address of the DNS64 server
