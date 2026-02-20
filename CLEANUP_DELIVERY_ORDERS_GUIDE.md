# 🧹 Ghid: Curățare Comenzi Delivery

## 📋 LOCAȚII UNDE SE GĂSESC COMENZILE

1. **Firestore** (`delivery_orders` collection)
2. **Restaurant App v3** (SQLite - tabela `orders` cu `type='delivery'`)
3. **FriendsRide App** (cache local, dacă există)

---

## 🗑️ METODA 1: Ștergere din Restaurant App v3 (SQLite)

### **Script Node.js:**

```bash
cd C:\restaurant_app\restaurant_app_v3_translation_system\server
node cleanup_all_delivery_orders.js
```

**Ce face:**
- Găsește toate comenzile cu `type='delivery'`
- Șterge permanent din SQLite
- Afișează rezumat

**Status:** ✅ Script creat și gata de rulare

---

## 🗑️ METODA 2: Ștergere din Firestore

### **Opțiunea A: Firebase Console (Manual)**

1. Deschide [Firebase Console](https://console.firebase.google.com)
2. Selectează proiectul FriendsRide
3. Mergi la **Firestore Database**
4. Selectează collection `delivery_orders`
5. Filtrează (opțional):
   - `restaurantId == 'restaurant_app_v3_test_id'` (pentru test orders)
   - `status == 'cancelled'` (pentru comenzi anulate)
6. Selectează toate comenzile
7. Click **Delete** (batch delete)

### **Opțiunea B: Script Dart (Programatic)**

**Folosește:** `lib/delivery/scripts/cleanup_test_orders.dart`

```dart
final cleanup = CleanupTestOrders();

// Șterge TOATE comenzile de delivery
await cleanup.deleteAllDeliveryOrders(
  onlyCancelled: false,        // false = șterge TOATE
  olderThan24Hours: false,     // false = șterge și cele noi
  restaurantId: 'restaurant_app_v3_test_id', // Opțional
);
```

**Sau folosește screen-ul UI:**
- Deschide aplicația
- Mergi la Delivery → Restaurant Dashboard
- Tab "Comenzi" → Buton "Curățare Comenzi"

---

## 🗑️ METODA 3: Ștergere Completă (Toate Locațiile)

### **Pași:**

1. **Șterge din Restaurant App v3:**
   ```bash
   cd C:\restaurant_app\restaurant_app_v3_translation_system\server
   node cleanup_all_delivery_orders.js
   ```

2. **Șterge din Firestore:**
   - Folosește Firebase Console (Metoda 2A)
   - SAU folosește scriptul Dart (Metoda 2B)

3. **Verifică:**
   - Restaurant App v3: Verifică ecranele BAR/BUCĂTĂRIE
   - Firestore: Verifică collection `delivery_orders`
   - FriendsRide: Verifică "Comenzile mele"

---

## ⚠️ ATENȚIE

- **Operația este IREVERSIBILĂ!**
- **Backup recomandat** înainte de ștergere
- **Testează** pe o comandă de test înainte de ștergerea în bloc

---

## ✅ STATUS IMPLEMENTARE

| Locație | Status | Metodă |
|---------|--------|--------|
| **Restaurant App v3** | ✅ Gata | `cleanup_all_delivery_orders.js` |
| **Firestore** | ✅ Gata | Firebase Console sau Script Dart |
| **FriendsRide App** | ✅ Gata | Se actualizează automat din Firestore |

---

## 🚀 RULARE RAPIDĂ

**Pentru ștergerea completă:**

1. **Restaurant App v3:**
   ```bash
   cd C:\restaurant_app\restaurant_app_v3_translation_system\server
   node cleanup_all_delivery_orders.js
   ```

2. **Firestore:**
   - Deschide Firebase Console
   - Șterge manual din `delivery_orders` collection
   - SAU folosește scriptul Dart din aplicație

**Gata!** 🎉

