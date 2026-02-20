# 🍕 ANALIZĂ DETALIATĂ: UBER EATS & BOLT FOOD - PLAN IMPLEMENTARE FRIENDSRIDE DELIVERY

**Data:** 2025-01-XX  
**Autor:** FriendsRide Development Team  
**Scop:** Analiză completă a funcționalităților de delivery și plan de implementare pentru FriendsRide

---

## 📋 CUPRINS

1. [Analiză Uber Eats](#1-analiză-uber-eats)
2. [Analiză Bolt Food](#2-analiză-bolt-food)
3. [Comparație Funcționalități](#3-comparație-funcționalități)
4. [Arhitectură Tehnică](#4-arhitectură-tehnică)
5. [Plan Implementare FriendsRide Delivery](#5-plan-implementare-friendsride-delivery)
6. [Decizie: Aplicație Separată vs Integrare](#6-decizie-aplicație-separată-vs-integrare)

---

## 1. ANALIZĂ UBER EATS

### 1.1. **ARHITECTURĂ GENERALĂ**

#### **Aplicații Separate:**
- **Uber Eats Customer App** (pentru clienți)
- **Uber Eats Driver App** (pentru curieri)
- **Uber Eats Restaurant App** (pentru restaurante - web/app)

#### **Integrare cu Uber Main App:**
- Clienții pot comanda din aplicația principală Uber
- Curierii pot accepta comenzi din aplicația principală Uber
- Separare clară între ride-sharing și delivery

### 1.2. **FLUXUL COMPLET AL COMENZII (CUSTOMER)**

#### **Faza 1: Selecție Restaurant & Produse**
1. **Căutare & Filtrare:**
   - Căutare text (nume restaurant, produs)
   - Filtrare după:
     - Tip bucătărie (italiană, chinezească, fast-food, etc.)
     - Rating (minim 4.0, 4.5, etc.)
     - Timp de livrare estimat
     - Preț (€, €€, €€€)
     - Distanță
     - Promoții active
     - Opțiuni dietetice (vegetarian, vegan, gluten-free, etc.)
   - Sortare (popularitate, rating, timp livrare, preț)

2. **Vizualizare Restaurant:**
   - **Header:**
     - Imagine restaurant
     - Nume, rating, număr recenzii
     - Timp estimat livrare (ex: "25-35 min")
     - Taxă livrare
     - Distanță
     - Program (ex: "Deschis până la 23:00")
   - **Secțiuni:**
     - Meniu organizat pe categorii (Aperitive, Feluri principale, Deserturi, Băuturi)
     - Produse populare
     - Recenzii și rating-uri
     - Informații restaurant (adresă, program, contact)

3. **Selecție Produse:**
   - **Card produs:**
     - Imagine produs
     - Nume, descriere
     - Preț
     - Opțiuni disponibile (dimensiune, topping-uri, etc.)
     - Alergeni și informații nutriționale
   - **Personalizare:**
     - Modificări (fără ceapă, extra sos, etc.)
     - Note speciale pentru restaurant
     - Cantitate

4. **Coș de Cumpărături:**
   - Listă produse selectate
     - Editare/ștergere produse
     - Modificare cantități
   - Subtotal produse
   - Taxă livrare
   - Taxă serviciu (10% din valoare, max 3€)
   - Discount-uri/promoții aplicate
   - **Total final**
   - Minimum order (ex: "Minimum 15€")

#### **Faza 2: Checkout & Plată**

1. **Adresă Livrare:**
   - Adresă curentă (GPS)
   - Adrese salvate (acasă, serviciu, etc.)
   - Adresă nouă (introducere manuală sau hartă)
   - Instrucțiuni speciale (ex: "Etaj 3, Ap. 12, Sonerie: Gheorghe")

2. **Metodă Plată:**
   - Carduri salvate
   - Cash (dacă disponibil)
   - PayPal, Apple Pay, Google Pay
   - Vouchers/promo codes
   - Uber Cash (portofel)

3. **Confirmare Comandă:**
   - Rezumat comandă
   - Estimare timp livrare
   - Taxe și total
   - Confirmare finală

#### **Faza 3: Tracking Live**

1. **Stări Comandă:**
   - **"Restaurantul pregătește comanda"** (preparing)
     - Timer countdown
     - Estimare: "Gata în ~15 min"
   - **"Curierul a preluat comanda"** (picked up)
     - Nume curier
     - Rating curier
     - Vehicul (bicicletă, scooter, mașină)
     - Tracking live pe hartă
     - ETA actualizat în timp real
   - **"Curierul este în drum"** (on the way)
     - Tracking live continuu
     - ETA actualizat
     - Notificări: "Curierul este la 2 min"
   - **"Comanda a ajuns"** (delivered)
     - Confirmare livrare
     - Opțiune rating

2. **Funcționalități Tracking:**
   - Hartă live cu locația curierului
   - Linie de rută estimată
   - ETA actualizat automat
   - Notificări push pentru fiecare schimbare de stare
   - Chat cu curier (opțional)
   - Apelare curier (opțional)

#### **Faza 4: După Livrare**

1. **Rating & Feedback:**
   - Rating restaurant (1-5 stele)
   - Rating curier (1-5 stele)
   - Comentarii opționale
   - Reclamă problemă (dacă e cazul)

2. **Istoric Comenzi:**
   - Listă comenzi anterioare
   - Re-comandă rapidă
   - Facturi/chitanțe

### 1.3. **FLUXUL COMPLET AL COMENZII (COURIER/DRIVER)**

#### **Faza 1: Activare & Disponibilitate**

1. **Login & Verificare:**
   - Autentificare
   - Verificare documente (permis, asigurare, etc.)
   - Verificare vehicul (dacă aplicabil)

2. **Setare Disponibilitate:**
   - Toggle "Go Online" / "Go Offline"
   - Selectare zonă de lucru (dacă aplicabil)
   - Selectare tip vehicul (bicicletă, scooter, mașină)

#### **Faza 2: Primire & Acceptare Comenzi**

1. **Notificare Comandă Nouă:**
   - Pop-up cu detalii comandă:
     - Restaurant (nume, adresă, distanță)
     - Destinație (adresă, distanță)
     - Valoare comandă
     - Estimare câștig
     - Timp estimat total
     - Rută pe hartă (preview)
   - Timer acceptare (15-30 secunde)
   - Opțiuni: "Accept" / "Decline"

2. **Batch Offers (Uber Eats Pro):**
   - Multiple comenzi simultan
   - Preview rute combinate
   - Câștig total estimat
   - Acceptare/refuz pentru toate

#### **Faza 3: Preluare Comandă**

1. **Navigare către Restaurant:**
   - Hartă cu rută
   - Navigație turn-by-turn
   - ETA către restaurant
   - Notificare: "Aproape de restaurant"

2. **La Restaurant:**
   - Buton "Arrived at Restaurant"
   - Așteptare pregătire comandă
   - Buton "Order Ready" (când restaurantul confirmă)
   - Scanare cod QR (dacă aplicabil)
   - Verificare comandă (produse, adresă)
   - Buton "Start Delivery"

#### **Faza 4: Livrare**

1. **Navigare către Destinație:**
   - Hartă cu rută
   - Navigație turn-by-turn
   - ETA către destinație
   - Tracking live pentru client

2. **La Destinație:**
   - Buton "Arrived at Destination"
   - Contact client (apel, SMS, chat)
   - Instrucțiuni speciale (ex: "Etaj 3, Ap. 12")
   - Buton "Delivered" (după predare)
   - Confirmare client (semnătură sau cod)

3. **După Livrare:**
   - Rating client (opțional)
   - Câștig înregistrat
   - Disponibil pentru următoarea comandă

#### **Faza 5: Dashboard & Analytics**

1. **Earnings Dashboard:**
   - Câștiguri zilnice/săptămânale/lunare
   - Număr comenzi
   - Medie pe comandă
   - Tips primite
   - Bonus-uri (surge, quests, etc.)

2. **Statistics:**
   - Acceptance rate
   - Completion rate
   - Average delivery time
   - Rating mediu
   - Top zones

### 1.4. **FLUXUL COMPLET AL COMENZII (RESTAURANT)**

#### **Faza 1: Onboarding**

1. **Înregistrare:**
   - Informații restaurant (nume, adresă, program)
   - Meniu (upload sau integrare POS)
   - Imagini produse
   - Informații legale (CUI, etc.)

2. **Configurare:**
   - Setare disponibilitate (program, zile)
   - Setare timp pregătire (per categorie/produs)
   - Setare minimum order
   - Setare taxe livrare
   - Setare zone livrare

#### **Faza 2: Gestionare Comenzi**

1. **Primire Comandă:**
   - Notificare (app/web/sound)
   - Detalii comandă:
     - Număr comandă
     - Client (nume, adresă, telefon)
     - Produse (cantități, modificări, note)
     - Timp estimat livrare
     - Metodă plată
   - Opțiuni: "Accept" / "Reject" / "Modify"

2. **Pregătire Comandă:**
   - Timer countdown
   - Status: "Preparing" → "Ready"
   - Notificare curier când e gata
   - Scanare cod QR (dacă aplicabil)

3. **Istoric Comenzi:**
   - Listă comenzi (zi/lună)
   - Filtrare (status, dată)
   - Export rapoarte

#### **Faza 3: Analytics & Management**

1. **Dashboard:**
   - Vânzări (zi/lună)
   - Comenzi (număr, valoare medie)
   - Produse populare
   - Rating-uri
   - Timp mediu pregătire

2. **Management Meniu:**
   - Adăugare/ștergere produse
   - Modificare prețuri
   - Setare disponibilitate (out of stock)
   - Promoții

### 1.5. **FUNCȚIONALITĂȚI AVANSATE**

#### **1.5.1. Pricing & Fees**
- **Taxă livrare:** Variabilă (1.99€ - 5.99€) în funcție de:
  - Distanță
  - Cerere (surge pricing)
  - Tip vehicul curier
- **Taxă serviciu:** 10% din valoare, max 3€
- **Suprataxă:** Pentru comenzi sub 15€ (+1.50€)
- **Surge pricing:** +20% - +50% în perioade aglomerate
- **Uber One:** Abonament 4.99€/lună → livrări gratuite + reduceri

#### **1.5.2. Matching & Assignment**
- **Algoritm matching:**
  - Proximitate curier-restaurant
  - Proximitate curier-destinație
  - Disponibilitate curier
  - Rating curier
  - Acceptance rate
  - Tip vehicul
- **Batch matching:** Multiple comenzi pentru același curier
- **Auto-reassignment:** Dacă curierul nu acceptă în 30 sec

#### **1.5.3. Real-time Tracking**
- **GPS tracking:** Actualizare la fiecare 5-10 secunde
- **ETA calculation:** Bazat pe:
  - Distanță
  - Trafic real-time
  - Viteză medie curier
  - Istoric livrări
- **Route optimization:** Cel mai scurt traseu

#### **1.5.4. Payment Integration**
- **Metode plată:**
  - Carduri (Visa, Mastercard, Amex)
  - Cash (dacă disponibil)
  - PayPal, Apple Pay, Google Pay
  - Uber Cash
- **Split payment:** Împărțire costuri între utilizatori
- **Tips:** Opțional, la finalizare

#### **1.5.5. Notifications System**
- **Push notifications:**
  - Comandă confirmată
  - Restaurant a început pregătirea
  - Curier a preluat comanda
  - Curier este în drum
  - Curier este aproape (2 min)
  - Comandă livrată
- **SMS notifications:** (opțional)
- **Email confirmations:** Factură/chitanță

#### **1.5.6. Rating & Reviews**
- **Rating restaurant:** 1-5 stele + comentarii
- **Rating curier:** 1-5 stele + comentarii
- **Rating client:** (pentru curier)
- **Moderare:** Verificare comentarii ofensatoare

#### **1.5.7. Promotions & Loyalty**
- **Promo codes:** Coduri promoționale
- **First order discount:** Reducere prima comandă
- **Referral program:** Bonus pentru invitați
- **Uber One:** Abonament cu beneficii
- **Restaurant promotions:** Oferte speciale

#### **1.5.8. Safety & Support**
- **Emergency button:** Buton de urgență
- **Live support:** Chat în aplicație
- **Dispute resolution:** Rezolvare probleme
- **Refund system:** Rambursări pentru probleme

---

## 2. ANALIZĂ BOLT FOOD

### 2.1. **ARHITECTURĂ GENERALĂ**

#### **Integrare cu Bolt Main App:**
- **Bolt Food** este integrat în aplicația principală Bolt
- Clienții pot comanda din aplicația Bolt
- Curierii pot accepta comenzi din aplicația Bolt
- Separare clară între ride-sharing și delivery în UI

### 2.2. **FLUXUL COMPLET AL COMENZII (CUSTOMER)**

#### **Faza 1: Selecție Restaurant & Produse**
1. **Căutare & Filtrare:**
   - Căutare text
   - Filtrare după:
     - Tip bucătărie
     - Rating
     - Timp livrare
     - Preț
     - Distanță
     - Promoții
   - Sortare

2. **Vizualizare Restaurant:**
   - Similar cu Uber Eats
   - Header cu imagine, rating, timp livrare
   - Meniu organizat pe categorii
   - Produse populare

3. **Selecție Produse:**
   - Card produs cu imagine, nume, preț
   - Personalizare (modificări, note)
   - Cantitate

4. **Coș de Cumpărături:**
   - Listă produse
   - Subtotal, taxe, total
   - Minimum order

#### **Faza 2: Checkout & Plată**
- Similar cu Uber Eats
- Adresă livrare
- Metodă plată
- Confirmare

#### **Faza 3: Tracking Live**
- Similar cu Uber Eats
- Stări: Preparing → Picked up → On the way → Delivered
- Tracking live pe hartă
- ETA actualizat

#### **Faza 4: După Livrare**
- Rating restaurant și curier
- Istoric comenzi

### 2.3. **FLUXUL COMPLET AL COMENZII (COURIER)**

#### **Similar cu Uber Eats:**
- Activare disponibilitate
- Primire & acceptare comenzi
- Preluare de la restaurant
- Livrare către client
- Dashboard & analytics

### 2.4. **DIFERENȚE FAȚĂ DE UBER EATS**

#### **2.4.1. Integrare în App Principală**
- Bolt Food este integrat în aplicația Bolt
- Nu necesită aplicație separată
- Switching între ride-sharing și delivery în același app

#### **2.4.2. Pricing**
- **Taxă livrare:** Variabilă (2.50€ - 4.50€)
- **Taxă serviciu:** 7% - 12% din valoare
- **Suprataxă:** Până la 3€ în ore aglomerate
- **Bolt Pass:** Abonament cu livrări gratuite

#### **2.4.3. Acoperire Geografică**
- Bolt Food este disponibil în mai multe țări din Europa
- În România: București, Cluj, Timișoara, Iași, etc.

---

## 3. COMPARAȚIE FUNCȚIONALITĂȚI

### 3.1. **TABEL COMPARATIV**

| Funcționalitate | Uber Eats | Bolt Food | Prioritate |
|----------------|-----------|-----------|------------|
| **Customer App** |
| Căutare & filtrare restaurante | ✅ | ✅ | 🔴 CRITIC |
| Vizualizare meniu | ✅ | ✅ | 🔴 CRITIC |
| Personalizare produse | ✅ | ✅ | 🔴 CRITIC |
| Coș de cumpărături | ✅ | ✅ | 🔴 CRITIC |
| Checkout & plată | ✅ | ✅ | 🔴 CRITIC |
| Tracking live | ✅ | ✅ | 🔴 CRITIC |
| Rating & feedback | ✅ | ✅ | 🟡 IMPORTANT |
| Istoric comenzi | ✅ | ✅ | 🟡 IMPORTANT |
| Re-comandă rapidă | ✅ | ✅ | 🟢 NICE TO HAVE |
| **Courier App** |
| Activare disponibilitate | ✅ | ✅ | 🔴 CRITIC |
| Primire & acceptare comenzi | ✅ | ✅ | 🔴 CRITIC |
| Navigație către restaurant | ✅ | ✅ | 🔴 CRITIC |
| Confirmare preluare | ✅ | ✅ | 🔴 CRITIC |
| Navigație către client | ✅ | ✅ | 🔴 CRITIC |
| Confirmare livrare | ✅ | ✅ | 🔴 CRITIC |
| Dashboard câștiguri | ✅ | ✅ | 🟡 IMPORTANT |
| Batch offers | ✅ | ⚠️ | 🟡 IMPORTANT |
| **Restaurant App** |
| Gestionare comenzi | ✅ | ✅ | 🔴 CRITIC |
| Management meniu | ✅ | ✅ | 🔴 CRITIC |
| Dashboard analytics | ✅ | ✅ | 🟡 IMPORTANT |
| **Features Avansate** |
| Surge pricing | ✅ | ✅ | 🟡 IMPORTANT |
| Promo codes | ✅ | ✅ | 🟡 IMPORTANT |
| Split payment | ✅ | ⚠️ | 🟢 NICE TO HAVE |
| Abonamente | ✅ | ✅ | 🟡 IMPORTANT |
| Chat cu curier | ✅ | ✅ | 🟢 NICE TO HAVE |
| Emergency button | ✅ | ✅ | 🟡 IMPORTANT |

### 3.2. **FUNCȚIONALITĂȚI UNICE UBER EATS**
- Batch offers pentru curieri (multiple comenzi simultan)
- Uber One (abonament premium)
- Integrare cu Uber main app (dar aplicații separate)

### 3.3. **FUNCȚIONALITĂȚI UNICE BOLT FOOD**
- Integrare completă în aplicația Bolt principală
- Switching seamless între ride-sharing și delivery

---

## 4. ARHITECTURĂ TEHNICĂ

### 4.1. **STACK TEHNOLOGIC (Uber Eats & Bolt Food)**

#### **Frontend:**
- **Mobile Apps:**
  - React Native (Uber Eats)
  - Flutter (Bolt Food - probabil)
  - Native iOS/Android (componente critice)

#### **Backend:**
- **Microservices Architecture:**
  - Order Service (gestionare comenzi)
  - Restaurant Service (gestionare restaurante)
  - Courier Service (gestionare curieri)
  - Payment Service (procesare plăți)
  - Notification Service (notificări push/SMS)
  - Tracking Service (GPS tracking)
  - Matching Service (algoritm matching)

#### **Database:**
- **Primary:** PostgreSQL/MySQL (date structurate)
- **Real-time:** Firebase Realtime Database / Firestore
- **Cache:** Redis (pentru performanță)
- **Search:** Elasticsearch (căutare restaurante/produse)

#### **Infrastructure:**
- **Cloud:** AWS / Google Cloud / Azure
- **CDN:** CloudFlare / AWS CloudFront
- **Push Notifications:** FCM (Firebase Cloud Messaging)
- **Maps & Navigation:** Google Maps / Mapbox
- **Payment Processing:** Stripe / PayPal / Adyen

### 4.2. **ARHITECTURĂ FRIENDSRIDE ACTUALĂ**

#### **Frontend:**
- **Flutter** (aplicație mobilă)
- **State Management:** Provider
- **Navigation:** Flutter Navigator

#### **Backend:**
- **Firebase Services:**
  - Firestore (database)
  - Firebase Auth (autentificare)
  - Firebase Storage (imagini/fișiere)
  - Firebase Cloud Messaging (notificări)
  - Firebase Functions (serverless functions)

#### **Services Existente:**
- `FirestoreService` (gestionare date)
- `RoutingService` (rute și navigație)
- `PricingService` (calcul prețuri)
- `PushNotificationService` (notificări)
- `RealTimeTrackingService` (tracking live)
- `RideSharingService` (ride sharing)
- `SplitPaymentService` (split payment)

#### **Models Existente:**
- `Ride` / `RideRequest` (pentru curse)
- `User` (utilizatori)
- `ChatMessage` (mesaje)
- `PaymentMethod` (metode plată)

---

## 5. PLAN IMPLEMENTARE FRIENDSRIDE DELIVERY

### 5.1. **DECIZIE ARHITECTURALĂ**

#### **Opțiunea 1: Integrare în Aplicația Existente (Recomandat)**
**Avantaje:**
- ✅ Reutilizare cod existent (FirestoreService, RoutingService, etc.)
- ✅ Un singur app pentru utilizatori
- ✅ Shared infrastructure (Firebase, Mapbox, etc.)
- ✅ Shared authentication
- ✅ Switching între ride-sharing și delivery în același app
- ✅ Costuri mai mici (un singur app de menținut)

**Dezavantaje:**
- ⚠️ App mai complex (mai multe funcționalități)
- ⚠️ Posibil app mai mare (dimensiune download)

**Recomandare:** ✅ **INTEGRARE ÎN APLICAȚIA EXISTENTĂ**

#### **Opțiunea 2: Aplicație Separată**
**Avantaje:**
- ✅ App mai simplu (doar delivery)
- ✅ Separare clară între ride-sharing și delivery
- ✅ Posibil branding diferit

**Dezavantaje:**
- ❌ Duplicare cod (servicii, models, etc.)
- ❌ Două app-uri de menținut
- ❌ Costuri mai mari (infrastructure, development)
- ❌ Utilizatorii trebuie să instaleze două app-uri

**Recomandare:** ❌ **NU RECOMANDAT**

### 5.2. **FAZE DE IMPLEMENTARE**

#### **FAZA 1: FUNDAȚIE (2-3 săptămâni)**

##### **1.1. Models & Data Structure**
- [ ] **`DeliveryOrder` Model:**
  ```dart
  class DeliveryOrder {
    String id;
    String customerId;
    String restaurantId;
    String? courierId;
    DeliveryOrderStatus status;
    List<OrderItem> items;
    double subtotal;
    double deliveryFee;
    double serviceFee;
    double total;
    Address deliveryAddress;
    Address restaurantAddress;
    DateTime createdAt;
    DateTime? estimatedDeliveryTime;
    PaymentMethod paymentMethod;
    String? promoCode;
    double? discount;
    Map<String, dynamic>? metadata;
  }
  ```

- [ ] **`OrderItem` Model:**
  ```dart
  class OrderItem {
    String id;
    String productId;
    String productName;
    int quantity;
    double unitPrice;
    double totalPrice;
    List<String> modifications; // ["fără ceapă", "extra sos"]
    String? specialNotes;
  }
  ```

- [ ] **`Restaurant` Model:**
  ```dart
  class Restaurant {
    String id;
    String name;
    String description;
    Address address;
    String? imageUrl;
    double rating;
    int reviewCount;
    int estimatedDeliveryTime; // minutes
    double deliveryFee;
    double minimumOrder;
    List<String> cuisineTypes;
    RestaurantStatus status; // open, closed, busy
    Map<String, WorkingHours> workingHours;
    List<String> deliveryZones;
  }
  ```

- [ ] **`Product` Model:**
  ```dart
  class Product {
    String id;
    String restaurantId;
    String name;
    String description;
    double price;
    String? imageUrl;
    String category; // "Aperitive", "Feluri principale", etc.
    bool isAvailable;
    List<String> allergens;
    Map<String, dynamic>? nutritionalInfo;
    List<ProductModification>? availableModifications;
  }
  ```

- [ ] **`Courier` Model:**
  ```dart
  class Courier {
    String id;
    String userId;
    CourierStatus status; // offline, online, delivering
    String? currentOrderId;
    VehicleType vehicleType; // bike, scooter, car
    double rating;
    int completedDeliveries;
    Location? currentLocation;
  }
  ```

##### **1.2. Firestore Collections Structure**
```
delivery_orders/
  {orderId}/
    - customerId
    - restaurantId
    - courierId
    - status
    - items: []
    - total
    - createdAt
    - ...

restaurants/
  {restaurantId}/
    - name
    - address
    - menu: []
    - status
    - ...

products/
  {productId}/
    - restaurantId
    - name
    - price
    - category
    - ...

couriers/
  {courierId}/
    - userId
    - status
    - vehicleType
    - rating
    - ...
```

##### **1.3. Services Foundation**
- [ ] **`DeliveryService`** (similar cu `FirestoreService`):
  - `createOrder()`
  - `getOrder()`
  - `updateOrderStatus()`
  - `assignCourier()`
  - `getOrderStream()`

- [ ] **`RestaurantService`**:
  - `getRestaurants()`
  - `getRestaurant()`
  - `getMenu()`
  - `searchRestaurants()`

- [ ] **`CourierService`**:
  - `goOnline()`
  - `goOffline()`
  - `acceptOrder()`
  - `rejectOrder()`
  - `updateLocation()`
  - `completeDelivery()`

- [ ] **`DeliveryMatchingService`**:
  - `findAvailableCouriers()`
  - `matchCourierToOrder()`
  - `calculateETA()`

#### **FAZA 2: CUSTOMER APP - CORE FEATURES (3-4 săptămâni)**

##### **2.1. Restaurant Discovery**
- [ ] **`RestaurantListScreen`:**
  - Listă restaurante cu filtre
  - Căutare text
  - Filtrare (tip bucătărie, rating, timp, preț)
  - Sortare
  - Map view (opțional)

- [ ] **`RestaurantDetailScreen`:**
  - Header cu imagine, rating, info
  - Meniu organizat pe categorii
  - Produse populare
  - Recenzii

##### **2.2. Product Selection**
- [ ] **`ProductDetailScreen`:**
  - Imagine produs
  - Nume, descriere, preț
  - Opțiuni personalizare
  - Note speciale
  - Adăugare în coș

- [ ] **`CartScreen`:**
  - Listă produse
  - Editare/ștergere
  - Calcul subtotal, taxe, total
  - Minimum order check

##### **2.3. Checkout**
- [ ] **`CheckoutScreen`:**
  - Adresă livrare (reutilizare `AddressInputView`)
  - Metodă plată (reutilizare `PaymentMethodSelection`)
  - Promo code input
  - Rezumat comandă
  - Confirmare

##### **2.4. Order Tracking**
- [ ] **`DeliveryTrackingScreen`:**
  - Stări comandă (preparing, picked up, on the way, delivered)
  - Tracking live pe hartă (reutilizare `MapScreen`)
  - ETA actualizat
  - Chat cu curier (opțional)
  - Apelare curier (opțional)

#### **FAZA 3: COURIER APP - CORE FEATURES (3-4 săptămâni)**

##### **3.1. Courier Dashboard**
- [ ] **`CourierDashboardScreen`:**
  - Toggle online/offline
  - Earnings summary
  - Statistics
  - Settings

##### **3.2. Order Management**
- [ ] **`CourierOrderScreen`:**
  - Notificare comandă nouă
  - Accept/Reject
  - Navigație către restaurant
  - Confirmare preluare
  - Navigație către client
  - Confirmare livrare

##### **3.3. Navigation**
- [ ] Integrare navigație (reutilizare `TurnByTurnNavigationWidget`)
- [ ] Tracking live pentru client

#### **FAZA 4: RESTAURANT APP/WEB (2-3 săptămâni)**

##### **4.1. Order Management**
- [ ] **Web Dashboard sau App:**
  - Listă comenzi noi
  - Accept/Reject/Modify
  - Timer pregătire
  - Mark as ready
  - Istoric comenzi

##### **4.2. Menu Management**
- [ ] Adăugare/ștergere produse
- [ ] Modificare prețuri
- [ ] Setare disponibilitate
- [ ] Categorii

#### **FAZA 5: MATCHING & OPTIMIZATION (2 săptămâni)**

##### **5.1. Courier Matching Algorithm**
- [ ] Algoritm matching bazat pe:
  - Proximitate restaurant
  - Proximitate destinație
  - Disponibilitate
  - Rating
  - Acceptance rate
  - Tip vehicul

##### **5.2. Route Optimization**
- [ ] Calcul rute optimale
- [ ] Batch matching (multiple comenzi)
- [ ] ETA calculation precis

#### **FAZA 6: ADVANCED FEATURES (2-3 săptămâni)**

##### **6.1. Pricing**
- [ ] Surge pricing
- [ ] Dynamic delivery fees
- [ ] Service fees calculation

##### **6.2. Promotions**
- [ ] Promo codes
- [ ] First order discount
- [ ] Restaurant promotions

##### **6.3. Notifications**
- [ ] Push notifications pentru toate stările
- [ ] SMS notifications (opțional)
- [ ] Email confirmations

##### **6.4. Rating & Reviews**
- [ ] Rating restaurant
- [ ] Rating courier
- [ ] Comentarii

#### **FAZA 7: TESTING & POLISH (2 săptămâni)**

##### **7.1. Testing**
- [ ] Unit tests
- [ ] Integration tests
- [ ] End-to-end tests
- [ ] Performance testing

##### **7.2. UI/UX Polish**
- [ ] Animations
- [ ] Loading states
- [ ] Error handling
- [ ] Accessibility

---

## 6. DECIZIE: APLICAȚIE SEPARATĂ VS INTEGRARE

### 6.1. **RECOMANDARE FINALĂ: INTEGRARE ÎN APLICAȚIA EXISTENTĂ**

#### **Motivații:**
1. **Reutilizare Cod:**
   - `FirestoreService` poate fi extins pentru delivery
   - `RoutingService` poate fi folosit pentru navigație
   - `PricingService` poate fi extins pentru calcul taxe delivery
   - `PushNotificationService` poate fi folosit pentru notificări
   - `RealTimeTrackingService` poate fi folosit pentru tracking
   - Models existente (`Address`, `PaymentMethod`, etc.)

2. **Infrastructure Shared:**
   - Firebase (Firestore, Auth, Storage, FCM)
   - Mapbox (hărți și navigație)
   - Shared authentication

3. **User Experience:**
   - Un singur app pentru toate serviciile
   - Switching seamless între ride-sharing și delivery
   - Shared payment methods, addresses, etc.

4. **Cost Efficiency:**
   - Un singur app de menținut
   - Shared infrastructure costs
   - Faster development (reutilizare cod)

#### **Structură Propusă în App:**
```
FriendsRide App
├── Ride Sharing (existent)
│   ├── Request Ride
│   ├── Active Ride
│   └── Ride History
│
└── Delivery (nou)
    ├── Browse Restaurants
    ├── My Orders
    ├── Active Delivery
    └── Delivery History
```

#### **Navigation Structure:**
- **Bottom Navigation Bar:**
  - Home (Ride Sharing)
  - Delivery (nou)
  - History (combinat: Rides + Deliveries)
  - Profile

- **Hamburger Menu:**
  - Switch between Passenger/Driver/Courier mode
  - Settings
  - Help
  - etc.

### 6.2. **IMPLEMENTARE MODULARĂ**

#### **Separare Cod:**
- **`lib/delivery/`** - Toate funcționalitățile delivery
  - `models/` - Delivery models
  - `screens/` - Delivery screens
  - `services/` - Delivery services
  - `widgets/` - Delivery widgets

- **`lib/ride/`** - Funcționalitățile ride-sharing (existente)
- **`lib/shared/`** - Cod partajat (services, models, widgets)

#### **Benefits:**
- ✅ Cod organizat și modular
- ✅ Ușor de menținut
- ✅ Posibilitate de a dezactiva delivery dacă e nevoie
- ✅ Testing mai ușor

---

## 7. ESTIMĂRI TIMP & RESURSE

### 7.1. **TIMELINE ESTIMAT**

| Fază | Durată | Resurse |
|------|--------|---------|
| Faza 1: Fundație | 2-3 săptămâni | 1-2 developeri |
| Faza 2: Customer App | 3-4 săptămâni | 1-2 developeri |
| Faza 3: Courier App | 3-4 săptămâni | 1-2 developeri |
| Faza 4: Restaurant App | 2-3 săptămâni | 1 developer |
| Faza 5: Matching | 2 săptămâni | 1 developer |
| Faza 6: Advanced Features | 2-3 săptămâni | 1-2 developeri |
| Faza 7: Testing & Polish | 2 săptămâni | 1-2 developeri |
| **TOTAL** | **16-21 săptămâni** | **1-2 developeri** |

### 7.2. **RESURSE NECESARE**

#### **Development:**
- 1-2 Flutter developers (full-time)
- 1 Backend developer (part-time, pentru Firebase Functions)
- 1 UI/UX designer (part-time)

#### **Infrastructure:**
- Firebase (Firestore, Auth, Storage, FCM) - existent
- Mapbox - existent
- Payment processing (Stripe/PayPal) - de adăugat

#### **Testing:**
- Test devices (iOS, Android)
- Beta testers (restaurante, curieri, clienți)

---

## 8. RISCURI & MITIGARE

### 8.1. **RISCURI IDENTIFICATE**

#### **Risc 1: Complexitate App**
- **Mitigare:** Cod modular, separare clară între ride-sharing și delivery

#### **Risc 2: Performance**
- **Mitigare:** Lazy loading, caching, optimization

#### **Risc 3: Onboarding Restaurante**
- **Mitigare:** Proces simplu de onboarding, suport dedicat

#### **Risc 4: Competition**
- **Mitigare:** Features unice, prețuri competitive, UX superior

### 8.2. **SUCCES METRICS**

- Număr restaurante partenere (target: 50+ în primul an)
- Număr comenzi (target: 1000+ pe lună în primul an)
- Număr curieri activi (target: 20+ în primul an)
- Customer satisfaction (target: 4.5+ rating)
- Courier satisfaction (target: 4.0+ rating)

---

## 9. CONCLUZII & NEXT STEPS

### 9.1. **CONCLUZII**

1. **Uber Eats și Bolt Food** oferă funcționalități similare, cu diferențe minore
2. **Integrarea în aplicația existentă** este recomandată pentru:
   - Reutilizare cod
   - Cost efficiency
   - User experience superior
3. **Implementare modulară** va permite menținere ușoară și testing

### 9.2. **NEXT STEPS**

1. **Review acest document** cu echipa
2. **Decizie finală** privind arhitectura (integrare vs separare)
3. **Prioritizare features** (MVP vs full feature set)
4. **Kickoff meeting** pentru Faza 1
5. **Setup development environment** pentru delivery features

---

**Document creat:** 2025-01-XX  
**Ultima actualizare:** 2025-01-XX  
**Versiune:** 1.0

