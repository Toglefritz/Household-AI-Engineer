---
sidebar_position: 6
---

# OpenAPI Specification

The Kiro Communication Bridge API is fully documented using the OpenAPI 3.0 specification. This machine-readable specification can be used to generate client libraries, test the API, and integrate with API development tools.

## Specification File

The complete OpenAPI specification is available at:

**[Download OpenAPI Spec](/openapi.yaml)**

## Interactive API Explorer

You can explore and test the API using the interactive Swagger UI:

The interactive API explorer is available when running the development server. For now, you can download the OpenAPI specification file and use it with your preferred API testing tool.

## Using the Specification

### Generate Client Libraries

You can use the OpenAPI specification to generate client libraries in various programming languages:

#### TypeScript/JavaScript

```bash
# Using OpenAPI Generator
npx @openapitools/openapi-generator-cli generate \
  -i http://localhost:3001/openapi.yaml \
  -g typescript-fetch \
  -o ./generated/typescript-client

# Using Swagger Codegen
swagger-codegen generate \
  -i http://localhost:3001/openapi.yaml \
  -l typescript-fetch \
  -o ./generated/typescript-client
```

#### Dart/Flutter

```bash
# Using OpenAPI Generator
npx @openapitools/openapi-generator-cli generate \
  -i http://localhost:3001/openapi.yaml \
  -g dart \
  -o ./generated/dart-client

# Additional configuration for Flutter
npx @openapitools/openapi-generator-cli generate \
  -i http://localhost:3001/openapi.yaml \
  -g dart \
  -o ./generated/flutter-client \
  --additional-properties=pubName=kiro_bridge_client,pubVersion=1.0.0
```

#### Python

```bash
# Using OpenAPI Generator
npx @openapitools/openapi-generator-cli generate \
  -i http://localhost:3001/openapi.yaml \
  -g python \
  -o ./generated/python-client
```

#### Java

```bash
# Using OpenAPI Generator
npx @openapitools/openapi-generator-cli generate \
  -i http://localhost:3001/openapi.yaml \
  -g java \
  -o ./generated/java-client
```

### API Testing

Use the specification for automated API testing:

#### Postman Collection

```bash
# Convert OpenAPI spec to Postman collection
npx openapi-to-postman \
  -s http://localhost:3001/openapi.yaml \
  -o kiro-bridge-api.postman_collection.json
```

#### Insomnia Workspace

Import the OpenAPI specification directly into Insomnia for API testing.

#### curl Commands

Generate curl commands from the specification:

```bash
# Using swagger-codegen
swagger-codegen generate \
  -i http://localhost:3001/openapi.yaml \
  -g bash \
  -o ./generated/bash-client
```

### API Validation

Validate API responses against the specification:

#### JavaScript/Node.js

```javascript
const OpenAPIValidator = require('express-openapi-validator');

app.use(
  OpenAPIValidator.middleware({
    apiSpec: './openapi.yaml',
    validateRequests: true,
    validateResponses: true,
  })
);
```

#### Python

```python
from openapi_spec_validator import validate_spec
import yaml

with open('openapi.yaml', 'r') as file:
    spec = yaml.safe_load(file)
    validate_spec(spec)
```

## Specification Highlights

### API Information

- **Title**: Kiro Communication Bridge API
- **Version**: 1.0.0
- **Base URL**: `http://localhost:3001`
- **Authentication**: Optional Bearer token (API key)

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Server health check |
| GET | `/api/kiro/status` | Get Kiro IDE status |
| POST | `/api/kiro/execute` | Execute Kiro commands |
| POST | `/api/kiro/input` | Provide user input |

### Key Features

- **Comprehensive Error Handling**: Detailed error responses with recovery guidance
- **Interactive Examples**: Multiple request/response examples for each endpoint
- **Type Safety**: Strict schema definitions for all data structures
- **Authentication Support**: Optional API key authentication
- **Validation Rules**: Input validation with clear error messages

### Schema Definitions

The specification includes complete schema definitions for:

- **Request/Response Types**: All API request and response structures
- **Error Types**: Comprehensive error handling schemas
- **Status Types**: Kiro IDE status and availability information
- **Input Types**: User input handling for interactive commands

## Integration Examples

### TypeScript Client

```typescript
import { Configuration, DefaultApi } from './generated/typescript-client';

const config = new Configuration({
  basePath: 'http://localhost:3001',
  accessToken: 'your-api-key', // Optional
});

const api = new DefaultApi(config);

// Execute command
const result = await api.executeKiroCommand({
  executeCommandRequest: {
    command: 'workbench.action.showCommands',
    args: [],
  },
});

console.log('Command result:', result);
```

### Dart/Flutter Client

```dart
import 'package:kiro_bridge_client/api.dart';

final api = DefaultApi();
api.apiClient.basePath = 'http://localhost:3001';
api.apiClient.authentication = HttpBearerAuth()..accessToken = 'your-api-key';

// Execute command
final request = ExecuteCommandRequest()
  ..command = 'workbench.action.showCommands'
  ..args = [];

final result = await api.executeKiroCommand(executeCommandRequest: request);
print('Command result: ${result.success}');
```

### Python Client

```python
import kiro_bridge_client
from kiro_bridge_client.rest import ApiException

# Configure API client
configuration = kiro_bridge_client.Configuration(
    host="http://localhost:3001"
)
configuration.access_token = 'your-api-key'  # Optional

# Create API instance
api_instance = kiro_bridge_client.DefaultApi(
    kiro_bridge_client.ApiClient(configuration)
)

# Execute command
try:
    request = kiro_bridge_client.ExecuteCommandRequest(
        command='workbench.action.showCommands',
        args=[]
    )
    result = api_instance.execute_kiro_command(execute_command_request=request)
    print(f"Command result: {result.success}")
except ApiException as e:
    print(f"Exception: {e}")
```

## Validation and Testing

### Schema Validation

The OpenAPI specification includes comprehensive validation rules:

```yaml
# Example validation rules
ExecuteCommandRequest:
  type: object
  required:
    - command
  properties:
    command:
      type: string
      minLength: 1
      description: Kiro command identifier to execute
    args:
      type: array
      items:
        type: string
      description: Optional array of command arguments
```

### Response Validation

All responses are validated against the schema:

```yaml
# Example response schema
ExecuteCommandResponse:
  type: object
  required:
    - success
    - output
    - executionTimeMs
  properties:
    success:
      type: boolean
    output:
      type: string
    executionTimeMs:
      type: number
      minimum: 0
```

### Error Handling

Comprehensive error schemas with recovery guidance:

```yaml
# Example error response
BridgeError:
  type: object
  required:
    - code
    - message
    - recoverable
    - timestamp
  properties:
    code:
      type: string
      example: COMMAND_EXECUTION_FAILED
    message:
      type: string
      example: Command execution failed
    recoverable:
      type: boolean
    timestamp:
      type: string
      format: date-time
```

## Keeping the Specification Updated

The OpenAPI specification is maintained alongside the API implementation to ensure accuracy:

1. **Automated Generation**: The specification can be generated from TypeScript interfaces
2. **Validation Testing**: API responses are validated against the specification
3. **Documentation Sync**: Changes to the API are reflected in the specification
4. **Version Control**: The specification is versioned with the API

## Tools and Resources

### OpenAPI Tools

- **[OpenAPI Generator](https://openapi-generator.tech/)** - Generate client libraries and server stubs
- **[Swagger Editor](https://editor.swagger.io/)** - Edit and validate OpenAPI specifications
- **[Swagger UI](https://swagger.io/tools/swagger-ui/)** - Interactive API documentation
- **[Postman](https://www.postman.com/)** - API testing and collection generation

### Validation Tools

- **[OpenAPI Spec Validator](https://github.com/p1c2u/openapi-spec-validator)** - Python validation library
- **[Swagger Parser](https://github.com/APIDevTools/swagger-parser)** - JavaScript validation library
- **[OpenAPI Tools](https://github.com/OpenAPITools)** - Collection of OpenAPI utilities

### IDE Extensions

- **VS Code**: OpenAPI (Swagger) Editor extension
- **IntelliJ IDEA**: OpenAPI Specifications plugin
- **Vim**: OpenAPI syntax highlighting plugins

## Next Steps

- **[API Overview](/docs/api/overview)** - Complete API reference documentation
- **[Execute Commands](/docs/api/endpoints/execute-command)** - Learn about command execution
- **[Flutter Integration](/docs/guides/flutter-setup)** - Use generated clients in Flutter
- **[Error Handling](/docs/guides/error-handling)** - Implement robust error handling