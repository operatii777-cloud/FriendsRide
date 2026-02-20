import 'package:flutter/material.dart';
import '../models/delivery_order_model.dart';
import '../models/delivery_status.dart';
import '../services/courier_service.dart';
import '../services/delivery_service.dart';
import 'courier_order_detail_screen.dart';

/// Dashboard pentru curieri - afișează comenzi disponibile și active
class CourierDashboardScreen extends StatefulWidget {
  const CourierDashboardScreen({super.key});

  @override
  State<CourierDashboardScreen> createState() => _CourierDashboardScreenState();
}

class _CourierDashboardScreenState extends State<CourierDashboardScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  final CourierService _courierService = CourierService();

  List<DeliveryOrder> _availableOrders = [];
  DeliveryOrder? _activeOrder;
  bool _isOnline = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToOrders();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get available orders (ready for pickup)
      final available = await _deliveryService.getAvailableOrders();

      // Get active order if any
      final active = await _deliveryService.getActiveOrderForCourier();

      if (mounted) {
        setState(() {
          _availableOrders = available;
          _activeOrder = active;
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

  void _subscribeToOrders() {
    // Subscribe to available orders stream
    _deliveryService.getAvailableOrdersStream().listen((orders) {
      if (mounted) {
        setState(() => _availableOrders = orders);
      }
    });

    // Subscribe to active order stream
    _deliveryService.getActiveOrderStreamForCourier().listen((order) {
      if (mounted) {
        setState(() => _activeOrder = order);
      }
    });
  }

  Future<void> _toggleOnlineStatus() async {
    try {
      await _courierService.setOnlineStatus(!_isOnline);
      if (mounted) {
        setState(() => _isOnline = !_isOnline);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    }
  }

  Future<void> _acceptOrder(DeliveryOrder order) async {
    try {
      await _deliveryService.acceptOrder(
        orderId: order.id,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourierOrderDetailScreen(orderId: order.id),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Curier'),
        actions: [
          Switch(
            value: _isOnline,
            onChanged: (value) => _toggleOnlineStatus(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeOrder != null
              ? _buildActiveOrderView()
              : _buildAvailableOrdersView(),
    );
  }

  Widget _buildActiveOrderView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comandă activă',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${_getStatusText(_activeOrder!.status)}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourierOrderDetailScreen(
                            orderId: _activeOrder!.id,
                          ),
                        ),
                      );
                    },
                    child: const Text('Vezi detalii'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersView() {
    if (_availableOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Nu sunt comenzi disponibile',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableOrders.length,
      itemBuilder: (context, index) {
        final order = _availableOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(DeliveryOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comandă #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${order.total.toStringAsFixed(2)} RON',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${order.items.length} produse'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress.address,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _acceptOrder(order),
                child: const Text('Acceptă comandă'),
              ),
            ),
          ],
        ),
      ),
    );
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
}

