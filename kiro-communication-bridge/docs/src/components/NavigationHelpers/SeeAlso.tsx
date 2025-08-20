import React from 'react';
import Link from '@docusaurus/Link';
import styles from './SeeAlso.module.css';

/**
 * Interface for related content links.
 */
interface RelatedLink {
  /** The URL or document path to link to */
  to: string;
  /** Display text for the link */
  label: string;
  /** Optional description of what the link contains */
  description?: string;
  /** Optional icon or emoji to display */
  icon?: string;
}

/**
 * Props for the SeeAlso component.
 */
interface SeeAlsoProps {
  /** Array of related links to display */
  links: RelatedLink[];
  /** Optional title for the section (defaults to "See Also") */
  title?: string;
  /** Optional additional CSS class name */
  className?: string;
}

/**
 * SeeAlso component for displaying related content links.
 * 
 * This component creates a visually appealing section that helps users
 * discover related documentation, improving navigation and content discovery.
 * 
 * @param props - Component props
 * @returns JSX element containing the related links section
 */
export default function SeeAlso({ 
  links, 
  title = 'See Also', 
  className = '' 
}: SeeAlsoProps): JSX.Element {
  if (!links || links.length === 0) {
    return <></>;
  }

  return (
    <div className={`${styles.seeAlso} ${className}`}>
      <h3 className={styles.title}>{title}</h3>
      <div className={styles.linkGrid}>
        {links.map((link, index) => (
          <Link
            key={index}
            to={link.to}
            className={styles.linkCard}
          >
            <div className={styles.linkHeader}>
              {link.icon && (
                <span className={styles.linkIcon}>{link.icon}</span>
              )}
              <span className={styles.linkLabel}>{link.label}</span>
            </div>
            {link.description && (
              <p className={styles.linkDescription}>{link.description}</p>
            )}
          </Link>
        ))}
      </div>
    </div>
  );
}