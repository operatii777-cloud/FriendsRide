# 📦 Widget JavaScript Integration Guide

**Versiune:** 1.0  
**Data:** 2025-01-28

---

## 🚀 Quick Start

### **1. Include Widget Script**

Adăugați script-ul în pagina HTML:

```html
<script src="https://cdn.friendsride.com/widget/friendsride-widget.js"></script>
```

### **2. Add Widget Container**

Adăugați container-ul widget-ului:

```html
<div id="friendsride-widget" data-restaurant-id="rest_123"></div>
```

---

## 📋 Configuration Options

### **Data Attributes**

```html
<div 
  id="friendsride-widget"
  data-restaurant-id="rest_123"
  data-theme="light"
  data-language="ro"
  data-api-key="your_api_key"
></div>
```

**Options:**

- `data-restaurant-id` (required) - ID-ul restaurantului
- `data-theme` - `light` sau `dark` (default: `light`)
- `data-language` - `ro` sau `en` (default: `ro`)
- `data-api-key` - API key pentru autentificare (opțional)

---

## 💻 Manual Initialization

```javascript
const widget = new FriendsRideWidget({
  restaurantId: 'rest_123',
  containerId: 'friendsride-widget',
  theme: 'light',
  language: 'ro',
  apiKey: 'your_api_key', // optional
});
```

---

## 🎨 Customization

### **Custom CSS**

Puteți suprascrie stilurile widget-ului:

```css
.friendsride-widget {
  border-radius: 16px !important;
}

.friendsride-widget-header {
  background: #your-color !important;
}
```

### **Theme Customization**

```javascript
const widget = new FriendsRideWidget({
  restaurantId: 'rest_123',
  theme: 'custom',
  customStyles: {
    primaryColor: '#1976d2',
    borderRadius: '12px',
    fontFamily: 'Arial, sans-serif',
  },
});
```

---

## 📱 Events

Widget-ul emite evenimente pentru integrare:

```javascript
// Listen for cart updates
document.addEventListener('friendsride:cart-updated', (event) => {
  console.log('Cart updated:', event.detail);
});

// Listen for order placed
document.addEventListener('friendsride:order-placed', (event) => {
  console.log('Order placed:', event.detail.orderId);
});
```

**Available Events:**

- `friendsride:cart-updated` - Coșul a fost actualizat
- `friendsride:order-placed` - Comandă plasată
- `friendsride:menu-loaded` - Meniul a fost încărcat
- `friendsride:error` - Eroare

---

## 🔧 API Methods

```javascript
// Get widget instance
const widget = window.friendsrideWidget;

// Add product to cart
widget.addToCart('product_id');

// Show cart
widget.showCart();

// Get cart items
const cartItems = widget.cart;

// Get cart total
const total = widget.getCartTotal();

// Reload menu
await widget.loadMenu();
```

---

## 📝 Examples

### **Example 1: Basic Integration**

```html
<!DOCTYPE html>
<html>
<head>
  <title>Restaurant Menu</title>
</head>
<body>
  <h1>Our Menu</h1>
  
  <!-- FriendsRide Widget -->
  <div id="friendsride-widget" data-restaurant-id="rest_123"></div>
  
  <script src="https://cdn.friendsride.com/widget/friendsride-widget.js"></script>
</body>
</html>
```

### **Example 2: Custom Container**

```html
<div id="my-delivery-widget" 
     data-restaurant-id="rest_123"
     data-theme="dark"
     data-language="en">
</div>

<script>
  // Widget will auto-initialize from data attributes
</script>
```

### **Example 3: Manual Initialization**

```html
<div id="friendsride-widget"></div>

<script>
  const widget = new FriendsRideWidget({
    restaurantId: 'rest_123',
    containerId: 'friendsride-widget',
    theme: 'light',
    language: 'ro',
  });
</script>
```

---

## 🐛 Troubleshooting

### **Widget nu se afișează**

1. Verificați că script-ul este încărcat
2. Verificați că container-ul există în DOM
3. Verificați `data-restaurant-id` este corect

### **Meniul nu se încarcă**

1. Verificați API key-ul (dacă e necesar)
2. Verificați console pentru erori
3. Verificați că restaurantul există în FriendsRide

---

## 📞 Support

Pentru întrebări sau probleme:

- **Email:** widget-support@friendsride.com
- **Documentație:** <https://docs.friendsride.com/widget>
