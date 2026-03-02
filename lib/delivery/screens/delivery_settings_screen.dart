import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';

/// Screen pentru setările de livrare
class DeliverySettingsScreen extends StatefulWidget {
  final Restaurant restaurant;

  const DeliverySettingsScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<DeliverySettingsScreen> createState() => _DeliverySettingsScreenState();
}

class _DeliverySettingsScreenState extends State<DeliverySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deliveryFeeController = TextEditingController();
  final _minimumOrderController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  final _webhookUrlController = TextEditingController();
  final RestaurantService _restaurantService = RestaurantService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _deliveryFeeController.text = widget.restaurant.deliveryFee.toStringAsFixed(2);
    _minimumOrderController.text = widget.restaurant.minimumOrder.toStringAsFixed(2);
    _estimatedTimeController.text = widget.restaurant.estimatedDeliveryTime.toString();
    _webhookUrlController.text = widget.restaurant.webhookUrl ?? 'http://localhost:3001';
    
    // Pentru device fizic Android, încarcă IP-ul configurat și sugerează-l
    if (Platform.isAndroid) {
      _loadConfiguredIpAndSuggest();
    }
  }
  
  /// Încarcă IP-ul configurat și sugerează-l în webhookUrl dacă este localhost
  Future<void> _loadConfiguredIpAndSuggest() async {
    final prefs = await SharedPreferences.getInstance();
    final configuredIp = prefs.getString('restaurant_app_v3_ip');
    
    if (configuredIp != null && configuredIp.isNotEmpty) {
      // Dacă webhookUrl este localhost sau 10.0.2.2, sugerează IP-ul configurat
      final currentUrl = _webhookUrlController.text;
      if (currentUrl.contains('localhost') || currentUrl.contains('10.0.2.2') || currentUrl.contains('127.0.0.1')) {
        if (mounted) {
          setState(() {
            _webhookUrlController.text = 'http://$configuredIp:3001';
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    _minimumOrderController.dispose();
    _estimatedTimeController.dispose();
    _webhookUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _restaurantService.updateRestaurant(
        restaurantId: widget.restaurant.id,
        deliveryFee: double.tryParse(_deliveryFeeController.text),
        minimumOrder: double.tryParse(_minimumOrderController.text),
        estimatedDeliveryTime: int.tryParse(_estimatedTimeController.text),
        webhookUrl: _webhookUrlController.text.trim().isEmpty
            ? null
            : _webhookUrlController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setările au fost actualizate cu succes')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setări livrare'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _deliveryFeeController,
              decoration: const InputDecoration(
                labelText: 'Taxă livrare (RON)',
                border: OutlineInputBorder(),
                prefixText: 'RON ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Taxa de livrare este obligatorie';
                }
                final fee = double.tryParse(value);
                if (fee == null || fee < 0) {
                  return 'Introduceți o valoare validă';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minimumOrderController,
              decoration: const InputDecoration(
                labelText: 'Comandă minimă (RON)',
                border: OutlineInputBorder(),
                prefixText: 'RON ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Comanda minimă este obligatorie';
                }
                final min = double.tryParse(value);
                if (min == null || min < 0) {
                  return 'Introduceți o valoare validă';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _estimatedTimeController,
              decoration: const InputDecoration(
                labelText: 'Timp estimat livrare (minute)',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Timpul estimat este obligatoriu';
                }
                final time = int.tryParse(value);
                if (time == null || time < 1) {
                  return 'Introduceți o valoare validă (minim 1 minut)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _webhookUrlController,
              decoration: InputDecoration(
                labelText: 'Webhook URL (Restaurant App v3)',
                border: const OutlineInputBorder(),
                helperText: Platform.isAndroid 
                    ? 'Pentru WiFi local: http://[IP_PC]:3001\nPentru date mobile: https://[ngrok-url] sau URL public\nPentru emulator: http://10.0.2.2:3001'
                    : 'URL-ul Restaurant App v3 pentru primirea comenzilor (ex: http://localhost:3001)',
                suffixIcon: Platform.isAndroid
                    ? IconButton(
                        icon: const Icon(Icons.info_outline),
                        tooltip: 'Configurează IP-ul PC-ului pentru device fizic',
                        onPressed: () => _showIpConfigDialog(context),
                      )
                    : null,
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final url = value.trim();
                  if (!url.startsWith('http://') && !url.startsWith('https://')) {
                    return 'URL-ul trebuie să înceapă cu http:// sau https://';
                  }
                }
                return null;
              },
            ),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 8),
              FutureBuilder<String?>(
                future: _getConfiguredIp(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Chip(
                      avatar: const Icon(Icons.computer, size: 18),
                      label: Text('IP PC configurat: ${snapshot.data}'),
                      onDeleted: () => _clearConfiguredIp(context),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                child: const Text('Salvează setările'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obține IP-ul configurat din SharedPreferences
  Future<String?> _getConfiguredIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('restaurant_app_v3_ip');
  }

  /// Șterge IP-ul configurat
  Future<void> _clearConfiguredIp(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('restaurant_app_v3_ip');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IP-ul configurat a fost șters')),
      );
      setState(() {});
    }
  }

  /// Afișează dialog pentru configurarea IP-ului PC-ului sau URL-ului public
  Future<void> _showIpConfigDialog(BuildContext context) async {
    final urlController = TextEditingController();
    final prefs = await SharedPreferences.getInstance();
    final currentIp = prefs.getString('restaurant_app_v3_ip');
    
    // Pre-populează cu IP-ul curent sau cu URL-ul default
    urlController.text = currentIp ?? '192.168.50.238';
    
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Configurează URL-ul Restaurant App v3'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configurează URL-ul complet al Restaurant App v3 (inclusiv protocolul și portul).',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL complet (ex: http://192.168.50.238:3001)',
                  hintText: 'http://192.168.50.238:3001',
                  border: OutlineInputBorder(),
                  helperText: 'URL complet: http://[IP sau domeniu]:[port]',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              const Text(
                '📱 Pentru utilizare pe stradă (date mobile):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Folosește ngrok sau un serviciu similar pentru URL public\n'
                '• Exemplu: https://abc123.ngrok.io\n'
                '• Sau configurează port forwarding pe router\n'
                '• Sau folosește un serviciu cloud (AWS, Heroku, etc.)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                '🏠 Pentru utilizare pe WiFi local:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Folosește IP-ul local al PC-ului\n'
                '• Exemplu: http://192.168.50.238:3001\n'
                '• PC-ul și telefonul trebuie să fie pe aceeași rețea WiFi',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                // Extrage doar IP-ul sau domeniul (fără http:// și port)
                final uri = Uri.tryParse(url);
                if (uri != null && uri.host.isNotEmpty) {
                  await prefs.setString('restaurant_app_v3_ip', uri.host);
                  if (!context.mounted) return;
                  
                  Navigator.pop(dialogContext);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('✅ URL configurat: $url\nAcum poți folosi $url în Webhook URL'),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  // Actualizează webhookUrl dacă este localhost
                  final currentUrl = _webhookUrlController.text;
                  if (currentUrl.contains('localhost') || currentUrl.contains('10.0.2.2') || currentUrl.contains('127.0.0.1')) {
                    setState(() {
                      _webhookUrlController.text = url;
                    });
                  }
                  setState(() {});
                } else {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('❌ URL invalid. Folosește formatul: http://[IP sau domeniu]:[port]'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }
}

