import 'dart:async';
import 'package:flutter/material.dart';
import '../models/delivery_order_model.dart';
import '../models/delivery_status.dart';
import '../services/delivery_service.dart';

/// Screen pentru tracking live al comenzii
class DeliveryTrackingScreen extends StatefulWidget {
  final String orderId;

  const DeliveryTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  DeliveryOrder? _order;
  bool _isLoading = true;
  Timer? _cancelTimer;
  Duration? _timeRemaining;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _subscribeToOrder();
    _startCancelTimer();
  }

  @override
  void dispose() {
    _cancelTimer?.cancel();
    super.dispose();
  }

  void _startCancelTimer() {
    _cancelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_order != null && mounted) {
        final timeSinceCreation = DateTime.now().difference(_order!.createdAt);
        const maxCancellationTime = Duration(minutes: 5);
        final remaining = maxCancellationTime - timeSinceCreation;

        setState(() {
          if (remaining.isNegative) {
            _timeRemaining = Duration.zero;
          } else {
            _timeRemaining = remaining;
          }
        });

        if (remaining.isNegative) {
          timer.cancel();
        }
      }
    });
  }

  bool _canCancel() {
    if (_order == null) return false;
    if (_order!.status == DeliveryOrderStatus.cancelled) return false;
    if (_order!.status == DeliveryOrderStatus.delivered) return false;
    if (_timeRemaining == null) return false;
    return _timeRemaining! > Duration.zero;
  }

  Future<void> _cancelOrder() async {
    if (!_canCancel()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nu mai poți anula comanda. Timpul de anulare (5 minute) a expirat.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anulează comanda'),
        content: const Text('Ești sigur că vrei să anulezi această comandă?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nu'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Da, anulează'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _deliveryService.cancelOrder(widget.orderId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comanda a fost anulată cu succes.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la anularea comenzii: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          SnackBar(content: Text('Eroare la încărcarea comenzii: $e')),
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

  Widget _buildStatusIcon(DeliveryOrderStatus status) {
    switch (status) {
      case DeliveryOrderStatus.pending:
        return const Icon(Icons.access_time, color: Colors.orange, size: 32);
      case DeliveryOrderStatus.accepted:
        return const Icon(Icons.check_circle_outline, color: Colors.blue, size: 32);
      case DeliveryOrderStatus.preparing:
        return const Icon(Icons.restaurant, color: Colors.orange, size: 32);
      case DeliveryOrderStatus.ready:
        return const Icon(Icons.restaurant_menu, color: Colors.green, size: 32);
      case DeliveryOrderStatus.pickedUp:
        return const Icon(Icons.delivery_dining, color: Colors.blue, size: 32);
      case DeliveryOrderStatus.onTheWay:
        return const Icon(Icons.directions_bike, color: Colors.purple, size: 32);
      case DeliveryOrderStatus.delivered:
        return const Icon(Icons.check_circle, color: Colors.green, size: 32);
      case DeliveryOrderStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.red, size: 32);
    }
  }

  String _getStatusMessage(DeliveryOrderStatus status) {
    switch (status) {
      case DeliveryOrderStatus.pending:
        return 'Comanda a fost plasată';
      case DeliveryOrderStatus.accepted:
        return 'Restaurantul a acceptat comanda';
      case DeliveryOrderStatus.preparing:
        return 'Comanda se pregătește';
      case DeliveryOrderStatus.ready:
        return 'Comanda este gata pentru preluare';
      case DeliveryOrderStatus.pickedUp:
        return 'Curierul a preluat comanda';
      case DeliveryOrderStatus.onTheWay:
        return 'Comanda este în drum către tine';
      case DeliveryOrderStatus.delivered:
        return 'Comanda a fost livrată cu succes';
      case DeliveryOrderStatus.cancelled:
        return 'Comanda a fost anulată';
    }
  }

  String _getStatusDescription(DeliveryOrderStatus status) {
    switch (status) {
      case DeliveryOrderStatus.pending:
        return 'Restaurantul va verifica comanda în curând';
      case DeliveryOrderStatus.accepted:
        return 'Comanda a fost acceptată și va începe pregătirea';
      case DeliveryOrderStatus.preparing:
        return 'Bucătăria pregătește comanda ta';
      case DeliveryOrderStatus.ready:
        return 'Comanda este gata și așteaptă curierul';
      case DeliveryOrderStatus.pickedUp:
        return 'Curierul a preluat comanda și o va livra în curând';
      case DeliveryOrderStatus.onTheWay:
        return 'Curierul este în drum către adresa ta';
      case DeliveryOrderStatus.delivered:
        return 'Comanda a fost livrată. Poftă bună!';
      case DeliveryOrderStatus.cancelled:
        return 'Comanda a fost anulată';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Urmărire comandă')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Urmărire comandă')),
        body: const Center(child: Text('Comanda nu a fost găsită')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Urmărire comandă'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatusIcon(_order!.status),
                    const SizedBox(height: 16),
                    Text(
                      _getStatusMessage(_order!.status),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStatusDescription(_order!.status),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Order details
            const Text(
              'Detalii comandă',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow('Comandă', '#${_order!.id.substring(0, 8)}'),
                    const Divider(),
                    _buildDetailRow('Subtotal', '${_order!.subtotal.toStringAsFixed(2)} RON'),
                    _buildDetailRow('Livrare', '${_order!.deliveryFee.toStringAsFixed(2)} RON'),
                    _buildDetailRow('Taxă serviciu', '${_order!.serviceFee.toStringAsFixed(2)} RON'),
                    const Divider(),
                    _buildDetailRow(
                      'Total',
                      '${_order!.total.toStringAsFixed(2)} RON',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),

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
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(_order!.deliveryAddress.address),
              ),
            ),

            // Cancel button (doar dacă poate fi anulată)
            if (_order!.status != DeliveryOrderStatus.cancelled &&
                _order!.status != DeliveryOrderStatus.delivered) ...[
              const SizedBox(height: 24),
              if (_canCancel()) ...[
                // Timer pentru anulare
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Timp rămas pentru anulare',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatDuration(_timeRemaining!),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cancelOrder,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Anulează comanda'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ] else if (_order!.status == DeliveryOrderStatus.pending ||
                  _order!.status == DeliveryOrderStatus.accepted) ...[
                // Timer expirat
                Card(
                  color: Colors.grey[200],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_off, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Timpul de anulare a expirat. Restaurantul a început să pregătească comanda.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            value,
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
}

