#!/bin/bash

# Alexa Computer Control - Local Lambda Testing Script
# Este script facilita o teste local da função Lambda usando AWS SAM

set -e

echo "🧪 Testando Lambda Alexa Computer Control localmente com SAM CLI"
echo "=============================================================="
echo ""

# Verificar se SAM CLI está instalado
if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI não encontrado. Instale primeiro: brew install aws-sam-cli"
    exit 1
fi

# Verificar se Docker está rodando
if ! docker info &> /dev/null; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker primeiro."
    echo "💡 No macOS: abra o Docker Desktop"
    exit 1
fi

# Instalar dependências se necessário
if [ ! -d "lambda-function/node_modules" ]; then
    echo "📦 Instalando dependências da função Lambda..."
    cd lambda-function && npm install && cd ..
    echo ""
fi

# Função para executar testes
run_test() {
    local test_name="$1"
    local event_file="$2"
    local description="$3"
    
    echo "🚀 Testando: $description"
    echo "   Evento: $event_file"
    echo "   ──────────────────────────────────────────"
    
    # Executar o teste usando SAM local invoke
    echo "📤 Enviando requisição..."
    echo ""
    
    local temp_file=$(mktemp)
    local exit_code=0
    
    # Redireciona apenas logs de build/inicialização para stderr, mantém resposta da Lambda
    sam local invoke ComputerControlFunction \
        --event "$event_file" \
        --env-vars env.json \
        --no-event 2>"$temp_file" || exit_code=$?
    
    # Mostra logs de build/inicialização se houver erro
    if [ $exit_code -ne 0 ]; then
        echo "❌ Falha na execução do SAM CLI:"
        cat "$temp_file"
        rm -f "$temp_file"
        echo "❌ Falha no teste: $test_name"
        return 1
    fi
    
    # Mostra avisos/logs se existirem (mas não falha o teste)
    if [ -s "$temp_file" ]; then
        echo "⚠️  Logs/Avisos:"
        cat "$temp_file"
        echo ""
    fi
    
    rm -f "$temp_file"
    
    echo ""
    echo "✅ Teste concluído: $test_name"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Verificar arquivos necessários
echo "🔍 Verificando configuração..."

if [ ! -f "template.yaml" ]; then
    echo "❌ Arquivo template.yaml não encontrado"
    exit 1
fi

if [ ! -f "env.json" ]; then
    echo "❌ Arquivo env.json não encontrado"
    exit 1
fi

if [ ! -d "test-events" ]; then
    echo "❌ Diretório test-events não encontrado"
    exit 1
fi

echo "✅ Configuração OK"
echo ""

# Mostrar configuração atual
echo "⚙️  CONFIGURAÇÃO ATUAL:"
echo "   COMPUTER_SERVER_URL: $(cat env.json | jq -r '.ComputerControlFunction.COMPUTER_SERVER_URL' 2>/dev/null || echo 'N/A')"
echo "   API_KEY: $(cat env.json | jq -r '.ComputerControlFunction.API_KEY' 2>/dev/null | sed 's/.*/***/' || echo 'N/A')"
echo "   COMPUTER_MAC: $(cat env.json | jq -r '.ComputerControlFunction.COMPUTER_MAC' 2>/dev/null || echo 'N/A')"
echo ""

# Verificar se o servidor local está rodando
SERVER_URL=$(cat env.json | jq -r '.ComputerControlFunction.COMPUTER_SERVER_URL' 2>/dev/null || echo "http://localhost:3000")
if [[ "$SERVER_URL" == *"localhost"* ]] || [[ "$SERVER_URL" == *"127.0.0.1"* ]]; then
    echo "🔍 Verificando se o servidor local está rodando..."
    if curl -s "$SERVER_URL/health" > /dev/null 2>&1; then
        echo "✅ Servidor local está respondendo em $SERVER_URL"
    else
        echo "⚠️  Servidor local não está respondendo em $SERVER_URL"
        echo "💡 Para iniciar o servidor: cd computer-server && npm start"
    fi
    echo ""
fi

# Executar testes baseado no argumento
case "${1:-all}" in
    "launch")
        run_test "LaunchRequest" "test-events/launch-request.json" "Abertura da skill"
        ;;
    "turn-on")
        run_test "TurnOnIntent" "test-events/turn-on-intent.json" "Ligar computador"
        ;;
    "status")
        run_test "StatusIntent" "test-events/status-intent.json" "Verificar status"
        ;;
    "all")
        echo "🎯 Executando todos os testes..."
        echo ""
        
        run_test "LaunchRequest" "test-events/launch-request.json" "Abertura da skill"
        run_test "TurnOnIntent" "test-events/turn-on-intent.json" "Ligar computador"
        run_test "StatusIntent" "test-events/status-intent.json" "Verificar status"
        
        echo "🎉 Todos os testes concluídos!"
        ;;
    "help"|"-h"|"--help")
        echo "📖 Uso: ./test-lambda-local.sh [TESTE]"
        echo ""
        echo "Testes disponíveis:"
        echo "  launch    - Testa abertura da skill"
        echo "  turn-on   - Testa comando de ligar computador"
        echo "  status    - Testa verificação de status"
        echo "  all       - Executa todos os testes (padrão)"
        echo "  help      - Mostra esta mensagem"
        echo ""
        echo "Exemplos:"
        echo "  ./test-lambda-local.sh"
        echo "  ./test-lambda-local.sh launch"
        echo "  ./test-lambda-local.sh turn-on"
        echo ""
        exit 0
        ;;
    *)
        echo "❌ Teste desconhecido: $1"
        echo "💡 Use: ./test-lambda-local.sh help para ver opções disponíveis"
        exit 1
        ;;
esac

echo ""
echo "💡 DICAS:"
echo "   • Para depurar: sam local invoke -d 5858 ComputerControlFunction -e test-events/launch-request.json"
echo "   • Para ver logs: adicione --log-file sam-local.log"
echo "   • Para alterar configuração: edite env.json"
echo "   • Para testar específico: ./test-lambda-local.sh [launch|turn-on|status]"