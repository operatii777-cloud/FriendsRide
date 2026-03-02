import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/restaurant_api_key_service.dart';

/// Screen pentru gestionarea API key-ului
class ApiKeyManagementScreen extends StatefulWidget {
  final String restaurantId;

  const ApiKeyManagementScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<ApiKeyManagementScreen> createState() => _ApiKeyManagementScreenState();
}

class _ApiKeyManagementScreenState extends State<ApiKeyManagementScreen> {
  final RestaurantApiKeyService _apiKeyService = RestaurantApiKeyService();
  Map<String, dynamic>? _apiKeyInfo;
  bool _isLoading = true;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _loadApiKeyInfo();
  }

  Future<void> _loadApiKeyInfo() async {
    setState(() => _isLoading = true);
    try {
      final info = await _apiKeyService.getApiKeyInfo(widget.restaurantId);
      if (mounted) {
        setState(() {
          _apiKeyInfo = info;
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

  Future<void> _regenerateApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerează API Key'),
        content: const Text(
          'Ești sigur? API key-ul vechi va fi dezactivat și va trebui să actualizezi toate integrările.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regenerează', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRegenerating = true);

    try {
      final user = await _getCurrentUserId();
      if (user == null) {
        throw Exception('Utilizator neautentificat');
      }

      final newApiKey = await _apiKeyService.regenerateApiKey(
        restaurantId: widget.restaurantId,
        ownerId: user,
      );

      if (mounted) {
        await _showNewApiKey(newApiKey);
        await _loadApiKeyInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
  }

  Future<String?> _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  Future<void> _showNewApiKey(String apiKey) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key nou generat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Salvează acest API key într-un loc sigur. Nu vei mai putea să-l vezi din nou!'),
            const SizedBox(height: 16),
            SelectableText(
              apiKey,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: apiKey));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key copiat în clipboard')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiază'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Am salvat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Key Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status API Key',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (_apiKeyInfo != null) ...[
                            _buildInfoRow('Status', _apiKeyInfo!['isActive'] == true ? 'Activ' : 'Inactiv'),
                            if (_apiKeyInfo!['createdAt'] != null)
                              _buildInfoRow(
                                'Creat la',
                                _formatDate(_apiKeyInfo!['createdAt']),
                              ),
                            if (_apiKeyInfo!['lastUsedAt'] != null)
                              _buildInfoRow(
                                'Ultima utilizare',
                                _formatDate(_apiKeyInfo!['lastUsedAt']),
                              ),
                          ] else
                            const Text('Nu există API key configurat'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isRegenerating ? null : _regenerateApiKey,
                      icon: _isRegenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Regenerează API Key'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Card(
                    color: Colors.blue,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ℹ️ Informații',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'API key-ul este folosit pentru integrarea cu sistemul tău de comenzi. Păstrează-l în siguranță și nu-l partaja public.',
                            style: TextStyle(color: Colors.white),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
    }
    return 'N/A';
  }
}

