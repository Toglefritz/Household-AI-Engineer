import React from 'react';
import Link from '@docusaurus/Link';
import styles from './TagSystem.module.css';

/**
 * Interface for tag definitions.
 */
interface Tag {
  /** Unique identifier for the tag */
  id: string;
  /** Display name for the tag */
  label: string;
  /** Optional description of what this tag represents */
  description?: string;
  /** Color theme for the tag */
  color?: 'primary' | 'secondary' | 'success' | 'info' | 'warning' | 'danger';
  /** Optional URL to a page about this tag */
  url?: string;
}

/**
 * Props for the TagSystem component.
 */
interface TagSystemProps {
  /** Array of tags to display */
  tags: Tag[];
  /** Optional title for the tag section */
  title?: string;
  /** Whether tags should be clickable links */
  clickable?: boolean;
  /** Optional additional CSS class name */
  className?: string;
}

/**
 * TagSystem component for displaying content tags and categories.
 * 
 * This component provides a flexible tagging system that helps organize
 * and categorize content, making it easier for users to find related
 * information and understand content relationships.
 * 
 * @param props - Component props
 * @returns JSX element containing the tag system
 */
export default function TagSystem({ 
  tags, 
  title = 'Tags',
  clickable = true,
  className = '' 
}: TagSystemProps): JSX.Element {
  if (!tags || tags.length === 0) {
    return <></>;
  }

  const renderTag = (tag: Tag) => {
    const tagElement = (
      <span 
        className={`${styles.tag} ${styles[`tag--${tag.color || 'primary'}`]}`}
        title={tag.description}
      >
        {tag.label}
      </span>
    );

    if (clickable && tag.url) {
      return (
        <Link key={tag.id} to={tag.url} className={styles.tagLink}>
          {tagElement}
        </Link>
      );
    }

    return <span key={tag.id}>{tagElement}</span>;
  };

  return (
    <div className={`${styles.tagSystem} ${className}`}>
      {title && <h4 className={styles.tagTitle}>{title}</h4>}
      <div className={styles.tagContainer}>
        {tags.map(renderTag)}
      </div>
    </div>
  );
}