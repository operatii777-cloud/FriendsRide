import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:friendsride_app/utils/logger.dart';

/// 🧠 Intelligent Cache Service - Sistem de cache inteligent pentru operațiuni frecvente
/// 
/// Acest serviciu oferă:
/// - Cache inteligent cu TTL dinamic
/// - Cache persistence cu SharedPreferences
/// - Cache warming pentru date frecvente
/// - Cache invalidation automată
/// - Memory management și cleanup
class IntelligentCacheService {
  static final IntelligentCacheService _instance = IntelligentCacheService._internal();
  factory IntelligentCacheService() => _instance;
  IntelligentCacheService._internal();

  // Cache layers
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, DateTime> _lastAccessTimes = {};
  
  // Configuration
  static const int _maxMemoryEntries = 200;
  // static const int _maxDiskEntries = 1000; // Reserved for future disk caching
  static const Duration _cleanupInterval = Duration(minutes: 5);
  
  // State
  bool _isInitialized = false;
  Timer? _cleanupTimer;
  
  /// Initialize cache service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Start cleanup timer
      _cleanupTimer = Timer.periodic(_cleanupInterval, (_) => _performCleanup());
      
      // Load persistent cache on startup
      await _loadPersistentCache();
      
      _isInitialized = true;
      Logger.info('Service initialized', tag: 'INTELLIGENT_CACHE');
    } catch (e) {
      Logger.error('Initialization failed: $e', tag: 'INTELLIGENT_CACHE', error: e);
    }
  }
  
  /// Get cached value with intelligent retrieval
  Future<T?> get<T>(String key, {Duration? maxAge}) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Check memory cache first
      final memoryEntry = _memoryCache[key];
      if (memoryEntry != null && !_isExpired(memoryEntry, maxAge)) {
        _lastAccessTimes[key] = DateTime.now();
        Logger.debug('Memory hit for key: $key', tag: 'INTELLIGENT_CACHE');
        return memoryEntry.data as T?;
      }
      
      // Check persistent cache
      final persistentData = await _getPersistentCache(key);
      if (persistentData != null && !_isExpired(CacheEntry(persistentData, DateTime.now()), maxAge)) {
        // Move to memory cache for faster access
        await set(key, persistentData, source: 'persistent');
        _lastAccessTimes[key] = DateTime.now();
        Logger.debug('Persistent hit for key: $key', tag: 'INTELLIGENT_CACHE');
        return persistentData as T?;
      }
      
      Logger.debug('Cache miss for key: $key', tag: 'INTELLIGENT_CACHE');
      return null;
    } catch (e) {
      Logger.error('Get failed for key $key: $e', tag: 'INTELLIGENT_CACHE', error: e);
      return null;
    }
  }
  
  /// Set cached value with intelligent storage
  Future<void> set<T>(String key, T value, {
    Duration? ttl,
    String source = 'manual',
    int priority = 1,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      final entry = CacheEntry(value, DateTime.now(), ttl, priority);
      
      // Always store in memory cache
      _memoryCache[key] = entry;
      _lastAccessTimes[key] = DateTime.now();
      
      // Store in persistent cache based on priority and type
      if (_shouldPersist(key, priority)) {
        await _setPersistentCache(key, value, ttl);
      }
      
      Logger.debug('Cached $source data for key: $key (priority: $priority)', tag: 'INTELLIGENT_CACHE');
      
      // Trigger cleanup if needed
      if (_memoryCache.length > _maxMemoryEntries) {
        _performMemoryCleanup();
      }
    } catch (e) {
      Logger.error('Set failed for key $key: $e', tag: 'INTELLIGENT_CACHE', error: e);
    }
  }
  
  /// Cache with automatic TTL based on data type
  Future<void> setIntelligent<T>(String key, T value) async {
    final ttl = _getIntelligentTTL(key);
    final priority = _getIntelligentPriority(key);
    await set(key, value, ttl: ttl, priority: priority, source: 'intelligent');
  }
  
  /// Warm cache with frequently accessed data
  Future<void> warmCache(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      await setIntelligent(entry.key, entry.value);
    }
    Logger.debug('Cache warmed with ${data.length} entries', tag: 'INTELLIGENT_CACHE');
  }
  
  /// Invalidate cache entry
  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    _lastAccessTimes.remove(key);
    await _removePersistentCache(key);
    Logger.debug('Invalidated cache for key: $key', tag: 'INTELLIGENT_CACHE');
  }
  
  /// Invalidate cache pattern
  Future<void> invalidatePattern(String pattern) async {
    final keysToRemove = <String>[];
    
    for (final key in _memoryCache.keys) {
      if (key.contains(pattern)) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      await invalidate(key);
    }
    
    Logger.debug('Invalidated ${keysToRemove.length} entries matching pattern: $pattern', tag: 'INTELLIGENT_CACHE');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getStats() {
    // final now = DateTime.now(); // Reserved for future use
    final memoryEntries = _memoryCache.length;
    final expiredEntries = _memoryCache.values.where((entry) => _isExpired(entry)).length;
    
    return {
      'memory_entries': memoryEntries,
      'expired_entries': expiredEntries,
      'hit_rate': _calculateHitRate(),
      'memory_usage_estimate': memoryEntries * 0.5, // Rough estimate in KB
      'oldest_entry': _memoryCache.values.isNotEmpty 
          ? _memoryCache.values.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newest_entry': _memoryCache.values.isNotEmpty
          ? _memoryCache.values.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }
  
  /// Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    _lastAccessTimes.clear();
    await _clearPersistentCache();
    Logger.debug('All cache cleared', tag: 'INTELLIGENT_CACHE');
  }
  
  /// Dispose service
  void dispose() {
    _cleanupTimer?.cancel();
    _memoryCache.clear();
    _lastAccessTimes.clear();
    _isInitialized = false;
  }
  
  // Private methods
  
  bool _isExpired(CacheEntry entry, [Duration? maxAge]) {
    final ttl = maxAge ?? entry.ttl ?? const Duration(minutes: 5);
    return DateTime.now().difference(entry.timestamp) > ttl;
  }
  
  bool _shouldPersist(String key, int priority) {
    // Persist high priority data and certain types
    return priority >= 3 || 
           key.contains('user_profile') ||
           key.contains('static_data') ||
           key.contains('poi_data');
  }
  
  Duration _getIntelligentTTL(String key) {
    if (key.contains('user_profile')) return const Duration(hours: 1);
    if (key.contains('driver_location') || key.contains('real_time')) return const Duration(seconds: 30);
    if (key.contains('poi') || key.contains('static')) return const Duration(hours: 6);
    if (key.contains('route') || key.contains('navigation')) return const Duration(minutes: 15);
    if (key.contains('address') || key.contains('geocoding')) return const Duration(hours: 2);
    return const Duration(minutes: 10); // Default
  }
  
  int _getIntelligentPriority(String key) {
    if (key.contains('user_profile')) return 5;
    if (key.contains('driver_location')) return 4;
    if (key.contains('poi') || key.contains('static')) return 3;
    if (key.contains('route')) return 2;
    return 1; // Default
  }
  
  Future<void> _performCleanup() async {
    try {
      // Clean expired memory entries
      final expiredKeys = _memoryCache.entries
          .where((entry) => _isExpired(entry.value))
          .map((entry) => entry.key)
          .toList();
      
      for (final key in expiredKeys) {
        _memoryCache.remove(key);
        _lastAccessTimes.remove(key);
      }
      
      // Clean persistent cache
      await _cleanupPersistentCache();
      
      if (expiredKeys.isNotEmpty) {
        Logger.debug('Cleaned up ${expiredKeys.length} expired entries', tag: 'INTELLIGENT_CACHE');
      }
    } catch (e) {
      Logger.error('Cleanup failed: $e', tag: 'INTELLIGENT_CACHE', error: e);
    }
  }
  
  void _performMemoryCleanup() {
    if (_memoryCache.length <= _maxMemoryEntries) return;
    
    // Sort by last access time and priority
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) {
        final aAccess = _lastAccessTimes[a.key] ?? a.value.timestamp;
        final bAccess = _lastAccessTimes[b.key] ?? b.value.timestamp;
        
        // Sort by priority first, then by last access
        if (a.value.priority != b.value.priority) {
          return b.value.priority.compareTo(a.value.priority);
        }
        return aAccess.compareTo(bAccess);
      });
    
    // Remove oldest/lowest priority entries
    final entriesToRemove = sortedEntries.take(_memoryCache.length - _maxMemoryEntries + 10);
    for (final entry in entriesToRemove) {
      _memoryCache.remove(entry.key);
      _lastAccessTimes.remove(entry.key);
    }
    
    Logger.debug('Memory cleanup removed ${entriesToRemove.length} entries', tag: 'INTELLIGENT_CACHE');
  }
  
  double _calculateHitRate() {
    // Simplified hit rate calculation
    final totalAccesses = _lastAccessTimes.length;
    if (totalAccesses == 0) return 0.0;
    
    final recentAccesses = _lastAccessTimes.values
        .where((time) => DateTime.now().difference(time) < const Duration(hours: 1))
        .length;
    
    return (recentAccesses / totalAccesses * 100).clamp(0.0, 100.0);
  }
  
  // Persistent cache methods
  
  Future<void> _loadPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
      
      int loadedCount = 0;
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          final cacheKey = key.substring(6); // Remove 'cache_' prefix
          try {
            final decoded = jsonDecode(data);
            await set(cacheKey, decoded, source: 'persistent_load');
            loadedCount++;
          } catch (e) {
            // Remove corrupted entry
            await prefs.remove(key);
          }
        }
      }
      
      if (loadedCount > 0) {
        Logger.info('Loaded $loadedCount entries from persistent cache', tag: 'INTELLIGENT_CACHE');
      }
    } catch (e) {
      Logger.error('Failed to load persistent cache: $e', tag: 'INTELLIGENT_CACHE', error: e);
    }
  }
  
  Future<void> _setPersistentCache(String key, dynamic value, Duration? ttl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cache_$key';
      final data = jsonEncode({
        'value': value,
        'timestamp': DateTime.now().toIso8601String(),
        'ttl': ttl?.inMilliseconds,
      });
      
      await prefs.setString(cacheKey, data);
    } catch (e) {
      Logger.error('Failed to set persistent cache for $key: $e', tag: 'INTELLIGENT_CACHE', error: e);
    }
  }
  
  Future<dynamic> _getPersistentCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cache_$key';
      final data = prefs.getString(cacheKey);
      
      if (data != null) {
        final decoded = jsonDecode(data);
        final timestamp = DateTime.parse(decoded['timestamp']);
        final ttlMs = decoded['ttl'] as int?;
        final ttl = ttlMs != null ? Duration(milliseconds: ttlMs) : const Duration(minutes: 5);
        
        if (DateTime.now().difference(timestamp) <= ttl) {
          return decoded['value'];
        } else {
          // Remove expired entry
          await prefs.remove(cacheKey);
        }
      }
    } catch (e) {
      Logger.error('Failed to get persistent cache for $key: $e', tag: 'INTELLIGENT_CACHE', error: e);
    }
    
    return null;
  }
  
  Future<void> _removePersistentCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');
    } catch (e) {
      Logger.error('Failed to remove persistent cache for $key: $e', tag: 'INTELLIGENT_CACHE', error: e);
    }
  }
  
  Future<void> _cleanupPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
      
      int removedCount = 0;
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          try {
            final decoded = jsonDecode(data);
            final timestamp = DateTime.parse(decoded['timestamp']);
            final ttlMs = decoded['ttl'] as int?;
            final ttl = ttlMs != null ? Duration(milliseconds: ttlMs) : const Duration(minutes: 5);
            
            if (DateTime.now().difference(timestamp) > ttl) {
              await prefs.remove(key);
              removedCount++;
            }
          } catch (e) {
            // Remove corrupted entry
            await prefs.remove(key);
            removedCount++;
          }
        }
      }
      
      if (removedCount > 0) {
        Logger.debug('Cleaned up $removedCount expired persistent entries', tag: 'INTELLIGENT_CACHE');
      }
    } catch (e) {
      Logger.error('Failed to cleanup persistent cache: $e', tag: 'INTELLIGENT_CACHE', error: e);
    }
  }
  
  Future<void> _clearPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      Logger.debug('Cleared ${keys.length} persistent cache entries', tag: 'INTELLIGENT_CACHE');
    } catch (e) {
      Logger.error('Failed to clear persistent cache: $e', tag: 'INTELLIGENT_CACHE', error: e);
    }
  }
}

/// Cache entry with metadata
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration? ttl;
  final int priority;
  
  CacheEntry(this.data, this.timestamp, [this.ttl, this.priority = 1]);
}
