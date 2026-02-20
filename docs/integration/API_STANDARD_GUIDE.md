# 📚 API Standard Integration Guide

**Versiune:** 1.0  
**Data:** 2025-01-28

---

## 🔑 Autentificare

Toate request-urile API necesită autentificare prin API Key în header:

```text
Authorization: Bearer {your_api_key}
```

### Obținere API Key

API Key-ul se obține după onboarding-ul restaurantului în FriendsRide:

- **Manual Onboarding:** Admin FriendsRide generează API key
- **Automat Onboarding:** API key generat automat după aprobare

---

## 📡 API Endpoints

### **Base URL**

```text
https://us-central1-friendsride.cloudfunctions.net
```

---

---

### **1. Menu Sync**


#### **POST /api/delivery/restaurants/{restaurantId}/menu/sync**

Sincronizează meniul restaurantului cu FriendsRide.

**Request:**

```json
{
  "products": [
    {
      "id": "prod_123",
      "name": "Pizza Margherita",
      "description": "Pizza clasică cu mozzarella și busuioc",
      "price": 35.00,
      "category": "Pizza",
      "imageUrl": "https://example.com/pizza.jpg",
      "isAvailable": true,
      "allergens": ["gluten", "lactose"],
      "availableModifications": [
        {
          "id": "mod_1",
          "name": "Extra mozzarella",
          "price": 5.00
        }
      ]
    }
  ]
}
```

**Response:**

```json
{
  "success": true,
  "syncedProducts": 25,
  "message": "Menu synced successfully"
}
```

---

### **2. Create Delivery Order**

#### **POST /api/delivery/orders**

Creează o comandă de delivery în FriendsRide.

**Request:**

```json
{
  "restaurantId": "rest_123",
  "items": [
    {
      "productId": "prod_456",
      "productName": "Pizza Margherita",
      "quantity": 2,
      "unitPrice": 35.00,
      "totalPrice": 70.00,
      "modifications": ["Extra mozzarella"],
      "specialNotes": "Fără ceapă"
    }
  ],
  "deliveryAddress": {
    "address": "Strada Exemplu, Nr. 10, București",
    "latitude": 44.4268,
    "longitude": 26.1025
  },
  "paymentMethod": "card",
  "customerPhone": "+40712345678",
  "customerName": "Ion Popescu",
  "notes": "Sună la intrare"
}
```

**Response:**

```json
{
  "success": true,
  "orderId": "order_789",
  "status": "pending",
  "estimatedDeliveryTime": 30,
  "total": 80.00
}
```

---

### **3. Update Order Status**

#### **PUT /api/delivery/orders/{orderId}/status**

Actualizează statusul unei comenzi.

**Request:**

```json
{
  "status": "ready",
  "estimatedTime": 15
}
```

**Status values:**

- `pending` - Comandă plasată
- `accepted` - Restaurantul a acceptat comanda
- `preparing` - Comanda se pregătește
- `ready` - Comanda este gata pentru pickup
- `pickedUp` - Curierul a preluat comanda
- `onTheWay` - Comanda este în drum
- `delivered` - Comanda a fost livrată
- `cancelled` - Comanda a fost anulată

**Response:**

```json
{
  "success": true,
  "orderId": "order_789",
  "status": "ready",
  "updatedAt": "2025-01-28T12:00:00Z"
}
```

---

### **4. Get Order Details**

#### **GET /api/delivery/orders/{orderId}**

Obține detalii despre o comandă.

**Response:**

```json
{
  "orderId": "order_789",
  "customerId": "user_456",
  "restaurantId": "rest_123",
  "status": "ready",
  "items": [...],
  "subtotal": 70.00,
  "deliveryFee": 5.00,
  "serviceFee": 3.00,
  "total": 78.00,
  "deliveryAddress": {...},
  "createdAt": "2025-01-28T11:30:00Z",
  "estimatedDeliveryTime": "2025-01-28T12:00:00Z"
}
```

---

### **5. Get Restaurant Menu**

#### **GET /api/delivery/restaurants/{restaurantId}/menu**

Obține meniul restaurantului din FriendsRide.

**Response:**

```json
{
  "restaurantId": "rest_123",
  "products": [
    {
      "id": "prod_456",
      "name": "Pizza Margherita",
      "description": "...",
      "price": 35.00,
      "category": "Pizza",
      "isAvailable": true,
      ...
    }
  ]
}
```

---

## 🔔 Webhooks

FriendsRide poate trimite webhooks către restaurant când se întâmplă evenimente importante.

### **Webhook URL Configuration**

Configurați webhook URL-ul în dashboard-ul restaurantului:

```text
POST /api/delivery/restaurants/{restaurantId}/webhook
Body: {
  "webhookUrl": "https://your-restaurant.com/webhooks/friendsride"
}
```

### **Webhook Events**

#### **1. Order Created**

```json
{
  "event": "order.created",
  "orderId": "order_789",
  "restaurantId": "rest_123",
  "timestamp": "2025-01-28T11:30:00Z",
  "data": {
    "order": {...}
  }
}
```

#### **2. Order Status Changed**

```json
{
  "event": "order.status_changed",
  "orderId": "order_789",
  "status": "ready",
  "timestamp": "2025-01-28T11:45:00Z"
}
```

#### **3. Courier Assigned**

```json
{
  "event": "order.courier_assigned",
  "orderId": "order_789",
  "courierId": "courier_123",
  "timestamp": "2025-01-28T11:50:00Z"
}
```

---

## ⚠️ Error Handling

Toate erorile returnează status code HTTP și un JSON cu detalii:

```json
{
  "error": {
    "code": "INVALID_API_KEY",
    "message": "API key is invalid or expired",
    "details": "..."
  }
}
```

**Status Codes:**

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized (invalid API key)
- `404` - Not Found
- `500` - Internal Server Error

---

## 📝 Rate Limiting

- **Requests per minute:** 100
- **Requests per hour:** 1000
- **Requests per day:** 10000

Dacă limita este depășită, veți primi status `429 Too Many Requests`.

---

## 🔒 Security

1. **HTTPS Only:** Toate request-urile trebuie să fie prin HTTPS
2. **API Key Rotation:** Se recomandă rotirea API key-urilor periodic
3. **IP Whitelisting:** Opțional, poate fi configurat în dashboard

---

## 📚 SDK Libraries

### **Node.js**
```bash
npm install @friendsride/delivery-api
```

```javascript
const { DeliveryApi } = require('@friendsride/delivery-api');

const api = new DeliveryApi({
  apiKey: 'your_api_key',
  baseUrl: 'https://us-central1-friendsride.cloudfunctions.net'
});

// Sync menu
await api.syncMenu(restaurantId, products);

// Create order
const order = await api.createOrder({
  restaurantId,
  items,
  deliveryAddress,
  paymentMethod: 'card'
});
```

### **Python**
```bash
pip install friendsride-delivery-api
```

```python
from friendsride import DeliveryApi

api = DeliveryApi(
    api_key='your_api_key',
    base_url='https://us-central1-friendsride.cloudfunctions.net'
)

# Sync menu
api.sync_menu(restaurant_id, products)

# Create order
order = api.create_order(
    restaurant_id=restaurant_id,
    items=items,
    delivery_address=delivery_address,
    payment_method='card'
)
```

### **PHP**
```bash
composer require friendsride/delivery-api
```

```php
use FriendsRide\DeliveryApi;

$api = new DeliveryApi([
    'api_key' => 'your_api_key',
    'base_url' => 'https://us-central1-friendsride.cloudfunctions.net'
]);

// Sync menu
$api->syncMenu($restaurantId, $products);

// Create order
$order = $api->createOrder([
    'restaurant_id' => $restaurantId,
    'items' => $items,
    'delivery_address' => $deliveryAddress,
    'payment_method' => 'card'
]);
```

---

## 📞 Support

---

Pentru întrebări sau probleme:

- **Email:** api-support@friendsride.com
- **Documentație:** <https://docs.friendsride.com/api>
- **Status Page:** <https://status.friendsride.com>
