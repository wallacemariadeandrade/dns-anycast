#!/bin/bash

echo ">>> DNS ANYCAST + HYPERLOCAL"
echo ">>> CRÉDITOS: MARCELO GONDIM"
echo ">>> https://wiki.brasilpeeringforum.org/w/DNS_Recursivo_Anycast_Hyperlocal"
echo ">>> BY WALLACE ANDRADE"

echo "=========================================="
echo "Atualizando os repositórios locais..."
echo "=========================================="
cp /etc/apt/sources.list /etc/apt/sources.list.old
echo "" > /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list
echo "deb http://deb.debian.org/debian bullseye main non-free contrib" >> /etc/apt/sources.list
echo "deb http://deb.debian.org/debian bullseye-updates main contrib non-free" >> /etc/apt/sources.list
echo "deb http://deb.debian.org/debian bullseye-backports main contrib non-free" >> /etc/apt/sources.list

echo "=========================================="
echo "Instalando pacotes necessários..."
echo "=========================================="
apt update -y && apt full-upgrade -y
apt install net-tools nftables htop iotop sipcalc tcpdump curl gnupg rsync wget host dnsutils mtr-tiny bmon sudo tmux whois ethtool dnstop frr frr-doc cron frr-pythontools irqbalance -y

echo "=========================================="
echo "Tunning de memória e outros recursos do sistema..."
echo "=========================================="
echo "net.core.rmem_max = 2147483647" >> /etc/sysctl.conf
echo "net.core.wmem_max = 2147483647" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 2147483647" >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 2147483647" >> /etc/sysctl.conf
echo "net.netfilter.nf_conntrack_buckets = 512000" >> /etc/sysctl.conf
echo "net.netfilter.nf_conntrack_max = 4096000" >> /etc/sysctl.conf
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo nf_conntrack >> /etc/modules
modprobe nf_conntrack
sysctl -p

systemctl enable irqbalance
systemctl enable cron

echo "=========================================="
echo "Desativando APPARMOR..."
echo "=========================================="
mkdir -p /etc/default/grub.d
echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT apparmor=0"' | tee /etc/default/grub.d/apparmor.cfg
update-grub

echo "=========================================="
echo "Instalando Unbound..."
echo "=========================================="
apt install unbound dns-root-data -y
mkdir -p /var/log/unbound
touch /var/log/unbound/unbound.log
chown -R unbound:unbound /var/log/unbound/
systemctl restart unbound

echo "=========================================="
echo "Configurando logrotate..."
echo "=========================================="
cat << EOF > /etc/logrotate.d/unbound
/var/log/unbound/unbound.log {
    rotate 5
    weekly
    postrotate
        unbound-control log_reopen
    endscript
}
EOF
systemctl restart logrotate.service

echo "=========================================="
echo "Copiando configuração base do Unbound para /etc/unbound/unbound.conf.d/local.conf..."
echo "=========================================="
cp local.conf /etc/unbound/unbound.conf.d/local.conf
echo "=========================================="
echo "Criando arquivo de blacklist /etc/unbound/rpz.block.hosts.zone..."
echo "=========================================="
echo "\$TTL 2h" >> /etc/unbound/rpz.block.hosts.zone
echo "@ IN SOA localhost. root.localhost. (2 6h 1h 1w 2h)" >> /etc/unbound/rpz.block.hosts.zone
echo "  IN NS  localhost." >> /etc/unbound/rpz.block.hosts.zone
echo "; RPZ manual block hosts" >> /etc/unbound/rpz.block.hosts.zone
echo "*.blaze.com CNAME ." >> /etc/unbound/rpz.block.hosts.zone
echo "blaze.com CNAME ." >> /etc/unbound/rpz.block.hosts.zone

echo "=========================================="
echo "Copiando arquivo de checagem do DNS para /root/teste_dns.sh..."
echo "=========================================="
cp teste_dns.sh /root/teste_dns.sh
chmod +x /root/teste_dns.sh

echo "=========================================="
echo "Configurando cron para checagem de DNS a cada minuto..."
echo "=========================================="
printf '* * * * * /root/teste_dns.sh' > /etc/cron.d/teste_dns 

echo "=========================================="
echo "Configurando FRR..."
echo "=========================================="
sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
systemctl restart frr
vtysh -c 'conf t' -c 'ip router-id 10.0.0.1' -c 'router bgp 64513' -c 'no bgp ebgp-requires-policy' -c 'no bgp network import-check' -c 'neighbor 10.100.100.1 remote-as 263537' -c 'address-family ipv4 unicast' -c 'network 10.200.200.12/32' -c 'network 10.200.200.13/32' -c 'network 10.200.200.144/32' -c 'neighbor 10.100.100.1 route-map IMPORT in' -c 'neighbor 10.100.100.1 route-map EXPORT out' -c 'exit-address-family' -c 'exit' -c 'ip prefix-list RECURSIVO seq 5 permit 10.200.200.12/32' -c 'ip prefix-list RECURSIVO seq 6 permit 10.200.200.13/32' -c 'ip prefix-list RECURSIVO seq 10 permit 10.200.200.144/32' -c 'ipv6 prefix-list RECURSIVO_V6 seq 5 permit 2001:db8:100c::3/128' -c 'route-map EXPORT permit 10' -c 'match ip address prefix-list RECURSIVO' -c 'exit' -c 'route-map EXPORT deny 1000' -c 'exit' -c 'route-map IMPORT deny 1000' -c 'exit' -c 'end' -c 'wr'

cat <<EOF


@
@

INSTALACAO FINALIZADA!

Você precisa ajustar os IPs dentro dos seguintes arquivos:
- /etc/unbound/unbound.conf.d/local.conf => adicione os IPs de anycast e corrija a access-list tambem
- /root/teste_dns.sh => corrija o IP do neighbor e AS utilizado
- /etc/frr/frr.conf => corrija a configuração do neighbor, networks, prefix-lists

PRESSIONE A TECLA ENTER PARA REINICIAR O SERVIDOR OU CTRL+C CASO QUERIA FAZER OS AJUSTES AGORA! 
NÃO SE ESQUEÇA DE APLICAR O REBOOT DEPOIS, NESSE CASO.

@
@


EOF

read teste

reboot