import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:friendsride_app/services/intelligent_cache_service.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Script pentru sincronizarea meniului din Restaurant App v3 în Firestore și cache
/// 
/// Acest script:
/// 1. Preia meniul din Restaurant App v3
/// 2. Salvează produsele în Firestore
/// 3. Salvează meniul în cache pentru acces rapid
Future<void> syncMenuToFirestoreAndCache({
  required String restaurantId,
  required String webhookUrl,
}) async {
  final firestore = FirebaseFirestore.instance;
  final cache = IntelligentCacheService();
  final cacheKey = 'menu_$restaurantId';
  
  Logger.info('🔄 [SYNC_SCRIPT] Starting menu sync for restaurant: $restaurantId', tag: 'SYNC');
  Logger.info('🔄 [SYNC_SCRIPT] Webhook URL: $webhookUrl', tag: 'SYNC');

  try {
    // Normalizează URL-ul pentru a funcționa atât pe emulator cât și pe device fizic
    final normalizedUrl = await _normalizeWebhookUrl(webhookUrl);
    Logger.info('🔄 [SYNC_SCRIPT] Normalized URL: $normalizedUrl', tag: 'SYNC');
    
    // 1. Preia meniul din Restaurant App v3
    final menuUrl = Uri.parse('$normalizedUrl/api/menu/all?lang=ro');
    Logger.info('🔄 [SYNC_SCRIPT] Fetching from: $menuUrl', tag: 'SYNC');
    
    final response = await http.get(menuUrl).timeout(const Duration(seconds: 30));
    Logger.info('🔄 [SYNC_SCRIPT] Response status: ${response.statusCode}', tag: 'SYNC');
    
    if (response.statusCode != 200) {
      Logger.error('❌ [SYNC_SCRIPT] Server returned status ${response.statusCode}', tag: 'SYNC');
      throw Exception('Server returned status ${response.statusCode}');
    }

    // 2. Parsează răspunsul
    final menuData = jsonDecode(response.body);
    Logger.info('🔄 [SYNC_SCRIPT] Response type: ${menuData.runtimeType}', tag: 'SYNC');
    
    // Răspunsul de la server este: {"message":"...", "data":[...]}
    final products = menuData is List 
        ? menuData 
        : (menuData['data'] as List<dynamic>? ?? menuData['menu'] as List<dynamic>? ?? []);
    
    Logger.info('🔄 [SYNC_SCRIPT] Extracted ${products.length} products', tag: 'SYNC');
    
    if (products.isEmpty) {
      Logger.warning('⚠️ [SYNC_SCRIPT] No products found in response', tag: 'SYNC');
      return;
    }

    // 3. Salvează produsele în Firestore
    int syncedCount = 0;
    int errorCount = 0;
    final List<Map<String, dynamic>> cacheData = [];

    Logger.info('🔄 [SYNC_SCRIPT] Processing ${products.length} products...', tag: 'SYNC');

    for (final productData in products) {
      try {
        final productId = (productData['id'] ?? productData['product_id'] ?? '').toString();
        final firestoreProductId = productId.isNotEmpty 
            ? productId 
            : firestore.collection('products').doc().id;
        
        final product = {
          'restaurantId': restaurantId,
          'name': productData['name'] ?? productData['name_ro'] ?? 'Produs fără nume',
          'description': productData['description'] ?? productData['description_ro'] ?? '',
          'price': ((productData['price'] ?? productData['sell_price'] ?? 0.0) as num).toDouble(),
          'category': productData['category'] ?? productData['category_ro'] ?? 'Other',
          'imageUrl': productData['image_url'] ?? productData['imageUrl'],
          'isAvailable': (productData['is_sellable'] ?? productData['isAvailable'] ?? 1) == 1,
          'allergens': _parseAllergens(productData['allergens']),
          'availableModifications': _parseModifications(productData['modifications'] ?? []),
          'nutritionalInfo': productData['nutritional_info'] ?? productData['nutritionalInfo'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Salvează în Firestore
        await firestore.collection('products').doc(firestoreProductId).set(product);
        
        // Adaugă la cache data (pentru salvare ulterioară)
        cacheData.add({
          'id': firestoreProductId,
          'restaurantId': restaurantId,
          'name': product['name'],
          'description': product['description'],
          'price': product['price'],
          'imageUrl': product['imageUrl'],
          'category': product['category'],
          'isAvailable': product['isAvailable'],
          'allergens': product['allergens'],
          'nutritionalInfo': product['nutritionalInfo'],
          'availableModifications': product['availableModifications'],
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        
        syncedCount++;
        Logger.info('✅ [SYNC_SCRIPT] Product synced: ${product['name']} (ID: $firestoreProductId)', tag: 'SYNC');
      } catch (e, stackTrace) {
        errorCount++;
        Logger.error('❌ [SYNC_SCRIPT] Error syncing product ${productData['name'] ?? 'Unknown'}: $e', tag: 'SYNC');
        Logger.error('❌ [SYNC_SCRIPT] Stack trace: $stackTrace', tag: 'SYNC');
      }
    }

    Logger.info('✅ [SYNC_SCRIPT] Firestore sync completed: $syncedCount successful, $errorCount errors', tag: 'SYNC');

    // 4. Salvează meniul în cache pentru acces rapid
    if (cacheData.isNotEmpty) {
      await cache.set(
        cacheKey,
        cacheData,
        ttl: const Duration(minutes: 15), // Cache TTL de 15 minute
        priority: 2, // Prioritate medie pentru meniu
      );
      Logger.info('✅ [SYNC_SCRIPT] Menu cached: ${cacheData.length} products', tag: 'SYNC');
    }

    Logger.info('✅ [SYNC_SCRIPT] Complete sync finished successfully!', tag: 'SYNC');
  } catch (e, stackTrace) {
    Logger.error('❌ [SYNC_SCRIPT] Fatal error: $e', tag: 'SYNC');
    Logger.error('❌ [SYNC_SCRIPT] Stack trace: $stackTrace', tag: 'SYNC');
    rethrow;
  }
}

List<String> _parseAllergens(dynamic allergens) {
  if (allergens == null) return [];
  if (allergens is String) {
    try {
      final parsed = jsonDecode(allergens);
      if (parsed is List) return parsed.cast<String>();
    } catch (_) {
      return allergens.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
  }
  if (allergens is List) return allergens.cast<String>();
  return [];
}

List<Map<String, dynamic>> _parseModifications(dynamic modifications) {
  if (modifications == null || modifications is! List) return [];
  return modifications.map((mod) {
    if (mod is Map) {
      return {
        'id': mod['id'] ?? '',
        'name': mod['name'] ?? mod['name_ro'] ?? '',
        'price': ((mod['price'] ?? 0.0) as num).toDouble(),
      };
    }
    return {'id': '', 'name': '', 'price': 0.0};
  }).toList();
}

/// Normalizează URL-ul webhook pentru a funcționa atât pe emulator cât și pe device fizic
Future<String> _normalizeWebhookUrl(String webhookUrl) async {
  // Dacă URL-ul conține localhost sau 127.0.0.1 sau 10.0.2.2, înlocuiește cu adresa corectă
  if (webhookUrl.contains('localhost') || webhookUrl.contains('127.0.0.1') || webhookUrl.contains('10.0.2.2')) {
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        
        // Dacă este device fizic, folosește host-ul configurat sau IP-ul default
        if (androidInfo.isPhysicalDevice) {
          // Încearcă să citească host-ul configurat din SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final configuredHost = prefs.getString('restaurant_app_v3_ip');
          
          // Dacă există host configurat, folosește-l
          if (configuredHost != null && configuredHost.isNotEmpty) {
            Logger.info('✅ [NORMALIZE_URL] Using configured host: $configuredHost', tag: 'SYNC');
            // Dacă webhookUrl este localhost sau 10.0.2.2, înlocuiește doar host-ul
            final uri = Uri.tryParse(webhookUrl);
            if (uri != null) {
              // Păstrează protocolul și portul, schimbă doar host-ul
              final newUri = uri.replace(host: configuredHost);
              return newUri.toString();
            }
            // Fallback: înlocuiește simplu
            return webhookUrl
                .replaceAll('localhost', configuredHost)
                .replaceAll('127.0.0.1', configuredHost)
                .replaceAll('10.0.2.2', configuredHost);
          }
          
          // Dacă nu există host configurat, folosește IP-ul default
          // NOTĂ: Pentru utilizare pe date mobile, configurează URL-ul public (ngrok, etc.)
          const defaultPcIp = '192.168.50.238'; // IP-ul PC-ului detectat
          Logger.warning('⚠️ [NORMALIZE_URL] No configured host found, using default: $defaultPcIp', tag: 'SYNC');
          Logger.warning('💡 [NORMALIZE_URL] Configure URL in Delivery Settings for mobile data usage', tag: 'SYNC');
          return webhookUrl
              .replaceAll('localhost', defaultPcIp)
              .replaceAll('127.0.0.1', defaultPcIp)
              .replaceAll('10.0.2.2', defaultPcIp);
        } else {
          // Pentru emulator Android, folosește 10.0.2.2
          return webhookUrl
              .replaceAll('localhost', '10.0.2.2')
              .replaceAll('127.0.0.1', '10.0.2.2');
        }
      } catch (e) {
        Logger.warning('⚠️ [NORMALIZE_URL] Error detecting device type: $e', tag: 'SYNC');
        // Fallback: presupunem că este emulator
        return webhookUrl
            .replaceAll('localhost', '10.0.2.2')
            .replaceAll('127.0.0.1', '10.0.2.2');
      }
    } else if (Platform.isIOS) {
      // Pentru iOS Simulator, localhost funcționează direct
      // Pentru device fizic iOS, ar trebui să folosească IP-ul PC-ului
      return webhookUrl;
    }
  }
  // Returnează URL-ul neschimbat dacă nu este localhost sau dacă este iOS
  return webhookUrl;
}

