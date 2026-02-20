# 🧪 Testare Integrare Delivery - FriendsRide ↔ Restaurant App v3

**Data:** 2025-01-28  
**Scop:** Ghid pas cu pas pentru testarea integrării între FriendsRide și Restaurant App v3

---

## ✅ PREGĂTIRE

### **1. Verifică că Restaurant App v3 rulează**

```powershell
cd C:\restaurant_app\restaurant_app_v3_translation_system\server
node server.js
```

**Așteaptă mesajul:**
```
🚀 Serverul HTTP cu WebSockets pornit pe portul 3001
🌐 Protocol: HTTP (pentru ngrok)
```

**⚠️ IMPORTANT:** Serverul trebuie să asculte pe `0.0.0.0`, nu doar pe `localhost`!

### **2. Verifică că FriendsRide App rulează**

- Deschide FriendsRide App în Flutter
- Sau rulează pe web/emulator

### **3. Configurează webhookUrl în Firestore**

**Opțiune A: Automat (la pornirea app-ului)**
- FriendsRide App configurează automat `webhookUrl` pentru toate restaurantele
- Verifică în Firebase Console că `webhookUrl` este setat

**Opțiune B: Manual**
```dart
// În FriendsRide App
await RestaurantService().updateRestaurant(
  restaurantId: 'restaurant_id',
  webhookUrl: 'http://localhost:3001', // Pentru iOS Simulator/Web
  // SAU
  webhookUrl: 'http://10.0.2.2:3001', // Pentru Android Emulator
  // SAU
  webhookUrl: 'http://192.168.1.100:3001', // Pentru device fizic (IP-ul PC-ului)
);
```

---

## 🧪 TEST 1: Verifică că Endpoint-ul Există

### **Test din Browser (pe PC)**

Deschide în browser:
```
http://localhost:3001/api/delivery/orders
```

**Rezultat așteptat:**
- **Method Not Allowed** (405) - ✅ Endpoint-ul există!
- **Not Found** (404) - ❌ Endpoint-ul lipsește

### **Test cu curl (PowerShell)**

```powershell
curl -X POST http://localhost:3001/api/delivery/orders -H "Content-Type: application/json" -d '{}'
```

**Rezultat așteptat:**
```json
{
  "success": false,
  "error": "Missing required fields for FriendsRide delivery order."
}
```

✅ **Endpoint-ul funcționează!**

---

## 🧪 TEST 2: Plasează Comandă din FriendsRide

### **Pași:**

1. **Deschide FriendsRide App**
2. **Navighează la Delivery**
3. **Selectează un restaurant**
4. **Adaugă produse în coș**
5. **Plasează comanda**

### **Ce să verifici:**

**În FriendsRide App:**
- ✅ Comanda apare în "My Orders"
- ✅ Status: "Pending"

**În Restaurant App v3 Console:**
```
🚀🚀🚀 ========================================
🚀 ENDPOINT /api/delivery/orders APELAT!
🚀🚀🚀 ========================================
✅ FriendsRide Delivery Order created in Restaurant App: #123 (FriendsRide ID: abc123)
```

**În Restaurant App v3 UI:**
- ✅ Comanda apare pe ecranele BAR și BUCĂTĂRIE
- ✅ Type: "delivery"
- ✅ Status: "pending"

**În Firestore:**
- ✅ Comanda este salvată în `delivery_orders` collection
- ✅ `restaurantOrderId` este setat

---

## 🧪 TEST 3: Marchează Comanda ca "Ready"

### **Pași:**

1. **În Restaurant App v3:**
   - Deschide ecranul BAR sau BUCĂTĂRIE
   - Găsește comanda de delivery
   - Marchează comanda ca "Ready" (completed)

### **Ce să verifici:**

**În Restaurant App v3 Console:**
```
✅ Pickup code generated: A3B9X2
✅ Status update trimis către FriendsRide pentru comanda abc123: ready
```

**În Restaurant App v3 UI (livrare1-3.html):**
- ✅ Apare secțiunea "Delivery Pickup Code"
- ✅ QR Code generat
- ✅ Câmp pentru introducere manuală cod

**În FriendsRide App:**
- ✅ Status comanda: "Ready for Pickup"
- ✅ Pickup code afișat

---

## 🧪 TEST 4: Verifică Pickup Code

### **Pași:**

1. **În Restaurant App v3 (livrare1-3.html):**
   - Găsește comanda de delivery
   - Introduce pickup code-ul (sau scanează QR)
   - Click "Verify Pickup Code"

### **Ce să verifici:**

**În Restaurant App v3 Console:**
```
✅ Pickup code verified for order #123. Order marked as delivered.
✅ Status update trimis către FriendsRide pentru comanda abc123: delivered
```

**În Restaurant App v3 UI:**
- ✅ Status comanda: "Delivered"
- ✅ Pickup code verificat

**În FriendsRide App:**
- ✅ Status comanda: "Delivered"
- ✅ Notificare push (dacă e configurată)

---

## 🧪 TEST 5: Verifică WebSocket Updates

### **Ce să verifici:**

**În Restaurant App v3:**
- ✅ Ecranele BAR/BUCĂTĂRIE se actualizează automat când apare o comandă nouă
- ✅ Status-ul comenzii se actualizează automat

**În FriendsRide App:**
- ✅ Status-ul comenzii se actualizează în timp real

---

## 🔍 DEBUGGING

### **Problema: Comanda nu ajunge în Restaurant App v3**

**Verifică:**

1. **Serverul rulează?**
   ```powershell
   # Verifică procesul
   Get-Process node
   ```

2. **Portul este corect?**
   - Restaurant App v3: port 3001
   - Verifică în `server.js`: `const PORT = process.env.PORT || 3001;`

3. **webhookUrl este configurat?**
   ```dart
   final restaurant = await RestaurantService().getRestaurant('restaurant_id');
   print('Webhook URL: ${restaurant?.webhookUrl}');
   ```

4. **Serverul ascultă pe 0.0.0.0?**
   ```javascript
   // În server.js
   server.listen(PORT, '0.0.0.0', () => { ... }); // ✅ Corect
   // server.listen(PORT, 'localhost', () => { ... }); // ❌ Greșit
   ```

5. **Firewall permite conexiuni?**
   ```powershell
   # Windows Firewall
   New-NetFirewallRule -DisplayName "Restaurant App v3" -Direction Inbound -LocalPort 3001 -Protocol TCP -Action Allow
   ```

6. **Verifică log-urile:**
   - Restaurant App v3 Console
   - FriendsRide App Console
   - Firebase Console (Firestore logs)

### **Problema: Pickup Code nu se generează**

**Verifică:**

1. **Comanda este marcată ca "completed"?**
   - Status trebuie să fie "completed" înainte de a genera pickup code

2. **Funcția `generatePickupCode()` există?**
   ```javascript
   // În server.js
   function generatePickupCode() {
     const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
     // ...
   }
   ```

3. **Endpoint-ul pentru status update există?**
   ```javascript
   // În server.js
   app.put('/api/orders/:id/complete', ...);
   ```

### **Problema: Status Update nu ajunge în FriendsRide**

**Verifică:**

1. **Webhook URL este corect?**
   - Trebuie să fie URL-ul către FriendsRide Cloud Functions
   - Sau URL-ul local pentru development

2. **API Key este configurat?**
   ```javascript
   // În app_settings
   friendsride_api_key: 'your_api_key_here'
   ```

3. **Verifică log-urile:**
   ```javascript
   // În server.js
   console.log('✅ Status update trimis către FriendsRide...');
   ```

---

## 📋 CHECKLIST FINAL

- [ ] Restaurant App v3 rulează pe portul 3001
- [ ] Serverul ascultă pe `0.0.0.0`
- [ ] FriendsRide App rulează
- [ ] `webhookUrl` este configurat în Firestore
- [ ] Endpoint-ul `/api/delivery/orders` răspunde
- [ ] Comanda ajunge în Restaurant App v3
- [ ] Comanda apare pe ecranele BAR/BUCĂTĂRIE
- [ ] Pickup code se generează când comanda este "ready"
- [ ] Pickup code se verifică corect
- [ ] Status update ajunge în FriendsRide
- [ ] WebSocket updates funcționează

---

## 🎉 SUCCES!

Dacă toate testele trec, integrarea funcționează corect! 🚀

