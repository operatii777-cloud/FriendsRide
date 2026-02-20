# 🔧 Configurare Webhook URL în Firestore

**Data:** 2025-01-28  
**Scop:** Configurare `webhookUrl` pentru restaurante în Firestore pentru integrarea cu Restaurant App v3

---

## 📋 METODA 1: Prin Cod (Recomandat)

### **Folosind RestaurantService**

```dart
import 'package:friendsride_app/delivery/services/restaurant_service.dart';

final restaurantService = RestaurantService();

// Configurează webhookUrl pentru un restaurant
await restaurantService.updateRestaurant(
  restaurantId: 'restaurant_id_here',
  webhookUrl: 'http://localhost:3001', // Portul Restaurant App v3
  restaurantAppV3TenantId: 'tenant_123', // Opțional
);
```

### **Folosind Firestore Direct**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

final firestore = FirebaseFirestore.instance;

await firestore.collection('restaurants').doc('restaurant_id_here').update({
  'webhookUrl': 'http://localhost:3001',
  'restaurantAppV3TenantId': 'tenant_123', // Opțional
  'updatedAt': FieldValue.serverTimestamp(),
});
```

---

## 📋 METODA 2: Prin Firebase Console (Manual)

### **Pași:**

1. **Deschide Firebase Console**
   - Accesează [Firebase Console](https://console.firebase.google.com)
   - Selectează proiectul FriendsRide

2. **Navighează la Firestore Database**
   - Click pe "Firestore Database" din meniul stâng
   - Selectează colecția `restaurants`

3. **Găsește Restaurantul**
   - Caută documentul restaurantului după ID
   - Sau folosește filtre pentru a găsi restaurantul

4. **Editează Documentul**
   - Click pe documentul restaurantului
   - Click pe "Edit document" (iconița de editare)
   - Adaugă câmpul `webhookUrl`:
     - **Field:** `webhookUrl`
     - **Type:** `string`
     - **Value:** `http://localhost:3001`
   - (Opțional) Adaugă `restaurantAppV3TenantId`:
     - **Field:** `restaurantAppV3TenantId`
     - **Type:** `string`
     - **Value:** `tenant_123`
   - Click "Update"

---

## 📋 METODA 3: Prin Script Flutter

### **Folosind Script-ul Predefinit**

```dart
import 'package:friendsride_app/delivery/scripts/configure_restaurant_webhook.dart';

// Configurează webhookUrl
await configureRestaurantWebhook(
  restaurantId: 'restaurant_id_here',
  webhookUrl: 'http://localhost:3001',
  restaurantAppV3TenantId: 'tenant_123', // Opțional
);
```

---

## 🔍 VERIFICARE CONFIGURARE

### **Verifică în Cod**

```dart
final restaurant = await RestaurantService().getRestaurant('restaurant_id_here');
print('Webhook URL: ${restaurant?.webhookUrl}');
// Ar trebui să afișeze: http://localhost:3001
```

### **Verifică în Firebase Console**

1. Deschide documentul restaurantului în Firestore
2. Verifică că există câmpul `webhookUrl` cu valoarea `http://localhost:3001`

---

## ⚠️ IMPORTANT

### **Format Webhook URL**

**✅ Corect:**
```
http://localhost:3001
https://your-domain.com
http://192.168.1.100:3001
```

**❌ Greșit:**
```
http://localhost:3001/  (fără / la final)
localhost:3001  (fără protocol)
http://localhost:3000  (port greșit)
```

### **Portul Restaurant App v3**

**⚠️ Restaurant App v3 rulează pe portul 3001, nu 3000!**

---

## 📝 EXEMPLU COMPLET

```dart
import 'package:friendsride_app/delivery/services/restaurant_service.dart';

void configureRestaurantForDelivery() async {
  final restaurantService = RestaurantService();
  
  // ID-ul restaurantului (obține-l din Firestore sau onboarding)
  const restaurantId = 'rest_abc123';
  
  // Webhook URL pentru Restaurant App v3
  const webhookUrl = 'http://localhost:3001';
  
  // Tenant ID (opțional, dacă Restaurant App v3 folosește multi-tenant)
  const tenantId = 'tenant_123';
  
  try {
    // Actualizează webhookUrl
    await restaurantService.updateRestaurant(
      restaurantId: restaurantId,
      webhookUrl: webhookUrl,
      restaurantAppV3TenantId: tenantId,
    );
    
    print('✅ Webhook URL configurat cu succes!');
    
    // Verifică configurarea
    final restaurant = await restaurantService.getRestaurant(restaurantId);
    print('📍 Webhook URL: ${restaurant?.webhookUrl}');
    
  } catch (e) {
    print('❌ Eroare: $e');
  }
}
```

---

## 🔗 LINK-URI UTILE

- [Restaurant App v3 Setup Guide](./RESTAURANT_APP_V3_SETUP.md)
- [Delivery Progress](../IMPLEMENTARE_DELIVERY_PROGRES.md)
- [Firebase Console](https://console.firebase.google.com)

