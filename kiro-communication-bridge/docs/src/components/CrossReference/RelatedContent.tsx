import React from 'react';
import Link from '@docusaurus/Link';
import { TagSystem } from './index';
import styles from './RelatedContent.module.css';

/**
 * Interface for related content items.
 */
interface RelatedItem {
  /** Unique identifier for the item */
  id: string;
  /** Title of the related content */
  title: string;
  /** URL to the related content */
  url: string;
  /** Brief description of the content */
  description?: string;
  /** Type of content (guide, reference, example, etc.) */
  type: 'guide' | 'reference' | 'example' | 'tutorial' | 'api' | 'concept';
  /** Relevance score (0-1) for sorting */
  relevance?: number;
  /** Tags associated with this content */
  tags?: string[];
}

/**
 * Props for the RelatedContent component.
 */
interface RelatedContentProps {
  /** Array of related content items */
  items: RelatedItem[];
  /** Current page URL to exclude from related items */
  currentUrl?: string;
  /** Maximum number of items to display */
  maxItems?: number;
  /** Optional title for the section */
  title?: string;
  /** Whether to show content type badges */
  showTypes?: boolean;
  /** Whether to show tags */
  showTags?: boolean;
  /** Optional additional CSS class name */
  className?: string;
}

/**
 * RelatedContent component for displaying contextually relevant content.
 * 
 * This component analyzes the current page context and displays related
 * documentation, guides, and examples that might be helpful to users,
 * improving content discoverability and user experience.
 * 
 * @param props - Component props
 * @returns JSX element containing related content links
 */
export default function RelatedContent({ 
  items, 
  currentUrl,
  maxItems = 6,
  title = 'Related Content',
  showTypes = true,
  showTags = false,
  className = '' 
}: RelatedContentProps): JSX.Element {
  // Filter out current page and sort by relevance
  const filteredItems = items
    .filter(item => item.url !== currentUrl)
    .sort((a, b) => (b.relevance || 0) - (a.relevance || 0))
    .slice(0, maxItems);

  if (filteredItems.length === 0) {
    return <></>;
  }

  const getTypeIcon = (type: RelatedItem['type']): string => {
    switch (type) {
      case 'guide': return '📖';
      case 'reference': return '📚';
      case 'example': return '💡';
      case 'tutorial': return '🎓';
      case 'api': return '🔗';
      case 'concept': return '🧠';
      default: return '📄';
    }
  };

  const getTypeColor = (type: RelatedItem['type']): string => {
    switch (type) {
      case 'guide': return 'primary';
      case 'reference': return 'secondary';
      case 'example': return 'success';
      case 'tutorial': return 'info';
      case 'api': return 'warning';
      case 'concept': return 'danger';
      default: return 'secondary';
    }
  };

  return (
    <div className={`${styles.relatedContent} ${className}`}>
      <h3 className={styles.title}>{title}</h3>
      
      <div className={styles.itemGrid}>
        {filteredItems.map((item) => (
          <Link
            key={item.id}
            to={item.url}
            className={styles.relatedItem}
          >
            <div className={styles.itemHeader}>
              <div className={styles.itemTitle}>
                {showTypes && (
                  <span className={styles.typeIcon}>
                    {getTypeIcon(item.type)}
                  </span>
                )}
                {item.title}
              </div>
              
              {showTypes && (
                <span className={`${styles.typeBadge} ${styles[`type--${getTypeColor(item.type)}`]}`}>
                  {item.type}
                </span>
              )}
            </div>
            
            {item.description && (
              <p className={styles.itemDescription}>{item.description}</p>
            )}
            
            {showTags && item.tags && item.tags.length > 0 && (
              <TagSystem
                tags={item.tags.map(tag => ({ id: tag, label: tag }))}
                title=""
                clickable={false}
                className={styles.itemTags}
              />
            )}
            
            {item.relevance && (
              <div className={styles.relevanceIndicator}>
                <div 
                  className={styles.relevanceBar}
                  style={{ width: `${item.relevance * 100}%` }}
                />
              </div>
            )}
          </Link>
        ))}
      </div>
    </div>
  );
}