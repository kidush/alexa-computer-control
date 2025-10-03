const express = require('express');
const wol = require('wake_on_lan');
const cors = require('cors');
const { exec } = require('child_process');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const API_KEY = process.env.API_KEY || 'your-secret-api-key-here';

// Middleware
app.use(cors());
app.use(express.json());

// Authentication middleware
const authenticate = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || authHeader !== `Bearer ${API_KEY}`) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
};

// Routes
app.get('/', (req, res) => {
    res.json({ 
        message: 'Computer Control Server is running',
        status: 'online',
        timestamp: new Date().toISOString()
    });
});

// Shutdown computer
app.post('/shutdown', authenticate, (req, res) => {
    console.log('Shutdown request received');
    
    // For Ubuntu/Linux systems
    exec('shutdown -h +1', (error, stdout, stderr) => {
        if (error) {
            console.error(`Shutdown error: ${error}`);
            return res.status(500).json({ 
                error: 'Failed to shutdown computer',
                message: error.message 
            });
        }
        
        console.log('Shutdown command executed successfully');
        res.json({ 
            message: 'Computer will shutdown in 1 minute',
            status: 'success',
            timestamp: new Date().toISOString()
        });
    });
});

// Cancel shutdown (in case user changes mind)
app.post('/cancel-shutdown', authenticate, (req, res) => {
    console.log('Cancel shutdown request received');
    
    exec('shutdown -c', (error, stdout, stderr) => {
        if (error) {
            console.error(`Cancel shutdown error: ${error}`);
            return res.status(500).json({ 
                error: 'Failed to cancel shutdown',
                message: error.message 
            });
        }
        
        console.log('Shutdown cancelled successfully');
        res.json({ 
            message: 'Shutdown cancelled',
            status: 'success',
            timestamp: new Date().toISOString()
        });
    });
});

// Wake-on-LAN endpoint (for remote wake up)
app.post('/wake', authenticate, (req, res) => {
    const { mac, broadcast } = req.body;
    
    if (!mac) {
        return res.status(400).json({ 
            error: 'MAC address is required',
            message: 'Please provide the MAC address of the computer to wake up'
        });
    }
    
    console.log(`Wake-on-LAN request for MAC: ${mac}`);
    
    wol.wake(mac, { address: broadcast || '255.255.255.255' }, (error) => {
        if (error) {
            console.error(`Wake-on-LAN error: ${error}`);
            return res.status(500).json({ 
                error: 'Failed to send wake-on-LAN packet',
                message: error.message 
            });
        }
        
        console.log('Wake-on-LAN packet sent successfully');
        res.json({ 
            message: 'Wake-on-LAN packet sent successfully',
            status: 'success',
            mac: mac,
            timestamp: new Date().toISOString()
        });
    });
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
    });
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Server error:', error);
    res.status(500).json({ 
        error: 'Internal server error',
        message: error.message 
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ 
        error: 'Not found',
        message: 'The requested endpoint does not exist'
    });
});

app.listen(PORT, () => {
    console.log(`Computer Control Server running on port ${PORT}`);
    console.log(`Make sure to set your API_KEY environment variable for security`);
    console.log(`Current API_KEY: ${API_KEY === 'your-secret-api-key-here' ? 'DEFAULT (CHANGE THIS!)' : 'CUSTOM'}`);
});