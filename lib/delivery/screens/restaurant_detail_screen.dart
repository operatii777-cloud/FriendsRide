import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant_model.dart';
import '../models/product_model.dart';
import '../services/restaurant_service.dart';
import '../services/cart_service.dart';
import '../scripts/sync_menu_to_firestore_and_cache.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

/// Screen pentru detalii restaurant și meniu
class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  final CartService _cartService = CartService();
  List<Product> _menu = [];
  Map<String, List<Product>> _menuByCategory = {};
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _cartService.setRestaurant(widget.restaurant);
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    debugPrint('🔍 [RESTAURANT_DETAIL] Loading menu for restaurant: ${widget.restaurant.id}');
    debugPrint('🔍 [RESTAURANT_DETAIL] WebhookUrl: ${widget.restaurant.webhookUrl}');

    try {
      final menu = await _restaurantService.getMenu(widget.restaurant.id);
      debugPrint('🔍 [RESTAURANT_DETAIL] Menu loaded: ${menu.length} products');

      // Dacă meniul este gol și restaurantul are webhookUrl configurat, sincronizează automat
      if (menu.isEmpty && 
          widget.restaurant.webhookUrl != null && 
          widget.restaurant.webhookUrl!.isNotEmpty) {
        debugPrint('🔍 [RESTAURANT_DETAIL] Menu is empty, attempting auto-sync from Restaurant App v3...');
        // Folosește scriptul de sincronizare care salvează direct în Firestore și cache
        try {
          await syncMenuToFirestoreAndCache(
            restaurantId: widget.restaurant.id,
            webhookUrl: widget.restaurant.webhookUrl!,
          );
          debugPrint('🔍 [RESTAURANT_DETAIL] Sync completed, reloading menu from cache...');
          // Reîncarcă meniul din cache (va fi disponibil imediat)
          final syncedMenu = await _restaurantService.getMenu(widget.restaurant.id, forceRefresh: false);
          debugPrint('🔍 [RESTAURANT_DETAIL] Synced menu loaded: ${syncedMenu.length} products');
        
          // Group by category
          final menuByCategory = <String, List<Product>>{};
          for (final product in syncedMenu) {
            if (!menuByCategory.containsKey(product.category)) {
              menuByCategory[product.category] = [];
            }
            menuByCategory[product.category]!.add(product);
          }

          if (mounted) {
            setState(() {
              _menu = syncedMenu;
              _menuByCategory = menuByCategory;
              _selectedCategory = menuByCategory.keys.isNotEmpty
                  ? menuByCategory.keys.first
                  : null;
              _isLoading = false;
            });
          }
          return;
        } catch (e) {
          debugPrint('❌ [RESTAURANT_DETAIL] Error during auto-sync: $e');
          // Continuă cu încărcarea normală dacă sincronizarea eșuează
        }
      }

      // Group by category
      final menuByCategory = <String, List<Product>>{};
      for (final product in menu) {
        if (!menuByCategory.containsKey(product.category)) {
          menuByCategory[product.category] = [];
        }
        menuByCategory[product.category]!.add(product);
      }

      if (mounted) {
        setState(() {
          _menu = menu;
          _menuByCategory = menuByCategory;
          _selectedCategory = menuByCategory.keys.isNotEmpty
              ? menuByCategory.keys.first
              : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la încărcarea meniului: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.restaurant.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: widget.restaurant.imageUrl != null
                  ? Image.network(
                      widget.restaurant.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),

          // Restaurant info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating and delivery info
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            widget.restaurant.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${widget.restaurant.reviewCount})',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.restaurant.estimatedDeliveryTime} min',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.delivery_dining, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.restaurant.deliveryFee.toStringAsFixed(2)} RON',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    widget.restaurant.description,
                    style: TextStyle(color: Colors.grey[700]),
                  ),

                  const SizedBox(height: 8),

                  // Cuisine types
                  Wrap(
                    spacing: 8,
                    children: widget.restaurant.cuisineTypes.map((type) {
                      return Chip(
                        label: Text(type),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),

                  const Divider(height: 32),
                ],
              ),
            ),
          ),

          // Category tabs
          if (_menuByCategory.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _menuByCategory.keys.length,
                  itemBuilder: (context, index) {
                    final category = _menuByCategory.keys.elementAt(index);
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = category);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

          // Menu items
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_menu.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Meniul este gol',
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      if (widget.restaurant.webhookUrl != null && widget.restaurant.webhookUrl!.isNotEmpty)
                        Text(
                          'Restaurant App v3: ${widget.restaurant.webhookUrl}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      const SizedBox(height: 24),
                      if (widget.restaurant.webhookUrl != null && widget.restaurant.webhookUrl!.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _syncMenuFromRestaurantAppV3,
                          icon: const Icon(Icons.sync),
                          label: const Text('Sincronizează meniul din Restaurant App v3'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (widget.restaurant.webhookUrl != null && widget.restaurant.webhookUrl!.isNotEmpty)
                        Text(
                          'Asigură-te că Restaurant App v3 rulează pe portul 3001',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = _selectedCategory ?? _menuByCategory.keys.first;
                  final products = _menuByCategory[category] ?? [];
                  if (index >= products.length) return null;
                  final product = products[index];
                  return _buildProductCard(product);
                },
                childCount: _selectedCategory != null
                    ? (_menuByCategory[_selectedCategory]?.length ?? 0)
                    : _menu.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CartScreen(cartService: _cartService),
            ),
          );
        },
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Coș'),
      ),
    );
  }

  /// Sincronizează meniurile din Restaurant App v3 către FriendsRide
  Future<void> _syncMenuFromRestaurantAppV3({bool silent = false}) async {
    debugPrint('🔄 [SYNC_MENU] Starting menu sync from Restaurant App v3');
    
    if (widget.restaurant.webhookUrl == null || widget.restaurant.webhookUrl!.isEmpty) {
      debugPrint('❌ [SYNC_MENU] WebhookUrl is not configured');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Restaurant App v3 nu este configurat. Configurează webhookUrl în setări.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted && !silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se sincronizează meniurile din Restaurant App v3...')),
      );
    }

    try {
      // Normalizează URL-ul pentru a funcționa atât pe emulator cât și pe device fizic
      final normalizedUrl = await _normalizeWebhookUrl(widget.restaurant.webhookUrl!);
      final menuUrl = Uri.parse('$normalizedUrl/api/menu/all?lang=ro');
      debugPrint('🔄 [SYNC_MENU] Fetching from: $menuUrl');
      final response = await http.get(menuUrl).timeout(const Duration(seconds: 30));
      debugPrint('🔄 [SYNC_MENU] Response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Restaurant App v3 nu rulează (${response.statusCode}). Asigură-te că rulează pe portul 3001.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final menuData = jsonDecode(response.body);
      debugPrint('🔄 [SYNC_MENU] Response body type: ${menuData.runtimeType}');
      debugPrint('🔄 [SYNC_MENU] Response keys: ${menuData is Map ? menuData.keys.toList() : 'N/A'}');
      
      // Răspunsul de la server este: {"message":"...", "data":[...]}
      final products = menuData is List 
          ? menuData 
          : (menuData['data'] as List<dynamic>? ?? menuData['menu'] as List<dynamic>? ?? []);
      
      debugPrint('🔄 [SYNC_MENU] Extracted products count: ${products.length}');
      
      if (products.isEmpty) {
        debugPrint('⚠️ [SYNC_MENU] No products found in response');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Nu există produse în Restaurant App v3. Adaugă produse în admin.html.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final firestore = FirebaseFirestore.instance;
      int syncedCount = 0;
      int errorCount = 0;

      debugPrint('🔄 [SYNC_MENU] Processing ${products.length} products...');

      for (final productData in products) {
        try {
          final productId = (productData['id'] ?? productData['product_id'] ?? '').toString();
          final firestoreProductId = productId.isNotEmpty 
              ? productId 
              : firestore.collection('products').doc().id;
          
          debugPrint('🔄 [SYNC_MENU] Syncing product: ${productData['name'] ?? 'Unknown'} (ID: $firestoreProductId)');
          
          final product = {
            'restaurantId': widget.restaurant.id,
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

          await firestore.collection('products').doc(firestoreProductId).set(product);
          syncedCount++;
          debugPrint('✅ [SYNC_MENU] Product synced: ${productData['name'] ?? 'Unknown'}');
        } catch (e, stackTrace) {
          errorCount++;
          debugPrint('❌ [SYNC_MENU] Error syncing product ${productData['name'] ?? 'Unknown'}: $e');
          debugPrint('❌ [SYNC_MENU] Stack trace: $stackTrace');
          debugPrint('❌ [SYNC_MENU] Product data keys: ${productData is Map ? productData.keys.toList() : 'N/A'}');
          // Continuă cu următorul produs
        }
      }

      debugPrint('✅ [SYNC_MENU] Sync completed: $syncedCount successful, $errorCount errors');

      if (mounted) {
        if (syncedCount > 0) {
          if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ $syncedCount produse sincronizate din Restaurant App v3'),
                backgroundColor: Colors.green,
              ),
            );
          }
          // Reîncarcă meniul doar dacă nu e silent (pentru că _loadMenu va fi apelat din exterior)
          if (!silent) {
            await _loadMenu();
          }
        } else {
          if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Nu s-au putut sincroniza produsele'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } on http.ClientException catch (e) {
      debugPrint('❌ [SYNC_MENU] HTTP Client Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Nu se poate conecta la Restaurant App v3: $e\n💡 Asigură-te că Restaurant App v3 rulează pe portul 3001'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [SYNC_MENU] General error: $e');
      debugPrint('❌ [SYNC_MENU] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Eroare la sincronizarea meniului: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                product: product,
                restaurant: widget.restaurant,
                cartService: _cartService,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildProductPlaceholder(),
                      )
                    : _buildProductPlaceholder(),
              ),

              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${product.price.toStringAsFixed(2)} RON',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Add button
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        product: product,
                        restaurant: widget.restaurant,
                        cartService: _cartService,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[300],
      child: Icon(
        Icons.restaurant,
        size: 64,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildProductPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: Icon(
        Icons.fastfood,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }

  /// Normalizează URL-ul webhook pentru a funcționa atât pe emulator cât și pe device fizic
  Future<String> _normalizeWebhookUrl(String webhookUrl) async {
    // Dacă URL-ul conține localhost sau 127.0.0.1 sau 10.0.2.2, înlocuiește cu adresa corectă
    if (webhookUrl.contains('localhost') || webhookUrl.contains('127.0.0.1') || webhookUrl.contains('10.0.2.2')) {
      if (Platform.isAndroid) {
        try {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          
          // Dacă este device fizic, folosește IP-ul configurat sau IP-ul default
          if (androidInfo.isPhysicalDevice) {
            // Încearcă să citească IP-ul configurat din SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            final configuredHost = prefs.getString('restaurant_app_v3_ip');
            
            // Dacă există host configurat, folosește-l
            if (configuredHost != null && configuredHost.isNotEmpty) {
              debugPrint('✅ [NORMALIZE_URL] Using configured host: $configuredHost');
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
            // NOTĂ: Utilizatorul poate configura URL-ul în DeliverySettingsScreen
            const defaultPcIp = '192.168.50.238'; // IP-ul PC-ului detectat
            debugPrint('⚠️ [NORMALIZE_URL] No configured host found, using default: $defaultPcIp');
            debugPrint('💡 [NORMALIZE_URL] Configure URL in Delivery Settings for mobile data usage');
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
          debugPrint('⚠️ [NORMALIZE_URL] Error detecting device type: $e');
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
}

