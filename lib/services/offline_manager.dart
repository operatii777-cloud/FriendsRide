import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/services/firestore_service.dart';
// Mapbox offline prefetch (aliased to avoid name conflicts)
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:friendsride_app/widgets/app_drawer.dart';

/// 🔄 OFFLINE CAPABILITIES: Advanced offline management system
/// 
/// Features:
/// - Offline data caching and synchronization
/// - Pending operations queue
/// - Offline route caching
/// - Background sync when connectivity returns
/// - Conflict resolution for data synchronization
class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  // OFFLINE CAPABILITIES: Core services
  Database? _database;
  final Connectivity _connectivity = Connectivity();
  final FirestoreService _firestoreService = FirestoreService();
  
  // OFFLINE CAPABILITIES: State management
  bool _isOnline = true;
  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _mapTilesPrefetched = false;
  bool _prefetchScheduled = false;
  static const bool emergencyPerformanceMode = true; // emergency: disable heavy prefetch

  // OFFLINE CAPABILITIES: Sync configuration
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _retryDelay = Duration(seconds: 30);
  static const int _maxRetries = 3;

  static const Duration _cacheExpiry = Duration(days: 7);
  static const Duration _searchCacheTtl = Duration(minutes: 20);
  
  // OFFLINE CAPABILITIES: Subscriptions and timers
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  Timer? _retryTimer;
  Timer? _prefetchTimer;
  
  // OFFLINE CAPABILITIES: Sync queues
  final List<PendingOperation> _pendingOperations = [];
  final Map<String, CachedData> _dataCache = {};
  final List<String> _conflictedItems = [];
  
  // OFFLINE CAPABILITIES: Callbacks
  Function(bool)? onConnectivityChanged;
  Function(SyncStatus)? onSyncStatusChanged;
  Function(List<String>)? onConflictsDetected;
  
  /// 🚀 OFFLINE CAPABILITIES: Initialize offline manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔄 [OFFLINE_MANAGER] Initializing offline capabilities...');
      
      // Initialize local database
      await _initializeDatabase();
      
      // Setup connectivity monitoring
      await _setupConnectivityMonitoring();
      
      // Load pending operations
      await _loadPendingOperations();
      
      // Load cached data
      await _loadCachedData();
      
      // Start periodic sync
      _startPeriodicSync();
      
      _isInitialized = true;
      
      debugPrint('✅ [OFFLINE_MANAGER] Offline capabilities initialized successfully');
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to initialize: $e');
      rethrow;
    }

    // Prefetch adaptiv (Wi‑Fi + Low Data Mode off) după o întârziere scurtă
    if (!emergencyPerformanceMode) {
      _schedulePrefetchIfEligible();
    } else {
      debugPrint('🚫 [OFFLINE_MANAGER] Prefetch disabled (emergency performance mode)');
    }
  }

  /// Prefetch Mapbox style pack și două tile regions (București centru + Ilfov)
  /// Rulează non-blocant și idempotent (nu repornește dacă deja a rulat)
  Future<void> prefetchBucharestIlfov() async {
    if (emergencyPerformanceMode) {
      debugPrint('🚫 [OFFLINE_MANAGER] Style pack and tile region prefetch disabled');
      return;
    }
    if (_mapTilesPrefetched) return;
    try {
      debugPrint('🗺️ [OFFLINE_MANAGER] Prefetch Mapbox style pack & tile regions (Bucharest + Ilfov)');

      // 1) Style packs (LIGHT + DARK) pentru paritate offline și switch instant
      final offlineManager = await mapbox.OfflineManager.create();
      Future<void> loadStyle(String uri, String label) async {
        await offlineManager.loadStylePack(
          uri,
          mapbox.StylePackLoadOptions(acceptExpired: true),
          (mapbox.StylePackLoadProgress p) {
            final pct = p.requiredResourceCount == 0
                ? 0
                : ((p.completedResourceCount / p.requiredResourceCount) * 100).clamp(0, 100).toInt();
            debugPrint('🎨 [STYLE $label] $pct% (${p.completedResourceCount}/${p.requiredResourceCount})');
          },
        );
      }
      await loadStyle(mapbox.MapboxStyles.LIGHT, 'LIGHT');
      await loadStyle(mapbox.MapboxStyles.DARK, 'DARK');

      // 2) Tile store
      final tileStore = await mapbox.TileStore.createDefault();

      // Quota 500MB pentru hărți
      tileStore.setDiskQuota(500 * 1024 * 1024, domain: mapbox.TileDataDomain.MAPS);

      // Helper pentru a crea un Polygon GeoJSON din BBOX: minLng,minLat,maxLng,maxLat
      Map<String, dynamic> polygonGeometryFromBbox(double minLng, double minLat, double maxLng, double maxLat) {
        final ring = <mapbox.Point>[
          mapbox.Point(coordinates: mapbox.Position(minLng, minLat)),
          mapbox.Point(coordinates: mapbox.Position(maxLng, minLat)),
          mapbox.Point(coordinates: mapbox.Position(maxLng, maxLat)),
          mapbox.Point(coordinates: mapbox.Position(minLng, maxLat)),
          mapbox.Point(coordinates: mapbox.Position(minLng, minLat)), // închidere
        ];
        final poly = mapbox.Polygon.fromPoints(points: [ring]);
        // Returnăm GeoJSON geometry (nu Feature)
        return poly.toJson();
      }

      // Regiunea 1: București centru (bounding box mai strâns)
      final centerGeometry = polygonGeometryFromBbox(25.98, 44.37, 26.12, 44.48);
      final centerDescriptor = mapbox.TilesetDescriptorOptions(
        styleURI: mapbox.MapboxStyles.LIGHT,
        minZoom: 11,
        maxZoom: 14,
        pixelRatio: 1.0,
      );
      try {
        final estimate = await tileStore.estimateTileRegion(
          'bucharest_center',
          mapbox.TileRegionLoadOptions(
            geometry: centerGeometry,
            descriptorsOptions: [centerDescriptor],
            acceptExpired: true,
            networkRestriction: mapbox.NetworkRestriction.DISALLOW_EXPENSIVE,
          ),
          null,
          null,
        );
        final estSize = estimate.transferSize;
        if (estSize > 150 * 1024 * 1024) {
          debugPrint('⏭️ [ESTIMATE] Center region too large (~${(estSize / (1024*1024)).toStringAsFixed(1)}MB), skipping');
        } else {
          await tileStore.loadTileRegion(
            'bucharest_center',
            mapbox.TileRegionLoadOptions(
              geometry: centerGeometry,
              descriptorsOptions: [centerDescriptor],
              acceptExpired: true,
              networkRestriction: mapbox.NetworkRestriction.DISALLOW_EXPENSIVE,
            ),
            (progress) {
              final req = progress.requiredResourceCount;
              final done = progress.completedResourceCount;
              if (req > 0) {
                final pct = ((done / req) * 100).clamp(0, 100).toInt();
                debugPrint('⬇️ [TILES center] $pct% ($done/$req)');
              }
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ [ESTIMATE] Center region estimate/load failed: $e');
      }

      // Regiunea 2: Ilfov (bounding box mai larg)
      // Coordonate aproximative Ilfov/București (din proiect): 25.75,44.20,26.45,44.70
      final ilfovGeometry = polygonGeometryFromBbox(25.75, 44.20, 26.45, 44.70);
      final ilfovDescriptor = mapbox.TilesetDescriptorOptions(
        styleURI: mapbox.MapboxStyles.LIGHT,
        minZoom: 6,
        maxZoom: 10,
        pixelRatio: 1.0,
      );
      try {
        final estimateIlfov = await tileStore.estimateTileRegion(
          'ilfov_region',
          mapbox.TileRegionLoadOptions(
            geometry: ilfovGeometry,
            descriptorsOptions: [ilfovDescriptor],
            acceptExpired: true,
            networkRestriction: mapbox.NetworkRestriction.DISALLOW_EXPENSIVE,
          ),
          null,
          null,
        );
        final estSizeIlfov = estimateIlfov.transferSize;
        if (estSizeIlfov > 300 * 1024 * 1024) {
          debugPrint('⏭️ [ESTIMATE] Ilfov region too large (~${(estSizeIlfov / (1024*1024)).toStringAsFixed(1)}MB), skipping');
        } else {
          await tileStore.loadTileRegion(
            'ilfov_region',
            mapbox.TileRegionLoadOptions(
              geometry: ilfovGeometry,
              descriptorsOptions: [ilfovDescriptor],
              acceptExpired: true,
              networkRestriction: mapbox.NetworkRestriction.DISALLOW_EXPENSIVE,
            ),
            (progress) {
              final req = progress.requiredResourceCount;
              final done = progress.completedResourceCount;
              if (req > 0) {
                final pct = ((done / req) * 100).clamp(0, 100).toInt();
                debugPrint('⬇️ [TILES ilfov] $pct% ($done/$req)');
              }
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ [ESTIMATE] Ilfov region estimate/load failed: $e');
      }

      _mapTilesPrefetched = true;
      debugPrint('✅ [OFFLINE_MANAGER] Map tiles prefetch completed');
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Prefetch error: $e');
      rethrow;
    }
  }

  /// Build a GeoJSON Polygon geometry from a bounding box.
  /// Note: returns a geometry object (not a Feature), suitable for TileRegionLoadOptions.geometry
  Map<String, dynamic> _polygonGeometryFromBboxGeojson(
    double minLng,
    double minLat,
    double maxLng,
    double maxLat,
  ) {
    final ring = <mapbox.Point>[
      mapbox.Point(coordinates: mapbox.Position(minLng, minLat)),
      mapbox.Point(coordinates: mapbox.Position(maxLng, minLat)),
      mapbox.Point(coordinates: mapbox.Position(maxLng, maxLat)),
      mapbox.Point(coordinates: mapbox.Position(minLng, maxLat)),
      mapbox.Point(coordinates: mapbox.Position(minLng, minLat)), // close ring
    ];
    final poly = mapbox.Polygon.fromPoints(points: [ring]);
    return poly.toJson();
  }

  /// Prefetch map tiles for a corridor defined by a bounding box.
  /// The region id is generated automatically unless provided.
  Future<void> prefetchRouteCorridorBounds({
    required double minLng,
    required double minLat,
    required double maxLng,
    required double maxLat,
    int minZoom = 10,
    int maxZoom = 16,
    String? regionId,
  }) async {
    if (emergencyPerformanceMode) {
      debugPrint('🚫 [OFFLINE_MANAGER] Corridor prefetch disabled');
      return;
    }
    try {
      // Honor Low Data Mode
      if (AppDrawer.lowDataMode) {
        debugPrint('⏭️ [OFFLINE_MANAGER] Skip corridor prefetch (Low Data Mode)');
        return;
      }

      final tileStore = await mapbox.TileStore.createDefault();
      // modest quota already set elsewhere

      final geometry = _polygonGeometryFromBboxGeojson(minLng, minLat, maxLng, maxLat);

      final descriptor = mapbox.TilesetDescriptorOptions(
        styleURI: mapbox.MapboxStyles.LIGHT,
        minZoom: minZoom,
        maxZoom: maxZoom,
        pixelRatio: 1.0,
      );

      final id = regionId ??
          'route_corridor_${minLat.toStringAsFixed(3)}_${minLng.toStringAsFixed(3)}_${maxLat.toStringAsFixed(3)}_${maxLng.toStringAsFixed(3)}_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('🚚 [OFFLINE_MANAGER] Prefetch route corridor: $id');
      await tileStore.loadTileRegion(
        id,
        mapbox.TileRegionLoadOptions(
          geometry: geometry,
          descriptorsOptions: [descriptor],
          acceptExpired: true,
          // Permit any network so that on-the-go navigation works even on mobile data
          networkRestriction: mapbox.NetworkRestriction.NONE,
        ),
        (progress) {
          final req = progress.requiredResourceCount;
          final done = progress.completedResourceCount;
          if (req > 0) {
            final pct = ((done / req) * 100).clamp(0, 100).toInt();
            debugPrint('⬇️ [TILES corridor] $pct% ($done/$req)');
          }
        },
      );
    } catch (e) {
      debugPrint('⚠️ [OFFLINE_MANAGER] Corridor prefetch failed: $e');
    }
  }

  /// Convenience: Prefetch a corridor around a sequence of points.
  /// Uses a simple bounding box with padding (in degrees) for robustness and speed.
  Future<void> prefetchRouteCorridorForPoints({
    required List<mapbox.Point> points,
    double paddingDegrees = 0.02, // ~2km at mid-latitudes
    int minZoom = 10,
    int maxZoom = 16,
  }) async {
    if (emergencyPerformanceMode) {
      debugPrint('🚫 [OFFLINE_MANAGER] Corridor prefetch (points) disabled');
      return;
    }
    if (points.isEmpty) return;
    try {
      double minLat = points.first.coordinates.lat.toDouble();
      double maxLat = points.first.coordinates.lat.toDouble();
      double minLng = points.first.coordinates.lng.toDouble();
      double maxLng = points.first.coordinates.lng.toDouble();

      for (final p in points) {
        final double lat = p.coordinates.lat.toDouble();
        final double lng = p.coordinates.lng.toDouble();
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }

      await prefetchRouteCorridorBounds(
        minLng: minLng - paddingDegrees,
        minLat: minLat - paddingDegrees,
        maxLng: maxLng + paddingDegrees,
        maxLat: maxLat + paddingDegrees,
        minZoom: minZoom,
        maxZoom: maxZoom,
      );
    } catch (e) {
      debugPrint('⚠️ [OFFLINE_MANAGER] prefetchRouteCorridorForPoints failed: $e');
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Initialize local database
  Future<void> _initializeDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'friendsride_offline.db');
      
      _database = await openDatabase(
        path,
        version: 3,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );
      
      debugPrint('✅ [OFFLINE_MANAGER] Local database initialized');
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Database initialization failed: $e');
      rethrow;
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Create database schema
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_operations (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        retries INTEGER DEFAULT 0
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cached_rides (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        status TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cached_routes (
        id TEXT PRIMARY KEY,
        start_lat REAL NOT NULL,
        start_lng REAL NOT NULL,
        end_lat REAL NOT NULL,
        end_lng REAL NOT NULL,
        route_data TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE search_cache_cells (
        key TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    
    debugPrint('✅ [OFFLINE_MANAGER] Database schema created');
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Upgrade database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE cached_rides ADD COLUMN sync_status TEXT DEFAULT 'pending'
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS search_cache_cells (
          key TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          timestamp INTEGER NOT NULL
        )
      ''');
    }
    
    debugPrint('✅ [OFFLINE_MANAGER] Database upgraded from $oldVersion to $newVersion');
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Setup connectivity monitoring
  Future<void> _setupConnectivityMonitoring() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = result.isNotEmpty && result.first != ConnectivityResult.none;
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          _handleConnectivityChange(results);
        },
        onError: (error) {
          debugPrint('❌ [OFFLINE_MANAGER] Connectivity monitoring error: $error');
        },
      );
      
      debugPrint('🌐 [OFFLINE_MANAGER] Connectivity monitoring active: $_isOnline');
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to setup connectivity monitoring: $e');
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.isNotEmpty && results.first != ConnectivityResult.none;
    
    debugPrint('🌐 [OFFLINE_MANAGER] Connectivity changed: $wasOnline -> $_isOnline');
    
    if (!wasOnline && _isOnline) {
      // Came back online - start sync
      debugPrint('🔄 [OFFLINE_MANAGER] Back online - starting sync...');
      _triggerSync();
      _schedulePrefetchIfEligible();
    }
    
    // Notify callbacks
    onConnectivityChanged?.call(_isOnline);
  }

  void _schedulePrefetchIfEligible() async {
    if (emergencyPerformanceMode) return;
    if (_mapTilesPrefetched || _prefetchScheduled) return;
    if (AppDrawer.lowDataMode) {
      debugPrint('⏭️ [OFFLINE_MANAGER] Skip prefetch (Low Data Mode)');
      return;
    }
    final results = await _connectivity.checkConnectivity();
    final onWifi = results.isNotEmpty && results.first == ConnectivityResult.wifi;
    if (!onWifi) {
      debugPrint('⏳ [OFFLINE_MANAGER] Waiting for Wi‑Fi to prefetch tiles');
      return;
    }
    _prefetchScheduled = true;
    _prefetchTimer?.cancel();
    _prefetchTimer = Timer(const Duration(seconds: 45), () async {
      try {
        if (AppDrawer.lowDataMode) return;
        final r = await _connectivity.checkConnectivity();
        final wifi = r.isNotEmpty && r.first == ConnectivityResult.wifi;
        if (!wifi) return;
        // Retry cu backoff simplu dacă eșuează
        int attempt = 0;
        const int maxAttempts = 3;
        while (attempt < maxAttempts) {
          try {
            await prefetchBucharestIlfov();
            break;
          } catch (_) {
            attempt++;
            if (attempt >= maxAttempts) break;
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          }
        }
      } catch (e) {
        debugPrint('❌ [OFFLINE_MANAGER] Prefetch schedule error: $e');
      }
    });
    debugPrint('🗓️ [OFFLINE_MANAGER] Prefetch scheduled in 45s (Wi‑Fi)');
  }

  /// 🔄 OFFLINE CAPABILITIES: Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      if (_isOnline && !_isSyncing) {
        _triggerSync();
      }
    });
  }

  /// 🔄 OFFLINE CAPABILITIES: Trigger synchronization
  Future<void> _triggerSync() async {
    if (_isSyncing || !_isOnline) return;
    
    try {
      _isSyncing = true;
      onSyncStatusChanged?.call(SyncStatus.syncing);
      
      debugPrint('🔄 [OFFLINE_MANAGER] Starting synchronization...');
      
      // Sync pending operations
      await _syncPendingOperations();
      
      // Sync cached data
      await _syncCachedData();
      
      // Cleanup old cache
      await _cleanupExpiredCache();
      
      onSyncStatusChanged?.call(SyncStatus.completed);
      debugPrint('✅ [OFFLINE_MANAGER] Synchronization completed');
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Synchronization failed: $e');
      onSyncStatusChanged?.call(SyncStatus.failed);
      _scheduleRetrySync();
    } finally {
      _isSyncing = false;
    }
  }

  /// 🔄 OFFLINE CAPABILITIES: Sync pending operations
  Future<void> _syncPendingOperations() async {
    final operations = List<PendingOperation>.from(_pendingOperations);
    
    for (final operation in operations) {
      try {
        await _executePendingOperation(operation);
        _pendingOperations.remove(operation);
        await _removePendingOperationFromDB(operation.id);
        
        debugPrint('✅ [OFFLINE_MANAGER] Synced operation: ${operation.type}');
        
      } catch (e) {
        debugPrint('❌ [OFFLINE_MANAGER] Failed to sync operation ${operation.id}: $e');
        
        operation.retries++;
        if (operation.retries >= _maxRetries) {
          debugPrint('🚨 [OFFLINE_MANAGER] Max retries exceeded for operation ${operation.id}');
          _pendingOperations.remove(operation);
          await _removePendingOperationFromDB(operation.id);
        } else {
          await _updatePendingOperationInDB(operation);
        }
      }
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Execute pending operation
  Future<void> _executePendingOperation(PendingOperation operation) async {
    switch (operation.type) {
      case 'create_ride':
        final rideData = jsonDecode(operation.data);
        final ride = Ride.fromMap(rideData);
        await _firestoreService.requestRide(ride);
        break;
        
      case 'update_ride_status':
        final data = jsonDecode(operation.data);
        await _firestoreService.updateRideStatus(data['rideId'], data['status']);
        break;
        
      case 'cancel_ride':
        final data = jsonDecode(operation.data);
        await _firestoreService.cancelRide(data['rideId']);
        break;
        
      case 'send_chat_message':
        final data = jsonDecode(operation.data);
        await _firestoreService.sendChatMessage(data['rideId'], data['message']);
        break;
        
      default:
        debugPrint('⚠️ [OFFLINE_MANAGER] Unknown operation type: ${operation.type}');
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Sync cached data
  Future<void> _syncCachedData() async {
    // This would sync cached rides, preferences, etc.
    // Implementation depends on specific sync requirements
    debugPrint('🔄 [OFFLINE_MANAGER] Syncing cached data...');
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Schedule retry sync
  void _scheduleRetrySync() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (_isOnline && !_isSyncing) {
        _triggerSync();
      }
    });
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Add pending operation
  Future<void> addPendingOperation({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final operation = PendingOperation(
        id: _generateOperationId(),
        type: type,
        data: jsonEncode(data),
        timestamp: DateTime.now(),
        retries: 0,
      );
      
      _pendingOperations.add(operation);
      await _savePendingOperationToDB(operation);
      
      debugPrint('📝 [OFFLINE_MANAGER] Added pending operation: $type');
      
      // Try immediate sync if online
      if (_isOnline && !_isSyncing) {
        _triggerSync();
      }
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to add pending operation: $e');
      rethrow;
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Cache ride data
  Future<void> cacheRide(Ride ride) async {
    try {
      if (_database == null) return;
      
      await _database!.insert(
        'cached_rides',
        {
          'id': ride.id,
          'data': jsonEncode(ride.toMap()),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': ride.status,
          'sync_status': 'cached',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('💾 [OFFLINE_MANAGER] Cached ride: ${ride.id}');
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to cache ride: $e');
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Get cached rides
  Future<List<Ride>> getCachedRides({String? status}) async {
    try {
      if (_database == null) return [];
      
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (status != null) {
        whereClause = 'WHERE status = ?';
        whereArgs.add(status);
      }
      
      final result = await _database!.query(
        'cached_rides',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'timestamp DESC',
      );
      
      return result.map((row) {
        final rideData = jsonDecode(row['data'] as String);
        return Ride.fromMap(rideData);
      }).toList();
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to get cached rides: $e');
      return [];
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Cache route data
  Future<void> cacheRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required Map<String, dynamic> routeData,
  }) async {
    try {
      if (_database == null) return;
      
      final routeId = _generateRouteId(startLat, startLng, endLat, endLng);
      
      await _database!.insert(
        'cached_routes',
        {
          'id': routeId,
          'start_lat': startLat,
          'start_lng': startLng,
          'end_lat': endLat,
          'end_lng': endLng,
          'route_data': jsonEncode(routeData),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('🗺️ [OFFLINE_MANAGER] Cached route: $routeId');
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to cache route: $e');
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Get cached route
  Future<Map<String, dynamic>?> getCachedRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    double tolerance = 0.001, // ~100m tolerance
  }) async {
    try {
      if (_database == null) return null;
      
      final result = await _database!.query(
        'cached_routes',
        where: '''
          ABS(start_lat - ?) < ? AND 
          ABS(start_lng - ?) < ? AND 
          ABS(end_lat - ?) < ? AND 
          ABS(end_lng - ?) < ?
        ''',
        whereArgs: [
          startLat, tolerance,
          startLng, tolerance,
          endLat, tolerance,
          endLng, tolerance,
        ],
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        final routeData = jsonDecode(result.first['route_data'] as String);
        debugPrint('🗺️ [OFFLINE_MANAGER] Found cached route');
        return routeData;
      }
      
      return null;
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to get cached route: $e');
      return null;
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Save user preference
  Future<void> savePreference(String key, dynamic value) async {
    try {
      if (_database == null) return;
      
      await _database!.insert(
        'user_preferences',
        {
          'key': key,
          'value': jsonEncode(value),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('💾 [OFFLINE_MANAGER] Saved preference: $key');
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to save preference: $e');
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Get user preference
  Future<T?> getPreference<T>(String key) async {
    try {
      if (_database == null) return null;
      
      final result = await _database!.query(
        'user_preferences',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        final value = jsonDecode(result.first['value'] as String);
        return value as T?;
      }
      
      return null;
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to get preference: $e');
      return null;
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Database helper methods
  Future<void> _loadPendingOperations() async {
    try {
      if (_database == null) return;
      
      final result = await _database!.query('pending_operations');
      
      for (final row in result) {
        final operation = PendingOperation(
          id: row['id'] as String,
          type: row['type'] as String,
          data: row['data'] as String,
          timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
          retries: row['retries'] as int,
        );
        
        _pendingOperations.add(operation);
      }
      
      debugPrint('📝 [OFFLINE_MANAGER] Loaded ${_pendingOperations.length} pending operations');
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to load pending operations: $e');
    }
  }
  
  Future<void> _loadCachedData() async {
    try {
      // Load cached data into memory if needed
      debugPrint('💾 [OFFLINE_MANAGER] Cached data loaded');
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to load cached data: $e');
    }
  }
  
  Future<void> _savePendingOperationToDB(PendingOperation operation) async {
    if (_database == null) return;
    
    await _database!.insert(
      'pending_operations',
      {
        'id': operation.id,
        'type': operation.type,
        'data': operation.data,
        'timestamp': operation.timestamp.millisecondsSinceEpoch,
        'retries': operation.retries,
      },
    );
  }
  
  Future<void> _updatePendingOperationInDB(PendingOperation operation) async {
    if (_database == null) return;
    
    await _database!.update(
      'pending_operations',
      {'retries': operation.retries},
      where: 'id = ?',
      whereArgs: [operation.id],
    );
  }
  
  Future<void> _removePendingOperationFromDB(String operationId) async {
    if (_database == null) return;
    
    await _database!.delete(
      'pending_operations',
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }
  
  Future<void> _cleanupExpiredCache() async {
    try {
      if (_database == null) return;
      
      final cutoffTime = DateTime.now().subtract(_cacheExpiry).millisecondsSinceEpoch;
      
      // Clean up old cached routes
      await _database!.delete(
        'cached_routes',
        where: 'timestamp < ?',
        whereArgs: [cutoffTime],
      );
      
      // Clean up old cached rides
      try {
        await _database!.delete(
          'cached_rides',
          where: 'timestamp < ? AND sync_status = ?',
          whereArgs: [cutoffTime, 'synced'],
        );
      } catch (e) {
        // Fallback pentru baze existente fără coloana sync_status
        await _database!.delete(
          'cached_rides',
          where: 'timestamp < ?',
          whereArgs: [cutoffTime],
        );
      }
      
      debugPrint('🧹 [OFFLINE_MANAGER] Cleaned up expired cache');
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to cleanup cache: $e');
    }

    // 🧹 Curățare tile regions vechi (TTL 14 zile)
    try {
      final tileStore = await mapbox.TileStore.createDefault();
      final regions = await tileStore.allTileRegions();
      final ttlDays = 14;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final region in regions) {
        final expires = region.expires; // epoch ms sau null
        if (expires != null) {
          final ageDays = (nowMs - expires) / (1000 * 60 * 60 * 24);
          if (ageDays > ttlDays) {
            debugPrint('🧹 [OFFLINE_MANAGER] Removing expired tile region: ${region.id}');
            await tileStore.removeRegion(region.id);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [OFFLINE_MANAGER] Failed to cleanup tile regions: $e');
    }

    // 🧹 Curățare search cache (TTL 20 min)
    try {
      if (_database != null) {
        final cutoff = DateTime.now().subtract(_searchCacheTtl).millisecondsSinceEpoch;
        final removed = await _database!.delete(
          'search_cache_cells',
          where: 'timestamp < ?',
          whereArgs: [cutoff],
        );
        if (removed > 0) {
          debugPrint('🧹 [OFFLINE_MANAGER] Removed $removed expired search cache cells');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [OFFLINE_MANAGER] Failed to cleanup search cache cells: $e');
    }
  }

  // 🔎 SEARCH CACHE (grid/TTL) API
  Future<void> saveSearchCacheCell({
    required String key,
    required String jsonData,
    int maxEntries = 60,
  }) async {
    if (_database == null) return;
    try {
      await _database!.insert(
        'search_cache_cells',
        {
          'key': key,
          'data': jsonData,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _trimSearchCache(maxEntries: maxEntries);
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to save search cache cell: $e');
    }
  }

  Future<String?> getSearchCacheCell(String key) async {
    if (_database == null) return null;
    try {
      final cutoff = DateTime.now().subtract(_searchCacheTtl).millisecondsSinceEpoch;
      final result = await _database!.query(
        'search_cache_cells',
        columns: ['data', 'timestamp'],
        where: 'key = ? AND timestamp >= ?',
        whereArgs: [key, cutoff],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return result.first['data'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to get search cache cell: $e');
      return null;
    }
  }

  Future<void> _trimSearchCache({int maxEntries = 60}) async {
    if (_database == null) return;
    try {
      final countRes = await _database!.rawQuery('SELECT COUNT(*) AS c FROM search_cache_cells');
      final count = (countRes.first['c'] as int?) ?? 0;
      if (count > maxEntries) {
        final toDelete = count - maxEntries;
        await _database!.rawDelete(
          'DELETE FROM search_cache_cells WHERE key IN (SELECT key FROM search_cache_cells ORDER BY timestamp ASC LIMIT ?)',
          [toDelete],
        );
      }
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to trim search cache: $e');
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Utility methods
  String _generateOperationId() {
    return 'op_${DateTime.now().millisecondsSinceEpoch}_${_pendingOperations.length}';
  }
  
  String _generateRouteId(double startLat, double startLng, double endLat, double endLng) {
    return 'route_${startLat.toStringAsFixed(3)}_${startLng.toStringAsFixed(3)}_${endLat.toStringAsFixed(3)}_${endLng.toStringAsFixed(3)}';
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Public API
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  int get pendingOperationsCount => _pendingOperations.length;
  
  /// 🔄 OFFLINE CAPABILITIES: Get sync status
  SyncStatus getSyncStatus() {
    if (_isSyncing) return SyncStatus.syncing;
    if (_pendingOperations.isEmpty) return SyncStatus.upToDate;
    return SyncStatus.pending;
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Force sync
  Future<void> forceSync() async {
    if (_isOnline) {
      await _triggerSync();
    } else {
      throw Exception('Cannot sync while offline');
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Clear all cache
  Future<void> clearCache() async {
    try {
      if (_database == null) return;
      
      await _database!.delete('cached_rides');
      await _database!.delete('cached_routes');
      await _database!.delete('user_preferences');
      
      debugPrint('🧹 [OFFLINE_MANAGER] All cache cleared');
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Failed to clear cache: $e');
    }
  }
  
  /// 🔄 OFFLINE CAPABILITIES: Dispose resources
  Future<void> dispose() async {
    try {
      _connectivitySubscription?.cancel();
      _syncTimer?.cancel();
      _retryTimer?.cancel();
      _prefetchTimer?.cancel();
      await _database?.close();
      
      _pendingOperations.clear();
      _dataCache.clear();
      _conflictedItems.clear();
      
      _isInitialized = false;
      
      debugPrint('✅ [OFFLINE_MANAGER] Resources disposed successfully');
      
    } catch (e) {
      debugPrint('❌ [OFFLINE_MANAGER] Error disposing resources: $e');
    }
  }
}

/// 🔄 OFFLINE CAPABILITIES: Data models
class PendingOperation {
  final String id;
  final String type;
  final String data;
  final DateTime timestamp;
  int retries;
  
  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.retries,
  });
}

class CachedData {
  final String id;
  final dynamic data;
  final DateTime timestamp;
  final String type;
  
  CachedData({
    required this.id,
    required this.data,
    required this.timestamp,
    required this.type,
  });
}

enum SyncStatus {
  upToDate,
  pending,
  syncing,
  completed,
  failed,
}
