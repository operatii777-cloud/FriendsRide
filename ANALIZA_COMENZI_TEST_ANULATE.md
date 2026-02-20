# 🔍 Analiză: Comenzi de Test Anulate - Ce se întâmplă?

## 📊 SITUAȚIA ACTUALĂ

### **1. Ce se întâmplă când o comandă este anulată în Restaurant App v3?**

**Flux actual:**
```
Restaurant App v3:
  ├─ Anulează comanda în SQLite (status = 'cancelled')
  ├─ Emite WebSocket event 'orderCancelled'
  └─ ❌ NU trimite automat webhook către FriendsRide
```

**Problema:** Anularea **NU se propagă automat** către FriendsRide!

---

### **2. Unde rămân comenzile anulate?**

**În Firestore (`delivery_orders` collection):**
- Comenzile rămân cu status **`pending`** sau **`ready`**
- **NU** sunt marcate automat ca **`cancelled`**
- Rămân **agățate** în Firestore până când sunt procesate manual

---

### **3. Se mai alocă curierilor comenzile anulate?**

**DA, dacă status = `ready`!**

**Logica actuală:**
```dart
// În delivery_service.dart
Stream<List<DeliveryOrder>> getAvailableOrdersStream() {
  return _db
      .collection('delivery_orders')
      .where('status', isEqualTo: DeliveryOrderStatus.ready.toFirestoreString())
      .orderBy('createdAt', descending: false)
      .limit(50)
      .snapshots()
      ...
}
```

**Problema:** Query-ul **NU filtrează** comenzile anulate din Restaurant App v3!

**Consecințe:**
- ✅ Comenzile cu status `ready` **pot fi alocate** curierilor
- ❌ Chiar dacă au fost anulate în Restaurant App v3
- ❌ Curierul va primi o comandă care nu mai există în restaurant

---

### **4. Există fallback sau verificare?**

**NU există fallback automat!**

**Ce lipsește:**
1. ❌ Webhook de la Restaurant App v3 către FriendsRide pentru anulări
2. ❌ Verificare periodică a status-ului comenzilor în Restaurant App v3
3. ❌ Filtrare a comenzilor anulate din query-ul pentru curieri

---

## 🔧 SOLUȚII

### **Soluția 1: Webhook pentru anulări (Recomandat)**

**Implementare în Restaurant App v3:**
```javascript
// În server.js, când comanda este anulată:
app.post('/api/orders/:id/cancel', async (req, res) => {
  // ... (logica existentă de anulare) ...
  
  // ✅ NOU: Trimite webhook către FriendsRide dacă e comandă delivery
  if (order.type === 'delivery' && order.friendsride_order_id) {
    await sendOrderStatusUpdateToFriendsRide(
      order.id, 
      'cancelled', 
      null,
      { reason: cancelReason }
    );
  }
  
  // ... (rest of code) ...
});
```

**Implementare în FriendsRide:**
```dart
// Endpoint pentru primirea anulărilor
// PUT /api/delivery/orders/{orderId}/status
// Body: { status: 'cancelled', reason: '...' }
```

---

### **Soluția 2: Verificare periodică (Fallback)**

**Implementare în FriendsRide:**
```dart
// Timer care verifică periodic status-ul comenzilor în Restaurant App v3
Timer.periodic(Duration(minutes: 5), (timer) async {
  // Query comenzile cu status 'ready' sau 'pending'
  // Verifică status-ul în Restaurant App v3
  // Actualizează în Firestore dacă au fost anulate
});
```

---

### **Soluția 3: Filtrare în query (Quick Fix)**

**Implementare în FriendsRide:**
```dart
// Adaugă filtru pentru comenzile care NU au fost anulate
Stream<List<DeliveryOrder>> getAvailableOrdersStream() {
  return _db
      .collection('delivery_orders')
      .where('status', isEqualTo: DeliveryOrderStatus.ready.toFirestoreString())
      .where('metadata.isCancelledInRestaurant', isEqualTo: false) // ✅ NOU
      .orderBy('createdAt', descending: false)
      .limit(50)
      .snapshots()
      ...
}
```

---

## 🧹 CURĂȚAREA COMENZILOR DE TEST

### **Script pentru curățare:**

**Am creat:** `lib/delivery/scripts/cleanup_test_orders.dart`

**Funcționalități:**
1. ✅ **Listează** toate comenzile de test
2. ✅ **Marchează** comenzile ca `cancelled`
3. ✅ **Șterge** comenzile (opțional, ireversibil)

**Utilizare:**
```dart
final cleanup = CleanupTestOrders();

// 1. Listează comenzile de test
await cleanup.listTestOrders(
  restaurantId: 'restaurant_app_v3_test_id',
  includeCancelled: true,
);

// 2. Marchează comenzile ca 'cancelled'
await cleanup.cancelAllTestOrders(
  onlyPending: true,        // Doar comenzile pending
  onlyReady: false,         // Sau doar ready
  olderThan24Hours: false,  // Sau doar cele mai vechi de 24h
  restaurantId: 'restaurant_app_v3_test_id',
);

// 3. Șterge comenzile (ATENȚIE: ireversibil!)
await cleanup.deleteAllTestOrders(
  onlyCancelled: true,     // Doar comenzile cancelled
  olderThan24Hours: true,   // Doar cele mai vechi de 24h
  restaurantId: 'restaurant_app_v3_test_id',
);
```

---

## 📋 PAȘI PENTRU CURĂȚARE IMEDIATĂ

### **Opțiunea 1: Marchează comenzile ca 'cancelled' (Recomandat)**

**În Firebase Console:**
1. Deschide `delivery_orders` collection
2. Filtrează după `restaurantId == 'restaurant_app_v3_test_id'`
3. Filtrează după `status IN ('pending', 'ready')`
4. Selectează toate comenzile
5. Update batch:
   ```json
   {
     "status": "cancelled",
     "updatedAt": "now",
     "metadata": {
       "cancellationReason": "Test order cleanup",
       "cancelledAt": "now",
       "cancelledBy": "system"
     }
   }
   ```

---

### **Opțiunea 2: Șterge comenzile (Ireversibil!)**

**În Firebase Console:**
1. Deschide `delivery_orders` collection
2. Filtrează după `restaurantId == 'restaurant_app_v3_test_id'`
3. Filtrează după `status == 'cancelled'` (sau `pending`/`ready`)
4. Selectează toate comenzile
5. Delete batch

**⚠️ ATENȚIE:** Operația este **ireversibilă**!

---

### **Opțiunea 3: Folosește scriptul Dart**

**În aplicație:**
```dart
// Adaugă buton în Restaurant Dashboard sau Settings
ElevatedButton(
  onPressed: () async {
    final cleanup = CleanupTestOrders();
    await cleanup.cancelAllTestOrders(
      onlyPending: true,
      restaurantId: currentRestaurantId,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Comenzile de test au fost anulate')),
    );
  },
  child: Text('Curăță Comenzile de Test'),
)
```

---

## 🎯 RECOMANDĂRI

### **1. Implementare imediată:**

✅ **Marchează comenzile de test ca 'cancelled'** (folosind scriptul sau Firebase Console)

✅ **Adaugă filtru în query-ul pentru curieri:**
```dart
.where('status', isEqualTo: 'ready')
.where('metadata.isCancelledInRestaurant', isEqualTo: false) // ✅ NOU
```

### **2. Implementare pe termen lung:**

✅ **Webhook pentru anulări** de la Restaurant App v3 către FriendsRide

✅ **Verificare periodică** a status-ului comenzilor (fallback)

✅ **Notificare curier** când o comandă este anulată

---

## 📊 REZUMAT

| Aspect | Status Actual | Problema | Soluție |
|--------|---------------|----------|---------|
| **Anulare în Restaurant App v3** | ✅ Funcționează | ❌ Nu se propagă la FriendsRide | Webhook |
| **Comenzi în Firestore** | ⚠️ Rămân agățate | Status `pending`/`ready` | Marchează ca `cancelled` |
| **Alocare curieri** | ⚠️ Se alocă | Chiar dacă anulate | Filtrare în query |
| **Fallback** | ❌ Nu există | Nu verifică status | Verificare periodică |

---

## ✅ ACȚIUNI IMEDIATE

1. **Marchează comenzile de test ca 'cancelled'** (folosind scriptul sau Firebase Console)
2. **Adaugă filtru în query-ul pentru curieri** (prevenire alocare comenzilor anulate)
3. **Implementează webhook pentru anulări** (sincronizare automată)

**Scriptul de curățare este gata:** `lib/delivery/scripts/cleanup_test_orders.dart`

