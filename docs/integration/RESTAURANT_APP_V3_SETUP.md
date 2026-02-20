# 🍽️ Restaurant App v3 - Setup pentru FriendsRide Delivery

**Data:** 2025-01-28  
**Status:** Configurare Integrare  
**Port Restaurant App v3:** 3001

---

## 📋 CONFIGURARE WEBHOOK URL

Pentru ca comenzile din FriendsRide să ajungă automat în Restaurant App v3, trebuie să configurezi `webhookUrl` în Firestore pentru fiecare restaurant.

### **Pas 1: Configurare în Firestore**

În colecția `restaurants` din Firestore, pentru fiecare restaurant care folosește Restaurant App v3, adaugă:

```javascript
restaurants/{restaurantId}:
{
  // ... alte câmpuri existente ...
  "webhookUrl": "http://localhost:3001",  // ⚠️ Portul corect este 3001
  "restaurantAppV3TenantId": "tenant_123" // ID-ul tenant-ului (opțional)
}
```

### **Pas 2: Format Webhook URL**

**Pentru development (localhost):**
```
http://localhost:3001
```

**Pentru production:**
```
https://your-restaurant-app-domain.com
```

**Important:** 
- Nu adăuga `/` la final (codul se ocupă de asta automat)
- URL-ul complet va fi: `{webhookUrl}/api/delivery/orders`
- Exemplu: `http://localhost:3001/api/delivery/orders`

---

## 🔄 FLUXUL COMENZII

### **1. Client plasează comandă în FriendsRide**

```
FriendsRide App
  ↓
DeliveryService.createOrder()
  ↓
Salvează în Firestore (delivery_orders)
  ↓
Verifică dacă restaurantul are webhookUrl
  ↓
POST http://localhost:3001/api/delivery/orders
```

### **2. Restaurant App v3 primește comanda**

```
Restaurant App v3 (port 3001)
  ↓
POST /api/delivery/orders
  ↓
Salvează în SQLite (orders table, type='delivery')
  ↓
Apare pe ecranele BAR și BUCĂTĂRIE
  ↓
Returnează restaurantOrderId către FriendsRide
```

### **3. Status Updates**

Când comanda este gata în Restaurant App v3:

```
Restaurant App v3
  ↓
Marchează comanda ca "ready"
  ↓
Generează pickup code
  ↓
POST către FriendsRide: /api/delivery/orders/{orderId}/status
  ↓
FriendsRide primește status "ready" + pickup code
```

---

## ✅ VERIFICARE CONFIGURARE

### **Test 1: Verifică webhookUrl în Firestore**

```dart
// În Flutter/Dart
final restaurant = await RestaurantService().getRestaurant(restaurantId);
print('Webhook URL: ${restaurant?.webhookUrl}');
// Ar trebui să afișeze: http://localhost:3001
```

### **Test 2: Plasează o comandă de test**

1. Deschide FriendsRide App
2. Selectează un restaurant cu `webhookUrl` configurat
3. Adaugă produse în coș
4. Plasează comanda
5. Verifică în Restaurant App v3 (port 3001) dacă comanda apare

### **Test 3: Verifică logs**

**În FriendsRide (DeliveryService):**
```
✅ Order {orderId} sent to Restaurant App v3 successfully
✅ Restaurant Order ID: {restaurantOrderId}
```

**În Restaurant App v3 (server.js):**
```
🚀 ENDPOINT /api/delivery/orders APELAT!
✅ FriendsRide Delivery Order created in Restaurant App: #{restaurantOrderId}
```

---

## 🔧 TROUBLESHOOTING

### **Problema: Comanda nu ajunge în Restaurant App v3**

**Cauze posibile:**
1. ❌ `webhookUrl` nu este configurat în Firestore
   - **Soluție:** Adaugă `webhookUrl: "http://localhost:3001"` în documentul restaurantului

2. ❌ Restaurant App v3 nu rulează pe portul 3001
   - **Soluție:** Verifică că serverul rulează: `node server.js` pe portul 3001

3. ❌ Firewall/CORS blochează conexiunea
   - **Soluție:** Verifică că Restaurant App v3 acceptă conexiuni de la FriendsRide

4. ❌ Format URL incorect
   - **Soluție:** Folosește `http://localhost:3001` (fără `/` la final)

### **Problema: Eroare 404 Not Found**

**Cauză:** Endpoint-ul `/api/delivery/orders` nu există în Restaurant App v3

**Soluție:** Verifică că ai implementat endpoint-ul în `server.js`:
```javascript
app.post('/api/delivery/orders', async (req, res) => {
  // ... implementare ...
});
```

### **Problema: Eroare 500 Internal Server Error**

**Cauză:** Eroare în procesarea comenzii în Restaurant App v3

**Soluție:** Verifică logs-urile din `server.js` pentru detalii despre eroare

---

## 📝 NOTĂ IMPORTANTĂ

**Portul Restaurant App v3 este 3001, nu 3000!**

Când configurezi `webhookUrl` în Firestore, folosește întotdeauna:
```
http://localhost:3001  // ✅ Corect
http://localhost:3000  // ❌ Greșit
```

---

## 🔗 LINK-URI UTILE

- [Restaurant App v3 Integration Guide](../FRIENDSRIDE_DELIVERY_INTEGRATION.md)
- [API Standard Guide](./API_STANDARD_GUIDE.md)
- [Delivery Progress](../IMPLEMENTARE_DELIVERY_PROGRES.md)

