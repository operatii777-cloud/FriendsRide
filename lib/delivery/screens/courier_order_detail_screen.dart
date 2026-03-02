import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/delivery_order_model.dart';
import '../models/delivery_status.dart';
import '../services/delivery_service.dart';

/// Screen pentru detalii comandă pentru curier
class CourierOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const CourierOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<CourierOrderDetailScreen> createState() => _CourierOrderDetailScreenState();
}

class _CourierOrderDetailScreenState extends State<CourierOrderDetailScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  DeliveryOrder? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _subscribeToOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _deliveryService.getOrder(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
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

  void _subscribeToOrder() {
    _deliveryService.getOrderStream(widget.orderId).listen((order) {
      if (mounted) {
        setState(() => _order = order);
      }
    });
  }

  Future<void> _markAsPickedUp() async {
    try {
      await _deliveryService.markAsPickedUp(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comanda a fost marcată ca preluată')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    }
  }

  Future<void> _markAsOnTheWay() async {
    try {
      await _deliveryService.markAsOnTheWay(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comanda este în drum')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    }
  }

  Future<void> _markAsDelivered() async {
    try {
      await _deliveryService.markAsDelivered(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comanda a fost livrată')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    }
  }

  Future<void> _openNavigation(String address) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nu s-a putut deschide navigația')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalii comandă')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalii comandă')),
        body: const Center(child: Text('Comanda nu a fost găsită')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Comandă #${_order!.id.substring(0, 8)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Card(
              color: _getStatusColor(_order!.status),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(_getStatusIcon(_order!.status), size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(_order!.status),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getStatusDescription(_order!.status),
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Restaurant address
            Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Restaurant'),
                subtitle: Text(_order!.restaurantAddress.address),
                trailing: IconButton(
                  icon: const Icon(Icons.navigation),
                  onPressed: () => _openNavigation(_order!.restaurantAddress.address),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Delivery address
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Adresă livrare'),
                subtitle: Text(_order!.deliveryAddress.address),
                trailing: IconButton(
                  icon: const Icon(Icons.navigation),
                  onPressed: () => _openNavigation(_order!.deliveryAddress.address),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Items
            const Text(
              'Produse',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._order!.items.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item.productName),
                  subtitle: Text('${item.quantity}x ${item.unitPrice.toStringAsFixed(2)} RON'),
                  trailing: Text(
                    '${item.totalPrice.toStringAsFixed(2)} RON',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Total
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_order!.total.toStringAsFixed(2)} RON',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (_order!.status) {
      case DeliveryOrderStatus.accepted:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _markAsPickedUp,
                icon: const Icon(Icons.check),
                label: const Text('Marchează ca preluată'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
      case DeliveryOrderStatus.pickedUp:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _markAsOnTheWay,
                icon: const Icon(Icons.directions_bike),
                label: const Text('Începe livrarea'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
      case DeliveryOrderStatus.onTheWay:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _markAsDelivered,
                icon: const Icon(Icons.check_circle),
                label: const Text('Marchează ca livrată'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(DeliveryOrderStatus status) {
    switch (status) {
      case DeliveryOrderStatus.pending:
      case DeliveryOrderStatus.accepted:
        return Colors.blue[50]!;
      case DeliveryOrderStatus.preparing:
      case DeliveryOrderStatus.ready:
        return Colors.orange[50]!;
      case DeliveryOrderStatus.pickedUp:
      case DeliveryOrderStatus.onTheWay:
        return Colors.purple[50]!;
      case DeliveryOrderStatus.delivered:
        return Colors.green[50]!;
      case DeliveryOrderStatus.cancelled:
        return Colors.red[50]!;
    }
  }

  IconData _getStatusIcon(DeliveryOrderStatus status) {
    switch (status) {
      case DeliveryOrderStatus.pending:
        return Icons.access_time;
      case DeliveryOrderStatus.accepted:
        return Icons.check_circle_outline;
      case DeliveryOrderStatus.preparing:
        return Icons.restaurant;
      case DeliveryOrderStatus.ready:
        return Icons.restaurant_menu;
      case DeliveryOrderStatus.pickedUp:
        return Icons.delivery_dining;
      case DeliveryOrderStatus.onTheWay:
        return Icons.directions_bike;
      case DeliveryOrderStatus.delivered:
        return Icons.check_circle;
      case DeliveryOrderStatus.cancelled:
        return Icons.cancel;
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

  String _getStatusDescription(DeliveryOrderStatus status) {
    switch (status) {
      case DeliveryOrderStatus.accepted:
        return 'Mergi la restaurant pentru a prelua comanda';
      case DeliveryOrderStatus.pickedUp:
        return 'Comanda a fost preluată, pornește către client';
      case DeliveryOrderStatus.onTheWay:
        return 'Livrează comanda la adresa clientului';
      default:
        return '';
    }
  }
}

