# 🚀 PLAN IMPLEMENTARE DELIVERY FRIENDSRIDE - VERSIUNEA FINALĂ

**Data:** 2025-01-28  
**Status:** Planificare Finală  
**Decizii:** ✅ Toate deciziile au fost luate

---

## 📋 DECIZII FINALE

### **1. Comisioane**
- **Range:** 9-14% (foarte competitiv, mai bun decât Bolt Food 10-15%)
- **Variabil:** În funcție de volum, oraș, tip restaurant
- **Model:** Comision din valoarea comenzii + taxă livrare (opțional)

### **2. Onboarding Restaurante**
- **Dual System:**
  - ✅ **Manual:** Admin FriendsRide adaugă restaurantul manual
  - ✅ **Automat:** Când restaurantul cumpără licența Restaurant App v3, se poate înscrie automat în FriendsRide (opțional)
- **Flexibilitate:** Unele restaurante pot alege să nu folosească delivery sau să aibă propriul delivery

### **3. Menu Sync**
- **Event-Based:** Doar la modificarea meniului în Restaurant App v3
- **Trigger:** Restaurant App v3 trimite webhook automat către FriendsRide când se modifică meniul
- **Eficiență:** Nu mai e nevoie de sync periodic, doar când se schimbă ceva

### **4. Order Management**
- **Source of Truth:** Restaurant App v3 (SQLite)
- **FriendsRide:** Doar creează comanda inițial și urmărește statusul
- **Actualizări:** Restaurant App v3 actualizează statusul → FriendsRide primește notificare

### **5. Curieri**
- **Dual System:**
  - ✅ **FriendsRide Curieri:** Curieri generali care lucrează pentru platformă
  - ✅ **Restaurant Curieri:** Curieri proprii ai restaurantului (gestionați în Restaurant App v3)
- **Flexibilitate:** Restaurantul poate alege să folosească curieri FriendsRide sau proprii curieri

---

## 🏗️ ARHITECTURĂ FINALĂ

```
┌─────────────────────────────────────────────────────────────┐
│                    FRIENDSRIDE PLATFORM                      │
│  ┌──────────────────┐  ┌──────────────────┐                 │
│  │  Customer App    │  │  Courier App     │                 │
│  │  (Flutter)       │  │  (Flutter)       │                 │
│  └────────┬─────────┘  └────────┬─────────┘                 │
│           │                     │                            │
│           └──────────┬──────────┘                            │
│                      ▼                                       │
│  ┌──────────────────────────────────────────┐               │
│  │      FRIENDSRIDE BACKEND (Firebase)      │               │
│  │  - Firestore (Orders, Couriers, Menu)    │               │
│  │  - Cloud Functions (Webhooks, Matching)  │               │
│  │  - Authentication                        │               │
│  └──────────┬───────────────────────────────┘               │
└─────────────┼───────────────────────────────────────────────┘
              │
              │ Webhooks + API
              │
┌─────────────▼───────────────────────────────────────────────┐
│         RESTAURANT APP v3 (White-Label Multi-Tenant)         │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Node.js + Express + SQLite                        │     │
│  │  - Menu Management (SQLite)                        │     │
│  │  - Order Management (SQLite) - SOURCE OF TRUTH     │     │
│  │  - Restaurant Couriers (SQLite)                    │     │
│  │  - Webhook Sender (când se modifică meniul)       │     │
│  │  - API Endpoints pentru FriendsRide                │     │
│  └─────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔄 FLUXURI PRINCIPALE

### **1. Menu Sync (Event-Based)**

```
Restaurant App v3:
  ├─ Admin modifică meniul (adaugă/șterge/modifică produs)
  ├─ Trigger: Webhook către FriendsRide
  └─ POST https://friendsride-api.com/webhooks/menu-update
      Body: {
        restaurantId: "rest_123",
        action: "create|update|delete",
        product: { ... }
      }

FriendsRide:
  ├─ Primește webhook
  ├─ Validează restaurantId și autentificare
  ├─ Actualizează Firestore (products collection)
  └─ Notifică clienții (opțional) că meniul s-a actualizat
```

### **2. Order Creation & Management**

```
Customer App (FriendsRide):
  ├─ Client plasează comandă
  ├─ Creează order în Firestore (delivery_orders)
  └─ POST către Restaurant App v3: /api/delivery/orders
      Body: {
        orderId: "order_123",
        restaurantId: "rest_123",
        items: [...],
        customerId: "user_456",
        deliveryAddress: {...},
        total: 150.00
      }

Restaurant App v3:
  ├─ Primește comanda
  ├─ Salvează în SQLite (orders table, type="delivery")
  ├─ Returnează confirmare
  └─ Actualizează status: "pending" → "accepted"

FriendsRide:
  ├─ Primește confirmare
  ├─ Actualizează Firestore order status
  └─ Notifică client că comanda a fost acceptată
```

### **3. Order Status Updates**

```
Restaurant App v3:
  ├─ Restaurant actualizează status (preparing, ready, etc.)
  ├─ PUT către FriendsRide: /api/delivery/orders/{orderId}/status
      Body: {
        status: "preparing|ready|completed",
        estimatedTime: 15
      }
  └─ Salvează în SQLite

FriendsRide:
  ├─ Primește actualizare status
  ├─ Actualizează Firestore order
  ├─ Dacă status = "ready": Trigger courier matching
  └─ Notifică client despre nou status
```

### **4. Courier Assignment**

```
FriendsRide (când order status = "ready"):
  ├─ Caută curieri disponibili (FriendsRide couriers)
  ├─ Verifică dacă restaurantul are curieri proprii disponibili
  ├─ Algoritm matching:
  │   ├─ Prioritate 1: Restaurant couriers (dacă disponibili)
  │   └─ Prioritate 2: FriendsRide couriers
  ├─ Atribuie curier
  └─ Notifică restaurant și client

Restaurant App v3 (dacă folosește curieri proprii):
  ├─ Primește notificare că trebuie să atribuie curier
  ├─ Selectează curier din lista proprie
  └─ Notifică FriendsRide despre curierul atribuit
```

---

## 📊 STRUCTURĂ FIRESTORE

### **Collections:**

```
restaurants/
  {restaurantId}/
    - name: "Restaurant Name"
    - address: {...}
    - imageUrl: "..."
    - rating: 4.5
    - reviewCount: 120
    - status: "open|closed|busy"
    - deliveryFee: 5.00
    - minimumOrder: 50.00
    - cuisineTypes: ["Italian", "Pizza"]
    - workingHours: {...}
    - deliveryZones: [...]
    - commissionRate: 0.12  // 12%
    - hasOwnCouriers: true
    - friendsrideApiKey: "..."  // pentru autentificare
    - webhookUrl: "..."  // pentru notificări către restaurant
    - createdAt: Timestamp
    - updatedAt: Timestamp

products/
  {productId}/
    - restaurantId: "rest_123"
    - name: "Pizza Margherita"
    - description: "..."
    - price: 35.00
    - imageUrl: "..."
    - category: "Pizza"
    - isAvailable: true
    - allergens: ["gluten", "lactose"]
    - nutritionalInfo: {...}
    - availableModifications: [...]
    - createdAt: Timestamp
    - updatedAt: Timestamp
    - lastSyncedAt: Timestamp  // când a fost sincronizat din Restaurant App

delivery_orders/
  {orderId}/
    - customerId: "user_456"
    - restaurantId: "rest_123"
    - courierId: "courier_789"  // null dacă nu e atribuit
    - courierType: "friendsride|restaurant"  // tip curier
    - status: "pending|accepted|preparing|ready|picked_up|on_the_way|delivered|cancelled"
    - items: [...]
    - subtotal: 120.00
    - deliveryFee: 5.00
    - serviceFee: 14.40  // 12% din subtotal
    - total: 139.40
    - deliveryAddress: {...}
    - restaurantAddress: {...}
    - paymentMethod: "card|cash|wallet"
    - promoCode: "..."
    - discount: 0.00
    - estimatedDeliveryTime: 30  // minutes
    - actualDeliveryTime: null
    - createdAt: Timestamp
    - updatedAt: Timestamp
    - restaurantOrderId: "..."  // ID-ul comenzii în Restaurant App v3

couriers/
  {courierId}/
    - userId: "user_789"
    - type: "friendsride|restaurant"
    - restaurantId: null  // doar dacă type = "restaurant"
    - status: "offline|online|delivering"
    - currentOrderId: "order_123"  // null dacă e liber
    - vehicleType: "bike|scooter|car"
    - rating: 4.8
    - completedDeliveries: 150
    - currentLocation: {...}
    - lastLocationUpdate: Timestamp
    - createdAt: Timestamp
    - updatedAt: Timestamp

restaurant_couriers/  // Curieri proprii ai restaurantelor
  {courierId}/
    - restaurantId: "rest_123"
    - userId: "user_999"
    - name: "Ion Popescu"
    - phone: "+40712345678"
    - status: "offline|online|delivering"
    - currentOrderId: null
    - vehicleType: "bike|scooter|car"
    - rating: 4.9
    - completedDeliveries: 45
    - currentLocation: {...}
    - lastLocationUpdate: Timestamp
```

---

## 🔌 API ENDPOINTS NECESARE

### **Restaurant App v3 → FriendsRide**

#### **1. Menu Webhook**
```
POST /webhooks/menu-update
Headers:
  Authorization: Bearer {restaurantApiKey}
  Content-Type: application/json
Body:
{
  "restaurantId": "rest_123",
  "action": "create|update|delete",
  "product": {
    "id": "prod_456",
    "name": "Pizza Margherita",
    "price": 35.00,
    ...
  }
}
```

#### **2. Order Status Update**
```
PUT /api/delivery/orders/{orderId}/status
Headers:
  Authorization: Bearer {restaurantApiKey}
Body:
{
  "status": "preparing|ready|completed",
  "estimatedTime": 15  // minutes
}
```

#### **3. Courier Assignment (Restaurant Couriers)**
```
PUT /api/delivery/orders/{orderId}/assign-courier
Headers:
  Authorization: Bearer {restaurantApiKey}
Body:
{
  "courierId": "rest_courier_789",
  "courierType": "restaurant"
}
```

### **FriendsRide → Restaurant App v3**

#### **1. Create Delivery Order**
```
POST {restaurantWebhookUrl}/api/delivery/orders
Headers:
  Authorization: Bearer {friendsrideApiKey}
Body:
{
  "orderId": "order_123",
  "customerId": "user_456",
  "items": [...],
  "deliveryAddress": {...},
  "total": 150.00,
  "paymentMethod": "card"
}
Response:
{
  "success": true,
  "restaurantOrderId": "rest_order_789",
  "estimatedPrepTime": 20  // minutes
}
```

#### **2. Get Order Status**
```
GET {restaurantWebhookUrl}/api/delivery/orders/{restaurantOrderId}
Headers:
  Authorization: Bearer {friendsrideApiKey}
Response:
{
  "status": "preparing",
  "estimatedTime": 15
}
```

---

## 🔌 TIPURI DE INTEGRARE RESTAURANTE

### **1. Restaurant App v3 (White-Label)**
- ✅ Integrare completă (event-based webhooks)
- ✅ Menu sync automat la modificare
- ✅ Order management în SQLite
- ✅ Ecrane bar/bucătărie/livrare integrate
- ✅ Pickup code verification în livrare1-3.html și comanda-supervisor11.html

### **2. API Standard (Restaurante cu Sistem Propriu)**
- ✅ API endpoints pentru menu sync
- ✅ Webhook receiver pentru orders
- ✅ Status updates prin API
- ✅ Pickup code verification prin API
- ✅ Flexibil: orice sistem poate integra

### **3. Widget JavaScript (Restaurante cu Site Propriu)**
- ✅ Widget embeddable în orice site
- ✅ Menu display din FriendsRide
- ✅ Cart și checkout integrat
- ✅ Order tracking
- ✅ Zero backend necesar pentru restaurant

### **4. Dashboard Manual (Restaurante Mici)**
- ✅ FriendsRide Dashboard pentru gestionare
- ✅ Menu management manual
- ✅ Order management manual
- ✅ Status updates manual
- ✅ Perfect pentru restaurante fără sistem

### **5. POS Integration (Restaurante cu POS Existente)**
- ✅ API client pentru POS-uri populare
- ✅ Plugin templates
- ✅ Menu sync automat
- ✅ Order management automat
- ✅ Compatibil cu majoritatea POS-urilor

---

## 🛠️ PLAN IMPLEMENTARE PAS CU PAS

### **FAZA 1: Foundation & Infrastructure** ⏱️ ~2-3 zile

#### **1.1. Firestore Collections Structure**
- [ ] Creează structura collections (restaurants, products, delivery_orders, couriers, restaurant_couriers)
- [ ] Definește Firestore security rules
- [ ] Creează indexes necesare pentru queries

#### **1.2. Restaurant Onboarding System**
- [ ] **Manual Onboarding:**
  - [ ] Admin screen în FriendsRide pentru adăugare restaurant
  - [ ] Formular: nume, adresă, configurare comision, etc.
  - [ ] Generare API key pentru restaurant
- [ ] **Automat Onboarding:**
  - [ ] Endpoint în Restaurant App v3 pentru self-registration
  - [ ] Validare și aprobare automată sau manuală
  - [ ] Generare API key automată

#### **1.3. Authentication & API Keys**
- [ ] Sistem de API keys pentru restaurante
- [ ] Middleware pentru validare API keys
- [ ] Rate limiting pentru API endpoints

---

### **FAZA 2: Menu Sync (Event-Based)** ⏱️ ~2-3 zile

#### **2.1. Restaurant App v3 - Webhook Sender**
- [ ] Adaugă webhook sender în Restaurant App v3
- [ ] Trigger când se modifică meniul (create/update/delete)
- [ ] Retry logic pentru webhook failures
- [ ] Queue pentru webhooks (dacă FriendsRide e offline)

#### **2.2. FriendsRide - Webhook Receiver**
- [ ] Cloud Function sau endpoint pentru webhook
- [ ] Validare autentificare (API key)
- [ ] Mapare product din Restaurant App format → Firestore format
- [ ] Actualizare Firestore products collection
- [ ] Notificare clienți (opțional) despre meniu actualizat

#### **2.3. Initial Menu Sync**
- [ ] Endpoint pentru sync inițial al meniului (când restaurantul se înscrie)
- [ ] Batch import din Restaurant App v3 → Firestore
- [ ] Validare și error handling

---

### **FAZA 3: Order Management** ⏱️ ~3-4 zile

#### **3.1. Order Creation (FriendsRide → Restaurant App)**
- [ ] Când client plasează comandă în FriendsRide:
  - [ ] Creează order în Firestore
  - [ ] Calculează comision (9-14%)
  - [ ] Trimite POST către Restaurant App v3
  - [ ] Așteaptă confirmare
  - [ ] Actualizează status în Firestore

#### **3.2. Order Status Updates (Restaurant App → FriendsRide)**
- [ ] Restaurant App actualizează status → FriendsRide
- [ ] FriendsRide actualizează Firestore order
- [ ] Notifică client despre nou status
- [ ] Dacă status = "ready": trigger courier matching

#### **3.3. Order Tracking**
- [ ] Real-time tracking în Customer App
- [ ] Status updates vizibile pentru client
- [ ] ETA calculation și display

---

### **FAZA 4: Courier System (Dual)** ⏱️ ~3-4 zile

#### **4.1. FriendsRide Couriers**
- [ ] Gestionare curieri în FriendsRide (Firestore)
- [ ] Courier registration și onboarding
- [ ] Courier status management (offline/online/delivering)
- [ ] Location tracking pentru curieri

#### **4.2. Restaurant Couriers**
- [ ] Gestionare curieri în Restaurant App v3 (SQLite)
- [ ] Sync către Firestore (restaurant_couriers collection)
- [ ] Restaurant poate atribui proprii curieri la comenzi

#### **4.3. Courier Matching Algorithm**
- [ ] Când order status = "ready":
  - [ ] Verifică dacă restaurantul are curieri proprii disponibili
  - [ ] Dacă da: notifică restaurant să atribuie curier
  - [ ] Dacă nu: caută FriendsRide couriers disponibili
  - [ ] Algoritm matching bazat pe distanță, rating, disponibilitate
  - [ ] Atribuire automată sau manuală

---

### **FAZA 5: Customer App - Delivery Screens** ⏱️ ~5-7 zile

#### **5.1. Restaurant Discovery**
- [ ] RestaurantListScreen: Listă restaurante disponibile
- [ ] Filtrare: distanță, rating, tip bucătărie, preț
- [ ] Căutare restaurante
- [ ] Map view cu restaurante pe hartă

#### **5.2. Restaurant Detail & Menu**
- [ ] RestaurantDetailScreen: Detalii restaurant
- [ ] Menu display cu categorii
- [ ] Product cards cu imagini, prețuri, alergeni
- [ ] Add to cart functionality

#### **5.3. Cart & Checkout**
- [ ] CartScreen: Coș de cumpărături
- [ ] Modificare cantități, ștergere items
- [ ] Calculare subtotal, delivery fee, service fee, total
- [ ] CheckoutScreen: Adresă livrare, payment method, promo codes
- [ ] Order confirmation

#### **5.4. Order Tracking**
- [ ] DeliveryTrackingScreen: Tracking live al comenzii
- [ ] Status updates în timp real
- [ ] ETA display
- [ ] Courier location (dacă e disponibil)
- [ ] Chat cu restaurant/courier (opțional)

---

### **FAZA 6: Courier App - Delivery Management** ⏱️ ~4-5 zile

#### **6.1. Courier Dashboard**
- [ ] Dashboard cu orders disponibile
- [ ] Accept/reject orders
- [ ] Current order display
- [ ] Earnings display

#### **6.2. Order Management**
- [ ] Order details screen
- [ ] Navigation către restaurant
- [ ] Pickup confirmation
- [ ] Navigation către client
- [ ] Delivery confirmation
- [ ] Rating client (opțional)

---

### **FAZA 7: Restaurant Integration Systems** ⏱️ ~10-12 zile

#### **7.1. Restaurant App v3 - Delivery Integration** ⏱️ ~3-4 zile
- [ ] Display delivery orders în Restaurant App v3
- [ ] Accept/reject orders
- [ ] Update order status (preparing, ready, etc.)
- [ ] Assign restaurant couriers (dacă aplicabil)
- [ ] Restaurant Couriers Management
- [ ] Webhook sender pentru menu updates
- [ ] Webhook receiver pentru order creation
- [ ] **Pickup Code System:**
  - [ ] Generare cod pickup când comanda e "ready"
  - [ ] Afișare cod în livrare1-3.html (scan QR + input manual)
  - [ ] Afișare cod în comanda-supervisor11.html (scan QR + input manual)
  - [ ] Endpoint verificare pickup code
  - [ ] Webhook către FriendsRide când e verificat

#### **7.2. API Standard Integration** ⏱️ ~2-3 zile
- [ ] **API Documentation:**
  - [ ] Menu sync endpoints
  - [ ] Order creation webhook
  - [ ] Status update endpoints
  - [ ] Pickup verification endpoint
- [ ] **API Client Library:**
  - [ ] SDK pentru Node.js
  - [ ] SDK pentru Python
  - [ ] SDK pentru PHP
  - [ ] Example implementations
- [ ] **Authentication System:**
  - [ ] API key generation
  - [ ] OAuth2 support (opțional)
  - [ ] Rate limiting
- [ ] **Webhook System:**
  - [ ] Webhook receiver în FriendsRide
  - [ ] Webhook sender către restaurante
  - [ ] Retry logic și error handling

#### **7.3. Widget JavaScript** ⏱️ ~2-3 zile
- [ ] **Widget Core:**
  - [ ] friendsride-widget.js (library)
  - [ ] Initialization și config
  - [ ] Menu loading din FriendsRide
  - [ ] Cart management
  - [ ] Checkout integration
- [ ] **Widget UI:**
  - [ ] Responsive design
  - [ ] Theme customization
  - [ ] Multi-language support
  - [ ] Mobile-friendly
- [ ] **Widget Features:**
  - [ ] Order tracking
  - [ ] Payment integration
  - [ ] Real-time updates
- [ ] **Documentation:**
  - [ ] Setup guide
  - [ ] API reference
  - [ ] Examples pentru diferite site-uri

#### **7.4. Dashboard Manual** ⏱️ ~1-2 zile
- [ ] **Restaurant Dashboard UI:**
  - [ ] Menu management (add/edit/delete products)
  - [ ] Order management (view/update status)
  - [ ] Settings (delivery zones, fees, etc.)
  - [ ] Statistics și rapoarte
- [ ] **Menu Management:**
  - [ ] CSV/Excel upload
  - [ ] Manual product entry
  - [ ] Image upload
  - [ ] Category management
- [ ] **Order Management:**
  - [ ] View orders
  - [ ] Update status manual
  - [ ] Pickup code verification
  - [ ] Order history

#### **7.5. POS Integration** ⏱️ ~2-3 zile
- [ ] **POS Plugin Templates:**
  - [ ] Template pentru Square
  - [ ] Template pentru Toast
  - [ ] Template pentru generic POS
- [ ] **API Client pentru POS:**
  - [ ] Menu sync adapter
  - [ ] Order creation adapter
  - [ ] Status update adapter
- [ ] **Documentation:**
  - [ ] Integration guide
  - [ ] POS-specific instructions
  - [ ] Troubleshooting

---

### **FAZA 8: Advanced Features** ⏱️ ~4-5 zile

#### **8.1. Pricing & Commissions**
- [ ] Calculare comisioane dinamice (9-14%)
- [ ] Surge pricing (dacă e necesar)
- [ ] Promo codes și discounturi
- [ ] Service fee calculation

#### **8.2. Notifications**
- [ ] Push notifications pentru clienți (order status updates)
- [ ] Push notifications pentru restaurante (new orders)
- [ ] Push notifications pentru curieri (new orders, assignments)

#### **8.3. Ratings & Reviews**
- [ ] Rating sistem pentru restaurante
- [ ] Rating sistem pentru curieri
- [ ] Review system

#### **8.4. Analytics & Reporting**
- [ ] Dashboard analytics pentru restaurante
- [ ] Dashboard analytics pentru FriendsRide admin
- [ ] Revenue reports
- [ ] Order statistics

---

### **FAZA 9: Testing & Polish** ⏱️ ~3-4 zile

#### **9.1. Integration Testing**
- [ ] Test menu sync end-to-end
- [ ] Test order creation și management
- [ ] Test courier assignment (both types)
- [ ] Test webhooks și API calls

#### **9.2. UI/UX Polish**
- [ ] Design consistency
- [ ] Animations și transitions
- [ ] Error handling și user feedback
- [ ] Loading states

#### **9.3. Performance Optimization**
- [ ] Firestore queries optimization
- [ ] Caching strategies
- [ ] Image optimization
- [ ] Network request optimization

---

## 📝 NOTIȚE TEHNICE IMPORTANTE

### **1. Comision Calculation**
```dart
double calculateCommission(double subtotal, double commissionRate) {
  // commissionRate: 0.09 - 0.14 (9% - 14%)
  return subtotal * commissionRate;
}

double calculateTotal(double subtotal, double deliveryFee, double commission) {
  return subtotal + deliveryFee + commission;
}
```

### **2. Menu Sync - Event-Based**
- Restaurant App v3 trimite webhook DOAR când se modifică meniul
- FriendsRide primește webhook și actualizează Firestore
- Nu mai e nevoie de sync periodic

### **3. Order Management - Restaurant App v3 = Source of Truth**
- Toate comenzile sunt gestionate în Restaurant App v3 (SQLite)
- FriendsRide doar creează comanda inițial și urmărește statusul
- Actualizările de status vin din Restaurant App v3

### **4. Courier Dual System**
- FriendsRide couriers: gestionați în Firestore, disponibili pentru toate restaurantele
- Restaurant couriers: gestionați în Restaurant App v3, disponibili doar pentru restaurantul respectiv
- Matching algorithm verifică ambele tipuri

### **5. Onboarding Dual**
- Manual: Admin FriendsRide adaugă restaurantul manual
- Automat: Restaurant App v3 poate trimite request de înscriere automată

---

## 🎯 TIMELINE ESTIMAT

- **Faza 1:** 2-3 zile
- **Faza 2:** 2-3 zile
- **Faza 3:** 3-4 zile
- **Faza 4:** 3-4 zile
- **Faza 5:** 5-7 zile
- **Faza 6:** 4-5 zile
- **Faza 7:** 10-12 zile (toate tipurile de integrare)
  - 7.1. Restaurant App v3: 3-4 zile
  - 7.2. API Standard: 2-3 zile
  - 7.3. Widget JavaScript: 2-3 zile
  - 7.4. Dashboard Manual: 1-2 zile
  - 7.5. POS Integration: 2-3 zile
- **Faza 8:** 4-5 zile
- **Faza 9:** 3-4 zile

**TOTAL:** ~40-50 zile (8-10 săptămâni)

---

## ✅ CHECKLIST FINAL

- [ ] Toate deciziile au fost clarificate
- [ ] Arhitectura este definită
- [ ] API endpoints sunt planificate
- [ ] Firestore structure este definită
- [ ] Fluxurile sunt documentate
- [ ] Planul de implementare este detaliat
- [ ] Timeline este realist

---

---

## 📚 DOCUMENTAȚIE INTEGRARE RESTAURANTE

### **1. Restaurant App v3 Integration**
- Documentație: `docs/integration/restaurant-app-v3.md`
- Webhook endpoints
- Pickup code system
- Order flow integration

### **2. API Standard Integration**
- Documentație: `docs/integration/api-standard.md`
- API Reference
- SDK Libraries (Node.js, Python, PHP)
- Example implementations

### **3. Widget JavaScript Integration**
- Documentație: `docs/integration/widget.md`
- Setup guide
- Configuration options
- Customization guide

### **4. Dashboard Manual Integration**
- Documentație: `docs/integration/dashboard-manual.md`
- User guide
- Menu management
- Order management

### **5. POS Integration**
- Documentație: `docs/integration/pos-integration.md`
- Supported POS systems
- Plugin templates
- Integration guides

---

**Status:** ✅ Plan Finalizat - Gata pentru Implementare (TOATE tipurile de integrare)

