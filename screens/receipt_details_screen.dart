import 'package:flutter/material.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/services/pdf_receipt_service.dart'; // Importăm serviciul PDF
import 'package:intl/intl.dart';
import 'package:printing/printing.dart'; // Importăm pachetul de partajare

// MODIFICAT: Am transformat în StatefulWidget pentru a gestiona starea de încărcare
class ReceiptDetailsScreen extends StatefulWidget {
  final Ride ride;

  const ReceiptDetailsScreen({super.key, required this.ride});

  @override
  State<ReceiptDetailsScreen> createState() => _ReceiptDetailsScreenState();
}

class _ReceiptDetailsScreenState extends State<ReceiptDetailsScreen> {
  bool _isSharing = false;

  // NOU: Funcția care generează și partajează PDF-ul
  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);
    try {
      final pdfService = PdfReceiptService();
      final pdfBytes = await pdfService.generateReceipt(widget.ride);
      
      // Folosim pachetul 'printing' pentru a deschide meniul de partajare
      await Printing.sharePdf(
          bytes: pdfBytes, filename: 'chitanta_${widget.ride.id.substring(0, 8)}.pdf');
          
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la generarea PDF-ului: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMMM HH:mm').format(widget.ride.timestamp);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detaliu Chitanță'),
        // NOU: Am adăugat butonul de Share în secțiunea 'actions'
        actions: [
          if (_isSharing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))),
            )
          else
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _shareReceipt,
              tooltip: 'Partajează PDF',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'CHITANTA',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ),
                Center(child: Text('ID Cursă: ${widget.ride.id}')),
                const SizedBox(height: 24),
                Text('Data: $formattedDate'),
                const Divider(height: 32),
                const Text('Detalii Cursă:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                _buildDetailRow('De la:', widget.ride.startAddress),
                _buildDetailRow('La:', widget.ride.destinationAddress),
                const SizedBox(height: 16),
                const Text('Calcul Preț:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                _buildDetailRow('Tarif de bază:', '${widget.ride.baseFare.toStringAsFixed(2)} RON'),
                _buildDetailRow('Cost Distanță (${widget.ride.distance.toStringAsFixed(1)} km):', '${(widget.ride.distance * widget.ride.perKmRate).toStringAsFixed(2)} RON'),
                _buildDetailRow('Cost Timp (${widget.ride.durationInMinutes?.toStringAsFixed(0) ?? '0'} min):', '${((widget.ride.durationInMinutes ?? 0) * widget.ride.perMinRate).toStringAsFixed(2)} RON'),
                if (widget.ride.tip > 0)
                  _buildDetailRow('Bacșiș:', '${widget.ride.tip.toStringAsFixed(2)} RON'),
                const Divider(thickness: 1.5),
                _buildDetailRow(
                  'TOTAL PLATIT:',
                  '${widget.ride.totalCost.toStringAsFixed(2)} RON',
                  isTotal: true,
                ),
                const Divider(height: 32),
                const Center(
                  child: Text(
                    'Vă mulțumim!',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 18 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}