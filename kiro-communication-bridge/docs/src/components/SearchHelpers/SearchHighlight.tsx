import React from 'react';
import styles from './SearchHighlight.module.css';

/**
 * Props for the SearchHighlight component.
 */
interface SearchHighlightProps {
  /** The text content to potentially highlight */
  text: string;
  /** The search term to highlight within the text */
  searchTerm?: string;
  /** Optional additional CSS class name */
  className?: string;
}

/**
 * SearchHighlight component for highlighting search terms in text content.
 * 
 * This component automatically highlights search terms within text content,
 * improving the search experience by making it easy to see why a particular
 * result was matched.
 * 
 * @param props - Component props
 * @returns JSX element with highlighted search terms
 */
export default function SearchHighlight({ 
  text, 
  searchTerm, 
  className = '' 
}: SearchHighlightProps): JSX.Element {
  if (!searchTerm || !text) {
    return <span className={className}>{text}</span>;
  }

  // Create a case-insensitive regex to find all instances of the search term
  const regex = new RegExp(`(${searchTerm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi');
  const parts = text.split(regex);

  return (
    <span className={className}>
      {parts.map((part, index) => {
        // Check if this part matches the search term (case-insensitive)
        const isHighlight = part.toLowerCase() === searchTerm.toLowerCase();
        
        return isHighlight ? (
          <mark key={index} className={styles.highlight}>
            {part}
          </mark>
        ) : (
          <span key={index}>{part}</span>
        );
      })}
    </span>
  );
}