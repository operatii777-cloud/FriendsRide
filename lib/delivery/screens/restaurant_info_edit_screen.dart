import 'package:flutter/material.dart';
import 'package:friendsride_app/models/saved_address_model.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';

/// Screen pentru editarea informațiilor restaurantului
class RestaurantInfoEditScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantInfoEditScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantInfoEditScreen> createState() => _RestaurantInfoEditScreenState();
}

class _RestaurantInfoEditScreenState extends State<RestaurantInfoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final RestaurantService _restaurantService = RestaurantService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.restaurant.name;
    _descriptionController.text = widget.restaurant.description;
    _addressController.text = widget.restaurant.address.address;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _restaurantService.updateRestaurant(
        restaurantId: widget.restaurant.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: SavedAddress(
          id: widget.restaurant.address.id,
          label: widget.restaurant.address.label,
          address: _addressController.text.trim(),
          coordinates: widget.restaurant.address.coordinates,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informațiile au fost actualizate cu succes')),
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
        title: const Text('Editează informații restaurant'),
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
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nume restaurant',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Numele este obligatoriu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descriere',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Descrierea este obligatorie';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresă',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Adresa este obligatorie';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: const Text('Salvează modificările'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

