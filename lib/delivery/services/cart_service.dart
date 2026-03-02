import 'package:flutter/foundation.dart';
import '../models/order_item_model.dart';
import '../models/restaurant_model.dart';

/// Service pentru gestionarea coșului de cumpărături
/// 
/// Gestionează:
/// - Adăugarea/ștergerea produselor
/// - Actualizarea cantităților
/// - Restaurant-ul selectat
/// - Calculul totalurilor
class CartService extends ChangeNotifier {
  final List<OrderItem> _items = [];
  Restaurant? _selectedRestaurant;

  // Getters
  List<OrderItem> get items => List.unmodifiable(_items);
  Restaurant? get selectedRestaurant => _selectedRestaurant;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
  
  double get deliveryFee {
    return _selectedRestaurant?.deliveryFee ?? 0.0;
  }
  
  double get total {
    return subtotal + deliveryFee;
  }
  
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  
  /// Setează restaurant-ul selectat
  /// Dacă se schimbă restaurant-ul, se șterge coșul
  void setRestaurant(Restaurant restaurant) {
    if (_selectedRestaurant?.id != restaurant.id) {
      clear();
    }
    _selectedRestaurant = restaurant;
    notifyListeners();
  }
  
  /// Adaugă un produs în coș
  /// Dacă produsul există deja (același ID și modificări), crește cantitatea
  void addItem(OrderItem item) {
    // Verifică dacă există deja un item identic
    final existingIndex = _items.indexWhere((existingItem) =>
        existingItem.productId == item.productId &&
        _areModificationsEqual(existingItem.modifications, item.modifications) &&
        existingItem.specialNotes == item.specialNotes);
    
    if (existingIndex != -1) {
      // Crește cantitatea item-ului existent
      final existingItem = _items[existingIndex];
      _items[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + item.quantity,
        totalPrice: existingItem.unitPrice * (existingItem.quantity + item.quantity),
      );
    } else {
      // Adaugă item nou
      _items.add(item);
    }
    
    notifyListeners();
  }
  
  /// Actualizează cantitatea unui item
  void updateItemQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _items[index];
      _items[index] = item.copyWith(
        quantity: quantity,
        totalPrice: item.unitPrice * quantity,
      );
      notifyListeners();
    }
  }
  
  /// Șterge un item din coș
  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }
  
  /// Șterge toate item-urile din coș
  void clear() {
    _items.clear();
    notifyListeners();
  }
  
  /// Șterge coșul și restaurant-ul selectat
  void reset() {
    _items.clear();
    _selectedRestaurant = null;
    notifyListeners();
  }
  
  /// Verifică dacă două liste de modificări sunt egale
  bool _areModificationsEqual(List<String> mods1, List<String> mods2) {
    if (mods1.length != mods2.length) return false;
    final sorted1 = List<String>.from(mods1)..sort();
    final sorted2 = List<String>.from(mods2)..sort();
    return sorted1.toString() == sorted2.toString();
  }
}

