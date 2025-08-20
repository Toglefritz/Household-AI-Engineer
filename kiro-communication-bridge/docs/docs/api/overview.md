---
sidebar_position: 1
---

# API Overview

The Kiro Communication Bridge provides a RESTful HTTP API that enables external applications to interact with Kiro IDE through a VS Code extension. This API is designed specifically for integration with Flutter frontend applications but can be used by any HTTP client.

## Base URL

The API server runs locally and is accessible at:

```
http://localhost:3001
```

The default port can be configured through VS Code settings (`kiroOrchestration.api.port`).

## API Design Principles

### RESTful Architecture
The API follows REST principles with:
- Resource-based URLs
- Standard HTTP methods (GET, POST)
- JSON request/response bodies
- Appropriate HTTP status codes

### Stateless Communication
Each API request is independent and contains all necessary information. The server does not maintain client session state.

### Error Handling
Consistent error response format across all endpoints with:
- Standard HTTP status codes
- Structured error messages
- Recovery guidance where applicable

## Authentication

Authentication is optional and can be enabled through configuration:

```json
{
  "kiroOrchestration.api.apiKey": "your-secret-key"
}
```

When enabled, include the API key in requests:

```bash
# Header-based authentication
curl -H "Authorization: Bearer your-secret-key" http://localhost:3001/api/kiro/status

# Query parameter authentication
curl "http://localhost:3001/api/kiro/status?apiKey=your-secret-key"
```

## Content Types

### Request Content-Type
All POST requests must include:
```
Content-Type: application/json
```

### Response Content-Type
All responses return:
```
Content-Type: application/json
```

## Rate Limiting

The API implements basic rate limiting to prevent abuse:
- Default timeout: 30 seconds per request
- Maximum concurrent commands: 3
- Request body size limit: 10MB

## CORS Support

Cross-Origin Resource Sharing (CORS) is enabled by default to support web-based clients. This can be disabled through configuration if needed.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Server health check |
| POST | `/api/kiro/execute` | Execute Kiro commands |
| GET | `/api/kiro/status` | Get Kiro status and available commands |
| POST | `/api/kiro/input` | Provide user input for interactive commands |

## Response Format

### Success Response
```json
{
  "success": true,
  "data": {
    // Endpoint-specific response data
  },
  "timestamp": "2025-01-19T10:30:00Z"
}
```

### Error Response
```json
{
  "code": "ERROR_CODE",
  "message": "Human-readable error description",
  "recoverable": true,
  "timestamp": "2025-01-19T10:30:00Z"
}
```

## Status Codes

| Code | Description | Usage |
|------|-------------|-------|
| 200 | OK | Successful GET requests |
| 201 | Created | Successful POST requests |
| 400 | Bad Request | Invalid request data |
| 401 | Unauthorized | Missing or invalid API key |
| 408 | Request Timeout | Request exceeded timeout limit |
| 422 | Unprocessable Entity | Command execution failed |
| 500 | Internal Server Error | Unexpected server error |
| 503 | Service Unavailable | Kiro IDE not available |

## Error Codes

The API uses specific error codes for programmatic error handling:

| Code | Description | Recoverable |
|------|-------------|-------------|
| `VALIDATION_FAILED` | Request validation failed | No |
| `KIRO_UNAVAILABLE` | Kiro IDE not responding | Yes |
| `OPERATION_TIMEOUT` | Operation timed out | Yes |
| `COMMAND_EXECUTION_FAILED` | Command execution failed | Yes |
| `CONFIGURATION_ERROR` | Server configuration error | No |

import { SeeAlso, PageNavigation } from '@site/src/components/NavigationHelpers';

## Next Steps

<SeeAlso
  title="Essential API Resources"
  links={[
    {
      to: '/docs/api/authentication',
      label: 'Authentication',
      description: 'Learn about API key setup and security',
      icon: '🔐'
    },
    {
      to: '/docs/api/endpoints/execute-command',
      label: 'Execute Commands',
      description: 'Run Kiro commands remotely',
      icon: '⚡'
    },
    {
      to: '/docs/api/endpoints/get-status',
      label: 'Status Monitoring',
      description: 'Monitor Kiro availability and health',
      icon: '📊'
    },
    {
      to: '/docs/guides/error-handling',
      label: 'Error Handling',
      description: 'Best practices for robust error handling',
      icon: '🛠️'
    },
    {
      to: '/docs/guides/quick-start',
      label: 'Quick Start Guide',
      description: 'Get up and running in minutes',
      icon: '🚀'
    },
    {
      to: '/docs/api/openapi-spec',
      label: 'OpenAPI Specification',
      description: 'Complete API specification for code generation',
      icon: '📄'
    }
  ]}
/>

<PageNavigation
  next={{
    to: '/docs/api/authentication',
    label: 'Authentication',
    description: 'Learn how to secure your API requests'
  }}
/>