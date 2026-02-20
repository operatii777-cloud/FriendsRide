import 'package:flutter/material.dart';
import 'package:friendsride_app/delivery/scripts/cleanup_test_orders.dart';
import 'package:friendsride_app/delivery/services/restaurant_service.dart';

/// Screen pentru curățarea comenzilor de test
class CleanupTestOrdersScreen extends StatefulWidget {
  const CleanupTestOrdersScreen({super.key});

  @override
  State<CleanupTestOrdersScreen> createState() => _CleanupTestOrdersScreenState();
}

class _CleanupTestOrdersScreenState extends State<CleanupTestOrdersScreen> {
  final CleanupTestOrders _cleanup = CleanupTestOrders();
  final RestaurantService _restaurantService = RestaurantService();
  String? _selectedRestaurantId;
  bool _isLoading = false;
  String? _resultMessage;
  bool _resultIsError = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurantAppV3TestId();
  }

  Future<void> _loadRestaurantAppV3TestId() async {
    try {
      final restaurants = await _restaurantService.getRestaurants();
      final testRestaurant = restaurants.firstWhere(
        (r) => r.name == 'Restaurant App v3 Test',
        orElse: () => restaurants.first,
      );
      setState(() {
        _selectedRestaurantId = testRestaurant.id;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Eroare la încărcarea restaurantului: $e';
        _resultIsError = true;
      });
    }
  }

  Future<void> _listTestOrders() async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      await _cleanup.listTestOrders(
        restaurantId: _selectedRestaurantId,
        includeCancelled: true,
      );
      setState(() {
        _resultMessage = 'Comenzile au fost listate în consolă.';
        _resultIsError = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Eroare: $e';
        _resultIsError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelTestOrders() async {
    if (_selectedRestaurantId == null) {
      setState(() {
        _resultMessage = 'Selectează un restaurant!';
        _resultIsError = true;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmare'),
        content: const Text(
          'Ești sigur că vrei să marchezi toate comenzile de test ca "cancelled"?\n\n'
          'Această acțiune va marca comenzile cu status "pending" sau "ready" ca "cancelled".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmă'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      await _cleanup.cancelAllTestOrders(
        onlyPending: true,
        onlyReady: false,
        olderThan24Hours: false,
        restaurantId: _selectedRestaurantId,
      );
      setState(() {
        _resultMessage = 'Comenzile de test au fost marcate ca "cancelled" cu succes!';
        _resultIsError = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Eroare: $e';
        _resultIsError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCancelledOrders() async {
    if (_selectedRestaurantId == null) {
      setState(() {
        _resultMessage = 'Selectează un restaurant!';
        _resultIsError = true;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ ATENȚIE'),
        content: const Text(
          'Ești sigur că vrei să ȘTERGI PERMANENT comenzile cancelled?\n\n'
          'Această acțiune este IREVERSIBILĂ!\n\n'
          'Doar comenzile cu status "cancelled" și mai vechi de 24 ore vor fi șterse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ȘTERGE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      await _cleanup.deleteAllDeliveryOrders(
        onlyCancelled: true,
        olderThan24Hours: true,
        restaurantId: _selectedRestaurantId,
      );
      setState(() {
        _resultMessage = 'Comenzile cancelled au fost șterse cu succes!';
        _resultIsError = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Eroare: $e';
        _resultIsError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curățare Comenzi de Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Restaurant:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedRestaurantId != null
                          ? 'Restaurant App v3 Test'
                          : 'Se încarcă...',
                      style: TextStyle(
                        color: _selectedRestaurantId != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _listTestOrders,
              icon: const Icon(Icons.list),
              label: const Text('Listează Comenzile de Test'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _cancelTestOrders,
              icon: const Icon(Icons.cancel),
              label: const Text('Marchează Comenzile ca "Cancelled"'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _deleteCancelledOrders,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Șterge Comenzile Cancelled (IREVERSIBIL)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_resultMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: _resultIsError ? Colors.red.shade50 : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _resultIsError ? Icons.error : Icons.check_circle,
                        color: _resultIsError ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _resultMessage!,
                          style: TextStyle(
                            color: _resultIsError ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ℹ️ Informații:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• "Listează" - afișează comenzile în consolă\n'
                      '• "Marchează ca Cancelled" - marchează comenzile pending/ready ca cancelled\n'
                      '• "Șterge Cancelled" - șterge PERMANENT comenzile cancelled (mai vechi de 24h)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

