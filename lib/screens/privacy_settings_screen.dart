import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _isSaving = false;

  bool _locationSharing = true;
  bool _profileVisibility = true;
  bool _analyticsConsent = true;
  bool _rideHistoryVisible = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  String? get _uid => _auth.currentUser?.uid;

  Future<void> _loadSettings() async {
    if (_uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('privacySettings')
          .doc('settings')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _locationSharing = data['locationSharing'] as bool? ?? true;
          _profileVisibility = data['profileVisibility'] as bool? ?? true;
          _analyticsConsent = data['analyticsConsent'] as bool? ?? true;
          _rideHistoryVisible = data['rideHistoryVisible'] as bool? ?? true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la încărcarea setărilor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_uid == null) return;
    setState(() => _isSaving = true);
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('privacySettings')
          .doc('settings')
          .set({
        'locationSharing': _locationSharing,
        'profileVisibility': _profileVisibility,
        'analyticsConsent': _analyticsConsent,
        'rideHistoryVisible': _rideHistoryVisible,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setări de confidențialitate salvate.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la salvare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _onToggle(String key, bool value) async {
    setState(() {
      switch (key) {
        case 'locationSharing':
          _locationSharing = value;
        case 'profileVisibility':
          _profileVisibility = value;
        case 'analyticsConsent':
          _analyticsConsent = value;
        case 'rideHistoryVisible':
          _rideHistoryVisible = value;
      }
    });
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confidențialitate'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader('Locație'),
                _buildToggleTile(
                  icon: Icons.location_on_outlined,
                  title: 'Partajare locație în timp real',
                  subtitle:
                      'Permite partajarea locației tale cu șoferul în timpul cursei',
                  value: _locationSharing,
                  key: 'locationSharing',
                ),
                const Divider(height: 1),
                _buildSectionHeader('Profil'),
                _buildToggleTile(
                  icon: Icons.person_outline,
                  title: 'Vizibilitate profil pentru șoferi',
                  subtitle:
                      'Șoferii pot vedea profilul tău (nume, fotografie, rating)',
                  value: _profileVisibility,
                  key: 'profileVisibility',
                ),
                _buildToggleTile(
                  icon: Icons.history_outlined,
                  title: 'Istoricul curselor vizibil',
                  subtitle:
                      'Permite afișarea istoricului curselor în profilul tău public',
                  value: _rideHistoryVisible,
                  key: 'rideHistoryVisible',
                ),
                const Divider(height: 1),
                _buildSectionHeader('Date și analiză'),
                _buildToggleTile(
                  icon: Icons.analytics_outlined,
                  title: 'Date pentru îmbunătățirea serviciului',
                  subtitle:
                      'Ajută-ne să îmbunătățim aplicația prin partajarea datelor de utilizare anonime',
                  value: _analyticsConsent,
                  key: 'analyticsConsent',
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Datele tale sunt procesate conform GDPR. '
                    'Poți solicita exportul sau ștergerea datelor din secțiunea Siguranță și Securitate.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required String key,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: _isSaving ? null : (v) => _onToggle(key, v),
    );
  }
}
