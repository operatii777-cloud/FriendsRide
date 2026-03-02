import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../models/restaurant_model.dart';
import '../models/order_item_model.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';

/// Screen pentru detalii produs cu modificări
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Restaurant restaurant;
  final CartService? cartService;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.restaurant,
    this.cartService,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _uuid = const Uuid();
  int _quantity = 1;
  final Map<String, ProductModification> _selectedModifications = {};
  final TextEditingController _notesController = TextEditingController();
  late final CartService _cartService;

  @override
  void initState() {
    super.initState();
    _cartService = widget.cartService ?? CartService();
    // Set restaurant in cart if not already set
    if (_cartService.selectedRestaurant?.id != widget.restaurant.id) {
      _cartService.setRestaurant(widget.restaurant);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    double total = widget.product.price * _quantity;
    for (final mod in _selectedModifications.values) {
      if (mod.price != null) {
        total += mod.price! * _quantity;
      }
    }
    return total;
  }

  void _addToCart() {
    final modificationsList = _selectedModifications.values
        .map((mod) => mod.name)
        .toList();
    
    // Create order item
    final orderItem = OrderItem(
      id: _uuid.v4(),
      productId: widget.product.id,
      productName: widget.product.name,
      quantity: _quantity,
      unitPrice: widget.product.price,
      totalPrice: _totalPrice,
      modifications: modificationsList,
      specialNotes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    // Add to cart service
    _cartService.addItem(orderItem);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} adăugat în coș'),
        action: SnackBarAction(
          label: 'Vezi coș',
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(cartService: _cartService),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            widget.product.imageUrl != null
                ? Image.network(
                    widget.product.imageUrl!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${widget.product.price.toStringAsFixed(2)} RON',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    widget.product.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),

                  // Allergens
                  if (widget.product.allergens.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Alergeni:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.product.allergens.map((allergen) {
                        return Chip(
                          label: Text(allergen),
                          backgroundColor: Colors.red[100],
                        );
                      }).toList(),
                    ),
                  ],

                  // Modifications
                  if (widget.product.availableModifications != null &&
                      widget.product.availableModifications!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Modificări:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.product.availableModifications!.map((mod) {
                      final isSelected = _selectedModifications.containsKey(mod.id);
                      return CheckboxListTile(
                        title: Text(mod.name),
                        subtitle: mod.price != null
                            ? Text('+${mod.price!.toStringAsFixed(2)} RON')
                            : const Text('Gratis'),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedModifications[mod.id] = mod;
                            } else {
                              _selectedModifications.remove(mod.id);
                            }
                          });
                        },
                      );
                    }),
                  ],

                  // Notes
                  const SizedBox(height: 24),
                  const Text(
                    'Note speciale:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Fără ceapă, extra sos...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  // Quantity
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Cantitate:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                              }
                            },
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setState(() => _quantity++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${_totalPrice.toStringAsFixed(2)} RON',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Adaugă în coș'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.grey[300],
      child: Icon(
        Icons.fastfood,
        size: 64,
        color: Colors.grey[400],
      ),
    );
  }
}

