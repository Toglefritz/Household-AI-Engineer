import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

/**
 * Sidebar configuration for Kiro Communication Bridge API Documentation.
 * 
 * This configuration defines the navigation structure for the documentation site,
 * organizing content into logical sections for different user personas and use cases.
 * The structure follows a progressive disclosure pattern, starting with getting started
 * content and moving to more advanced topics.
 */
const sidebars: SidebarsConfig = {
  // Main documentation sidebar with enhanced navigation structure
  tutorialSidebar: [
    // Getting Started Section - First-time users
    {
      type: 'doc',
      id: 'intro',
      label: '🚀 Getting Started',
    },
    
    // Quick Start Guide - Immediate value
    {
      type: 'category',
      label: '⚡ Quick Start',
      collapsed: false,
      description: 'Get up and running quickly with the Kiro Communication Bridge',
      items: [
        'guides/quick-start',
        'guides/flutter-setup',
      ],
    },

    // System Overview - Understanding the architecture
    {
      type: 'category',
      label: '🏗️ Architecture & Overview',
      collapsed: true,
      description: 'Understand how the Kiro Communication Bridge works',
      items: [
        'overview/architecture',
        {
          type: 'category',
          label: 'Integration Patterns',
          collapsed: true,
          items: [
            'guides/polling-strategies',
            'guides/error-handling',
          ],
        },
      ],
    },

    // API Reference - Core documentation
    {
      type: 'category',
      label: '📚 API Reference',
      collapsed: true,
      description: 'Complete API documentation with examples and schemas',
      items: [
        'api/overview',
        'api/authentication',
        
        // Core Endpoints - Most commonly used
        {
          type: 'category',
          label: '🔗 Core Endpoints',
          collapsed: false,
          description: 'Primary API endpoints for application development',
          items: [
            'api/endpoints/execute-command',
            'api/endpoints/get-status',
            'api/endpoints/user-input',
          ],
        },
        
        // System Endpoints - Health and monitoring
        {
          type: 'category',
          label: '🔧 System Endpoints',
          collapsed: true,
          description: 'Health checks and system monitoring endpoints',
          items: [
            'api/endpoints/health-check',
          ],
        },
        
        // Data Types - Reference material
        {
          type: 'category',
          label: '📋 Data Types & Schemas',
          collapsed: true,
          description: 'TypeScript interfaces and data structures',
          items: [
            'api/types/command-execution',
            'api/types/application-metadata',
            'api/types/development-job',
            'api/types/error-types',
          ],
        },
        
        // OpenAPI Specification
        {
          type: 'doc',
          id: 'api/openapi-spec',
          label: '📄 OpenAPI Specification',
        },
      ],
    },

    // Integration Guides - Practical implementation
    {
      type: 'category',
      label: '🛠️ Integration Guides',
      collapsed: true,
      description: 'Step-by-step guides for different platforms and scenarios',
      items: [
        {
          type: 'category',
          label: 'Flutter/Dart',
          collapsed: false,
          items: [
            'guides/flutter-setup',
            'guides/error-handling',
          ],
        },
        {
          type: 'category',
          label: 'Best Practices',
          collapsed: true,
          items: [
            'guides/polling-strategies',
            'guides/troubleshooting',
          ],
        },
      ],
    },

    // Reference Material - Configuration and advanced topics
    {
      type: 'category',
      label: '📖 Reference',
      collapsed: true,
      description: 'Configuration options, troubleshooting, and advanced topics',
      items: [
        'reference/configuration',
        'guides/troubleshooting',
      ],
    },
  ],
};

export default sidebars;
