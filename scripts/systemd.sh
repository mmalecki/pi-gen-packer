# Use the same configurations for both networks, but keep them separate in case
# they need to be re-configured separately.
configure_network () {
  tee /etc/systemd/network/$1.network <<EOF
[Match]
Name=$1

[Network]
DHCP=yes
MulticastDNS=yes
LLMNR=no
EOF
}

configure_network wlan0
configure_network eth0

# Enable mDNS, disable LLMNR on the resolver
tee /etc/systemd/resolved.conf <<-EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1
DNSSEC=allow-downgrade
DNSOverTLS=opportunistic
MulticastDNS=yes
LLMNR=no
EOF
