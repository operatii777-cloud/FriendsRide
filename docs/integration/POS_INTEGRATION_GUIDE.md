# 🖥️ POS Integration Guide

**Versiune:** 1.0  
**Data:** 2025-01-28

---

## 🎯 Overview

POS Integration permite restaurante cu sisteme POS existente să se integreze cu FriendsRide Delivery prin API Standard sau plugin-uri specifice.

---

## 🔌 Supported POS Systems

### **1. Square**

- Plugin disponibil
- Sync automat meniu
- Comenzi integrate

### **2. Toast**

- Plugin disponibil
- Sync automat meniu
- Comenzi integrate

### **3. Generic POS (API Standard)**

- Orice POS care suportă API REST
- Integrare prin API Standard
- Documentație: `API_STANDARD_GUIDE.md`

---

## 📦 Square Integration

### **Square Installation**

1. Accesați Square App Marketplace
2. Căutați "FriendsRide Delivery"
3. Click "Install"
4. Autentificați-vă cu contul FriendsRide

### **Configuration**

1. Conectați contul Square cu FriendsRide
2. Selectați locațiile care vor folosi delivery
3. Configurați maparea categoriilor
4. Activează sync automat

### **Features**

- ✅ Sync automat meniu (când se modifică în Square)
- ✅ Comenzi delivery apar în Square
- ✅ Status updates sincronizate
- ✅ Rapoarte integrate

---

## 🍞 Toast Integration

### **Toast Installation**

1. Accesați Toast App Directory
2. Căutați "FriendsRide Delivery"
3. Click "Install"
4. Autentificați-vă cu contul FriendsRide

### **Configuration**

1. Conectați contul Toast cu FriendsRide
2. Selectați restaurantele
3. Configurați maparea meniului
4. Activează sync automat

### **Features**

- ✅ Sync automat meniu
- ✅ Comenzi delivery în Toast
- ✅ Status updates sincronizate
- ✅ Inventory sync (opțional)

---

## 🔧 Generic POS Integration

Pentru POS-uri care nu au plugin dedicat, folosiți API Standard:


### **Step 1: Get API Key**

1. Accesați Dashboard FriendsRide
2. Navigați la "Settings" → "API Keys"
3. Generați un API key nou

### **Step 2: Implement API Client**

Folosiți SDK-urile disponibile sau implementați manual:

**Node.js Example:**

```javascript
const { DeliveryApi } = require('@friendsride/delivery-api');

const api = new DeliveryApi({
  apiKey: 'your_api_key',
});

// Sync menu from POS to FriendsRide
async function syncMenu() {
  const posMenu = await getMenuFromPOS();
  await api.syncMenu(restaurantId, posMenu);
}

// Create order in FriendsRide when received in POS
async function createDeliveryOrder(order) {
  const deliveryOrder = await api.createOrder({
    restaurantId: restaurantId,
    items: order.items,
    deliveryAddress: order.deliveryAddress,
    paymentMethod: 'card',
  });
}
```

### **Step 3: Webhook Setup**

Configurați webhooks în POS pentru a primi notificări:

```javascript
// Webhook endpoint in your POS
app.post('/webhooks/friendsride', async (req, res) => {
  const { event, orderId, status } = req.body;
  
  if (event === 'order.status_changed') {
    // Update order status in POS
    await updateOrderInPOS(orderId, status);
  }
});
```

---

## 📋 Integration Checklist

### **Pre-Integration**

- [ ] Verificați că POS-ul suportă API/plugins
- [ ] Obțineți API key din FriendsRide
- [ ] Testați conectivitatea

### **Menu Sync**

- [ ] Configurați maparea categoriilor
- [ ] Testați sync inițial
- [ ] Verificați produsele în FriendsRide
- [ ] Activează sync automat

### **Order Management**

- [ ] Testați crearea comenzii
- [ ] Verificați status updates
- [ ] Testați webhooks
- [ ] Verificați sincronizarea

### **Post-Integration**

- [ ] Monitorizați erorile
- [ ] Verificați rapoartele
- [ ] Optimizați sync-ul
- [ ] Documentați procesul

---

## 🐛 Troubleshooting

### **Menu nu se sincronizează**

1. Verificați API key-ul
2. Verificați conectivitatea
3. Verificați log-urile pentru erori
4. Contactați support

### **Comenzi nu apar în POS**

1. Verificați webhook URL-ul
2. Verificați autentificarea webhook-ului
3. Verificați log-urile POS-ului

---

## 📞 Support

Pentru întrebări sau probleme:

---

- **Email:** pos-integration@friendsride.com
- **Documentație:** <https://docs.friendsride.com/pos-integration>
- **Status:** <https://status.friendsride.com>

---

## 🔄 Plugin Templates

Plugin templates pentru POS-uri populare sunt disponibile în:

- `plugins/square/`
- `plugins/toast/`
- `plugins/generic/`

Consultați README-ul din fiecare director pentru instrucțiuni specifice.
