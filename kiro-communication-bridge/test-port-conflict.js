/**
 * Test script to simulate port conflicts for the Kiro Communication Bridge.
 * 
 * This script creates servers on the same ports that the extension uses
 * to test the port conflict handling functionality.
 */

const express = require('express');
const { createServer } = require('http');
const { WebSocketServer } = require('ws');

const API_PORT = 3001;
const WS_PORT = 3002;

let apiServer;
let wsServer;
let httpServer;

function startTestServers() {
  console.log('Starting test servers to simulate port conflicts...');
  
  // Start API server on port 3001
  const app = express();
  app.get('/health', (req, res) => {
    res.json({ status: 'test-server', message: 'This is a test server blocking the port' });
  });
  
  apiServer = app.listen(API_PORT, () => {
    console.log(`✅ Test API server started on port ${API_PORT}`);
  });
  
  apiServer.on('error', (error) => {
    console.error(`❌ Test API server error:`, error.message);
  });
  
  // Start WebSocket server on port 3002
  httpServer = createServer();
  wsServer = new WebSocketServer({ server: httpServer });
  
  wsServer.on('connection', (ws) => {
    console.log('Test WebSocket client connected');
    ws.send(JSON.stringify({ type: 'test', message: 'This is a test WebSocket server' }));
  });
  
  httpServer.listen(WS_PORT, () => {
    console.log(`✅ Test WebSocket server started on port ${WS_PORT}`);
  });
  
  httpServer.on('error', (error) => {
    console.error(`❌ Test WebSocket server error:`, error.message);
  });
  
  console.log('\n🔥 Port conflict simulation active!');
  console.log('Now try activating the Kiro Communication Bridge extension.');
  console.log('The extension should detect the port conflicts and offer to resolve them.');
  console.log('\nPress Ctrl+C to stop the test servers.\n');
}

function stopTestServers() {
  console.log('\nStopping test servers...');
  
  if (apiServer) {
    apiServer.close(() => {
      console.log('✅ Test API server stopped');
    });
  }
  
  if (wsServer) {
    wsServer.close(() => {
      console.log('✅ Test WebSocket server stopped');
    });
  }
  
  if (httpServer) {
    httpServer.close(() => {
      console.log('✅ Test HTTP server stopped');
    });
  }
  
  console.log('Test servers stopped. You can now try activating the extension again.');
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  stopTestServers();
  process.exit(0);
});

process.on('SIGTERM', () => {
  stopTestServers();
  process.exit(0);
});

// Start the test servers
startTestServers();