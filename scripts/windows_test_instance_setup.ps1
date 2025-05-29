# Hopefully that AWS keep uses Ethernet4 as the default interface
Set-DnsClientServerAddress -InterfaceAlias "Ethernet4" -ServerAddresses ("2600:1f14:900:3000:b47a:d617:fdb:ec89", "") #This is the IPv6 address of the DNS64 server
