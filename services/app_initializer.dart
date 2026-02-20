import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async' show unawaited;

import 'package:friendsride_app/firebase_options.dart';
import 'package:friendsride_app/config/environment.dart';
import 'package:friendsride_app/services/firebase_service.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/services/push_notification_service.dart';
import 'package:friendsride_app/services/offline_manager.dart';
import 'package:friendsride_app/services/app_monitor.dart';
import 'package:friendsride_app/utils/mapbox_config.dart';
import 'package:friendsride_app/voice/nlp/ride_intent_processor.dart';
import 'package:friendsride_app/services/startup_timer.dart';
import 'package:friendsride_app/delivery/services/restaurant_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

enum AppStatus { initializing, ready, error }

class AppInitializer with ChangeNotifier {
  AppStatus _status = AppStatus.initializing;
  AppStatus get status => _status;

  bool _started = false;

  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    _status = AppStatus.initializing;
    notifyListeners();

    try {
      StartupTimer.instance.mark('initializer.start');
      // Load env and validate keys (fast operations)
      try {
        await dotenv.load(fileName: ".env");
        StartupTimer.instance.mark('env.loaded');
        Environment.validateTokens();
        StartupTimer.instance.mark('env.validated');
        if (kDebugMode) {
          Environment.printConfigurationStatus();
        }
      } catch (e) {
        debugPrint('❗ ENV validation error (non-fatal): $e');
      }

      // Ensure Firebase is initialized FIRST
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        StartupTimer.instance.mark('firebase.ready');
      }

      // Run critical initializations first (fast operations only)
      await FirebaseService().initialize().then((_) => StartupTimer.instance.mark('firebase.service')).catchError((e) => debugPrint('❌ FirebaseService init: $e'));
      
      // Mark as ready early to allow UI to show
      _status = AppStatus.ready;
      notifyListeners();
      
      // Run heavy initializations in background (non-blocking)
      unawaited(_initializeBackgroundServices());

      StartupTimer.instance.mark('initializer.ready');
      StartupTimer.instance.printSummary();
      debugPrint('✅ Core services initialized successfully.');
    } catch (e) {
      _status = AppStatus.error;
      debugPrint('🚨 CRITICAL: App initialization failed: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Initialize heavy services in background without blocking UI
  Future<void> _initializeBackgroundServices() async {
    // Configurează webhookUrl pentru restaurante (dacă nu e configurat)
    unawaited(_configureRestaurantsWebhook());
    try {
      debugPrint('🔄 Starting background services initialization...');
      
      // ✅ NOU: Pornește timer-ul automat pentru resetare curse blocate (pentru testare)
      // NOTĂ: Nu anulăm automat cursele la pornire - utilizatorul ar putea fi în mașină
      FirestoreService().startStuckRideCleanupTimer();
      
      // Run independent initializations in parallel (non-fatal on errors)
      final List<Future<void>> tasks = <Future<void>>[
        PushNotificationService().initialize().then((_) => StartupTimer.instance.mark('push.ready')).catchError((e) => debugPrint('❌ PushNotificationService init: $e')),
        OfflineManager().initialize().then((_) => StartupTimer.instance.mark('offline.ready')).catchError((e) => debugPrint('❌ OfflineManager init: $e')),
        AppMonitor().initialize().then((_) => StartupTimer.instance.mark('appmonitor.ready')).catchError((e) => debugPrint('❌ AppMonitor init: $e')),
        if (!kIsWeb) MapboxConfig.initialize().then((_) => StartupTimer.instance.mark('mapbox.ready')).catchError((e) => debugPrint('❌ MapboxConfig init: $e')),
        RideIntentProcessor.initializeIsolate().then((_) => StartupTimer.instance.mark('nlp.ready')).catchError((e) => debugPrint('❌ NLP Isolate init: $e')),
      ];

      await Future.wait(tasks);
      debugPrint('✅ Background services initialized successfully.');
    } catch (e) {
      debugPrint('⚠️ Background services initialization error (non-fatal): $e');
    }
  }

  /// Configurează webhookUrl pentru toate restaurantele care nu au configurat
  Future<void> _configureRestaurantsWebhook() async {
    try {
      debugPrint('🔧 Configurare webhookUrl pentru restaurante...');
      
      final firestore = FirebaseFirestore.instance;
      final restaurantService = RestaurantService();
      
      // Obține toate restaurantele
      final restaurantsSnapshot = await firestore.collection('restaurants').get();
      
      if (restaurantsSnapshot.docs.isEmpty) {
        debugPrint('ℹ️ Nu există restaurante în Firestore');
        return;
      }
      
      // Detectează automat URL-ul corect pentru platformă
      final webhookUrl = _getWebhookUrlForPlatform();
      int configured = 0;
      int skipped = 0;
      
      for (final doc in restaurantsSnapshot.docs) {
        final restaurantId = doc.id;
        final data = doc.data();
        final currentWebhookUrl = data['webhookUrl'] as String?;
        
        // Dacă deja are webhookUrl configurat, skip
        if (currentWebhookUrl != null && currentWebhookUrl.isNotEmpty) {
          skipped++;
          continue;
        }
        
        // Configurează webhookUrl
        try {
          await restaurantService.updateRestaurant(
            restaurantId: restaurantId,
            webhookUrl: webhookUrl,
          );
          configured++;
          debugPrint('✅ Webhook URL configurat pentru restaurant $restaurantId');
        } catch (e) {
          debugPrint('⚠️ Eroare la configurarea webhookUrl pentru $restaurantId: $e');
        }
      }
      
      if (configured > 0) {
        debugPrint('✅ Webhook URL configurat pentru $configured restaurante (skip: $skipped)');
      } else if (skipped > 0) {
        debugPrint('ℹ️ Toate restaurantele au deja webhookUrl configurat ($skipped)');
      }
    } catch (e) {
      debugPrint('⚠️ Eroare la configurarea webhookUrl pentru restaurante (non-fatal): $e');
    }
  }

  /// Detectează automat URL-ul corect pentru webhook bazat pe platformă
  String _getWebhookUrlForPlatform() {
    // Production - folosește URL public (dacă e configurat)
    // if (Environment.isProduction) {
    //   return 'https://restaurant-app.yourdomain.com';
    // }
    
    // Development - detectează platforma
    if (kIsWeb) {
      // Web - folosește localhost (browser rulează pe PC)
      return 'http://localhost:3001';
    }
    
    // Mobile platforms
    if (Platform.isAndroid) {
      // Android Emulator: 10.0.2.2 = localhost-ul PC-ului
      // Android Device: trebuie IP-ul PC-ului (configurat manual)
      // Pentru emulator, folosim 10.0.2.2
      // Pentru device fizic, trebuie configurat manual în Firestore
      return 'http://10.0.2.2:3001'; // ✅ Funcționează pe Android Emulator
    } else if (Platform.isIOS) {
      // iOS Simulator: localhost funcționează direct
      // iOS Device: trebuie IP-ul PC-ului (configurat manual)
      return 'http://localhost:3001'; // ✅ Funcționează pe iOS Simulator
    }
    
    // Default: localhost
    return 'http://localhost:3001';
    
    // NOTĂ IMPORTANTĂ:
    // - Pentru device-uri fizice (Android/iOS), trebuie să folosești IP-ul PC-ului
    //   Exemplu: http://192.168.1.100:3001
    // - Configurează manual în Firestore sau prin DeliverySettingsScreen
  }
}


