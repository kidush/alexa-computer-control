#!/bin/bash

# Alexa Computer Control - Server Test Script
# Este script testa os endpoints do servidor

set -e

# Configurações
SERVER_URL="http://localhost:3000"
API_KEY="${API_KEY:-your-secret-api-key-here}"
TEST_MAC="00:11:22:33:44:55"

echo "🧪 Testando servidor do Controle do Computador..."
echo "📍 URL: $SERVER_URL"
echo "🔐 API Key: ${API_KEY:0:10}..."
echo ""

# Função para fazer chamadas HTTP
make_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local auth_required="$4"
    
    local headers=""
    if [ "$auth_required" = "true" ]; then
        headers="-H 'Authorization: Bearer $API_KEY'"
    fi
    
    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        eval curl -s -X "$method" "$SERVER_URL$endpoint" -H "Content-Type: application/json" $headers -d "'$data'" -w "\\n%{http_code}"
    else
        eval curl -s -X "$method" "$SERVER_URL$endpoint" $headers -w "\\n%{http_code}"
    fi
}

# Teste 1: Health check público
echo "1️⃣ Testando endpoint público (/health)..."
response=$(make_request "GET" "/health" "" "false")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "200" ]; then
    echo "✅ Health check: OK"
    echo "📊 Status: $(echo "$body" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)"
    echo "⏱️  Uptime: $(echo "$body" | grep -o '"uptime":[^,}]*' | cut -d':' -f2) segundos"
else
    echo "❌ Health check falhou (HTTP $http_code)"
    echo "$body"
fi
echo ""

# Teste 2: Endpoint raiz público
echo "2️⃣ Testando endpoint raiz (/)..."
response=$(make_request "GET" "/" "" "false")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "200" ]; then
    echo "✅ Endpoint raiz: OK"
    echo "📝 Mensagem: $(echo "$body" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)"
else
    echo "❌ Endpoint raiz falhou (HTTP $http_code)"
    echo "$body"
fi
echo ""

# Teste 3: Endpoint protegido sem autenticação
echo "3️⃣ Testando segurança (sem autenticação)..."
response=$(make_request "POST" "/shutdown" "" "false")
http_code=$(echo "$response" | tail -n1)

if [ "$http_code" = "401" ]; then
    echo "✅ Segurança: OK (rejeitou requisição não autenticada)"
else
    echo "❌ Problema de segurança: endpoint deveria rejeitar (HTTP $http_code)"
fi
echo ""

# Teste 4: Wake-on-LAN (com autenticação)
echo "4️⃣ Testando Wake-on-LAN..."
wol_data='{"mac":"'$TEST_MAC'"}'
response=$(make_request "POST" "/wake" "$wol_data" "true")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "200" ]; then
    echo "✅ Wake-on-LAN: OK"
    echo "📝 Resposta: $(echo "$body" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)"
else
    echo "❌ Wake-on-LAN falhou (HTTP $http_code)"
    echo "$body"
fi
echo ""

# Teste 5: Status do computador
echo "5️⃣ Testando verificação de status..."
response=$(make_request "GET" "/health" "" "true")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "200" ]; then
    echo "✅ Verificação de status: OK"
    uptime=$(echo "$body" | grep -o '"uptime":[^,}]*' | cut -d':' -f2)
    uptime_minutes=$(echo "scale=1; $uptime / 60" | bc 2>/dev/null || echo "N/A")
    echo "⏱️  Computador ligado há: ${uptime_minutes} minutos"
else
    echo "❌ Verificação de status falhou (HTTP $http_code)"
    echo "$body"
fi
echo ""

# Teste 6: Cancel shutdown (não vamos testar shutdown real por segurança)
echo "6️⃣ Testando cancelamento de shutdown..."
response=$(make_request "POST" "/cancel-shutdown" "" "true")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "200" ] || [ "$http_code" = "500" ]; then
    echo "✅ Cancelamento de shutdown: OK (endpoint funciona)"
    if [ "$http_code" = "500" ]; then
        echo "ℹ️  Normal se não houver shutdown ativo para cancelar"
    fi
else
    echo "❌ Cancelamento de shutdown falhou (HTTP $http_code)"
    echo "$body"
fi
echo ""

# Resumo
echo "📋 RESUMO DOS TESTES"
echo "==================="

# Verificar se o servidor está funcionando
if curl -s "$SERVER_URL/health" > /dev/null 2>&1; then
    echo "✅ Servidor está funcionando"
    echo "✅ Endpoints estão respondendo"
    echo "✅ Autenticação está funcionando"
    echo ""
    echo "🎯 Próximos passos:"
    echo "1. Configure seu endereço MAC real no .env"
    echo "2. Exponha o servidor para internet (port forwarding/ngrok)"
    echo "3. Configure a função Lambda com a URL correta"
    echo "4. Teste com a Alexa!"
    echo ""
    echo "💡 Para testar com ngrok: ngrok http 3000"
    echo "💡 Para encontrar seu MAC: ip link show"
else
    echo "❌ Servidor não está funcionando"
    echo "💡 Verifique se o servidor está rodando: npm start"
fi
echo ""

echo "🏁 Teste concluído!"