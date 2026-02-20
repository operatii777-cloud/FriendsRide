import 'package:flutter/material.dart';
import 'package:friendsride_app/screens/add_card_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // Vom folosi o listă statică pentru a simula cardurile salvate
  final List<Map<String, String>> _savedCards = [
    {
      "brand": "Visa",
      "last4": "4242",
      "expiry": "12/28"
    },
    {
      "brand": "Mastercard",
      "last4": "5555",
      "expiry": "08/26"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metode de Plată'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _savedCards.length,
                itemBuilder: (context, index) {
                  final card = _savedCards[index];
                  return _buildCardTile(card);
                },
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_card),
              label: const Text('Adaugă un card nou'),
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AddCardScreen()));
              },
               style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16)
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTile(Map<String, String> card) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          card["brand"] == "Visa" ? Icons.credit_card : Icons.credit_card_sharp,
          color: card["brand"] == "Visa" ? Colors.blue.shade800 : Colors.orange.shade800,
          size: 40,
        ),
        title: Text('${card["brand"]} terminat în ${card["last4"]}'),
        subtitle: Text('Expiră la: ${card["expiry"]}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            // Simulare ștergere
            setState(() {
              _savedCards.removeWhere((c) => c["last4"] == card["last4"]);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cardul a fost șters (simulare).')),
            );
          },
        ),
      ),
    );
  }
}
