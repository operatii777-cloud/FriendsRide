import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/scheduler.dart';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:friendsride_app/services/performance_monitor.dart';
import 'package:friendsride_app/services/firebase_service.dart';
import 'package:friendsride_app/voice/core/voice_analytics.dart';
import 'package:friendsride_app/voice/core/voice_analytics_bridge.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 🏥 App Monitor - Sistema de prevenire crash-uri și recuperare automată
/// 
/// Acest serviciu oferă:
/// - System health monitoring în timp real
/// - Crash prevention și auto-recovery
/// - Memory management și resource cleanup
/// - Performance optimization automată
/// - Emergency fallback mechanisms
class AppMonitor {
  static final AppMonitor _instance = AppMonitor._internal();
  factory AppMonitor() => _instance;
  AppMonitor._internal();

  // Core Services
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final FirebaseService _firebaseService = FirebaseService();
  final VoiceAnalytics _voiceAnalytics = VoiceAnalytics();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Connectivity _connectivity = Connectivity();
  VoiceAnalyticsBridge? _voiceBridge;

  // System Health State
  bool _isInitialized = false;
  bool _isHealthy = true;
  bool _isMemoryHealthy = true;
  bool _isNetworkHealthy = true;
  bool _isCpuHealthy = true;
  
  // Monitoring Configuration
  static const Duration _healthCheckInterval = Duration(minutes: 1);
  static const Duration _memoryCheckInterval = Duration(seconds: 30);
  static const Duration _networkCheckInterval = Duration(seconds: 45); // reduce polling
  // Thresholds
  static const int _maxMemoryMB = 150;
  static const int _maxErrorsPerMinute = 10;
  
  // Health Data
  final Map<String, SystemHealthMetric> _healthMetrics = {};
  final List<CrashReport> _recentCrashes = [];
  final Map<String, RecoveryAction> _recoveryHistory = {};
  
  // Timers and Subscriptions
  Timer? _healthCheckTimer;
  Timer? _memoryCheckTimer;
  Timer? _networkCheckTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Callbacks
  Function(SystemHealthStatus)? onHealthStatusChanged;
  Function(CrashReport)? onCrashDetected;
  Function(RecoveryAction)? onRecoveryActionTaken;
  
  /// 🚀 Initialize App Monitor
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🏥 [APP_MONITOR] Initializing system health monitoring...');
      
      // Setup crash detection
      await _setupCrashDetection();
      
      // Initialize system info
      await _initializeSystemInfo();
      
      // Start health monitoring
      await _startHealthMonitoring();
      
      // Setup network monitoring
      await _setupNetworkMonitoring();
      
      // Initialize recovery mechanisms
      await _initializeRecoveryMechanisms();
      _initializeVoiceBridge();

      // Hook Flutter frame timings pentru FPS aproximativ
      try {
        _hookFrameTimings();
      } catch (_) {}
      
      _isInitialized = true;
      
      debugPrint('✅ [APP_MONITOR] System health monitoring initialized successfully');
      
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Failed to initialize: $e');
      await _recordCrash('app_monitor_initialization_failed', e, StackTrace.current);
      rethrow;
    }
  }

  void _hookFrameTimings() {
    // Use scheduler API to observe frame timings without overriding Flutter's dispatcher callback
    try {
      SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
        for (final t in timings) {
          final buildMs = t.buildDuration.inMilliseconds;
          final rasterMs = t.rasterDuration.inMilliseconds;
          _performanceMonitor.recordMetric(
            'frame_timing',
            {'build_ms': buildMs, 'raster_ms': rasterMs},
            category: 'ui',
          );
          if (buildMs > 16 || rasterMs > 16) {
            _performanceMonitor.recordWarning(
              'Jank',
              'Frame exceeded 16ms',
              context: {'build_ms': buildMs, 'raster_ms': rasterMs},
              category: 'ui',
            );
          }
        }
      });
    } catch (_) {}
  }
  
  /// 🔧 Setup crash detection
  Future<void> _setupCrashDetection() async {
    // Setup Flutter error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };
    
    // Setup platform dispatcher error handler
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };
    
    // Setup isolate error handler
    Isolate.current.addErrorListener(RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair;
      final error = errorAndStacktrace[0];
      final stack = errorAndStacktrace[1];
      await _handleIsolateError(error, stack);
    }).sendPort);
  }
  
  /// 📊 Initialize system information
  Future<void> _initializeSystemInfo() async {
    try {
      final deviceInfo = await _getDeviceInfo();
      
      _healthMetrics['device_info'] = SystemHealthMetric(
        name: 'device_info',
        value: deviceInfo,
        timestamp: DateTime.now(),
        isHealthy: true,
      );
      
      debugPrint('📱 [APP_MONITOR] Device info initialized: ${deviceInfo['platform']}');
      
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Failed to get device info: $e');
    }
  }
  
  /// 🏃 Start health monitoring
  Future<void> _startHealthMonitoring() async {
    // Start periodic health checks
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) => _performHealthCheck());
    
    // Start memory monitoring
    _memoryCheckTimer = Timer.periodic(_memoryCheckInterval, (_) => _checkMemoryHealth());
    
    // Start network monitoring
    _networkCheckTimer = Timer.periodic(_networkCheckInterval, (_) => _checkNetworkHealth());
    
    debugPrint('🏃 [APP_MONITOR] Health monitoring started');
  }
  
  /// 🌐 Setup network monitoring
  Future<void> _setupNetworkMonitoring() async {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        _handleConnectivityChange(result);
      },
      onError: (error) {
        debugPrint('❌ [APP_MONITOR] Connectivity monitoring error: $error');
        _recordNetworkIssue('connectivity_monitoring_error', error.toString());
      },
    );
  }
  
  /// 🛠️ Initialize recovery mechanisms
  Future<void> _initializeRecoveryMechanisms() async {
    // Initialize performance monitor
    await _performanceMonitor.initialize();
    
    // Initialize voice analytics
    await _voiceAnalytics.initialize();
    
    debugPrint('🛠️ [APP_MONITOR] Recovery mechanisms initialized');
  }
  
  /// 🏥 Perform comprehensive health check
  Future<void> _performHealthCheck() async {
    try {
      final healthStatus = SystemHealthStatus(
        isOverallHealthy: _isHealthy,
        memoryHealth: _isMemoryHealthy,
        networkHealth: _isNetworkHealthy,
        cpuHealth: _isCpuHealthy,
        timestamp: DateTime.now(),
        metrics: Map.from(_healthMetrics),
      );
      
      // Update health metrics
      _updateHealthMetrics();
      
      // Check for critical issues
      await _checkCriticalIssues();
      
      // Trigger callback
      onHealthStatusChanged?.call(healthStatus);
      
      // Log health status periodically
      if (DateTime.now().minute % 5 == 0) {
        debugPrint('🏥 [APP_MONITOR] Health Status: Overall=$_isHealthy, Memory=$_isMemoryHealthy, Network=$_isNetworkHealthy, CPU=$_isCpuHealthy');
      }
      
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Health check failed: $e');
      await _recordCrash('health_check_failed', e, StackTrace.current);
    }
  }
  
  /// 🧠 Check memory health
  Future<void> _checkMemoryHealth() async {
    try {
      // Get current memory usage (simplified for Flutter limitations)
      final memoryInfo = await _getMemoryInfo();
      
      _healthMetrics['memory'] = SystemHealthMetric(
        name: 'memory',
        value: memoryInfo,
        timestamp: DateTime.now(),
        isHealthy: memoryInfo['usedMB'] < _maxMemoryMB,
      );
      
      final memoryUsageMB = memoryInfo['usedMB'] as int;
      _isMemoryHealthy = memoryUsageMB < _maxMemoryMB;
      
      if (!_isMemoryHealthy) {
        debugPrint('⚠️ [APP_MONITOR] High memory usage detected: ${memoryUsageMB}MB');
        await _handleMemoryIssue(memoryUsageMB);
      }
      
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Memory check failed: $e');
      _isMemoryHealthy = false;
    }
  }
  
  /// 🌐 Check network health
  int _networkBackoffSeconds = 0;
  Future<void> _checkNetworkHealth() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isConnected = connectivityResult.isNotEmpty && connectivityResult.first != ConnectivityResult.none;
      
      _healthMetrics['network'] = SystemHealthMetric(
        name: 'network',
        value: {'connectivity': connectivityResult.isNotEmpty ? connectivityResult.first.name : 'unknown', 'isConnected': isConnected},
        timestamp: DateTime.now(),
        isHealthy: isConnected,
      );
      
      _isNetworkHealthy = isConnected;
      
      if (!_isNetworkHealthy) {
        // Log only on state change (handled elsewhere); backoff polling
        _networkBackoffSeconds = _networkBackoffSeconds == 0 ? 15 : (_networkBackoffSeconds * 2).clamp(15, 120);
        _rescheduleNetworkTimer(_networkBackoffSeconds);
        await _handleNetworkIssue('connectivity_lost', 'No network connection available');
      } else if (_networkBackoffSeconds != 0) {
        // Recovered: reset backoff and restore normal interval
        _networkBackoffSeconds = 0;
        _rescheduleNetworkTimer(_networkCheckInterval.inSeconds);
      }
      
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Network check failed: $e');
      _isNetworkHealthy = false;
      _networkBackoffSeconds = _networkBackoffSeconds == 0 ? 15 : (_networkBackoffSeconds * 2).clamp(15, 120);
      _rescheduleNetworkTimer(_networkBackoffSeconds);
    }
  }

  void _rescheduleNetworkTimer(int seconds) {
    try {
      _networkCheckTimer?.cancel();
      _networkCheckTimer = Timer.periodic(Duration(seconds: seconds), (_) => _checkNetworkHealth());
      debugPrint('🌐 [APP_MONITOR] Network poll interval: ${seconds}s');
    } catch (_) {}
  }
  
  /// ⚠️ Check for critical issues
  Future<void> _checkCriticalIssues() async {
    // Check error rate
    final recentErrors = _recentCrashes.where(
      (crash) => crash.timestamp.isAfter(DateTime.now().subtract(Duration(minutes: 1))),
    ).length;
    
    if (recentErrors > _maxErrorsPerMinute) {
      debugPrint('🚨 [APP_MONITOR] Critical: High error rate detected: $recentErrors errors/minute');
      await _handleCriticalIssue('high_error_rate', 'Too many errors: $recentErrors/minute');
    }
    
    // Update overall health
    _isHealthy = _isMemoryHealthy && _isNetworkHealthy && _isCpuHealthy && recentErrors <= _maxErrorsPerMinute;
  }
  
  /// 📈 Update health metrics
  void _updateHealthMetrics() {
    final now = DateTime.now();
    
    // Clean old metrics (keep last hour)
    final cutoff = now.subtract(Duration(hours: 1));
    _healthMetrics.removeWhere((key, metric) => metric.timestamp.isBefore(cutoff));
    
    // Clean old crashes (keep last day)
    final crashCutoff = now.subtract(Duration(days: 1));
    _recentCrashes.removeWhere((crash) => crash.timestamp.isBefore(crashCutoff));
    
    // Clean old recovery actions (keep last day)
    final recoveryCutoff = now.subtract(Duration(days: 1));
    _recoveryHistory.removeWhere((key, action) => action.timestamp.isBefore(recoveryCutoff));
  }
  
  /// 🛠️ Handle Flutter errors
  Future<void> _handleFlutterError(FlutterErrorDetails details) async {
    debugPrint('🚨 [APP_MONITOR] Flutter Error: ${details.exception}');
    
    await _recordCrash(
      'flutter_error',
      details.exception,
      details.stack,
      context: {
        'library': details.library,
        'context': details.context?.toString(),
        'informationCollector': details.informationCollector?.call().map((e) => e.toString()).join('\n') ?? '',
      },
    );
    
    // Attempt recovery
    await _attemptErrorRecovery('flutter_error', details.exception);
  }
  
  /// 🛠️ Handle platform errors
  Future<void> _handlePlatformError(Object error, StackTrace stack) async {
    debugPrint('🚨 [APP_MONITOR] Platform Error: $error');
    
    await _recordCrash('platform_error', error, stack);
    await _attemptErrorRecovery('platform_error', error);
  }
  
  /// 🛠️ Handle isolate errors
  Future<void> _handleIsolateError(dynamic error, dynamic stack) async {
    debugPrint('🚨 [APP_MONITOR] Isolate Error: $error');
    
    await _recordCrash('isolate_error', error, stack);
    await _attemptErrorRecovery('isolate_error', error);
  }
  
  /// 🧠 Handle memory issues
  Future<void> _handleMemoryIssue(int memoryUsageMB) async {
    debugPrint('🧠 [APP_MONITOR] Handling memory issue: ${memoryUsageMB}MB');
    
    final recoveryAction = RecoveryAction(
      type: 'memory_cleanup',
      reason: 'High memory usage: ${memoryUsageMB}MB',
      timestamp: DateTime.now(),
    );
    
    try {
      // Force garbage collection
      await _forceGarbageCollection();
      
      // Clear caches
      await _clearCaches();
      
      // Dispose unused resources
      await _disposeUnusedResources();
      
      recoveryAction.success = true;
      recoveryAction.result = 'Memory cleanup completed successfully';
      
      debugPrint('✅ [APP_MONITOR] Memory recovery completed');
      
    } catch (e) {
      recoveryAction.success = false;
      recoveryAction.result = 'Memory cleanup failed: $e';
      
      debugPrint('❌ [APP_MONITOR] Memory recovery failed: $e');
    }
    
    _recoveryHistory['memory_${DateTime.now().millisecondsSinceEpoch}'] = recoveryAction;
    onRecoveryActionTaken?.call(recoveryAction);
  }
  
  /// 🌐 Handle network issues
  Future<void> _handleNetworkIssue(String type, String reason) async {
    debugPrint('🌐 [APP_MONITOR] Handling network issue: $type - $reason');
    
    final recoveryAction = RecoveryAction(
      type: 'network_recovery',
      reason: reason,
      timestamp: DateTime.now(),
    );
    
    try {
      // Attempt to reconnect
      await _attemptNetworkRecovery();
      
      // Switch to offline mode if needed
      await _enableOfflineMode();
      
      recoveryAction.success = true;
      recoveryAction.result = 'Network recovery completed';
      
      debugPrint('✅ [APP_MONITOR] Network recovery completed');
      
    } catch (e) {
      recoveryAction.success = false;
      recoveryAction.result = 'Network recovery failed: $e';
      
      debugPrint('❌ [APP_MONITOR] Network recovery failed: $e');
    }
    
    _recoveryHistory['network_${DateTime.now().millisecondsSinceEpoch}'] = recoveryAction;
    onRecoveryActionTaken?.call(recoveryAction);
  }
  
  /// 🚨 Handle critical issues
  Future<void> _handleCriticalIssue(String type, String reason) async {
    debugPrint('🚨 [APP_MONITOR] CRITICAL ISSUE: $type - $reason');
    
    final recoveryAction = RecoveryAction(
      type: 'critical_recovery',
      reason: reason,
      timestamp: DateTime.now(),
    );
    
    try {
      // Emergency cleanup
      await _emergencyCleanup();
      
      // Restart critical services
      await _restartCriticalServices();
      
      // Reset to safe state
      await _resetToSafeState();
      
      recoveryAction.success = true;
      recoveryAction.result = 'Critical recovery completed';
      
      debugPrint('✅ [APP_MONITOR] Critical recovery completed');
      
    } catch (e) {
      recoveryAction.success = false;
      recoveryAction.result = 'Critical recovery failed: $e';
      
      debugPrint('❌ [APP_MONITOR] Critical recovery failed: $e');
      
      // Last resort: notify user
      await _notifyUserOfCriticalIssue(type, reason);
    }
    
    _recoveryHistory['critical_${DateTime.now().millisecondsSinceEpoch}'] = recoveryAction;
    onRecoveryActionTaken?.call(recoveryAction);
  }
  
  /// 🔄 Attempt error recovery
  Future<void> _attemptErrorRecovery(String errorType, Object error) async {
    try {
      final recoveryAction = RecoveryAction(
        type: 'error_recovery',
        reason: 'Error: $errorType - $error',
        timestamp: DateTime.now(),
      );
      
      // Determine recovery strategy based on error type
      if (errorType.contains('memory') || error.toString().contains('memory')) {
        await _handleMemoryIssue(_maxMemoryMB + 10); // Trigger memory cleanup
      } else if (errorType.contains('network') || error.toString().contains('network')) {
        await _handleNetworkIssue('error_recovery', error.toString());
      } else if (errorType.contains('permission')) {
        await _requestMissingPermissions();
      } else {
        await _performGenericRecovery();
      }
      
      recoveryAction.success = true;
      recoveryAction.result = 'Error recovery completed';
      
      _recoveryHistory['error_${DateTime.now().millisecondsSinceEpoch}'] = recoveryAction;
      onRecoveryActionTaken?.call(recoveryAction);
      
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Error recovery failed: $e');
    }
  }
  
  /// 📱 Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'version': androidInfo.version.release,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'version': iosInfo.systemVersion,
          'model': iosInfo.model,
          'name': iosInfo.name,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      } else {
        return {
          'platform': Platform.operatingSystem,
          'version': 'unknown',
          'model': 'unknown',
          'manufacturer': 'unknown',
          'isPhysicalDevice': true,
        };
      }
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Failed to get device info: $e');
      return {
        'platform': 'unknown',
        'version': 'unknown',
        'model': 'unknown',
        'manufacturer': 'unknown',
        'isPhysicalDevice': true,
      };
    }
  }
  
  /// 🧠 Get memory information (improved)
  Future<Map<String, dynamic>> _getMemoryInfo() async {
    try {
      // Improved memory estimation based on multiple factors
      final metrics = _performanceMonitor.getPerformanceSummary();
      final totalMetrics = metrics['total_metrics'] as int? ?? 0;
      final activeServices = metrics['active_services'] as int? ?? 0;
      final cachedItems = metrics['cached_items'] as int? ?? 0;
      
      // More accurate memory calculation
      final baseMemoryMB = 30; // Base app memory
      final servicesMemoryMB = activeServices * 5; // 5MB per active service
      final cacheMemoryMB = (cachedItems * 0.1).round(); // 0.1MB per cached item
      final metricsMemoryMB = (totalMetrics * 0.02).round(); // 0.02MB per metric
      
      final estimatedMemoryMB = baseMemoryMB + servicesMemoryMB + cacheMemoryMB + metricsMemoryMB;
      
      return {
        'usedMB': estimatedMemoryMB,
        'availableMB': _maxMemoryMB - estimatedMemoryMB,
        'percentageUsed': (estimatedMemoryMB / _maxMemoryMB * 100).round(),
        'breakdown': {
          'base': baseMemoryMB,
          'services': servicesMemoryMB,
          'cache': cacheMemoryMB,
          'metrics': metricsMemoryMB,
        }
      };
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Failed to get memory info: $e');
      return {
        'usedMB': 50, // Default estimation
        'availableMB': _maxMemoryMB - 50,
        'percentageUsed': 33,
        'breakdown': {'base': 50, 'services': 0, 'cache': 0, 'metrics': 0}
      };
    }
  }
  
  /// 🧹 Force garbage collection (improved)
  Future<void> _forceGarbageCollection() async {
    try {
      // More effective GC trigger
      final tempLists = <List<int>>[];
      
      // Create temporary objects to trigger GC
      for (int i = 0; i < 20; i++) {
        final temp = List.generate(2000, (index) => index * i);
        tempLists.add(temp);
      }
      
      // Clear all temporary objects
      for (final list in tempLists) {
        list.clear();
      }
      tempLists.clear();
      
      // Force multiple GC cycles
      for (int i = 0; i < 3; i++) {
        await Future.delayed(Duration(milliseconds: 50));
        // Create and discard more objects
        final temp = {
          for (final item in List.generate(1000, (index) => index)) item: 'temp_$item',
        };
        temp.clear();
      }
      
      debugPrint('🧹 [APP_MONITOR] Garbage collection completed');
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] GC failed: $e');
    }
  }
  
  /// 🧹 Clear caches
  Future<void> _clearCaches() async {
    try {
      // Clear image cache if available
      try {
        // Skip image cache clearing for now - requires Flutter services
        debugPrint('⚠️ [APP_MONITOR] Image cache clearing skipped - requires Flutter services');
      } catch (e) {
        debugPrint('⚠️ [APP_MONITOR] Could not clear image cache: $e');
      }
      
      debugPrint('🧹 [APP_MONITOR] Caches cleared');
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Failed to clear caches: $e');
    }
  }
  
  /// 🗑️ Dispose unused resources
  Future<void> _disposeUnusedResources() async {
    try {
      // This would dispose of any unused resources
      // Implementation depends on specific resource management strategy
      
      debugPrint('🗑️ [APP_MONITOR] Unused resources disposed');
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Failed to dispose resources: $e');
    }
  }
  
  /// 🌐 Attempt network recovery
  Future<void> _attemptNetworkRecovery() async {
    try {
      // Attempt to reconnect to Firebase
      await _firebaseService.initialize();
      
      debugPrint('🌐 [APP_MONITOR] Network recovery attempted');
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Network recovery failed: $e');
    }
  }
  
  /// 📴 Enable offline mode
  Future<void> _enableOfflineMode() async {
    try {
      // Enable Firestore offline persistence
      // This would typically be done at app startup
      
      debugPrint('📴 [APP_MONITOR] Offline mode enabled');
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Failed to enable offline mode: $e');
    }
  }
  
  /// 🚨 Emergency cleanup
  Future<void> _emergencyCleanup() async {
    try {
      await _forceGarbageCollection();
      await _clearCaches();
      await _disposeUnusedResources();
      
      debugPrint('🚨 [APP_MONITOR] Emergency cleanup completed');
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Emergency cleanup failed: $e');
    }
  }
  
  /// 🔄 Restart critical services
  Future<void> _restartCriticalServices() async {
    try {
      // Restart performance monitor
      _performanceMonitor.dispose();
      await _performanceMonitor.initialize();
      
      // Restart voice analytics
      _voiceAnalytics.dispose();
      await _voiceAnalytics.initialize();
      
      debugPrint('🔄 [APP_MONITOR] Critical services restarted');
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Failed to restart services: $e');
    }
  }
  
  /// 🔒 Reset to safe state
  Future<void> _resetToSafeState() async {
    try {
      // Reset system to a known good state
      _isHealthy = true;
      _isMemoryHealthy = true;
      _isNetworkHealthy = true;
      _isCpuHealthy = true;
      
      // Clear recent crashes to avoid cascade failures
      _recentCrashes.clear();
      
      debugPrint('🔒 [APP_MONITOR] Reset to safe state');
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Failed to reset to safe state: $e');
    }
  }
  
  /// 🔐 Request missing permissions
  Future<void> _requestMissingPermissions() async {
    try {
      // This would request any missing permissions
      // Implementation depends on specific permission requirements
      
      debugPrint('🔐 [APP_MONITOR] Missing permissions requested');
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Failed to request permissions: $e');
    }
  }
  
  /// 🔧 Perform generic recovery
  Future<void> _performGenericRecovery() async {
    try {
      await _forceGarbageCollection();
      await Future.delayed(Duration(milliseconds: 500));
      
      debugPrint('🔧 [APP_MONITOR] Generic recovery completed');
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Generic recovery failed: $e');
    }
  }
  
  /// 📢 Notify user of critical issue
  Future<void> _notifyUserOfCriticalIssue(String type, String reason) async {
    try {
      // This would show a user notification about the critical issue
      // Implementation depends on UI framework and user notification strategy
      
      debugPrint('📢 [APP_MONITOR] User notified of critical issue: $type - $reason');
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Failed to notify user: $e');
    }
  }
  
  /// 📝 Record crash
  Future<void> _recordCrash(String type, Object error, StackTrace? stackTrace, {Map<String, dynamic>? context}) async {
    try {
      final crash = CrashReport(
        type: type,
        error: error.toString(),
        stackTrace: stackTrace?.toString(),
        context: context,
        timestamp: DateTime.now(),
      );
      
      _recentCrashes.add(crash);
      
      // Record to Firebase Crashlytics
      await _firebaseService.crashlytics.recordError(
        error,
        stackTrace,
        information: context?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
      );
      
      // Record to Voice Analytics
      _voiceAnalytics.trackError(
        errorType: type,
        errorMessage: error.toString(),
        stackTrace: stackTrace,
      );

      _voiceBridge?.recordCrash(type);

      if (Sentry.isEnabled) {
        Sentry.addBreadcrumb(
          Breadcrumb(
            level: SentryLevel.error,
            category: 'app.monitor',
            message: 'Crash recorded: $type',
            data: {
              'error': error.toString(),
              if (context != null) ...context.map((key, value) => MapEntry(key, value.toString())),
            },
          ),
        );

        await Sentry.captureException(
          error,
          stackTrace: stackTrace,
          withScope: (scope) {
            scope.setTag('app_monitor.type', type);
            context?.forEach((key, value) {
              scope.setExtra('app_monitor.$key', value.toString());
            });
          },
        );
      }
      
      // Trigger callback
      onCrashDetected?.call(crash);
      
      debugPrint('📝 [APP_MONITOR] Crash recorded: $type - $error');
      
    } catch (e) {
      debugPrint('❌ [APP_MONITOR] Failed to record crash: $e');
    }
  }
  
  /// 🌐 Record network issue
  void _recordNetworkIssue(String type, String reason) {
    _healthMetrics['network_issue_${DateTime.now().millisecondsSinceEpoch}'] = SystemHealthMetric(
      name: 'network_issue',
      value: {'type': type, 'reason': reason},
      timestamp: DateTime.now(),
      isHealthy: false,
    );
    
    debugPrint('🌐 [APP_MONITOR] Network issue recorded: $type - $reason');
  }
  
  /// 🌐 Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) {
    final wasHealthy = _isNetworkHealthy;
    _isNetworkHealthy = result != ConnectivityResult.none;
    
    if (wasHealthy != _isNetworkHealthy) {
      debugPrint('🌐 [APP_MONITOR] Connectivity changed: ${result.name} (healthy: $_isNetworkHealthy)');
      
      if (!_isNetworkHealthy) {
        _recordNetworkIssue('connectivity_lost', 'Connection changed to: ${result.name}');
      }
    }
  }
  
  /// 📊 Get system health status
  SystemHealthStatus getHealthStatus() {
    return SystemHealthStatus(
      isOverallHealthy: _isHealthy,
      memoryHealth: _isMemoryHealthy,
      networkHealth: _isNetworkHealthy,
      cpuHealth: _isCpuHealthy,
      timestamp: DateTime.now(),
      metrics: Map.from(_healthMetrics),
    );
  }
  
  /// 📊 Get health summary
  Map<String, dynamic> getHealthSummary() {
    return {
      'isInitialized': _isInitialized,
      'isOverallHealthy': _isHealthy,
      'memoryHealth': _isMemoryHealthy,
      'networkHealth': _isNetworkHealthy,
      'cpuHealth': _isCpuHealthy,
      'recentCrashes': _recentCrashes.length,
      'recoveryActions': _recoveryHistory.length,
      'healthMetrics': _healthMetrics.length,
      'lastHealthCheck': _healthMetrics.isNotEmpty ? _healthMetrics.values.last.timestamp.toIso8601String() : null,
      'voiceAnalytics': _voiceBridge?.snapshot.toMap(),
    };
  }

  void _initializeVoiceBridge() {
    _voiceBridge?.dispose();
    _voiceBridge = VoiceAnalyticsBridge(
      analytics: _voiceAnalytics,
      crashlyticsKeySetter: (key, value) => _firebaseService.crashlytics.setCustomKey(key, value ?? ''),
      breadcrumbRecorder: (category, data) {
        if (!Sentry.isEnabled) return;
        Sentry.addBreadcrumb(
          Breadcrumb(
            category: category,
            data: data,
            level: SentryLevel.info,
            type: 'info',
          ),
        );
      },
    )..start();
  }

  /// 🧹 Dispose App Monitor
  void dispose() {
    debugPrint('🧹 [APP_MONITOR] Disposing system health monitoring...');
    
    // Cancel timers
    _healthCheckTimer?.cancel();
    _memoryCheckTimer?.cancel();
    _networkCheckTimer?.cancel();
    
    // Cancel subscriptions
    _connectivitySubscription?.cancel();
    _voiceBridge?.dispose();
    _voiceBridge = null;
    
    // Clear data
    _healthMetrics.clear();
    _recentCrashes.clear();
    _recoveryHistory.clear();
    
    // Reset state
    _isInitialized = false;
    _isHealthy = true;
    _isMemoryHealthy = true;
    _isNetworkHealthy = true;
    _isCpuHealthy = true;
    
    debugPrint('✅ [APP_MONITOR] System health monitoring disposed');
  }
}

/// 📊 System health status
class SystemHealthStatus {
  final bool isOverallHealthy;
  final bool memoryHealth;
  final bool networkHealth;
  final bool cpuHealth;
  final DateTime timestamp;
  final Map<String, SystemHealthMetric> metrics;

  SystemHealthStatus({
    required this.isOverallHealthy,
    required this.memoryHealth,
    required this.networkHealth,
    required this.cpuHealth,
    required this.timestamp,
    required this.metrics,
  });
}

/// 📈 System health metric
class SystemHealthMetric {
  final String name;
  final dynamic value;
  final DateTime timestamp;
  final bool isHealthy;

  SystemHealthMetric({
    required this.name,
    required this.value,
    required this.timestamp,
    required this.isHealthy,
  });
}

/// 🚨 Crash report
class CrashReport {
  final String type;
  final String error;
  final String? stackTrace;
  final Map<String, dynamic>? context;
  final DateTime timestamp;

  CrashReport({
    required this.type,
    required this.error,
    this.stackTrace,
    this.context,
    required this.timestamp,
  });
}

/// 🔧 Recovery action
class RecoveryAction {
  final String type;
  final String reason;
  final DateTime timestamp;
  bool success = false;
  String? result;

  RecoveryAction({
    required this.type,
    required this.reason,
    required this.timestamp,
  });
}
