/**
 * Port utility functions for the Kiro Communication Bridge.
 * 
 * This module provides utilities for checking port availability,
 * finding free ports, and managing port conflicts.
 */

import { createServer } from 'net';

/**
 * Checks if a specific port is available for use.
 * 
 * @param port - Port number to check
 * @param host - Host address to check (defaults to 'localhost')
 * @returns Promise that resolves to true if port is available, false otherwise
 */
export async function isPortAvailable(port: number, host: string = 'localhost'): Promise<boolean> {
  return new Promise((resolve) => {
    const server = createServer();
    
    server.listen(port, host, () => {
      server.close(() => {
        resolve(true);
      });
    });
    
    server.on('error', () => {
      resolve(false);
    });
  });
}

/**
 * Finds the next available port starting from a given port number.
 * 
 * @param startPort - Port number to start checking from
 * @param maxPort - Maximum port number to check (defaults to startPort + 100)
 * @param host - Host address to check (defaults to 'localhost')
 * @returns Promise that resolves to an available port number, or null if none found
 */
export async function findAvailablePort(
  startPort: number, 
  maxPort: number = startPort + 100,
  host: string = 'localhost'
): Promise<number | null> {
  for (let port = startPort; port <= maxPort; port++) {
    if (await isPortAvailable(port, host)) {
      return port;
    }
  }
  return null;
}

/**
 * Checks if multiple ports are available.
 * 
 * @param ports - Array of port numbers to check
 * @param host - Host address to check (defaults to 'localhost')
 * @returns Promise that resolves to an object mapping port numbers to availability status
 */
export async function checkPortsAvailability(
  ports: number[], 
  host: string = 'localhost'
): Promise<Record<number, boolean>> {
  const results: Record<number, boolean> = {};
  
  const checks = ports.map(async (port) => {
    const available = await isPortAvailable(port, host);
    results[port] = available;
  });
  
  await Promise.all(checks);
  return results;
}

/**
 * Gets information about what process is using a specific port.
 * 
 * This function uses platform-specific commands to identify the process
 * using a given port.
 * 
 * @param port - Port number to check
 * @param host - Host address to check (defaults to 'localhost')
 * @returns Promise that resolves to process information or null if no process found
 */
export async function getProcessUsingPort(
  port: number, 
  host: string = 'localhost'
): Promise<{ pid: number; name?: string; command?: string } | null> {
  const { spawn } = await import('child_process');
  const os = await import('os');
  
  return new Promise((resolve) => {
    if (os.platform() === 'win32') {
      // Windows: Use netstat to find the process
      const netstat = spawn('netstat', ['-ano']);
      let output = '';
      
      netstat.stdout.on('data', (data) => {
        output += data.toString();
      });
      
      netstat.on('close', (code) => {
        if (code !== 0) {
          resolve(null);
          return;
        }
        
        const lines = output.split('\n');
        const portPattern = new RegExp(`${host}:${port}\\s+.*?LISTENING\\s+(\\d+)`);
        
        for (const line of lines) {
          const match = line.match(portPattern);
          if (match) {
            const pid = parseInt(match[1], 10);
            resolve({ pid });
            return;
          }
        }
        
        resolve(null);
      });
      
      netstat.on('error', () => resolve(null));
    } else {
      // Unix-like systems: Use lsof to find the process
      const lsof = spawn('lsof', ['-ti', `tcp:${port}`]);
      let output = '';
      
      lsof.stdout.on('data', (data) => {
        output += data.toString();
      });
      
      lsof.on('close', (code) => {
        if (code !== 0) {
          resolve(null);
          return;
        }
        
        const pids = output.trim().split('\n').filter(pid => pid.length > 0);
        if (pids.length > 0) {
          const pid = parseInt(pids[0], 10);
          resolve({ pid });
        } else {
          resolve(null);
        }
      });
      
      lsof.on('error', () => resolve(null));
    }
  });
}

/**
 * Validates that a port number is within the valid range.
 * 
 * @param port - Port number to validate
 * @returns True if port is valid, false otherwise
 */
export function isValidPort(port: number): boolean {
  return Number.isInteger(port) && port >= 1 && port <= 65535;
}

/**
 * Gets a list of commonly used ports that should be avoided.
 * 
 * @returns Array of port numbers that are commonly reserved
 */
export function getReservedPorts(): number[] {
  return [
    21,   // FTP
    22,   // SSH
    23,   // Telnet
    25,   // SMTP
    53,   // DNS
    80,   // HTTP
    110,  // POP3
    143,  // IMAP
    443,  // HTTPS
    993,  // IMAPS
    995,  // POP3S
    3000, // Common dev server
    3306, // MySQL
    5432, // PostgreSQL
    6379, // Redis
    8080, // Common HTTP alternate
    8443, // Common HTTPS alternate
  ];
}