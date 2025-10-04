# Alexa Computer Control - Architecture & Workflow

## Overview

The Alexa Computer Control system allows you to remotely control your computer through voice commands via Amazon Alexa. The system consists of three main components that work together to bridge the gap between Alexa's cloud services and your local computer.

## System Components

### 1. **Local Computer Server** (`computer-server/`)
- **What it is**: A Node.js Express server that runs on your target computer
- **Purpose**: Receives commands and controls the local computer (shutdown, Wake-on-LAN, status)
- **Network**: Must be accessible from the internet (via port forwarding or ngrok)

### 2. **AWS Lambda Function** (`lambda-function/`)
- **What it is**: Cloud function that processes Alexa voice commands
- **Purpose**: Translates Alexa intents into HTTP API calls to your computer server
- **Network**: Runs in AWS cloud, makes outbound HTTP requests to your public server

### 3. **Alexa Skill** (`alexa-skill/`)
- **What it is**: Voice interface configuration for Amazon Alexa
- **Purpose**: Defines what voice commands trigger which intents
- **Network**: Managed by Amazon, sends requests to your Lambda function

## Network Architecture

```mermaid
graph TB
    subgraph "Amazon Cloud"
        A[Alexa Device] --> B[Alexa Skills Service]
        B --> C[Your AWS Lambda Function]
    end
    
    subgraph "Internet"
        C --> D[Public Internet]
    end
    
    subgraph "Your Home Network"
        D --> E[Router/Firewall<br/>Port Forward :3000]
        E --> F[Your Computer<br/>Running Express Server :3000]
    end
    
    subgraph "Target Computer (Optional)"
        F --> G[Wake-on-LAN Packet<br/>To Target Computer]
    end
    
    style A fill:#ff9999
    style C fill:#99ccff
    style F fill:#99ff99
    style G fill:#ffcc99
```

## Request-Response Workflow

### Scenario 1: "Turn On Computer" Command

```mermaid
sequenceDiagram
    participant U as User
    participant A as Alexa Device
    participant AS as Alexa Skills Service
    participant L as AWS Lambda
    participant CS as Computer Server<br/>(Your Home)
    participant TC as Target Computer

    U->>A: "Alexa, ask computer control to turn on my computer"
    A->>AS: Voice → Intent Recognition
    AS->>L: TurnOnComputerIntent JSON
    
    Note over L: Lambda processes intent
    L->>CS: GET /health (check if already on)
    CS-->>L: 200 OK or Connection Failed
    
    alt Computer already responding
        L-->>AS: "Computer is already on"
    else Computer not responding
        L->>CS: POST /wake<br/>{"mac": "00:11:22:33:44:55"}
        CS->>TC: Wake-on-LAN Magic Packet
        CS-->>L: 200 OK "Wake signal sent"
        L-->>AS: "Sent wake signal, computer should be starting"
    end
    
    AS-->>A: Response Speech (Portuguese)
    A-->>U: "Enviei um sinal para acordar seu computador"
```

### Scenario 2: "Shut Down Computer" Command

```mermaid
sequenceDiagram
    participant U as User
    participant A as Alexa Device
    participant AS as Alexa Skills Service
    participant L as AWS Lambda
    participant CS as Computer Server<br/>(Your Home)

    U->>A: "Alexa, ask computer control to shut down my computer"
    A->>AS: Voice → Intent Recognition
    AS->>L: TurnOffComputerIntent JSON
    
    L->>CS: POST /shutdown<br/>Authorization: Bearer [API_KEY]
    
    Note over CS: Schedules shutdown in 1 minute<br/>shutdown -h +1
    CS-->>L: 200 OK "Shutdown scheduled"
    L-->>AS: "Shutdown initiated, computer will shut down in 1 minute"
    AS-->>A: Response Speech (Portuguese)
    A-->>U: "Iniciei o processo de desligamento..."
```

### Scenario 3: "Check Computer Status" Command

```mermaid
sequenceDiagram
    participant U as User
    participant A as Alexa Device
    participant AS as Alexa Skills Service
    participant L as AWS Lambda
    participant CS as Computer Server<br/>(Your Home)

    U->>A: "Alexa, ask computer control for computer status"
    A->>AS: Voice → Intent Recognition
    AS->>L: ComputerStatusIntent JSON
    
    L->>CS: GET /health<br/>Authorization: Bearer [API_KEY]
    
    alt Computer is running
        CS-->>L: 200 OK<br/>{"uptime": 3600, "status": "online"}
        L-->>AS: "Computer is running for 60 minutes"
    else Computer is off/unreachable
        CS-->>L: Connection refused/timeout
        L-->>AS: "Computer appears to be offline"
    end
    
    AS-->>A: Response Speech (Portuguese)
    A-->>U: Status message
```

## Network Setup Requirements

### 1. Computer Server Setup

Your computer needs to run the Express server that listens for commands:

```mermaid
graph LR
    subgraph "Your Computer"
        A[Express Server<br/>Port 3000] --> B[System Commands<br/>shutdown, wakeonlan]
        A --> C[Network Interface<br/>Send WoL packets]
    end
    
    subgraph "Network Access"
        D[Internet] --> E[Router Port Forward<br/>External:3000 → Internal:3000]
        E --> A
    end
```

**Required Steps:**
1. Install dependencies: `cd computer-server && npm install`
2. Configure `.env` file with API key and target MAC address
3. Start server: `npm start`
4. Configure router to forward port 3000 to your computer
5. **OR** use ngrok for temporary public access: `ngrok http 3000`

### 2. Internet Accessibility Options

#### Option A: Port Forwarding (Permanent)
```mermaid
graph TB
    A[Internet] --> B[Your Router<br/>Public IP: 203.0.113.1]
    B --> C[Port Forward Rule<br/>External 3000 → Internal 3000]
    C --> D[Your Computer<br/>192.168.1.100:3000]
```

**Setup:**
1. Access your router's admin panel
2. Create port forwarding rule: External 3000 → Internal 3000 → Your Computer IP
3. Use your public IP in Lambda environment: `http://YOUR_PUBLIC_IP:3000`

#### Option B: ngrok (Development/Temporary)
```mermaid
graph TB
    A[Internet] --> B[ngrok Service<br/>https://abc123.ngrok.io]
    B --> C[ngrok Tunnel]
    C --> D[Your Computer<br/>localhost:3000]
```

**Setup:**
1. Install ngrok: `brew install ngrok`
2. Run: `ngrok http 3000`
3. Use ngrok URL in Lambda environment: `https://abc123.ngrok.io`

## Security Considerations

### Authentication Flow

```mermaid
sequenceDiagram
    participant L as Lambda Function
    participant CS as Computer Server
    
    L->>CS: HTTP Request
    Note over L,CS: Headers:<br/>Authorization: Bearer [SECRET_API_KEY]<br/>Content-Type: application/json
    
    alt Valid API Key
        CS-->>L: 200 OK + Response
    else Invalid/Missing API Key
        CS-->>L: 401 Unauthorized
    end
```

### Security Features
- **API Key Authentication**: All requests require Bearer token
- **CORS Protection**: Server configured for specific origins
- **Shutdown Safety**: 1-minute delay with cancellation option
- **Input Validation**: All endpoints validate request parameters
- **Request Logging**: All operations are logged for audit

## Environment Variables

### Lambda Function (`env.json`)
```json
{
  "ComputerControlFunction": {
    "COMPUTER_SERVER_URL": "http://your-public-ip:3000",
    "API_KEY": "your-32-char-secret-key-here",
    "COMPUTER_MAC": "00:11:22:33:44:55"
  }
}
```

### Computer Server (`.env`)
```bash
API_KEY=your-32-char-secret-key-here
COMPUTER_MAC=00:11:22:33:44:55
PORT=3000
```

## Wake-on-LAN Workflow

```mermaid
sequenceDiagram
    participant L as Lambda
    participant CS as Computer Server<br/>(Always Running)
    participant TC as Target Computer<br/>(May be Off)
    participant NIC as Network Card

    L->>CS: POST /wake {"mac": "00:11:22:33:44:55"}
    CS->>CS: Create Magic Packet<br/>(6 bytes FF + 16x MAC address)
    CS->>NIC: Send UDP broadcast<br/>Port 7 or 9
    NIC->>TC: Magic Packet → Network Card
    
    Note over TC: If WoL enabled in BIOS<br/>and network card supports it
    TC->>TC: Power On Sequence
    CS-->>L: 200 OK "Wake signal sent"
```

**Wake-on-LAN Requirements:**
1. Target computer BIOS must have WoL enabled
2. Network card must support WoL
3. Enable WoL on network interface: `sudo ethtool -s eth0 wol g`
4. Computer must be connected via Ethernet (WiFi WoL is unreliable)

## Testing Workflow

```mermaid
graph TB
    subgraph "Local Testing"
        A[Local Computer Server<br/>localhost:3000] --> B[Direct HTTP Tests<br/>curl commands]
        C[SAM CLI Local<br/>Docker Container] --> D[Lambda Function Test<br/>Cannot reach localhost]
    end
    
    subgraph "Integration Testing"
        E[Computer Server<br/>Public URL] --> F[Lambda Function<br/>AWS Cloud]
        F --> G[Alexa Skill<br/>Voice Commands]
    end
    
    style D fill:#ffcccc
    style F fill:#ccffcc
```

## Deployment Checklist

### 1. Local Setup
- [ ] Install computer server dependencies
- [ ] Configure `.env` with API key and MAC address
- [ ] Test server locally: `curl http://localhost:3000/health`
- [ ] Enable Wake-on-LAN on target computer

### 2. Network Setup
- [ ] Choose port forwarding or ngrok
- [ ] Test external access to server
- [ ] Document public URL for Lambda configuration

### 3. AWS Lambda Deployment
- [ ] Deploy Lambda function: `./deploy-lambda.sh`
- [ ] Configure environment variables in AWS Console
- [ ] Test Lambda with SAM CLI locally
- [ ] Test Lambda deployed in AWS

### 4. Alexa Skill Setup
- [ ] Create Alexa Skill in Developer Console
- [ ] Upload interaction model (Portuguese)
- [ ] Link skill to Lambda function ARN
- [ ] Test with Alexa simulator

### 5. End-to-End Testing
- [ ] Test voice commands with actual Alexa device
- [ ] Verify all intents (turn on, turn off, status, cancel)
- [ ] Test error scenarios (computer offline, network issues)

## Troubleshooting

### Common Issues

| Issue | Symptoms | Solution |
|-------|----------|----------|
| Lambda can't reach server | "Connection refused" errors | Check port forwarding/ngrok setup |
| Wake-on-LAN not working | Computer doesn't wake up | Enable WoL in BIOS and network interface |
| 401 Unauthorized | Authentication errors | Verify API_KEY matches in both systems |
| Alexa doesn't understand | Skill not responding | Check skill invocation name and intents |

### Debug Commands

```bash
# Test local server
curl http://localhost:3000/health

# Test public server access
curl http://YOUR_PUBLIC_IP:3000/health

# Test Lambda locally
./test-lambda-local.sh launch

# Test Wake-on-LAN manually
wakeonlan 00:11:22:33:44:55
```

This architecture enables secure, reliable remote computer control through natural voice commands while maintaining proper security boundaries and network isolation.