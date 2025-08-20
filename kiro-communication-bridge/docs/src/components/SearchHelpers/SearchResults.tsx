import React from 'react';
import Link from '@docusaurus/Link';
import SearchHighlight from './SearchHighlight';
import styles from './SearchResults.module.css';

/**
 * Interface for search result items.
 */
interface SearchResult {
  /** Unique identifier for the result */
  id: string;
  /** Title of the page or section */
  title: string;
  /** URL to the result page */
  url: string;
  /** Brief excerpt or description */
  excerpt?: string;
  /** Section or category the result belongs to */
  section?: string;
  /** Relevance score (0-1) */
  score?: number;
}

/**
 * Props for the SearchResults component.
 */
interface SearchResultsProps {
  /** Array of search results to display */
  results: SearchResult[];
  /** The search query that generated these results */
  query: string;
  /** Whether search is currently loading */
  loading?: boolean;
  /** Optional message when no results are found */
  noResultsMessage?: string;
  /** Optional additional CSS class name */
  className?: string;
}

/**
 * SearchResults component for displaying search results with highlighting.
 * 
 * This component provides a clean, accessible interface for displaying
 * search results with proper highlighting of search terms and clear
 * navigation to result pages.
 * 
 * @param props - Component props
 * @returns JSX element containing the search results
 */
export default function SearchResults({ 
  results, 
  query, 
  loading = false,
  noResultsMessage = 'No results found',
  className = '' 
}: SearchResultsProps): JSX.Element {
  if (loading) {
    return (
      <div className={`${styles.searchResults} ${className}`}>
        <div className={styles.loading}>
          <div className={styles.loadingSpinner}></div>
          <span>Searching...</span>
        </div>
      </div>
    );
  }

  if (!results || results.length === 0) {
    return (
      <div className={`${styles.searchResults} ${className}`}>
        <div className={styles.noResults}>
          <p>{noResultsMessage}</p>
          {query && (
            <p className={styles.noResultsHint}>
              Try adjusting your search terms or check the spelling.
            </p>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className={`${styles.searchResults} ${className}`}>
      <div className={styles.resultsHeader}>
        <span className={styles.resultsCount}>
          {results.length} result{results.length !== 1 ? 's' : ''} for "{query}"
        </span>
      </div>
      
      <div className={styles.resultsList}>
        {results.map((result) => (
          <Link
            key={result.id}
            to={result.url}
            className={styles.resultItem}
          >
            <div className={styles.resultHeader}>
              <h3 className={styles.resultTitle}>
                <SearchHighlight text={result.title} searchTerm={query} />
              </h3>
              {result.section && (
                <span className={styles.resultSection}>{result.section}</span>
              )}
            </div>
            
            {result.excerpt && (
              <p className={styles.resultExcerpt}>
                <SearchHighlight text={result.excerpt} searchTerm={query} />
              </p>
            )}
            
            <div className={styles.resultMeta}>
              <span className={styles.resultUrl}>{result.url}</span>
              {result.score && (
                <span className={styles.resultScore}>
                  {Math.round(result.score * 100)}% match
                </span>
              )}
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}