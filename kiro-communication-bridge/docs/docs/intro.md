---
sidebar_position: 1
---

# Getting Started

Welcome to the **Kiro Communication Bridge API** documentation! This REST API enables seamless integration between Flutter frontend applications and the Kiro IDE for automated application development.

## What is the Kiro Communication Bridge?

The Kiro Communication Bridge is a VS Code extension that provides a REST API interface for communicating with Kiro IDE. It enables external applications, particularly Flutter frontends, to:

- Execute Kiro commands remotely
- Monitor command execution status
- Handle user input for interactive development sessions
- Retrieve system health and availability information

## Quick Overview

The API provides four main endpoints:

- **`POST /api/kiro/execute`** - Execute Kiro commands
- **`GET /api/kiro/status`** - Get current Kiro status and available commands
- **`POST /api/kiro/input`** - Provide user input for interactive commands
- **`GET /health`** - Check API server health

## Prerequisites

Before integrating with the Kiro Communication Bridge API, ensure you have:

- **Kiro IDE** installed and configured
- **VS Code** with the Kiro Communication Bridge extension installed
- **Network access** to the API server (default: `http://localhost:3001`)
- **API Key** (if authentication is enabled)

## Your First API Call

Here's a simple example to get you started:

```bash
# Check if the API server is running
curl http://localhost:3001/health

# Get current Kiro status
curl http://localhost:3001/api/kiro/status
```

import { SeeAlso, PageNavigation } from '@site/src/components/NavigationHelpers';

## Next Steps

<SeeAlso
  title="Get Started Quickly"
  links={[
    {
      to: '/docs/guides/quick-start',
      label: 'Quick Start Guide',
      description: 'Build your first integration in minutes',
      icon: '🚀'
    },
    {
      to: '/docs/guides/flutter-setup',
      label: 'Flutter Integration',
      description: 'Specific guidance for Flutter applications',
      icon: '📱'
    },
    {
      to: '/docs/api/overview',
      label: 'API Reference',
      description: 'Explore all available endpoints and features',
      icon: '📖'
    },
    {
      to: '/docs/overview/architecture',
      label: 'Architecture Overview',
      description: 'Understand how the system works',
      icon: '🏗️'
    }
  ]}
/>

<SeeAlso
  title="Need Help?"
  links={[
    {
      to: '/docs/guides/troubleshooting',
      label: 'Troubleshooting Guide',
      description: 'Common issues and solutions',
      icon: '🐛'
    },
    {
      to: 'https://github.com/Toglefritz/Household-AI-Engineer/discussions',
      label: 'GitHub Discussions',
      description: 'Community support and questions',
      icon: '💬'
    },
    {
      to: 'https://github.com/Toglefritz/Household-AI-Engineer/issues',
      label: 'GitHub Issues',
      description: 'Report bugs or request features',
      icon: '🚨'
    }
  ]}
/>

<PageNavigation
  next={{
    to: '/docs/guides/quick-start',
    label: 'Quick Start Guide',
    description: 'Build your first integration with the API'
  }}
/>
