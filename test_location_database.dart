// test_location_database.dart
// Test file pentru baza de date de locații București + Ilfov

import 'package:flutter/material.dart';
import 'lib/voice/ai/ai_methods.dart';

void main() {
  runApp(const LocationDatabaseTestApp());
}

class LocationDatabaseTestApp extends StatelessWidget {
  const LocationDatabaseTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Baza de Date Locații',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LocationDatabaseTestScreen(),
    );
  }
}

class LocationDatabaseTestScreen extends StatefulWidget {
  const LocationDatabaseTestScreen({super.key});

  @override
  State<LocationDatabaseTestScreen> createState() => _LocationDatabaseTestScreenState();
}

class _LocationDatabaseTestScreenState extends State<LocationDatabaseTestScreen> {
  String _selectedCounty = 'bucuresti';
  String _selectedCategory = 'transport';
  String _searchQuery = '';
  List<String> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📍 Test Baza de Date Locații'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCountySelector(),
            const SizedBox(height: 16),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            _buildSearchSection(),
            const SizedBox(height: 16),
            _buildSearchResults(),
            const SizedBox(height: 16),
            _buildPopularDestinations(),
            const SizedBox(height: 16),
            _buildAllLocationsInCategory(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCountySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏛️ Selectează Județul:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: AIMethods.getAvailableCounties().map((county) {
                return ChoiceChip(
                  label: Text(county.toUpperCase()),
                  selected: _selectedCounty == county,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCounty = county;
                      _selectedCategory = 'transport';
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📂 Selectează Categoria:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: AIMethods.getAvailableCategories().map((category) {
                return ChoiceChip(
                  label: Text(_getCategoryDisplayName(category)),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔍 Căutare Locații:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Caută locații...',
                hintText: 'ex: mall, restaurant, spital, universitate...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  if (_searchQuery.isNotEmpty) {
                    _searchResults = AIMethods.searchAllLocations(_searchQuery).map((item) => '${item['name']}: ${item['address']}').toList();
                  } else {
                    _searchResults = [];
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Caută în toate județele: București + Ilfov', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔍 Rezultate Căutare (${_searchResults.length})', 
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    title: Text(result),
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    subtitle: Text('Apasă pentru a testa comanda'),
                    onTap: () => _testLocationCommand(result),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularDestinations() {
    final popular = AIMethods.getPopularDestinationsInCounty(_selectedCounty);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⭐ Destinații Populare în ${_selectedCounty.toUpperCase()}', 
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: popular.take(9).map((destination) {
                return ElevatedButton(
                  onPressed: () => _testLocationCommand(destination),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    destination.split(',').first,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllLocationsInCategory() {
    final locations = AIMethods.getLocationsByCategory(_selectedCategory);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📋 Toate Locațiile din ${_getCategoryDisplayName(_selectedCategory)} - ${_selectedCounty.toUpperCase()}', 
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final location = locations[index];
                  return ListTile(
                    title: Text(location['name']!),
                    subtitle: Text(location['address']!),
                    leading: const Icon(Icons.place, color: Colors.blue),
                    trailing: IconButton(
                      onPressed: () => _testLocationCommand(location['name']!),
                      icon: const Icon(Icons.play_arrow, color: Colors.green),
                      tooltip: 'Testează locația',
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

  void _testLocationCommand(String location) {
    final command = 'Vreau să merg la $location';
    
    // Afișează comanda generată
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🧪 Comanda generată: "$command"'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Copiază',
          onPressed: () {
            // Aici s-ar putea copia în clipboard
          },
        ),
      ),
    );
    
    // Simulează procesarea comenzii
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Comanda procesată cu succes!'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'transport':
        return 'Transport';
      case 'shopping':
        return 'Shopping';
      case 'restaurante':
        return 'Restaurante';
      case 'sport':
        return 'Sport';
      case 'institutii':
        return 'Instituții';
      case 'medical':
        return 'Medical';
      case 'educatie':
        return 'Educație';
      case 'hoteluri':
        return 'Hoteluri';
      case 'servicii':
        return 'Servicii';
      case 'public':
        return 'Servicii Publice';
      default:
        return category;
    }
  }
}
