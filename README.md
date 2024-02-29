# dns-anycast
script de automação para dns anycast + hyperlocal

baseado no artigo do mestre Marcelo Gondim para o BPF, [disponível aqui](https://wiki.brasilpeeringforum.org/w/DNS_Recursivo_Anycast_Hyperlocal)

VALIDADO EM DEBIAN 11!! PARA OUTRAS DISTROS, TESTAR!!

``` 

apt update -y && apt upgrade -y && apt install git -y
git clone https://github.com/wallacemariadeandrade/dns-anycast.git
cd dns-anycast
chmod +x dns-anycast.sh
./dns-anycast.sh

```