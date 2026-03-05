import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/delivery_order_model.dart';
import '../models/product_model.dart';
import '../models/delivery_status.dart';
import '../services/delivery_service.dart';
import '../services/restaurant_service.dart';
import 'package:file_picker/file_picker.dart';
import 'product_edit_screen.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Dashboard Manual pentru restaurante mici
/// 
/// Permite restaurante să gestioneze manual:
/// - Menu management
/// - Order management
/// - Settings
class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen>
    with SingleTickerProviderStateMixin {
  final DeliveryService _deliveryService = DeliveryService();
  final RestaurantService _restaurantService = RestaurantService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TabController? _tabController;
  List<DeliveryOrder> _orders = [];
  final List<Product> _menu = [];
  bool _isLoading = true;
  String? _restaurantId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get restaurant ID for current user
      final user = _auth.currentUser;
      if (user != null) {
        _restaurantId = await _restaurantService.getRestaurantIdByOwnerId(user.uid);
        
        if (_restaurantId != null) {
          // Load menu
          final menu = await _restaurantService.getMenu(_restaurantId!);
          if (mounted) {
            setState(() => _menu.clear());
            setState(() => _menu.addAll(menu));
          }

          // Load orders
          _deliveryService.getRestaurantOrders(restaurantId: _restaurantId!).listen((orders) {
            if (mounted) {
              setState(() => _orders = orders);
            }
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nu ai un restaurant asociat. Contactează suportul pentru onboarding.'),
              ),
            );
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Restaurant'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Meniu'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Comenzi'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMenuTab(),
                _buildOrdersTab(),
              ],
            ),
    );
  }

  Widget _buildMenuTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Adaugă produs'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _importMenuFromCSV,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import CSV'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _menu.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Meniul este gol'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _addProduct,
                        child: const Text('Adaugă primul produs'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _menu.length,
                  itemBuilder: (context, index) {
                    final product = _menu[index];
                    return _buildProductCard(product);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: product.imageUrl != null
            ? Image.network(product.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
            : const Icon(Icons.fastfood),
        title: Text(product.name),
        subtitle: Text('${product.price.toStringAsFixed(2)} RON • ${product.category}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editProduct(product),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteProduct(product),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Toate'),
                selected: true,
                onSelected: (selected) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('În așteptare'),
                selected: false,
                onSelected: (selected) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Gata'),
                selected: false,
                onSelected: (selected) {},
              ),
            ],
          ),
        ),
        Expanded(
          child: _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Nu sunt comenzi'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderCard(order);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(DeliveryOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text('Comandă #${order.id.substring(0, 8)}'),
        subtitle: Text('${order.items.length} produse • ${order.total.toStringAsFixed(2)} RON'),
        trailing: Chip(
          label: Text(_getStatusText(order.status)),
          backgroundColor: _getStatusColor(order.status),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) {
                  return ListTile(
                    dense: true,
                    title: Text(item.productName),
                    subtitle: Text('${item.quantity}x ${item.unitPrice.toStringAsFixed(2)} RON'),
                    trailing: Text('${item.totalPrice.toStringAsFixed(2)} RON'),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${order.total.toStringAsFixed(2)} RON',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (order.status == DeliveryOrderStatus.pending ||
                    order.status == DeliveryOrderStatus.accepted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(order.id, DeliveryOrderStatus.preparing),
                      child: const Text('Marchează ca se pregătește'),
                    ),
                  ),
                if (order.status == DeliveryOrderStatus.preparing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(order.id, DeliveryOrderStatus.ready),
                      child: const Text('Marchează ca gata'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _addProduct() {
    if (_restaurantId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductEditScreen(restaurantId: _restaurantId!),
      ),
    ).then((added) {
      if (added == true) {
        _loadData();
      }
    });
  }

  void _editProduct(Product product) {
    if (_restaurantId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductEditScreen(
          restaurantId: _restaurantId!,
          product: product,
        ),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadData();
      }
    });
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge produs'),
        content: Text('Ești sigur că vrei să ștergi "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _restaurantService.deleteProduct(product.id);
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Produs șters cu succes')),
                );
                _loadData();
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Eroare: $e')),
                );
              }
            },
            child: const Text('Șterge', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _importMenuFromCSV() async {
    if (_restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu ai un restaurant asociat')),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final content = await file.readAsString();
        
        // Parse CSV
        final lines = content.split('\n');
        if (lines.isEmpty) {
          throw Exception('Fișierul CSV este gol');
        }

        // Skip header line
        final dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty).toList();
        
        int successCount = 0;
        int errorCount = 0;

        for (final line in dataLines) {
          try {
            // CSV format: name,description,price,category,imageUrl,isAvailable,allergens
            final fields = line.split(',').map((f) => f.trim()).toList();
            
            if (fields.length < 4) {
              errorCount++;
              continue;
            }

            final name = fields[0];
            final description = fields.length > 1 ? fields[1] : '';
            final price = double.tryParse(fields[2]) ?? 0.0;
            final category = fields.length > 3 ? fields[3] : 'Altele';
            final imageUrl = fields.length > 4 && fields[4].isNotEmpty ? fields[4] : null;
            final isAvailable = fields.length > 5 ? fields[5].toLowerCase() == 'true' : true;
            final allergens = fields.length > 6 && fields[6].isNotEmpty
                ? fields[6].split(';').map((a) => a.trim()).where((a) => a.isNotEmpty).toList()
                : <String>[];

            await _restaurantService.createProduct(
              restaurantId: _restaurantId!,
              name: name,
              description: description,
              price: price,
              category: category,
              imageUrl: imageUrl,
              isAvailable: isAvailable,
              allergens: allergens,
            );

            successCount++;
          } catch (e) {
            errorCount++;
            Logger.error('Error importing product from CSV: $e', error: e);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import complet: $successCount produse adăugate, $errorCount erori'),
            ),
          );
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la import CSV: $e')),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, DeliveryOrderStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _deliveryService.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Status actualizat: ${_getStatusText(status)}')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Eroare: $e')),
      );
    }
  }

  String _getStatusText(DeliveryOrderStatus status) {
    switch (status) {
      case DeliveryOrderStatus.pending:
        return 'În așteptare';
      case DeliveryOrderStatus.accepted:
        return 'Acceptată';
      case DeliveryOrderStatus.preparing:
        return 'Se pregătește';
      case DeliveryOrderStatus.ready:
        return 'Gata';
      case DeliveryOrderStatus.pickedUp:
        return 'Preluată';
      case DeliveryOrderStatus.onTheWay:
        return 'În drum';
      case DeliveryOrderStatus.delivered:
        return 'Livrată';
      case DeliveryOrderStatus.cancelled:
        return 'Anulată';
    }
  }

  Color _getStatusColor(DeliveryOrderStatus status) {
    switch (status) {
      case DeliveryOrderStatus.pending:
        return Colors.orange[100]!;
      case DeliveryOrderStatus.accepted:
      case DeliveryOrderStatus.preparing:
        return Colors.blue[100]!;
      case DeliveryOrderStatus.ready:
        return Colors.green[100]!;
      case DeliveryOrderStatus.pickedUp:
      case DeliveryOrderStatus.onTheWay:
        return Colors.purple[100]!;
      case DeliveryOrderStatus.delivered:
        return Colors.green[200]!;
      case DeliveryOrderStatus.cancelled:
        return Colors.red[100]!;
    }
  }

}

