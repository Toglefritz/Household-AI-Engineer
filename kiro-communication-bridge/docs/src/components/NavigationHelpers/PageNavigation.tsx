import React from 'react';
import Link from '@docusaurus/Link';
import styles from './PageNavigation.module.css';

/**
 * Interface for navigation items.
 */
interface NavigationItem {
  /** The URL or document path to link to */
  to: string;
  /** Display text for the navigation item */
  label: string;
  /** Optional description */
  description?: string;
}

/**
 * Props for the PageNavigation component.
 */
interface PageNavigationProps {
  /** Previous page navigation item */
  previous?: NavigationItem;
  /** Next page navigation item */
  next?: NavigationItem;
  /** Optional additional CSS class name */
  className?: string;
}

/**
 * PageNavigation component for displaying previous/next page links.
 * 
 * This component provides intuitive navigation between related pages,
 * improving the user experience by making it easy to move through
 * sequential content or related topics.
 * 
 * @param props - Component props
 * @returns JSX element containing the page navigation
 */
export default function PageNavigation({ 
  previous, 
  next, 
  className = '' 
}: PageNavigationProps): JSX.Element {
  if (!previous && !next) {
    return <></>;
  }

  return (
    <nav className={`${styles.pageNavigation} ${className}`}>
      <div className={styles.navigationGrid}>
        {previous && (
          <Link to={previous.to} className={`${styles.navLink} ${styles.navPrevious}`}>
            <div className={styles.navDirection}>
              <span className={styles.navArrow}>←</span>
              <span className={styles.navLabel}>Previous</span>
            </div>
            <div className={styles.navContent}>
              <div className={styles.navTitle}>{previous.label}</div>
              {previous.description && (
                <div className={styles.navDescription}>{previous.description}</div>
              )}
            </div>
          </Link>
        )}
        
        {next && (
          <Link to={next.to} className={`${styles.navLink} ${styles.navNext}`}>
            <div className={styles.navDirection}>
              <span className={styles.navLabel}>Next</span>
              <span className={styles.navArrow}>→</span>
            </div>
            <div className={styles.navContent}>
              <div className={styles.navTitle}>{next.label}</div>
              {next.description && (
                <div className={styles.navDescription}>{next.description}</div>
              )}
            </div>
          </Link>
        )}
      </div>
    </nav>
  );
}