# Alexa Computer Control / Controle do Computador via Alexa

Controle seu computador remotamente usando comandos de voz da Alexa. Ligue, desligue, verifique o status e cancele desligamentos com comandos simples em português ou inglês.

Control your computer remotely using Alexa voice commands. Turn on, turn off, check status, and cancel shutdowns with simple commands in Portuguese or English.

## 🇧🇷 Português

### Funcionalidades

- **Ligar o computador**: Wake-on-LAN para acordar o computador remotamente
- **Desligar o computador**: Desligamento seguro com delay de 1 minuto
- **Cancelar desligamento**: Cancele um desligamento programado
- **Verificar status**: Verifique se o computador está ligado e há quanto tempo
- **Comandos em português**: Suporte completo para português brasileiro
- **Comandos em inglês**: Também aceita comandos em inglês

### Comandos de Voz Suportados

#### Ligar o Computador
- "Alexa, peça para o controle do computador ligar meu computador"
- "Alexa, peça para o controle do computador acordar o computador"
- "Alexa, peça para o controle do computador iniciar o computador"

#### Desligar o Computador
- "Alexa, peça para o controle do computador desligar meu computador"
- "Alexa, peça para o controle do computador fazer shutdown do computador"
- "Alexa, peça para o controle do computador apagar o computador"

#### Verificar Status
- "Alexa, peça para o controle do computador verificar status do computador"
- "Alexa, peça para o controle do computador como está o computador"

#### Cancelar Desligamento
- "Alexa, peça para o controle do computador cancelar shutdown"
- "Alexa, peça para o controle do computador não desligar"

### Pré-requisitos

1. **Conta AWS** com acesso ao Lambda e Alexa Skills Kit
2. **Computador com Ubuntu/Linux** para executar o servidor local
3. **Wake-on-LAN habilitado** no seu computador
4. **Node.js 18+** instalado

### Configuração Inicial

#### 1. Clone e Configure o Projeto

```bash
cd alexa-computer-control
```

#### 2. Configure o Servidor Local

```bash
cd computer-server

# Copie e configure as variáveis de ambiente
cp .env.example .env

# Edite o arquivo .env e configure:
# - API_KEY: Uma chave secreta forte (use um gerador de senhas)
# - COMPUTER_MAC: O endereço MAC da sua placa de rede
```

Para encontrar seu endereço MAC:
```bash
ip link show
# ou
ifconfig
```

#### 3. Habilite Wake-on-LAN

```bash
# Instale ethtool se não tiver
sudo apt install ethtool

# Substitua 'eth0' pela sua interface de rede
sudo ethtool -s eth0 wol g

# Para tornar permanente, adicione ao /etc/rc.local:
echo "ethtool -s eth0 wol g" | sudo tee -a /etc/rc.local
```

#### 4. Configure a Função Lambda

```bash
cd ../lambda-function

# Configure as variáveis de ambiente no AWS Lambda:
# - COMPUTER_SERVER_URL: http://SEU-IP-EXTERNO:3000
# - API_KEY: A mesma chave do arquivo .env
# - COMPUTER_MAC: O endereço MAC do seu computador
```

### Instalação

#### 1. Execute o Servidor Local

```bash
cd computer-server
npm start
```

O servidor ficará disponível na porta 3000.

#### 2. Exponha o Servidor para a Internet

Você precisa expor seu servidor local para que a AWS Lambda possa acessá-lo. Opções:

**Opção A: Port Forwarding no Roteador**
- Configure port forwarding da porta 3000 para o IP interno do seu computador
- Use seu IP externo no COMPUTER_SERVER_URL

**Opção B: Tunnel (ngrok, etc.)**
```bash
# Exemplo com ngrok
ngrok http 3000
# Use a URL fornecida no COMPUTER_SERVER_URL
```

**Opção C: VPN/VPS**
- Configure um túnel VPN para seu computador doméstico

#### 3. Crie a Função Lambda

1. Acesse o [AWS Lambda Console](https://console.aws.amazon.com/lambda/)
2. Clique em "Create function"
3. Escolha "Author from scratch"
4. Nome: `computer-control-alexa-skill`
5. Runtime: `Node.js 18.x`
6. Crie a função

7. Faça upload do código:
```bash
cd lambda-function
zip -r function.zip .
```

8. Configure as variáveis de ambiente:
   - `COMPUTER_SERVER_URL`: URL do seu servidor (ex: `http://seu-ip:3000`)
   - `API_KEY`: Sua chave secreta
   - `COMPUTER_MAC`: Endereço MAC do seu computador

#### 4. Configure a Skill da Alexa

1. Acesse o [Alexa Developer Console](https://developer.amazon.com/alexa/console/ask)
2. Clique em "Create Skill"
3. Nome: "Controle do Computador"
4. Idioma primário: "Portuguese (BR)"
5. Modelo: "Custom"
6. Método de hospedagem: "Provision your own"

7. Configure o Interaction Model:
   - Copie o conteúdo de `alexa-skill/interactionModel-pt-BR.json`
   - Cole no JSON Editor da skill

8. Configure o Endpoint:
   - Tipo: AWS Lambda ARN
   - ARN: O ARN da sua função Lambda
   - Região: Sua região da AWS

9. Teste a skill no simulador

### Segurança

⚠️ **IMPORTANTE**: Este projeto expõe controles do seu computador para a internet. Siga estas práticas:

1. **Use uma chave API forte** (mínimo 32 caracteres aleatórios)
2. **Configure firewall** para permitir apenas tráfego necessário
3. **Monitore logs** do servidor para atividade suspeita
4. **Use HTTPS** se possível (configure certificado SSL)
5. **Considere VPN** em vez de exposição direta

### Troubleshooting

**Alexa não responde:**
- Verifique se a skill está habilitada na sua conta
- Confirme o nome de invocação: "controle do computador"

**Erro de conexão:**
- Verifique se o servidor está rodando
- Confirme se a URL está correta
- Teste a conexão: `curl http://seu-servidor:3000/health`

**Wake-on-LAN não funciona:**
- Confirme se WoL está habilitado no BIOS
- Verifique o endereço MAC
- Teste localmente: `wakeonlan 00:11:22:33:44:55`

**Shutdown não funciona:**
- Verifique permissões do usuário para comando shutdown
- Teste localmente: `shutdown -h +1`

---

## 🇺🇸 English

### Features

- **Turn on computer**: Wake-on-LAN to wake up computer remotely
- **Turn off computer**: Safe shutdown with 1-minute delay
- **Cancel shutdown**: Cancel a scheduled shutdown
- **Check status**: Check if computer is on and for how long
- **Portuguese commands**: Full support for Brazilian Portuguese
- **English commands**: Also accepts English commands

### Supported Voice Commands

#### Turn On Computer
- "Alexa, ask Computer Control to turn on my computer"
- "Alexa, ask Computer Control to wake up the computer"
- "Alexa, ask Computer Control to start the computer"

#### Turn Off Computer
- "Alexa, ask Computer Control to turn off my computer"
- "Alexa, ask Computer Control to shutdown the computer"
- "Alexa, ask Computer Control to power down the computer"

#### Check Status
- "Alexa, ask Computer Control to check computer status"
- "Alexa, ask Computer Control how is the computer"

#### Cancel Shutdown
- "Alexa, ask Computer Control to cancel shutdown"
- "Alexa, ask Computer Control don't shutdown"

### Prerequisites

1. **AWS Account** with Lambda and Alexa Skills Kit access
2. **Ubuntu/Linux computer** to run the local server
3. **Wake-on-LAN enabled** on your computer
4. **Node.js 18+** installed

### Setup Instructions

Follow the Portuguese instructions above, using the English interaction model (`interactionModel.json`) and adjusting the skill name and invocation to "Computer Control".

### License

MIT License - see LICENSE file for details.

### Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

### Support

For issues and questions, please create an issue on GitHub.