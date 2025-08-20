import React from 'react';
import Link from '@docusaurus/Link';
import styles from './AutoLink.module.css';

/**
 * Interface for cross-reference definitions.
 */
interface CrossReference {
  /** The term or phrase to link */
  term: string;
  /** The URL to link to */
  url: string;
  /** Optional description for tooltip */
  description?: string;
  /** Whether this is an external link */
  external?: boolean;
}

/**
 * Props for the AutoLink component.
 */
interface AutoLinkProps {
  /** The text content to process for automatic linking */
  children: string;
  /** Array of cross-reference definitions */
  crossReferences?: CrossReference[];
  /** Optional additional CSS class name */
  className?: string;
}

/**
 * Default cross-references for common API terms.
 */
const DEFAULT_CROSS_REFERENCES: CrossReference[] = [
  {
    term: 'execute command',
    url: '/docs/api/endpoints/execute-command',
    description: 'Execute Kiro commands remotely'
  },
  {
    term: 'get status',
    url: '/docs/api/endpoints/get-status',
    description: 'Get current Kiro status and available commands'
  },
  {
    term: 'user input',
    url: '/docs/api/endpoints/user-input',
    description: 'Provide user input for interactive commands'
  },
  {
    term: 'health check',
    url: '/docs/api/endpoints/health-check',
    description: 'Check API server health'
  },
  {
    term: 'authentication',
    url: '/docs/api/authentication',
    description: 'Learn about API key setup and security'
  },
  {
    term: 'error handling',
    url: '/docs/guides/error-handling',
    description: 'Best practices for robust error handling'
  },
  {
    term: 'polling strategies',
    url: '/docs/guides/polling-strategies',
    description: 'Strategies for monitoring long-running operations'
  },
  {
    term: 'Flutter integration',
    url: '/docs/guides/flutter-setup',
    description: 'Specific guidance for Flutter applications'
  },
  {
    term: 'troubleshooting',
    url: '/docs/guides/troubleshooting',
    description: 'Common issues and solutions'
  },
  {
    term: 'OpenAPI specification',
    url: '/docs/api/openapi-spec',
    description: 'Complete API specification for code generation'
  }
];

/**
 * AutoLink component for automatically creating cross-references in text.
 * 
 * This component processes text content and automatically creates links
 * to related documentation pages based on predefined cross-reference
 * definitions, improving content discoverability.
 * 
 * @param props - Component props
 * @returns JSX element with automatic cross-references
 */
export default function AutoLink({ 
  children, 
  crossReferences = DEFAULT_CROSS_REFERENCES,
  className = '' 
}: AutoLinkProps): JSX.Element {
  if (!children || typeof children !== 'string') {
    return <span className={className}>{children}</span>;
  }

  // Sort cross-references by term length (longest first) to avoid partial matches
  const sortedRefs = [...crossReferences].sort((a, b) => b.term.length - a.term.length);
  
  let processedText: (string | JSX.Element)[] = [children];

  // Process each cross-reference
  sortedRefs.forEach((ref, refIndex) => {
    const newProcessedText: (string | JSX.Element)[] = [];
    
    processedText.forEach((segment, segmentIndex) => {
      if (typeof segment === 'string') {
        // Create case-insensitive regex for the term
        const regex = new RegExp(`\\b(${ref.term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})\\b`, 'gi');
        const parts = segment.split(regex);
        
        parts.forEach((part, partIndex) => {
          if (part.toLowerCase() === ref.term.toLowerCase()) {
            // This part matches the cross-reference term
            const linkKey = `${refIndex}-${segmentIndex}-${partIndex}`;
            newProcessedText.push(
              <Link
                key={linkKey}
                to={ref.url}
                className={`${styles.autoLink} ${ref.external ? styles.externalLink : ''}`}
                title={ref.description}
                {...(ref.external && { target: '_blank', rel: 'noopener noreferrer' })}
              >
                {part}
              </Link>
            );
          } else if (part) {
            // Regular text part
            newProcessedText.push(part);
          }
        });
      } else {
        // Already processed JSX element
        newProcessedText.push(segment);
      }
    });
    
    processedText = newProcessedText;
  });

  return <span className={className}>{processedText}</span>;
}