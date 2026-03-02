import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';
import '../services/restaurant_onboarding_service.dart';
import '../scripts/sync_menu_to_firestore_and_cache.dart';
import 'restaurant_detail_screen.dart';

/// Screen pentru listarea restaurante disponibile
class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  final RestaurantOnboardingService _onboardingService = RestaurantOnboardingService();
  final TextEditingController _searchController = TextEditingController();

  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCuisineType;
  double? _minRating;
  geolocator.Position? _userLocation;

  final List<String> _cuisineTypes = [
    'Pizza',
    'Burgers',
    'Sushi',
    'Chinese',
    'Italian',
    'Mexican',
    'Romanian',
    'Fast Food',
    'Desserts',
    'Vegetarian',
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadRestaurants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _userLocation = position;
        });
      }
    } catch (e) {
      debugPrint('Error getting user location: $e');
    }
  }

  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);

    try {
      final restaurants = await _restaurantService.getRestaurants(
        cuisineType: _selectedCuisineType,
        minRating: _minRating,
        status: RestaurantStatus.open,
      );

      // Sort by distance if user location is available
      if (_userLocation != null) {
        restaurants.sort((a, b) {
          final distA = _calculateDistance(
            _userLocation!.latitude,
            _userLocation!.longitude,
            a.address.coordinates.latitude,
            a.address.coordinates.longitude,
          );
          final distB = _calculateDistance(
            _userLocation!.latitude,
            _userLocation!.longitude,
            b.address.coordinates.latitude,
            b.address.coordinates.longitude,
          );
          return distA.compareTo(distB);
        });
      } else {
        // Sort by rating if no location
        restaurants.sort((a, b) => b.rating.compareTo(a.rating));
      }

      if (mounted) {
        setState(() {
          _restaurants = restaurants;
          _filteredRestaurants = restaurants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la încărcarea restaurante: $e')),
        );
      }
    }
  }

  void _filterRestaurants() {
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        final matchesSearch = _searchQuery.isEmpty ||
            restaurant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            restaurant.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            restaurant.cuisineTypes.any(
              (type) => type.toLowerCase().contains(_searchQuery.toLowerCase()),
            );

        final matchesCuisine = _selectedCuisineType == null ||
            restaurant.cuisineTypes.contains(_selectedCuisineType);

        final matchesRating = _minRating == null || restaurant.rating >= _minRating!;

        return matchesSearch && matchesCuisine && matchesRating;
      }).toList();
    });
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return geolocator.Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // km
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Caută restaurante...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _filterRestaurants();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _filterRestaurants();
              },
            ),
          ),

          // Filter chips
          if (_selectedCuisineType != null || _minRating != null)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_selectedCuisineType != null)
                    Chip(
                      label: Text(_selectedCuisineType!),
                      onDeleted: () {
                        setState(() => _selectedCuisineType = null);
                        _loadRestaurants();
                      },
                    ),
                  if (_minRating != null)
                    Chip(
                      label: Text('Rating: ${_minRating!.toStringAsFixed(1)}+'),
                      onDeleted: () {
                        setState(() => _minRating = null);
                        _loadRestaurants();
                      },
                    ),
                ],
              ),
            ),

          // Restaurant list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRestaurants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nu s-au găsit restaurante',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _createSampleRestaurants,
                              icon: const Icon(Icons.add_business),
                              label: const Text('Creează restaurante de test'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pentru testare',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRestaurants,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = _filteredRestaurants[index];
                            return _buildRestaurantCard(restaurant);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    final distance = _userLocation != null
        ? _calculateDistance(
            _userLocation!.latitude,
            _userLocation!.longitude,
            restaurant.address.coordinates.latitude,
            restaurant.address.coordinates.longitude,
          )
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailScreen(
                restaurant: restaurant,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: restaurant.imageUrl != null
                  ? Image.network(
                      restaurant.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Cuisine types
                  Wrap(
                    spacing: 8,
                    children: restaurant.cuisineTypes.take(3).map((type) {
                      return Chip(
                        label: Text(
                          type,
                          style: const TextStyle(fontSize: 12),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 8),

                  // Info row
                  Row(
                    children: [
                      if (distance != null) ...[
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.estimatedDeliveryTime} min',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.delivery_dining, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.deliveryFee.toStringAsFixed(2)} RON',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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

  Future<void> _createSampleRestaurants() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trebuie să fii autentificat pentru a crea restaurante')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se creează restaurantul conectat la Restaurant App v3...')),
      );
    }

    try {
      // Șterge restaurantele vechi (Pizza Place, Burger House) dacă există
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se curăță restaurantele vechi...')),
        );
      }

      final existingRestaurants = await _restaurantService.getRestaurants();
      final firestore = FirebaseFirestore.instance;
      
      for (final restaurant in existingRestaurants) {
        if (restaurant.name == 'Pizza Place' || 
            restaurant.name == 'Burger House' ||
            restaurant.name == 'Sushi Master' ||
            restaurant.name == 'La Mama') {
          try {
            // Șterge produsele asociate
            final productsSnapshot = await firestore
                .collection('products')
                .where('restaurantId', isEqualTo: restaurant.id)
                .get();
            
            for (final productDoc in productsSnapshot.docs) {
              await productDoc.reference.delete();
            }
            
            // Șterge restaurantul
            await firestore.collection('restaurants').doc(restaurant.id).delete();
          } catch (e) {
            // Ignoră erorile la ștergere
          }
        }
      }

      // Verifică dacă există deja "Restaurant App v3 Test"
      final updatedRestaurants = await _restaurantService.getRestaurants();
      Restaurant? existingTestRestaurant;
      try {
        existingTestRestaurant = updatedRestaurants.firstWhere(
          (r) => r.name == 'Restaurant App v3 Test',
        );
      } catch (_) {
        existingTestRestaurant = null;
      }

      if (existingTestRestaurant != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Restaurant App v3 Test există deja!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadRestaurants();
        }
        return;
      }

      // ✅ Restaurant App v3 Test Restaurant (conectat la Restaurant App v3)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se creează restaurantul conectat la Restaurant App v3...')),
        );
      }

      final restaurantId = await _onboardingService.createManualOnboardingRequest(
        restaurantName: 'Restaurant App v3 Test',
        description: 'Restaurant de test conectat la Restaurant App v3 cu meniurile existente',
        address: 'Strada Test 123, București',
        latitude: 44.4268,
        longitude: 26.1025,
        phoneNumber: '+40712345678',
        email: 'test@restaurantappv3.ro',
        ownerId: user.uid,
        commissionRate: 12.0,
        cuisineTypes: ['Romanian', 'Traditional'],
        deliveryFee: 7.0,
        minimumOrder: 30.0,
        estimatedDeliveryTime: 35,
        workingHours: {
          'monday': {'openTime': '10:00', 'closeTime': '22:00', 'isOpen': true},
          'tuesday': {'openTime': '10:00', 'closeTime': '22:00', 'isOpen': true},
          'wednesday': {'openTime': '10:00', 'closeTime': '22:00', 'isOpen': true},
          'thursday': {'openTime': '10:00', 'closeTime': '22:00', 'isOpen': true},
          'friday': {'openTime': '10:00', 'closeTime': '23:00', 'isOpen': true},
          'saturday': {'openTime': '10:00', 'closeTime': '23:00', 'isOpen': true},
          'sunday': {'openTime': '12:00', 'closeTime': '22:00', 'isOpen': true},
        },
      );

      // Configurează webhookUrl pentru Restaurant App v3
      await _restaurantService.updateRestaurant(
        restaurantId: restaurantId,
        webhookUrl: 'http://localhost:3001',
        restaurantAppV3TenantId: 'test_tenant_1',
      );

      // Sincronizează meniurile din Restaurant App v3
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se sincronizează meniurile din Restaurant App v3...')),
        );
      }

      await _syncMenuFromRestaurantAppV3(restaurantId);

      // Reîncarcă lista
      await _loadRestaurants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Restaurant App v3 Test creat cu succes! Meniurile au fost sincronizate.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Sincronizează meniurile din Restaurant App v3 către FriendsRide
  Future<void> _syncMenuFromRestaurantAppV3(String restaurantId) async {
    try {
      // Folosește scriptul centralizat care salvează în Firestore și cache
      await syncMenuToFirestoreAndCache(
        restaurantId: restaurantId,
        webhookUrl: 'http://localhost:3001',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Meniul a fost sincronizat și salvat în cache!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrează restaurante'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tip bucătărie:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _cuisineTypes.map((type) {
                  final isSelected = _selectedCuisineType == type;
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCuisineType = selected ? type : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Rating minim:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _minRating ?? 0.0,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      label: _minRating?.toStringAsFixed(1) ?? '0.0',
                      onChanged: (value) {
                        setState(() => _minRating = value);
                      },
                    ),
                  ),
                  Text(_minRating?.toStringAsFixed(1) ?? '0.0'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCuisineType = null;
                _minRating = null;
              });
            },
            child: const Text('Resetează'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadRestaurants();
            },
            child: const Text('Aplică'),
          ),
        ],
      ),
    );
  }
}

