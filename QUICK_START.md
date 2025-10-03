# 🚀 Guia Rápido - Alexa Computer Control

Este guia te ajudará a configurar e testar sua skill da Alexa rapidamente.

## ✅ Pré-requisitos

Antes de começar, certifique-se de ter:

- [ ] Node.js 18+ instalado
- [ ] Conta AWS configurada
- [ ] Computador Ubuntu/Linux
- [ ] Acesso ao roteador (para port forwarding) OU ngrok

## 🔧 Configuração em 5 Passos

### 1. Configure o Servidor Local

```bash
cd computer-server

# Copie e edite as configurações
cp .env.example .env
nano .env  # ou use seu editor favorito
```

**Configure no arquivo .env:**
- `API_KEY`: Uma senha forte (ex: `minha-chave-super-secreta-123`)
- `COMPUTER_MAC`: Seu endereço MAC (use o script get-network-info.sh)

### 2. Encontre suas Informações de Rede

```bash
./get-network-info.sh
```

Copie o MAC address mostrado para o arquivo `.env`.

### 3. Inicie o Servidor

```bash
cd computer-server
npm start
```

### 4. Teste o Servidor Localmente

Em outro terminal:
```bash
./test-server.sh
```

Verifique se todos os testes passaram ✅.

### 5. Exponha o Servidor para Internet

**Opção A - ngrok (mais fácil para teste):**
```bash
# Instale ngrok se não tiver: https://ngrok.com/download
ngrok http 3000
```

**Opção B - Port Forwarding:**
- Configure no seu roteador: porta 3000 → IP interno do seu computador
- Use seu IP externo

### 6. Configure AWS Lambda

```bash
# Configure suas credenciais AWS primeiro
aws configure

# Faça deploy da função
./deploy-lambda.sh
```

Anote o ARN da função Lambda que será mostrado.

### 7. Configure Variáveis Lambda

No AWS Console, configure estas variáveis de ambiente na função Lambda:

- `COMPUTER_SERVER_URL`: URL do ngrok ou seu IP externo (ex: `http://1234.ngrok.io`)
- `API_KEY`: A mesma chave do arquivo .env
- `COMPUTER_MAC`: Seu endereço MAC

### 8. Crie a Skill da Alexa

1. Acesse [Alexa Developer Console](https://developer.amazon.com/alexa/console/ask)
2. "Create Skill"
3. Nome: "Controle do Computador"
4. Idioma: "Portuguese (BR)"
5. Modelo: "Custom"
6. Método: "Provision your own"

### 9. Configure a Skill

**Interaction Model:**
- Copie o conteúdo de `alexa-skill/interactionModel-pt-BR.json`
- Cole no JSON Editor da skill

**Endpoint:**
- Tipo: "AWS Lambda ARN"
- ARN: O ARN da sua função Lambda
- Região: Sua região AWS

### 10. Teste!

**No Simulador da Alexa:**
- "ligar meu computador"
- "verificar status do computador"
- "desligar meu computador"

**No seu dispositivo Alexa:**
- "Alexa, peça para o controle do computador ligar meu computador"

## 🐛 Resolução de Problemas

### Servidor não responde
```bash
# Verifique se está rodando
curl http://localhost:3000/health

# Verifique logs
cd computer-server && npm start
```

### Alexa não entende
- Verifique o nome de invocação: "controle do computador"
- Certifique-se de que a skill está habilitada na sua conta

### Lambda retorna erro
- Verifique as variáveis de ambiente
- Veja os logs no CloudWatch
- Teste a URL do servidor manualmente

### Wake-on-LAN não funciona
```bash
# Habilite WoL (substitua eth0 pela sua interface)
sudo apt install ethtool
sudo ethtool -s eth0 wol g

# Teste localmente
sudo apt install wakeonlan
wakeonlan SEU-MAC-ADDRESS
```

## 📋 Lista de Verificação de Teste

- [ ] Servidor local responde em http://localhost:3000
- [ ] Todos os testes passam em `./test-server.sh`
- [ ] Servidor é acessível da internet
- [ ] Função Lambda foi criada com sucesso
- [ ] Variáveis de ambiente estão configuradas
- [ ] Skill da Alexa foi criada
- [ ] Interaction Model foi configurado
- [ ] Endpoint Lambda está conectado
- [ ] Teste no simulador funciona
- [ ] Wake-on-LAN está habilitado

## 🎯 Comandos para Testar

### Comandos em Português
- "Alexa, peça para o controle do computador ligar meu computador"
- "Alexa, peça para o controle do computador desligar meu computador"
- "Alexa, peça para o controle do computador verificar status do computador"
- "Alexa, peça para o controle do computador cancelar shutdown"

### Comandos Abreviados (depois que a skill estiver ativa)
- "Alexa, abra controle do computador"
- "ligar o computador"
- "desligar o computador"
- "status do computador"

## 🔒 Segurança

⚠️ **IMPORTANTE**: Você está expondo controles do seu computador na internet!

**Medidas de segurança implementadas:**
- ✅ Autenticação via API key
- ✅ CORS configurado
- ✅ Endpoints protegidos
- ✅ Delay de 1 minuto no shutdown

**Recomendações adicionais:**
- Use uma API key forte (32+ caracteres)
- Configure firewall no servidor
- Monitore logs regularmente
- Considere usar VPN em vez de exposição direta

## 🎉 Pronto!

Se tudo funcionou, agora você pode:
- Ligar seu computador de qualquer lugar do mundo
- Desligar com segurança via voz
- Verificar se está ligado
- Cancelar desligamentos acidentais

**Divirta-se com sua nova skill da Alexa! 🎈**