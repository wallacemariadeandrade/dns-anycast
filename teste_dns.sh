#!/usr/bin/env bash
#Script para teste de DNS v1.3
#-----------------------------------------------------------------------
#Informe um domínio por linha:
dominios_testar=(
www.google.com
www.terra.com.br
www.uol.com.br
www.globo.com
www.facebook.com
www.youtube.com
www.twitch.com
www.discord.com
www.debian.org
www.redhat.com
)
corte_taxa_falha=100 #Porcentagem de falha para executar uma ação
NEIGHBOR=10.0.0.2
NEIGHBOR_V6=2001:db8::1
AS=64513
#-----------------------------------------------------------------------
qt_falhas=0
qt_total="${#dominios_testar[@]}"
echo "total_dominios: $qt_total"
for site in "${dominios_testar[@]}"
do
  resp=''
  resolver="127.0.0.1"
  echo " - dominio $site - $resolver"
  resp=$( host $site $resolver | grep "connection timed out" )
  if [ ! -z "$resp" ]; then
     ((qt_falhas++))
     echo "[$resp]"
  fi
done

taxa_falha=$((qt_falhas*100/qt_total))
echo "Falhas $qt_falhas/$qt_total ($taxa_falha%)"
habilitado="`vtysh -c 'show run' | grep \"neighbor $NEIGHBOR prefix-list BLOQUEIA-TUDO out\"`"
if [ "$taxa_falha" -ge "$corte_taxa_falha" ]; then
   if [ "$habilitado" == "" ]; then
      vtysh -c 'conf t' -c "router bgp $AS" -c 'address-family ipv4 unicast' -c "neighbor $NEIGHBOR prefix-list BLOQUEIA-TUDO out" -c "exit-address-family"  -c 'address-family ipv6 unicast'  -c "neighbor $NEIGHBOR_V6 prefix-list BLOQUEIA-TUDO out" -c 'end' -c 'wr'
      echo "caiu: `date`" >> /root/dnsreport.log
   fi
   exit
else
   if [ "$habilitado" != "" ]; then
      vtysh -c 'conf t' -c "router bgp $AS" -c 'address-family ipv4 unicast' -c "no neighbor $NEIGHBOR prefix-list BLOQUEIA-TUDO out" -c "exit-address-family"  -c 'address-family ipv6 unicast'  -c "no neighbor $NEIGHBOR_V6 prefix-list BLOQUEIA-TUDO out" -c 'end' -c 'wr'
      echo "voltou: `date`" >> /root/dnsreport.log
   fi
fi