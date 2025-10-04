# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**Alexa Computer Control** is a voice-controlled system that allows remote computer management through Amazon Alexa. The system consists of three main components:

1. **Local Node.js Server** (`computer-server/`) - Runs on the target computer, handles Wake-on-LAN, shutdown commands, and status checks
2. **AWS Lambda Function** (`lambda-function/`) - Processes Alexa voice commands and communicates with the local server
3. **Alexa Skill Configuration** (`alexa-skill/`) - Defines voice interaction models in Portuguese and English

## Architecture

```
Alexa Device → Alexa Skills Service → AWS Lambda Function → Local Express Server → Computer Actions
```

The system supports:
- Remote power on via Wake-on-LAN
- Safe shutdown with 1-minute delay
- Cancel shutdown capability
- Computer status monitoring
- Bilingual support (Portuguese primary, English secondary)

## Development Commands

### Local Server (computer-server/)
```bash
# Install dependencies
cd computer-server && npm install

# Start development server
cd computer-server && npm start

# Start with custom port
cd computer-server && PORT=8080 npm start

# Development with auto-reload (if nodemon is installed globally)
cd computer-server && npm run dev
```

### AWS Lambda Function (lambda-function/)
```bash
# Install dependencies
cd lambda-function && npm install

# Deploy to AWS (requires AWS CLI configured)
./deploy-lambda.sh

# Manual package creation
cd lambda-function && zip -r function.zip . -x "*.git*" "node_modules/.cache/*" "*.md"
```

### Testing and Utilities
```bash
# Test local server endpoints
./test-server.sh

# Test Lambda function locally with AWS SAM CLI
./test-lambda-local.sh

# Test specific Lambda intents
./test-lambda-local.sh launch
./test-lambda-local.sh turn-on
./test-lambda-local.sh status

# Get network information for setup
./get-network-info.sh

# Test Wake-on-LAN locally (requires wakeonlan package)
wakeonlan [MAC_ADDRESS]
```

## Configuration

### Environment Setup
1. Copy `computer-server/.env.example` to `computer-server/.env`
2. Configure required variables:
   - `API_KEY`: Strong authentication key (32+ characters)
   - `COMPUTER_MAC`: Target computer's MAC address
   - `PORT`: Server port (default: 3000)

### Network Requirements
- Wake-on-LAN must be enabled: `sudo ethtool -s [interface] wol g`
- Server must be accessible from internet (port forwarding or ngrok)
- AWS Lambda needs three environment variables: `COMPUTER_SERVER_URL`, `API_KEY`, `COMPUTER_MAC`

## Key Implementation Details

### Security Features
- Bearer token authentication for all protected endpoints
- CORS configuration for cross-origin requests
- Input validation on all endpoints
- 1-minute safety delay on shutdown commands
- Audit logging for all operations

### API Endpoints
| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/` | GET | No | Server status |
| `/health` | GET | No | Health check with uptime |
| `/shutdown` | POST | Yes | Initiate shutdown with delay |
| `/cancel-shutdown` | POST | Yes | Cancel pending shutdown |
| `/wake` | POST | Yes | Send Wake-on-LAN packet |

### Voice Commands (Portuguese - Primary)
- **Power On**: "Alexa, peça para o controle do computador ligar meu computador"
- **Power Off**: "Alexa, peça para o controle do computador desligar meu computador"
- **Status**: "Alexa, peça para o controle do computador verificar status do computador"
- **Cancel**: "Alexa, peça para o controle do computador cancelar shutdown"

### Lambda Function Structure
- Uses Alexa Skills Kit SDK v2
- Async/await pattern for HTTP calls to local server
- Error handling with fallback responses in Portuguese
- Axios for HTTP requests with proper authentication headers

## Project Structure

```
alexa-computer-control/
├── computer-server/          # Express.js local server
│   ├── server.js            # Main server with API endpoints
│   ├── package.json         # Dependencies: express, cors, dotenv, wake_on_lan
│   └── .env.example         # Environment template
├── lambda-function/          # AWS Lambda Alexa skill handler
│   ├── index.js             # Alexa intent handlers
│   └── package.json         # Dependencies: ask-sdk-core, ask-sdk-model, axios
├── alexa-skill/             # Alexa skill configuration
│   ├── interactionModel-pt-BR.json  # Portuguese voice intents
│   ├── interactionModel.json        # English voice intents
│   └── skill-manifest.json          # Skill metadata
├── deploy-lambda.sh         # Automated AWS deployment
├── test-server.sh          # Server testing script
├── get-network-info.sh     # Network configuration helper
├── QUICK_START.md          # Step-by-step setup guide (Portuguese)
├── CONFIG_SUMMARY.md       # Configuration summary
└── README.md              # Complete documentation
```

## Local Lambda Testing

The project includes AWS SAM CLI integration for local Lambda testing:

### Prerequisites
- AWS SAM CLI installed: `brew install aws-sam-cli`
- Docker running (required by SAM CLI)

### Testing Commands
```bash
# Test all intents
./test-lambda-local.sh

# Test specific intent
./test-lambda-local.sh launch    # Test skill launch
./test-lambda-local.sh turn-on   # Test turn on computer
./test-lambda-local.sh status    # Test status check
```

### Configuration
- `template.yaml`: SAM template defining Lambda function
- `env.json`: Environment variables for local testing
- `test-events/`: Sample Alexa request events

### SAM CLI Commands
```bash
# Direct SAM invoke with custom event
sam local invoke ComputerControlFunction -e test-events/launch-request.json

# Debug mode (port 5858)
sam local invoke -d 5858 ComputerControlFunction -e test-events/turn-on-intent.json

# Build and test
sam build && sam local invoke ComputerControlFunction
```

## Development Workflow

### Setting Up for Development
1. Run `./get-network-info.sh` to identify network configuration
2. Configure `.env` file with proper MAC address and API key
3. Start local server: `cd computer-server && npm start`
4. Test endpoints: `./test-server.sh`
5. For internet exposure, use ngrok: `ngrok http 3000`

### Deployment Process
1. Configure AWS CLI credentials
2. Run `./deploy-lambda.sh` for automated deployment
3. Set Lambda environment variables via AWS Console
4. Create Alexa skill using interaction model JSON
5. Connect skill to Lambda function ARN

### Testing Strategy
- Local server testing via `test-server.sh` script
- Local Lambda testing via `test-lambda-local.sh` script (AWS SAM CLI)
- Authentication testing (401 responses for unauthorized requests)
- Wake-on-LAN packet testing
- Alexa skill testing via Developer Console simulator

## Important Notes

- The system exposes computer control to the internet - security is critical
- Wake-on-LAN requires BIOS support and network card configuration
- Shutdown commands have a 1-minute safety delay to prevent accidents
- Portuguese is the primary language with full voice command support
- The system assumes Ubuntu/Linux for shutdown commands (`shutdown -h +1`)
- All protected endpoints require Bearer token authentication

## Common Issues

- **WoL not working**: Check `ethtool [interface] | grep Wake-on` and BIOS settings
- **Lambda timeouts**: Verify COMPUTER_SERVER_URL accessibility from AWS
- **Alexa doesn't respond**: Confirm skill invocation name "controle do computador"
- **Server unreachable**: Check firewall rules and port forwarding configuration