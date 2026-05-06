// src/utils/cache.js
// In-process LRU caches — no Redis required.
// Import the named export from lru-cache v11.
const { LRUCache } = require('lru-cache');

/**
 * Individual product pages.
 * Key: product UUID string.  500 entries, 60 s TTL.
 */
const productCache = new LRUCache({
  max: 500,
  ttl: 60 * 1000,
});

/**
 * Featured / new-arrivals carousel (single entry).
 * Key: 'featured'.  1 entry, 60 s TTL.
 */
const featuredCache = new LRUCache({
  max: 1,
  ttl: 60 * 1000,
});

/**
 * Collections list + individual collection-by-slug pages.
 * Key: 'all' or slug string.  100 entries, 5 min TTL.
 */
const collectionsCache = new LRUCache({
  max: 100,
  ttl: 5 * 60 * 1000,
});

module.exports = { productCache, featuredCache, collectionsCache };
