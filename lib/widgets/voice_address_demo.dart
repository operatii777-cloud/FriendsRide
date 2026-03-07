
import 'package:flutter/material.dart';
import 'package:friendsride_app/widgets/voice_address_input_field.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:friendsride_app/utils/logger.dart';

/// 🎯 VoiceAddressDemo - Demonstrație completă a funcționalității de input vocal pentru adrese
/// 
/// Acest widget demonstrează cum să folosești VoiceAddressInputField în diferite scenarii:
/// - 🚀 Câmp pentru pickup (start location)
/// - 🎯 Câmp pentru destinație
/// - 🛑 Câmpuri pentru opriri multiple
/// - 🏠 Câmpuri pentru adrese favorite (acasă, serviciu)
/// - 📝 Câmpuri pentru editarea adreselor
class VoiceAddressDemo extends StatefulWidget {
  const VoiceAddressDemo({super.key});

  @override
  State<VoiceAddressDemo> createState() => _VoiceAddressDemoState();
}

class _VoiceAddressDemoState extends State<VoiceAddressDemo> {
  // Controllers pentru câmpurile de input
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _stop1Controller = TextEditingController();
  final _stop2Controller = TextEditingController();
  final _homeController = TextEditingController();
  final _workController = TextEditingController();
  final _favoriteController = TextEditingController();

  // Focus nodes pentru câmpuri
  final _pickupFocusNode = FocusNode();
  final _destinationFocusNode = FocusNode();
  final _stop1FocusNode = FocusNode();
  final _stop2FocusNode = FocusNode();
  final _homeFocusNode = FocusNode();
  final _workFocusNode = FocusNode();
  final _favoriteFocusNode = FocusNode();

  // Starea validării pentru fiecare câmp
  final Map<String, bool> _fieldValidationStates = {};
  final Map<String, Point?> _fieldCoordinates = {};

  @override
  void initState() {
    super.initState();
    // Inițializează starea validării
    _initializeValidationStates();
  }

  @override
  void dispose() {
    // Dispose controllers
    _pickupController.dispose();
    _destinationController.dispose();
    _stop1Controller.dispose();
    _stop2Controller.dispose();
    _homeController.dispose();
    _workController.dispose();
    _favoriteController.dispose();

    // Dispose focus nodes
    _pickupFocusNode.dispose();
    _destinationFocusNode.dispose();
    _stop1FocusNode.dispose();
    _stop2FocusNode.dispose();
    _homeFocusNode.dispose();
    _workFocusNode.dispose();
    _favoriteFocusNode.dispose();

    super.dispose();
  }

  /// 🚀 Inițializează starea validării pentru toate câmpurile
  void _initializeValidationStates() {
    final fields = [
      'pickup',
      'destination',
      'stop1',
      'stop2',
      'home',
      'work',
      'favorite',
    ];

    for (final field in fields) {
      _fieldValidationStates[field] = false;
      _fieldCoordinates[field] = null;
    }
  }

  /// ✅ Gestionează validarea cu succes a unei adrese
  void _onAddressValidated(String fieldName, String address, Point coordinates) {
    setState(() {
      _fieldValidationStates[fieldName] = true;
      _fieldCoordinates[fieldName] = coordinates;
    });

    // Afișează feedback
    _showSuccessMessage('✅ $fieldName validat: $address');
    
    // Debug info
    Logger.info('$fieldName validated:');
    Logger.debug('Address: $address');
    Logger.debug('Coordinates: ${coordinates.coordinates.lat}, ${coordinates.coordinates.lng}');
  }

  /// ❌ Gestionează validarea eșuată a unei adrese
  void _onAddressInvalid(String fieldName, String error) {
    setState(() {
      _fieldValidationStates[fieldName] = false;
      _fieldCoordinates[fieldName] = null;
    });

    // Afișează feedback
    _showErrorMessage('❌ $fieldName invalid: $error');
  }

  /// 🗺️ Gestionează apăsarea butonului de hartă
  void _onMapButtonPressed(String fieldName) {
    // Aici ai integra cu MapPickerScreen-ul existent
    _showInfoMessage('🗺️ Deschide harta pentru $fieldName');
    
    // Exemplu de integrare:
    // Navigator.of(context).push<Map<String, dynamic>>(
    //   MaterialPageRoute(
    //     builder: (ctx) => MapPickerScreen(initialLocation: currentPosition),
    //   ),
    // ).then((result) {
    //   if (result != null && result.containsKey('location')) {
    //     final point = result['location'] as Point;
    //     final address = result['address'] as String;
    //     _onAddressValidated(fieldName, address, point);
    //   }
    // });
  }

  /// 🎯 Verifică dacă toate câmpurile obligatorii sunt validate
  bool get _areRequiredFieldsValid {
    return _fieldValidationStates['pickup'] == true &&
           _fieldValidationStates['destination'] == true;
  }

  /// 🚀 Procesează formularul complet
  void _processForm() {
    if (!_areRequiredFieldsValid) {
      _showErrorMessage('❌ Completează pickup-ul și destinația înainte de a continua');
      return;
    }

    // Aici ai procesa datele pentru crearea cursei
    final pickup = _fieldCoordinates['pickup']!;
    final destination = _fieldCoordinates['destination']!;
    
    _showSuccessMessage('🚀 Formular procesat cu succes!');
    _showInfoMessage('📍 Pickup: ${pickup.coordinates.lat}, ${pickup.coordinates.lng}');
    _showInfoMessage('🎯 Destinație: ${destination.coordinates.lat}, ${destination.coordinates.lng}');
  }

  /// ✅ Afișează un mesaj de succes
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ❌ Afișează un mesaj de eroare
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// ℹ️ Afișează un mesaj informativ
  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Demo Input Vocal pentru Adrese'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header cu instrucțiuni
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Instrucțiuni de utilizare',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '🎤 Apasă butonul de microfon pentru a introduce adresa prin voce\n'
                      '✅ Adresa se validează automat și se extrag coordonatele\n'
                      '🗺️ Folosește butonul de hartă pentru a alege locația vizual\n'
                      '🔍 Sugestiile de adrese apar automat pentru clarificare',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Secțiunea principală - Ride Request
            Text(
              '🚗 Creează o cursă',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Câmp pentru pickup
            VoiceAddressInputField(
              controller: _pickupController,
              focusNode: _pickupFocusNode,
              labelText: '🚀 Preluare de la',
              prefixIcon: Icons.my_location,
              isStart: true,
              onAddressValidated: (address, coordinates) => 
                  _onAddressValidated('pickup', address, coordinates),
              onAddressInvalid: (error) => _onAddressInvalid('pickup', error),
              onMapButtonPressed: () => _onMapButtonPressed('pickup'),
            ),
            
            const SizedBox(height: 16),
            
            // Câmp pentru destinație
            VoiceAddressInputField(
              controller: _destinationController,
              focusNode: _destinationFocusNode,
              labelText: '🎯 Destinație',
              prefixIcon: Icons.location_on,
              onAddressValidated: (address, coordinates) => 
                  _onAddressValidated('destination', address, coordinates),
              onAddressInvalid: (error) => _onAddressInvalid('destination', error),
              onMapButtonPressed: () => _onMapButtonPressed('destination'),
            ),
            
            const SizedBox(height: 24),
            
            // Secțiunea pentru opriri
            Text(
              '🛑 Opriri opționale',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Oprirea 1
            VoiceAddressInputField(
              controller: _stop1Controller,
              focusNode: _stop1FocusNode,
              labelText: '🛑 Oprirea 1',
              prefixIcon: Icons.add_location_alt,
              onAddressValidated: (address, coordinates) => 
                  _onAddressValidated('stop1', address, coordinates),
              onAddressInvalid: (error) => _onAddressInvalid('stop1', error),
              onMapButtonPressed: () => _onMapButtonPressed('stop1'),
            ),
            
            const SizedBox(height: 12),
            
            // Oprirea 2
            VoiceAddressInputField(
              controller: _stop2Controller,
              focusNode: _stop2FocusNode,
              labelText: '🛑 Oprirea 2',
              prefixIcon: Icons.add_location_alt,
              onAddressValidated: (address, coordinates) => 
                  _onAddressValidated('stop2', address, coordinates),
              onAddressInvalid: (error) => _onAddressInvalid('stop2', error),
              onMapButtonPressed: () => _onMapButtonPressed('stop2'),
            ),
            
            const SizedBox(height: 24),
            
            // Secțiunea pentru adrese favorite
            Text(
              '🏠 Adrese favorite',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Adresa acasă
            VoiceAddressInputField(
              controller: _homeController,
              focusNode: _homeFocusNode,
              labelText: '🏠 Acasă',
              prefixIcon: Icons.home,
              onAddressValidated: (address, coordinates) => 
                  _onAddressValidated('home', address, coordinates),
              onAddressInvalid: (error) => _onAddressInvalid('home', error),
              onMapButtonPressed: () => _onMapButtonPressed('home'),
            ),
            
            const SizedBox(height: 12),
            
            // Adresa serviciului
            VoiceAddressInputField(
              controller: _workController,
              focusNode: _workFocusNode,
              labelText: '💼 Serviciu',
              prefixIcon: Icons.work,
              onAddressValidated: (address, coordinates) => 
                  _onAddressValidated('work', address, coordinates),
              onAddressInvalid: (error) => _onAddressInvalid('work', error),
              onMapButtonPressed: () => _onMapButtonPressed('work'),
            ),
            
            const SizedBox(height: 12),
            
            // Adresa favorită personalizată
            VoiceAddressInputField(
              controller: _favoriteController,
              focusNode: _favoriteFocusNode,
              labelText: '⭐ Adresă favorită',
              prefixIcon: Icons.star,
              onAddressValidated: (address, coordinates) => 
                  _onAddressValidated('favorite', address, coordinates),
              onAddressInvalid: (error) => _onAddressInvalid('favorite', error),
              onMapButtonPressed: () => _onMapButtonPressed('favorite'),
            ),
            
            const SizedBox(height: 32),
            
            // Butonul de procesare
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _areRequiredFieldsValid ? _processForm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _areRequiredFieldsValid 
                      ? theme.colorScheme.primary 
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _areRequiredFieldsValid 
                      ? '🚀 Procesează formularul'
                      : '❌ Completează câmpurile obligatorii',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Status-ul validării
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Status validare câmpuri',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                                         ..._fieldValidationStates.entries.map((entry) {
                       final fieldName = entry.key;
                       final isValid = entry.value;
                       final coordinates = _fieldCoordinates[fieldName];
                       
                       return Padding(
                         padding: const EdgeInsets.only(bottom: 8),
                         child: Row(
                           children: [
                             Icon(
                               isValid ? Icons.check_circle : Icons.circle_outlined,
                               color: isValid ? Colors.green : Colors.grey,
                               size: 20,
                             ),
                             const SizedBox(width: 8),
                             Expanded(
                               child: Text(
                                 '${_getFieldDisplayName(fieldName)}: ${isValid ? "Validat" : "Nevalidat"}',
                                 style: TextStyle(
                                   fontWeight: isValid ? FontWeight.bold : FontWeight.normal,
                                   color: isValid ? Colors.green : Colors.grey,
                                 ),
                               ),
                             ),
                             if (coordinates != null)
                               Text(
                                 '📍 ${coordinates.coordinates.lat.toStringAsFixed(4)}, ${coordinates.coordinates.lng.toStringAsFixed(4)}',
                                 style: theme.textTheme.bodySmall?.copyWith(
                                   color: Colors.blue,
                                   fontFamily: 'monospace',
                                 ),
                               ),
                           ],
                         ),
                       );
                     }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🏷️ Obține numele de afișare pentru un câmp
  String _getFieldDisplayName(String fieldName) {
    switch (fieldName) {
      case 'pickup':
        return '🚀 Preluare';
      case 'destination':
        return '🎯 Destinație';
      case 'stop1':
        return '🛑 Oprirea 1';
      case 'stop2':
        return '🛑 Oprirea 2';
      case 'home':
        return '🏠 Acasă';
      case 'work':
        return '💼 Serviciu';
      case 'favorite':
        return '⭐ Favorită';
      default:
        return fieldName;
    }
  }
}
