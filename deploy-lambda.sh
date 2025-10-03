#!/bin/bash

# Alexa Computer Control - Lambda Deployment Script
# Este script empacota e faz deploy da função Lambda

set -e

echo "🚀 Iniciando deploy da função Lambda..."

# Verificar se AWS CLI está configurado
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI não encontrado. Instale primeiro: https://aws.amazon.com/cli/"
    exit 1
fi

# Verificar credenciais AWS
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI não está configurado. Execute: aws configure"
    exit 1
fi

# Configurações
FUNCTION_NAME="computer-control-alexa-skill"
REGION="${AWS_REGION:-us-east-1}"
RUNTIME="nodejs18.x"
HANDLER="index.handler"
ROLE_NAME="lambda-execution-role-computer-control"

echo "📍 Região: $REGION"
echo "📁 Função: $FUNCTION_NAME"

# Navegar para o diretório da função Lambda
cd lambda-function

# Instalar dependências
echo "📦 Instalando dependências..."
npm install --production

# Criar pacote ZIP
echo "📦 Criando pacote de deployment..."
rm -f function.zip
zip -r function.zip . -x "*.git*" "node_modules/.cache/*" "*.md"

# Verificar se a função já existe
FUNCTION_EXISTS=$(aws lambda list-functions --region $REGION --query "Functions[?FunctionName=='$FUNCTION_NAME'].FunctionName" --output text)

if [ "$FUNCTION_EXISTS" = "$FUNCTION_NAME" ]; then
    echo "🔄 Atualizando função existente..."
    aws lambda update-function-code \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://function.zip \
        --region $REGION
    
    echo "⚙️ Atualizando configuração..."
    aws lambda update-function-configuration \
        --function-name $FUNCTION_NAME \
        --runtime $RUNTIME \
        --handler $HANDLER \
        --timeout 30 \
        --memory-size 256 \
        --region $REGION
else
    echo "🆕 Criando nova função..."
    
    # Criar role IAM se não existir
    ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text 2>/dev/null || echo "")
    
    if [ -z "$ROLE_ARN" ]; then
        echo "🔐 Criando IAM role..."
        
        # Criar trust policy
        cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
        
        aws iam create-role \
            --role-name $ROLE_NAME \
            --assume-role-policy-document file://trust-policy.json
        
        aws iam attach-role-policy \
            --role-name $ROLE_NAME \
            --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
        
        rm trust-policy.json
        
        # Esperar role ser criada
        echo "⏳ Aguardando role ser criada..."
        sleep 10
        
        ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)
    fi
    
    echo "🔐 Usando IAM Role: $ROLE_ARN"
    
    # Criar função
    aws lambda create-function \
        --function-name $FUNCTION_NAME \
        --runtime $RUNTIME \
        --role $ROLE_ARN \
        --handler $HANDLER \
        --zip-file fileb://function.zip \
        --timeout 30 \
        --memory-size 256 \
        --region $REGION
    
    # Aguardar função ficar ativa
    echo "⏳ Aguardando função ficar ativa..."
    aws lambda wait function-active --function-name $FUNCTION_NAME --region $REGION
fi

# Obter ARN da função
FUNCTION_ARN=$(aws lambda get-function --function-name $FUNCTION_NAME --region $REGION --query 'Configuration.FunctionArn' --output text)

echo "✅ Deploy concluído!"
echo "📋 ARN da função: $FUNCTION_ARN"
echo ""
echo "🔧 Próximos passos:"
echo "1. Configure as variáveis de ambiente no AWS Console:"
echo "   - COMPUTER_SERVER_URL: http://seu-ip:3000"
echo "   - API_KEY: sua-chave-secreta"
echo "   - COMPUTER_MAC: seu-endereco-mac"
echo ""
echo "2. Adicione permissão para Alexa invocar a função:"
echo "   aws lambda add-permission \\"
echo "     --function-name $FUNCTION_NAME \\"
echo "     --statement-id alexa-skill-invoke \\"
echo "     --action lambda:InvokeFunction \\"
echo "     --principal alexa-appkit.amazon.com \\"
echo "     --region $REGION"
echo ""
echo "3. Use este ARN na configuração da sua Skill Alexa:"
echo "   $FUNCTION_ARN"

# Limpar arquivos temporários
rm -f function.zip

echo "🎉 Deploy finalizado com sucesso!"