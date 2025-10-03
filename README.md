# 🎤 Alexa Computer Control

> Control your computer remotely using Alexa voice commands with full Portuguese language support!

**Alexa Computer Control** is a complete voice-controlled solution that allows you to remotely manage your computer using Amazon Alexa. Built with Node.js, AWS Lambda, and the Alexa Skills Kit, it provides secure Wake-on-LAN functionality, safe shutdowns, status monitoring, and full Portuguese language support.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)](https://nodejs.org/)
[![AWS Lambda](https://img.shields.io/badge/AWS-Lambda-orange)](https://aws.amazon.com/lambda/)
[![Alexa Skills Kit](https://img.shields.io/badge/Alexa-Skills%20Kit-blue)](https://developer.amazon.com/alexa/console/ask)

## ✨ Features

- 🔌 **Remote Power On**: Wake-on-LAN support for remotely turning on your computer
- 🛑 **Safe Shutdown**: Secure shutdown with 1-minute safety delay
- ❌ **Cancel Shutdown**: Ability to cancel scheduled shutdowns
- 📊 **Status Monitoring**: Check if your computer is online and running time
- 🇧🇷 **Portuguese Support**: Full Brazilian Portuguese voice command support
- 🇺🇸 **English Support**: Also accepts English voice commands
- 🔐 **Secure Authentication**: API key-based security for all endpoints
- 📱 **Multi-platform**: Works with any Alexa-enabled device
- 🏠 **Home Automation**: Perfect for smart home setups
- ☁️ **Cloud-based**: Uses AWS Lambda for reliable cloud execution

## 🎯 Voice Commands

### Portuguese Commands (Primary)
- **Turn On**: *"Alexa, peça para o controle do computador ligar meu computador"*
- **Turn Off**: *"Alexa, peça para o controle do computador desligar meu computador"*
- **Check Status**: *"Alexa, peça para o controle do computador verificar status do computador"*
- **Cancel Shutdown**: *"Alexa, peça para o controle do computador cancelar shutdown"*

### English Commands (Secondary)
- **Turn On**: *"Alexa, ask Computer Control to turn on my computer"*
- **Turn Off**: *"Alexa, ask Computer Control to turn off my computer"*
- **Check Status**: *"Alexa, ask Computer Control to check computer status"*
- **Cancel Shutdown**: *"Alexa, ask Computer Control to cancel shutdown"*

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐    ┌──────────────┐
│  Alexa Device   │───▶│ Alexa Skills │───▶│  AWS Lambda     │───▶│ Your Computer│
│                 │    │   Service    │    │   Function      │    │   (Local)    │
└─────────────────┘    └──────────────┘    └─────────────────┘    └──────────────┘
                                                      │                      │
                                                      │                      ▼
                                                      │            ┌──────────────┐
                                                      │            │    Express   │
                                                      └───────────▶│    Server    │
                                                                   │ (Node.js API)│
                                                                   └──────────────┘
```

## 🚀 Quick Start

### Prerequisites

1. **AWS Account** with Lambda and Alexa Skills Kit access
2. **Ubuntu/Linux Computer** to run the local server
3. **Wake-on-LAN enabled** on your computer
4. **Node.js 18+** installed

### 1. Clone the Repository

```bash
git clone https://github.com/kidush/alexa-computer-control.git
cd alexa-computer-control
```

### 2. Get Network Information

```bash
./get-network-info.sh
```

This script will help you find your network interface and MAC address.

### 3. Configure Local Server

```bash
cd computer-server

# Copy and configure environment variables
cp .env.example .env
# Edit .env file with:
# - API_KEY: A strong secret key
# - COMPUTER_MAC: Your network card MAC address
```

### 4. Enable Wake-on-LAN

```bash
# Install ethtool if not available
sudo apt install ethtool wakeonlan

# Enable Wake-on-LAN (replace 'eth0' with your interface)
sudo ethtool -s eth0 wol g

# To make it permanent, add to /etc/rc.local:
echo "ethtool -s eth0 wol g" | sudo tee -a /etc/rc.local
```

### 5. Install Dependencies

```bash
# Install server dependencies
cd computer-server
npm install

# Install Lambda function dependencies
cd ../lambda-function
npm install
```

## 📦 Installation

### 1. Start Local Server

```bash
cd computer-server
npm start
```

The server will be available on port 3000.

### 2. Test Local Server

```bash
# In another terminal
./test-server.sh
```

### 3. Expose Server to Internet

You need to expose your local server so AWS Lambda can access it:

**Option A: ngrok (Recommended for testing)**
```bash
# Install ngrok: https://ngrok.com/download
ngrok http 3000
# Note the public URL provided (e.g., https://abc123.ngrok.io)
```

**Option B: Router Port Forwarding**
- Configure port forwarding: port 3000 → your computer's internal IP
- Use your external IP in COMPUTER_SERVER_URL

**Option C: VPN/VPS**
- Set up a VPN tunnel to your home computer

### 4. Deploy AWS Lambda Function

**Automated Deployment:**
```bash
# Configure AWS CLI first
aws configure

# Deploy using our script
./deploy-lambda.sh
```

**Manual Deployment:**
1. Go to [AWS Lambda Console](https://console.aws.amazon.com/lambda/)
2. Click "Create function"
3. Choose "Author from scratch"
4. Name: `computer-control-alexa-skill`
5. Runtime: `Node.js 18.x`
6. Create the function

7. Upload the code:
```bash
cd lambda-function
zip -r function.zip .
# Upload function.zip via AWS Console
```

8. Configure environment variables:
   - `COMPUTER_SERVER_URL`: Your server's public URL
   - `API_KEY`: Your secret API key
   - `COMPUTER_MAC`: Your computer's MAC address

### 5. Create Alexa Skill

1. Go to [Alexa Developer Console](https://developer.amazon.com/alexa/console/ask)
2. Click "Create Skill"
3. Name: "Controle do Computador" (or "Computer Control")
4. Primary language: "Portuguese (BR)" (or "English (US)")
5. Model: "Custom"
6. Hosting method: "Provision your own"

7. Configure Interaction Model:
   - Copy content from `alexa-skill/interactionModel-pt-BR.json`
   - Paste in the JSON Editor

8. Configure Endpoint:
   - Type: AWS Lambda ARN
   - ARN: Your Lambda function ARN
   - Region: Your AWS region

9. Test the skill in the simulator

## 🔒 Security

⚠️ **IMPORTANT**: This project exposes computer controls to the internet. Follow these security practices:

- ✅ **Strong API Key**: Use a minimum 32-character random API key
- 🔥 **Firewall Configuration**: Allow only necessary traffic
- 🔍 **Monitor Logs**: Watch server logs for suspicious activity
- 🔒 **HTTPS Preferred**: Configure SSL certificate if possible
- 🚪 **Consider VPN**: Use VPN instead of direct exposure when possible
- ⏰ **Safety Delays**: 1-minute shutdown delay for safety
- 🎯 **Endpoint Protection**: Authentication required for all critical endpoints

### Security Features Implemented

- ✅ API key authentication
- ✅ CORS protection
- ✅ Input validation
- ✅ Audit logging
- ✅ Safe shutdown delays
- ✅ Error handling

## 🚑 Troubleshooting

### Alexa Doesn't Respond
- Verify the skill is enabled in your Alexa account
- Confirm invocation name: "controle do computador" (PT) or "computer control" (EN)
- Check skill status in Alexa Developer Console

### Connection Errors
```bash
# Check if server is running
curl http://localhost:3000/health

# Check server logs
cd computer-server && npm start

# Test with your API key
curl -H "Authorization: Bearer your-api-key" http://localhost:3000/health
```

### Wake-on-LAN Not Working
```bash
# Check WoL status
sudo ethtool eth0 | grep Wake-on

# Enable WoL
sudo ethtool -s eth0 wol g

# Test locally
wakeonlan 00:11:22:33:44:55

# Check BIOS settings for WoL support
```

### Shutdown Issues
```bash
# Test shutdown command locally
sudo shutdown -h +1

# Check user permissions
sudo visudo
# Add: username ALL=(ALL) NOPASSWD: /sbin/shutdown
```

### Lambda Function Errors
- Check CloudWatch logs for detailed error messages
- Verify environment variables are set correctly
- Test server URL accessibility from external networks

## 📚 Project Structure

```
alexa-computer-control/
├── computer-server/          # Local Node.js server
│   ├── server.js             # Express server with API endpoints
│   ├── package.json          # Server dependencies
│   └── .env.example          # Environment configuration template
├── lambda-function/          # AWS Lambda function
│   ├── index.js              # Alexa skill handler
│   └── package.json          # Lambda dependencies
├── alexa-skill/             # Alexa skill configuration
│   ├── interactionModel-pt-BR.json   # Portuguese interaction model
│   ├── interactionModel.json         # English interaction model
│   └── skill-manifest.json           # Skill manifest
├── deploy-lambda.sh         # Automated AWS deployment script
├── test-server.sh          # Server testing script
├── get-network-info.sh     # Network information helper
├── QUICK_START.md          # Quick setup guide
└── README.md               # This file
```

## 🎨 API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/` | GET | ❌ | Server status |
| `/health` | GET | ❌ | Health check |
| `/shutdown` | POST | ✅ | Shutdown computer |
| `/cancel-shutdown` | POST | ✅ | Cancel shutdown |
| `/wake` | POST | ✅ | Wake-on-LAN |

## 🔌 Available Scripts

```bash
# Get network information
./get-network-info.sh

# Test local server
./test-server.sh

# Deploy to AWS Lambda
./deploy-lambda.sh

# Start local server
cd computer-server && npm start

# Start with custom port
cd computer-server && PORT=8080 npm start
```

## 🌍 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and questions:

- 🐛 **Issues**: [GitHub Issues](https://github.com/kidush/alexa-computer-control/issues)
- 📚 **Documentation**: Check the `QUICK_START.md` for detailed setup
- ✨ **Features**: Request new features via GitHub Issues

## 🎆 Acknowledgments

- Amazon Alexa Skills Kit for voice interface capabilities
- AWS Lambda for serverless computing
- Node.js and Express.js for the local server
- Wake-on-LAN protocol for remote power management

---

**🎉 Happy voice controlling! Now you can manage your computer from anywhere in the world with just your voice!**
