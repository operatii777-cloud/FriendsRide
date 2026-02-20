import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:printing/printing.dart';
import 'package:friendsride_app/models/saved_address_model.dart';
import 'package:friendsride_app/services/pdf_receipt_service.dart';
import '../models/order_item_model.dart';
import '../models/restaurant_model.dart';
import '../services/delivery_service.dart';
import '../services/cart_service.dart';
import 'delivery_tracking_screen.dart';
import 'my_orders_screen.dart';

/// Screen pentru checkout și plată
class CheckoutScreen extends StatefulWidget {
  final List<OrderItem> cartItems;
  final Restaurant restaurant;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.restaurant,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  final CartService _cartService = CartService();
  final PdfReceiptService _pdfService = PdfReceiptService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _paymentMethod = 'card';
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return widget.cartItems.fold(0.0, (total, item) => total + item.totalPrice);
  }

  double get _deliveryFee {
    return widget.restaurant.deliveryFee;
  }

  double get _serviceFee {
    // Service fee: 10% of subtotal, max 3 RON
    return (_subtotal * 0.10).clamp(0.0, 3.0);
  }

  double get _total {
    return _subtotal + _deliveryFee + _serviceFee;
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilizator neautentificat');
      }

      // Get user location for delivery address
      geolocator.Position? userPosition;
      try {
        userPosition = await geolocator.Geolocator.getCurrentPosition(
          locationSettings: const geolocator.LocationSettings(
            accuracy: geolocator.LocationAccuracy.high,
          ),
        );
      } catch (e) {
        debugPrint('Error getting user location: $e');
      }

      // Create delivery address
      final deliveryAddress = SavedAddress(
        id: '',
        label: 'Livrare',
        address: _addressController.text,
        coordinates: userPosition != null
            ? GeoPoint(userPosition.latitude, userPosition.longitude)
            : widget.restaurant.address.coordinates,
      );

      // Create order using service
      final order = await _deliveryService.createOrder(
        restaurantId: widget.restaurant.id,
        items: widget.cartItems,
        deliveryAddress: deliveryAddress,
        restaurantAddress: widget.restaurant.address,
        paymentMethod: _paymentMethod,
        subtotal: _subtotal,
        deliveryFee: _deliveryFee,
        serviceFee: _serviceFee,
        total: _total,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      final orderId = order.id;

      // Golește cosul după plasarea comenzii
      _cartService.clear();

      if (mounted) {
        // Generează și descarcă PDF-ul
        await _generateAndDownloadPdf(order);

        // Afișează dialog cu opțiuni
        await _showOrderPlacedDialog(orderId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la plasarea comenzii: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.restaurant, color: Colors.orange),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.restaurant.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.restaurant.estimatedDeliveryTime} min • ${widget.restaurant.deliveryFee.toStringAsFixed(2)} RON livrare',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Delivery address
              const Text(
                'Adresă livrare',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'Strada, număr, bloc, apartament...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Introduceți adresa de livrare';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Phone
              const Text(
                'Telefon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  hintText: '07XX XXX XXX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Introduceți numărul de telefon';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Notes
              const Text(
                'Note pentru restaurant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Sunați la intrare, lăsați la ușă...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Payment method
              const Text(
                'Metodă de plată',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _paymentMethod,
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
                child: Column(
                  children: const [
                    RadioListTile<String>(
                      title: Text('Card'),
                      value: 'card',
                    ),
                    RadioListTile<String>(
                      title: Text('Numerar la livrare'),
                      value: 'cash',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Order summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', _subtotal),
                      _buildSummaryRow('Livrare', _deliveryFee),
                      _buildSummaryRow('Taxă serviciu', _serviceFee),
                      const Divider(),
                      _buildSummaryRow('Total', _total, isTotal: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Place order button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Plasează comanda'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} RON',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Generează și descarcă PDF-ul comenzii
  Future<void> _generateAndDownloadPdf(dynamic order) async {
    try {
      final pdfBytes = await _pdfService.generateDeliveryOrderReceipt(order);
      
      if (mounted) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'comanda_delivery_${order.id.substring(0, 8)}.pdf',
        );
      }
    } catch (e) {
      debugPrint('❌ Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la generarea PDF-ului: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Afișează dialog cu opțiuni după plasarea comenzii
  Future<void> _showOrderPlacedDialog(String orderId) async {
    if (!mounted) return;
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text('Comandă plasată!')),
          ],
        ),
        content: const Text(
          'Comanda ta a fost plasată cu succes!\n\nRezumatul comenzii a fost descărcat ca PDF.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('track'),
            child: const Text('Urmărește comanda'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('orders'),
            child: const Text('Comenzile mele'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('new'),
            child: const Text('Comandă nouă'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('home'),
            child: const Text('Acasă'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    // Navighează în funcție de opțiunea aleasă
    switch (result) {
      case 'track':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryTrackingScreen(orderId: orderId),
          ),
        );
        break;
      case 'orders':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MyOrdersScreen(),
          ),
          (route) => route.isFirst,
        );
        break;
      case 'new':
        // Revine la lista de restaurante (se va face în navigare)
        Navigator.popUntil(context, (route) => route.isFirst);
        break;
      case 'home':
      default:
        // Revine la ecranul principal
        Navigator.popUntil(context, (route) => route.isFirst);
        break;
    }
  }
}

