import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'Kiro Communication Bridge API',
  tagline: 'REST API Documentation for Flutter Integration',
  favicon: 'img/favicon.ico',

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // Set the production url of your site here
  url: 'https://toglefritz.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/Household-AI-Engineer/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'Toglefritz', // Usually your GitHub org/user name.
  projectName: 'Household-AI-Engineer', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: '/docs',
          editUrl:
            'https://github.com/Toglefritz/Household-AI-Engineer/tree/main/kiro-communication-bridge/docs/',
          // Enhanced navigation features
          breadcrumbs: true,
          showLastUpdateAuthor: true,
          showLastUpdateTime: true,
          // Enable doc versioning for future API versions
          includeCurrentVersion: true,
          // Add navigation helpers
          sidebarCollapsible: true,
          sidebarCollapsed: true,
        },
        blog: false, // Disable blog functionality
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  plugins: [
    [
      '@easyops-cn/docusaurus-search-local',
      {
        // Whether to index docs pages
        indexDocs: true,
        
        // Whether to index blog pages
        indexBlog: false,
        
        // Language of your documentation
        language: ['en'],
        
        // Highlight matching terms in search results
        highlightSearchTermsOnTargetPage: true,
      },
    ],
  ],

  themeConfig: {
    // Replace with your project's social card
    image: 'img/docusaurus-social-card.jpg',
    
    // Search configuration (using local search plugin instead of Algolia)
    // algolia: {
    //   // Algolia configuration can be added here when ready
    //   // For now, we're using the local search plugin
    // },
    
    // Enhanced navigation bar with better organization
    navbar: {
      title: 'Kiro Bridge API',
      logo: {
        alt: 'Kiro Bridge Logo',
        src: 'img/logo.svg',
      },
      hideOnScroll: false,
      items: [
        // Primary navigation - organized by user journey
        {
          to: '/docs/intro',
          label: '🚀 Getting Started',
          position: 'left',
          activeBaseRegex: '/docs/(intro|guides/quick-start|guides/flutter-setup)',
        },
        {
          type: 'dropdown',
          label: '📚 API Reference',
          position: 'left',
          items: [
            {
              to: '/docs/api/overview',
              label: 'API Overview',
            },
            {
              to: '/docs/api/authentication',
              label: 'Authentication',
            },
            {
              type: 'html',
              value: '<hr style="margin: 0.3rem 0;">',
            },
            {
              to: '/docs/api/endpoints/execute-command',
              label: 'Execute Command',
            },
            {
              to: '/docs/api/endpoints/get-status',
              label: 'Get Status',
            },
            {
              to: '/docs/api/endpoints/user-input',
              label: 'User Input',
            },
            {
              type: 'html',
              value: '<hr style="margin: 0.3rem 0;">',
            },
            {
              to: '/docs/api/openapi-spec',
              label: 'OpenAPI Spec',
            },
          ],
        },
        {
          type: 'dropdown',
          label: '🛠️ Guides',
          position: 'left',
          items: [
            {
              to: '/docs/guides/quick-start',
              label: 'Quick Start',
            },
            {
              to: '/docs/guides/flutter-setup',
              label: 'Flutter Integration',
            },
            {
              type: 'html',
              value: '<hr style="margin: 0.3rem 0;">',
            },
            {
              to: '/docs/guides/error-handling',
              label: 'Error Handling',
            },
            {
              to: '/docs/guides/polling-strategies',
              label: 'Polling Strategies',
            },
            {
              to: '/docs/guides/troubleshooting',
              label: 'Troubleshooting',
            },
          ],
        },
        {
          to: '/docs/overview/architecture',
          label: '🏗️ Architecture',
          position: 'left',
        },
        
        // Secondary navigation
        {
          type: 'search',
          position: 'right',
        },
        {
          href: 'https://github.com/Toglefritz/Household-AI-Engineer',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    
    // Enhanced table of contents
    tableOfContents: {
      minHeadingLevel: 2,
      maxHeadingLevel: 4,
    },
    
    // Add docs sidebar configuration
    docs: {
      sidebar: {
        hideable: true,
        autoCollapseCategories: true,
      },
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Getting Started',
              to: '/docs/intro',
            },
            {
              label: 'API Reference',
              to: '/docs/api/overview',
            },
            {
              label: 'Guides',
              to: '/docs/guides/quick-start',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'GitHub Issues',
              href: 'https://github.com/Toglefritz/Household-AI-Engineer/issues',
            },
            {
              label: 'GitHub Discussions',
              href: 'https://github.com/Toglefritz/Household-AI-Engineer/discussions',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/Toglefritz/Household-AI-Engineer',
            },
            {
              label: 'VS Code Extension',
              href: 'https://marketplace.visualstudio.com/items?itemName=household-ai-engineer.kiro-communication-bridge',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Dwellware. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['dart', 'bash', 'json', 'typescript'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
