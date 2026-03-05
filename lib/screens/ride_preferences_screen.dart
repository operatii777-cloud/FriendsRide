import 'package:flutter/material.dart';
import 'package:friendsride_app/models/ride_preferences_model.dart';
import 'package:friendsride_app/widgets/ride_preferences_widget.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Ecran pentru setarea preferințelor de cursă (Uber-like)
class RidePreferencesScreen extends StatefulWidget {
  const RidePreferencesScreen({super.key});

  @override
  State<RidePreferencesScreen> createState() => _RidePreferencesScreenState();
}

class _RidePreferencesScreenState extends State<RidePreferencesScreen> {
  RidePreferences? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      // Note: Preferences will be loaded from Firestore or SharedPreferences in future update
      setState(() {
        _preferences = RidePreferences();
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading preferences: $e', error: e);
      setState(() {
        _preferences = RidePreferences();
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences(RidePreferences preferences) async {
    try {
      // Note: Preferences will be saved to Firestore in future update
      setState(() {
        _preferences = preferences;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferințele au fost salvate'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error saving preferences: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la salvare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preferințe Cursă')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferințe Cursă'),
      ),
      body: RidePreferencesWidget(
        initialPreferences: _preferences,
        onPreferencesChanged: _savePreferences,
      ),
    );
  }
}

