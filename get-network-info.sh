#!/bin/bash

# Alexa Computer Control - Network Information Helper
# Este script ajuda a encontrar informações de rede necessárias

echo "🔍 Coletando informações de rede..."
echo "=================================="
echo ""

echo "📡 INTERFACES DE REDE DISPONÍVEIS:"
echo "-----------------------------------"

# Listar interfaces de rede
if command -v ip &> /dev/null; then
    ip link show | grep -E "^[0-9]+:" | while IFS= read -r line; do
        interface=$(echo "$line" | cut -d: -f2 | sed 's/^ *//')
        
        # Obter endereço MAC
        mac=$(ip link show "$interface" | grep -o -E "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}" | head -1)
        
        # Verificar se está ativo
        state=$(echo "$line" | grep -o "state [A-Z]*" | cut -d' ' -f2)
        
        echo "Interface: $interface"
        echo "  MAC: ${mac:-N/A}"
        echo "  Estado: ${state:-UNKNOWN}"
        
        # Obter IP se disponível
        if command -v ip &> /dev/null; then
            ip=$(ip addr show "$interface" 2>/dev/null | grep -o "inet [0-9.]*" | cut -d' ' -f2)
            if [ -n "$ip" ]; then
                echo "  IP: $ip"
            fi
        fi
        echo ""
    done
else
    # Fallback para ifconfig
    echo "Usando ifconfig como fallback..."
    ifconfig -a | grep -E "^[a-zA-Z]" | while IFS= read -r line; do
        interface=$(echo "$line" | cut -d: -f1)
        echo "Interface: $interface"
        
        # Buscar MAC na próxima linha
        mac=$(ifconfig "$interface" | grep -o -E "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}")
        echo "  MAC: ${mac:-N/A}"
        echo ""
    done
fi

echo ""
echo "🌐 ENDEREÇO IP EXTERNO:"
echo "----------------------"
external_ip=$(curl -s https://ipinfo.io/ip 2>/dev/null || echo "Não foi possível obter")
echo "IP externo: $external_ip"
echo ""

echo "🏠 REDE LOCAL:"
echo "-------------"
if command -v hostname &> /dev/null; then
    local_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "N/A")
    echo "IP local: $local_ip"
    
    if [ "$local_ip" != "N/A" ]; then
        echo "URL do servidor: http://$local_ip:3000"
    fi
fi
echo ""

echo "⚙️  WAKE-ON-LAN STATUS:"
echo "----------------------"
if command -v ethtool &> /dev/null; then
    # Verificar WoL nas interfaces principais
    for interface in eth0 enp* ens*; do
        if ip link show "$interface" &>/dev/null; then
            echo "Verificando $interface..."
            wol_status=$(ethtool "$interface" 2>/dev/null | grep "Wake-on" || echo "  N/A")
            echo "  $wol_status"
        fi
    done
else
    echo "ethtool não instalado. Para verificar WoL:"
    echo "sudo apt install ethtool"
    echo "sudo ethtool <interface>"
fi
echo ""

echo "📋 RESUMO PARA CONFIGURAÇÃO:"
echo "==========================="

# Encontrar a melhor interface
best_interface=""
best_mac=""
best_ip=""

if command -v ip &> /dev/null; then
    # Buscar interface com IP que não seja loopback
    for interface in $(ip link show | grep -E "^[0-9]+:" | cut -d: -f2 | sed 's/^ *//'); do
        if [ "$interface" != "lo" ]; then
            ip_addr=$(ip addr show "$interface" 2>/dev/null | grep -o "inet [0-9.]*" | head -1 | cut -d' ' -f2)
            if [ -n "$ip_addr" ] && [ "$ip_addr" != "127.0.0.1" ]; then
                mac_addr=$(ip link show "$interface" | grep -o -E "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}" | head -1)
                best_interface="$interface"
                best_mac="$mac_addr"
                best_ip="$ip_addr"
                break
            fi
        fi
    done
fi

if [ -n "$best_interface" ]; then
    echo "Interface recomendada: $best_interface"
    echo "MAC Address para .env: COMPUTER_MAC=$best_mac"
    echo "URL do servidor: http://$best_ip:3000"
    echo ""
    echo "Para habilitar Wake-on-LAN:"
    echo "sudo ethtool -s $best_interface wol g"
    echo ""
    echo "Para testar Wake-on-LAN:"
    echo "sudo apt install wakeonlan"
    echo "wakeonlan $best_mac"
else
    echo "❌ Não foi possível determinar a melhor configuração automaticamente."
    echo "Verifique manualmente as interfaces acima."
fi

echo ""
echo "🔧 Próximos passos:"
echo "1. Copie o MAC address para o arquivo .env"
echo "2. Configure port forwarding no seu roteador (porta 3000)"
echo "3. Use o IP externo na configuração da Lambda"
echo "4. Teste a conectividade com o script test-server.sh"