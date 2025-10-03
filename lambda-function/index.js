const Alexa = require('ask-sdk-core');
const axios = require('axios');

// Configuration - Replace with your computer server URL and API key
const COMPUTER_SERVER_URL = process.env.COMPUTER_SERVER_URL || 'http://your-computer-ip:3000';
const API_KEY = process.env.API_KEY || 'your-secret-api-key-here';
const COMPUTER_MAC = process.env.COMPUTER_MAC || '00:11:22:33:44:55';

// Helper function to make API calls to computer server
const callComputerServer = async (endpoint, method = 'POST', data = {}) => {
    try {
        const config = {
            method,
            url: `${COMPUTER_SERVER_URL}${endpoint}`,
            headers: {
                'Authorization': `Bearer ${API_KEY}`,
                'Content-Type': 'application/json'
            }
        };
        
        if (method === 'POST' && Object.keys(data).length > 0) {
            config.data = data;
        }
        
        const response = await axios(config);
        return { success: true, data: response.data };
    } catch (error) {
        console.error('Computer server call failed:', error.message);
        return { 
            success: false, 
            error: error.response?.data?.message || error.message 
        };
    }
};

// Launch Request Handler
const LaunchRequestHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'LaunchRequest';
    },
    handle(handlerInput) {
        const speakOutput = 'Bem-vindo ao Controle do Computador! Você pode pedir para eu ligar ou desligar seu computador. O que gostaria de fazer?';
        
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .reprompt(speakOutput)
            .getResponse();
    }
};

// Turn On Computer Intent Handler
const TurnOnComputerIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && Alexa.getIntentName(handlerInput.requestEnvelope) === 'TurnOnComputerIntent';
    },
    async handle(handlerInput) {
        let speakOutput;
        
        try {
            // First check if computer is already on
            const healthCheck = await callComputerServer('/health', 'GET');
            
            if (healthCheck.success) {
                speakOutput = 'Seu computador já está ligado e respondendo.';
            } else {
                // Send Wake-on-LAN packet
                const wakeResult = await callComputerServer('/wake', 'POST', { 
                    mac: COMPUTER_MAC 
                });
                
                if (wakeResult.success) {
                    speakOutput = 'Enviei um sinal para acordar seu computador. Ele deve estar ligando agora.';
                } else {
                    speakOutput = `Não consegui ligar seu computador. ${wakeResult.error}`;
                }
            }
        } catch (error) {
            console.error('Turn on computer error:', error);
            speakOutput = 'Desculpe, encontrei um erro ao tentar ligar seu computador.';
        }
        
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .getResponse();
    }
};

// Turn Off Computer Intent Handler
const TurnOffComputerIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && Alexa.getIntentName(handlerInput.requestEnvelope) === 'TurnOffComputerIntent';
    },
    async handle(handlerInput) {
        let speakOutput;
        
        try {
            const shutdownResult = await callComputerServer('/shutdown');
            
            if (shutdownResult.success) {
                speakOutput = 'Iniciei o processo de desligamento. Seu computador vai desligar em um minuto.';
            } else {
                speakOutput = `Não consegui desligar seu computador. ${shutdownResult.error}`;
            }
        } catch (error) {
            console.error('Turn off computer error:', error);
            speakOutput = 'Desculpe, encontrei um erro ao tentar desligar seu computador.';
        }
        
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .getResponse();
    }
};

// Cancel Shutdown Intent Handler
const CancelShutdownIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && Alexa.getIntentName(handlerInput.requestEnvelope) === 'CancelShutdownIntent';
    },
    async handle(handlerInput) {
        let speakOutput;
        
        try {
            const cancelResult = await callComputerServer('/cancel-shutdown');
            
            if (cancelResult.success) {
                speakOutput = 'O desligamento foi cancelado. Seu computador vai continuar ligado.';
            } else {
                speakOutput = `Não consegui cancelar o desligamento. ${cancelResult.error}`;
            }
        } catch (error) {
            console.error('Cancel shutdown error:', error);
            speakOutput = 'Desculpe, encontrei um erro ao tentar cancelar o desligamento.';
        }
        
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .getResponse();
    }
};

// Computer Status Intent Handler
const ComputerStatusIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && Alexa.getIntentName(handlerInput.requestEnvelope) === 'ComputerStatusIntent';
    },
    async handle(handlerInput) {
        let speakOutput;
        
        try {
            const healthCheck = await callComputerServer('/health', 'GET');
            
            if (healthCheck.success) {
                const uptime = Math.floor(healthCheck.data.uptime / 60); // Convert to minutes
                speakOutput = `Seu computador está ligado e funcionando há ${uptime} minutos.`;
            } else {
                speakOutput = 'Seu computador parece estar desligado ou não está respondendo.';
            }
        } catch (error) {
            console.error('Computer status error:', error);
            speakOutput = 'Não consegui verificar o status do seu computador no momento.';
        }
        
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .getResponse();
    }
};

// Help Intent Handler
const HelpIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && Alexa.getIntentName(handlerInput.requestEnvelope) === 'AMAZON.HelpIntent';
    },
    handle(handlerInput) {
        const speakOutput = 'Você pode me pedir para ligar ou desligar seu computador, verificar o status, ou cancelar um desligamento. Tente falar "ligar meu computador" ou "desligar meu computador".';
        
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .reprompt(speakOutput)
            .getResponse();
    }
};

// Cancel and Stop Intent Handler
const CancelAndStopIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && (Alexa.getIntentName(handlerInput.requestEnvelope) === 'AMAZON.CancelIntent'
                || Alexa.getIntentName(handlerInput.requestEnvelope) === 'AMAZON.StopIntent');
    },
    handle(handlerInput) {
        const speakOutput = 'Tchau!';
        
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .getResponse();
    }
};

// Fallback Intent Handler
const FallbackIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && Alexa.getIntentName(handlerInput.requestEnvelope) === 'AMAZON.FallbackIntent';
    },
    handle(handlerInput) {
        const speakOutput = 'Desculpe, não entendi isso. Você pode me pedir para ligar ou desligar seu computador, ou verificar o status.';
        
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .reprompt(speakOutput)
            .getResponse();
    }
};

// Session Ended Request Handler
const SessionEndedRequestHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'SessionEndedRequest';
    },
    handle(handlerInput) {
        console.log(`~~~~ Session ended: ${JSON.stringify(handlerInput.requestEnvelope)}`);
        return handlerInput.responseBuilder.getResponse();
    }
};

// Intent Reflector Handler - for testing
const IntentReflectorHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest';
    },
    handle(handlerInput) {
        const intentName = Alexa.getIntentName(handlerInput.requestEnvelope);
        const speakOutput = `You just triggered ${intentName}`;
        
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .getResponse();
    }
};

// Error Handler
const ErrorHandler = {
    canHandle() {
        return true;
    },
    handle(handlerInput, error) {
        const speakOutput = 'Desculpe, tive problemas para fazer o que você pediu. Tente novamente.';
        console.log(`~~~~ Error handled: ${JSON.stringify(error)}`);
        
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .reprompt(speakOutput)
            .getResponse();
    }
};

// Lambda handler
exports.handler = Alexa.SkillBuilders.custom()
    .addRequestHandlers(
        LaunchRequestHandler,
        TurnOnComputerIntentHandler,
        TurnOffComputerIntentHandler,
        CancelShutdownIntentHandler,
        ComputerStatusIntentHandler,
        HelpIntentHandler,
        CancelAndStopIntentHandler,
        FallbackIntentHandler,
        SessionEndedRequestHandler,
        IntentReflectorHandler
    )
    .addErrorHandlers(ErrorHandler)
    .withCustomUserAgent('alexa-computer-control/v1.0')
    .lambda();