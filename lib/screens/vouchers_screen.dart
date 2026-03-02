import 'package:flutter/material.dart';
import 'package:friendsride_app/services/firestore_service.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final _voucherController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  // Listă simulată de vouchere deja aplicate
  final List<String> _appliedVouchers = ["10% reducere la următoarea cursă"];

  void _applyVoucher() async {
    if (_voucherController.text.isEmpty) return;
    
    setState(() { _isLoading = true; });
    final response = await _firestoreService.validateVoucher(_voucherController.text);
    setState(() { _isLoading = false; });
    
    if (!mounted) return;
    
    final bool success = response['success'];
    final String message = response['message'];
    
    if (success) {
      setState(() {
        _appliedVouchers.add(message);
        _voucherController.clear();
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vouchere și Promoții'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Secțiunea de adăugare cod
            const Text('Adaugă un cod promoțional', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _voucherController,
                    decoration: const InputDecoration(
                      hintText: 'ex: PROMO5',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 60,
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator()) 
                    : ElevatedButton(
                        onPressed: _applyVoucher,
                        child: const Text('Aplică'),
                      ),
                )
              ],
            ),
            const Divider(height: 40),
            // Secțiunea cu voucherele active
            const Text('Promoțiile tale active', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: _appliedVouchers.isEmpty
                ? const Center(child: Text('Nu ai niciun voucher activ.'))
                : ListView.builder(
                    itemCount: _appliedVouchers.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: Colors.lightBlue.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.local_offer, color: Colors.blue),
                          title: Text(_appliedVouchers[index]),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

