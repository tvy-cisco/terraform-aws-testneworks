https://confluence-eng-rtp2.cisco.com/conf/display/PROD/Test+Network+Design
Network 5 (IPv6 intranet to dual-stack Internet with DNS64/NAT64):


                        +--------------+
                        | DNS64/NAT64  +-------------- IPv4
IPv6 -------------------+              |
                        |    NAT66     +-------------- IPv6
                        +--------------+

Expectations:

* IPv4 remote resolvers can be reached using NAT64 address mapping
* IPv6 remote resolvers can be reached
* IPv6 local resolvers can be reached
* local network is ipv6 only
* system resolvers are ipv6
  * resolvers are dns64 enabled
* Internet resources pointed to by AAAA records are reachable
* Internet resources pointed to by A records are reachable (due to nat64 address translation)
* local (intranet) resources pointed to by AAAA records are reachable

Test cases:
* dig a ipv4only.arpa @<system resolver ipv6 addr> should return with at least one answer
* dig aaaa ipv4only.arpa @<system resolver ipv6 addr> should return with at least one answer
* dig a ipv4only.arpa @<public nat64-mapped ipv4 resolver address> should return with at least one answer
* dig aaaa ipv4only.arpa @<public nat64-mapped ipv4 resolver address> should return with 0 answers
* curl http://ipv4.tlund.se/ should return data
* curl http://ipv4c.tlund.se/ should return data
* curl http://dual.tlund.se/ should return data
* curl http://dualc.tlund.se/ should return data
* curl http://193.15.228.195/ should fail
* curl http://<nat64 mapping of 193.15.228.195>/ should return data
* curl http://ipv6.tlund.se/ should return data
* curl http://ipv6c.tlund.se/ should return data
* curl http://[2a00:801:f::195]/ should return data
* curl http://ipv6-only.tlund.se/ should return data (requires ipv6 resolver; not a nat64-mapped ipv4 resolver)
* curl http://ipv6-onlyc.tlund.se/ should return data (requires ipv6 resolver; not a nat64-mapped ipv4 resolver)

notes:
* ERC currently does not support this scenario (but we need to be sure it behaves correctly)
* The ::ffff:w.x.y.z mapping should not available here because the network is not dual-stack.
