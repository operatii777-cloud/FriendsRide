import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/restaurant_service.dart';

/// Screen pentru adăugare/editare produs
class ProductEditScreen extends StatefulWidget {
  final String restaurantId;
  final Product? product; // null = add new, not null = edit

  const ProductEditScreen({
    super.key,
    required this.restaurantId,
    this.product,
  });

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final RestaurantService _restaurantService = RestaurantService();
  bool _isLoading = false;
  bool _isAvailable = true;
  final List<String> _allergens = [];
  final TextEditingController _allergenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toStringAsFixed(2);
      _categoryController.text = widget.product!.category;
      _imageUrlController.text = widget.product!.imageUrl ?? '';
      _isAvailable = widget.product!.isAvailable;
      _allergens.addAll(widget.product!.allergens);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _allergenController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final price = double.tryParse(_priceController.text);
      if (price == null || price < 0) {
        throw Exception('Preț invalid');
      }

      if (widget.product == null) {
        // Create new product
        await _restaurantService.createProduct(
          restaurantId: widget.restaurantId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          category: _categoryController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          isAvailable: _isAvailable,
          allergens: _allergens,
        );
      } else {
        // Update existing product
        await _restaurantService.updateProduct(
          productId: widget.product!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          category: _categoryController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          isAvailable: _isAvailable,
          allergens: _allergens,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product == null
                ? 'Produs adăugat cu succes'
                : 'Produs actualizat cu succes'),
          ),
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

  void _addAllergen() {
    final allergen = _allergenController.text.trim();
    if (allergen.isNotEmpty && !_allergens.contains(allergen)) {
      setState(() {
        _allergens.add(allergen);
        _allergenController.clear();
      });
    }
  }

  void _removeAllergen(String allergen) {
    setState(() {
      _allergens.remove(allergen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Adaugă produs' : 'Editează produs'),
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
              onPressed: _saveProduct,
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
                labelText: 'Nume produs',
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
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Descrierea este obligatorie';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Preț (RON)',
                      border: OutlineInputBorder(),
                      prefixText: 'RON ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Prețul este obligatoriu';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Preț invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Categorie',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Categoria este obligatorie';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL imagine (opțional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Disponibil'),
              subtitle: const Text('Produsul este disponibil pentru comandă'),
              value: _isAvailable,
              onChanged: (value) {
                setState(() => _isAvailable = value);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Alergeni',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _allergenController,
                    decoration: const InputDecoration(
                      labelText: 'Adaugă alergen',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addAllergen(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addAllergen,
                ),
              ],
            ),
            if (_allergens.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _allergens.map((allergen) {
                  return Chip(
                    label: Text(allergen),
                    onDeleted: () => _removeAllergen(allergen),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                child: Text(widget.product == null ? 'Adaugă produs' : 'Salvează modificările'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

