# 🚗 FLUXUL APLICAȚIEI FRIENDSRIDE - END TO END

## 📋 SUMAR EXECUTIV

Aplicația FriendsRide oferă două modalități de rezervare a unei curse:
1. **Fluxul UI (Manual)** - Interacțiune tradițională prin interfață grafică
2. **Fluxul AI (Vocal)** - Interacțiune prin butonul AI și comandă vocală

Ambele fluxuri converg către același rezultat: crearea unei solicitări de cursă în Firebase și căutarea unui șofer disponibil.

---

## 🖥️ FLUXUL UI (MANUAL) - END TO END

### **Pasul 1: Pornirea Aplicației**

```
SplashScreen → AuthWrapper → MapScreen
```

1. **SplashScreen** (`lib/screens/splash_screen.dart`)
   - Animație de pornire
   - Inițializare servicii în fundal
   - Navigare către autentificare sau MapScreen

2. **AuthWrapper** (`lib/main.dart`)
   - Verifică starea autentificării Firebase
   - Dacă utilizatorul nu este autentificat → **AuthScreen**
   - Dacă utilizatorul este autentificat → **MapScreen**

3. **MapScreen** (`lib/screens/map_screen.dart`)
   - Ecranul principal cu hartă Mapbox
   - Afișează locația curentă a utilizatorului
   - Afișează șoferi disponibili în apropiere (dacă e în modul pasager)
   - Butonul AI este vizibil doar pentru pasageri sau șoferi indisponibili

---

### **Pasul 2: Selectarea Adreselor (UI)**

**Utilizatorul introduce adresele manual:**

1. **Pickup (Punct de plecare)**
   - Utilizatorul apasă pe câmpul "De la" sau pe hartă
   - Se deschide căutarea de adrese
   - Utilizatorul selectează sau introduce adresa
   - Sistemul face geocoding → convertește adresa în coordonate GPS
   - Se afișează marker pe hartă

2. **Destinație**
   - Utilizatorul apasă pe câmpul "La" sau pe hartă
   - Se deschide căutarea de adrese
   - Utilizatorul selectează sau introduce destinația
   - Sistemul face geocoding → convertește adresa în coordonate GPS
   - Se afișează marker pe hartă

3. **Calcularea Rutei**
   - După ce ambele adrese sunt setate, sistemul:
     - Calculează ruta folosind **RoutingService**
     - Afișează polilinia pe hartă
     - Calculează distanța (km) și durata (minute)
     - Calculează prețul folosind **PricingService**

---

### **Pasul 3: Panoul de Rezervare (RideRequestPanel)**

**Când ambele adrese sunt setate, apare panoul de rezervare:**

1. **Afișare Informații**
   - Distanța calculată
   - Durata estimată
   - Prețul calculat pentru fiecare categorie (Standard, Premium, etc.)
   - Opțiuni de categorie de cursă

2. **Selecție Categorie**
   - Utilizatorul selectează categoria (Standard, Premium, etc.)
   - Prețul se actualizează automat

3. **Opriri Intermediare (Opțional)**
   - Utilizatorul poate adăuga opriri intermediare
   - Fiecare oprire este adăugată la ruta calculată

4. **Rezervare Programată (Opțional)**
   - Utilizatorul poate programa cursă pentru mai târziu
   - Selectează data și ora

---

### **Pasul 4: Confirmarea și Trimiterea Solicitării**

**Când utilizatorul apasă "Confirmă":**

```dart
// lib/widgets/ride_request_panel.dart - _confirmAndRequestRide()
```

1. **Validare**
   - Verifică că ambele adrese sunt setate
   - Verifică că categoria este selectată
   - Verifică că prețul este calculat

2. **Crearea Obiectului Ride**
   ```dart
   final ride = Ride(
     id: '', // Va fi generat de Firestore
     passengerId: userId,
     startAddress: _startAddress,
     destinationAddress: _destinationAddress,
     distance: _distanceInKm,
     startLatitude: _startPoint!.coordinates.lat.toDouble(),
     startLongitude: _startPoint!.coordinates.lng.toDouble(),
     destinationLatitude: _endPoint!.coordinates.lat.toDouble(),
     destinationLongitude: _endPoint!.coordinates.lng.toDouble(),
     durationInMinutes: _estimatedDurationInMinutes,
     baseFare: fareDetails['baseFare']!,
     perKmRate: fareDetails['perKmRate']!,
     perMinRate: fareDetails['perMinRate']!,
     totalCost: fareDetails['totalCost']!,
     appCommission: fareDetails['appCommission']!,
     driverEarnings: fareDetails['driverEarnings']!,
     timestamp: DateTime.now(),
     status: 'pending',
     category: _selectedCategory,
     stops: _stops.map((stop) => stop.toMap()).toList(),
   );
   ```

3. **Trimitere la Firebase**
   ```dart
   final rideId = await _firestoreService.requestRide(ride);
   ```
   - Se creează documentul în Firestore
   - Se returnează ID-ul cursei

4. **Navigare la SearchingForDriverScreen**
   ```dart
   Navigator.of(context).pushReplacement(
     MaterialPageRoute(
       builder: (context) => SearchingForDriverScreen(rideId: rideId)
     ),
   );
   ```

---

### **Pasul 5: Căutarea Șoferului (SearchingForDriverScreen)**

**Ecranul de căutare șofer:**

1. **Inițializare**
   - Se abonează la stream-ul cursei din Firestore
   - Afișează animație de căutare
   - Mesaj: "Se caută șoferi în apropiere..."

2. **Monitorizare Status Cursă**
   - Ascultă schimbările în Firestore pentru cursa cu ID-ul primit
   - Când un șofer acceptă cursa:
     - Status-ul cursei se schimbă din `pending` → `accepted`
     - Se actualizează UI-ul cu informații despre șofer
     - Se navighează la **ActiveRideScreen**

3. **Timeout**
   - Dacă nu se găsește șofer în 60 de secunde, se afișează mesaj de eroare
   - Utilizatorul poate încerca din nou

---

### **Pasul 6: Cursa Activă (ActiveRideScreen)**

**După ce șoferul acceptă:**

1. **Tracking în Timp Real**
   - Se afișează locația șoferului în timp real
   - Se afișează ruta către pasager
   - Se afișează ETA (Estimated Time of Arrival)

2. **Stări ale Cursăi**
   - `accepted` → Șoferul a acceptat
   - `driver_en_route` → Șoferul este în drum către pasager
   - `driver_arrived` → Șoferul a ajuns la pasager
   - `in_progress` → Cursa este în desfășurare
   - `completed` → Cursa s-a finalizat

3. **Finalizare**
   - După finalizare, utilizatorul poate evalua șoferul
   - Se revine la MapScreen

---

## 🎤 FLUXUL AI (VOCAL) - END TO END

### **Pasul 1: Inițierea Interacțiunii Vocale**

**Utilizatorul apasă butonul AI:**

```dart
// lib/screens/map_screen.dart - DraggableAIButton
onTap: () async {
  await voiceIntegration.startVoiceInteraction();
}
```

1. **Verificare Vizibilitate Buton**
   - Butonul AI este vizibil doar pentru:
     - **Pasageri** (întotdeauna)
     - **Șoferi indisponibili** (nu sunt disponibili pentru curse)
   - Butonul este ascuns pentru șoferi disponibili

2. **Pornirea Sistemului Vocal**
   ```dart
   // lib/voice/integration/friendsride_voice_integration.dart
   await startVoiceInteraction()
   ```
   - Se inițializează **VoiceOrchestrator** (STT - Speech-to-Text)
   - Se inițializează **NaturalVoiceSynthesizer** (TTS - Text-to-Speech)
   - Se inițializează **GeminiVoiceEngine** (AI conversational)

3. **Salutul Inițial**
   - AI-ul rostește: "Salut, unde doriți să mergeți?"
   - Se activează ascultarea continuă (continuous listening)

---

### **Pasul 2: Procesarea Comenzii Vocale**

**Utilizatorul spune destinația:**

1. **Recunoaștere Vocală (STT)**
   ```dart
   // lib/voice/core/voice_orchestrator.dart
   // VoiceOrchestrator ascultă și convertește vorbirea în text
   ```
   - Utilizatorul spune: "Vreau să merg la Aeroport"
   - Sistemul convertește vorbirea în text

2. **Procesare AI (Gemini)**
   ```dart
   // lib/voice/ride/ride_flow_manager.dart - processVoiceInput()
   ```
   - Textul este trimis la **GeminiVoiceEngine**
   - AI-ul analizează intenția și extrage entități:
     - **Destinație**: "Aeroport"
     - **Tip de comandă**: "booking"

3. **Curățare Input**
   - Sistemul elimină "echo-ul" TTS-ului (ce spune AI-ul)
   - Se normalizează textul

4. **Răspuns AI**
   - AI-ul răspunde: "Am înțeles! Doriți să mergeți la Aeroport. Confirmați?"
   - Starea se schimbă în `awaitingConfirmation`

---

### **Pasul 3: Confirmarea Destinației**

**Utilizatorul confirmă:**

1. **Confirmare Vocală**
   - Utilizatorul spune: "Da, confirm" sau "Perfect"
   - Sistemul procesează confirmarea

2. **Geocoding Destinație**
   ```dart
   // lib/voice/ride/ride_flow_manager.dart - _handleDestinationConfirmedResponse()
   ```
   - Sistemul face geocoding pentru destinație
   - Convertește "Aeroport" în coordonate GPS
   - Salvează destinația în `_destination`

3. **Detectare Pickup**
   - Sistemul detectează automat locația curentă a utilizatorului
   - Sau cere utilizatorului să specifice pickup-ul

4. **Calculare Preț**
   ```dart
   // _calculateRealPrice()
   ```
   - Calculează distanța și durata folosind **RoutingService**
   - Calculează prețul folosind **PricingService**
   - Afișează prețul utilizatorului

---

### **Pasul 4: Confirmarea Finală și Trimiterea**

**Utilizatorul confirmă rezervarea:**

1. **Confirmare Finală**
   - Utilizatorul spune: "Da, rezerv" sau "Confirmă"
   - AI-ul răspunde: "Perfect! Completez adresele și trimit solicitarea către șoferi."

2. **Validare și Creare Ride**
   ```dart
   // lib/voice/ride/ride_flow_manager.dart - _fillAddressAndNavigateToConfirmation()
   ```
   - Validează adresele
   - Calculează prețul real
   - Creează obiectul Ride complet

3. **Trimitere la Firebase**
   ```dart
   final rideId = await onCreateRideRequest(rideRequest);
   ```
   - Se trimite cursa la Firestore
   - Se returnează ID-ul cursei

4. **Navigare la SearchingForDriverScreen**
   ```dart
   final searchingScreen = SearchingForDriverScreen(rideId: rideId);
   onNavigateToScreen(searchingScreen);
   ```
   - Se navighează direct la ecranul de căutare șofer
   - Se închide interacțiunea vocală

---

### **Pasul 5: Căutarea Șoferului (Identic cu Fluxul UI)**

**După trimiterea solicitării, fluxul este identic cu cel UI:**

1. **SearchingForDriverScreen**
   - Se caută șoferi disponibili
   - Se monitorizează status-ul cursei

2. **ActiveRideScreen**
   - Tracking în timp real
   - Finalizare cursă

---

## 🔄 COMPARAȚIE FLUXURI

| Aspect | Flux UI (Manual) | Flux AI (Vocal) |
|--------|------------------|----------------|
| **Inițiere** | Utilizatorul introduce adresele manual | Utilizatorul apasă butonul AI și vorbește |
| **Selectare Adrese** | Căutare text + geocoding | Comandă vocală + geocoding |
| **Confirmare** | Buton "Confirmă" | Comandă vocală "Da, confirm" |
| **Calculare Preț** | Automat după setarea adreselor | Automat după confirmarea destinației |
| **Trimitere Firebase** | Identic | Identic |
| **Căutare Șofer** | Identic | Identic |
| **Tracking Cursă** | Identic | Identic |

---

## 🎯 PUNCTE DE CONVERGENȚĂ

Ambele fluxuri converg în următoarele puncte:

1. **Crearea Obiectului Ride**
   - Același model de date (`Ride`)
   - Aceleași validări
   - Aceleași calcule de preț

2. **Trimiterea la Firebase**
   - Același serviciu (`FirestoreService.requestRide()`)
   - Același format de date

3. **Căutarea Șoferului**
   - Același ecran (`SearchingForDriverScreen`)
   - Aceeași logică de monitorizare

4. **Tracking Cursă**
   - Același ecran (`ActiveRideScreen`)
   - Aceeași logică de tracking

---

## 🏗️ ARHITECTURA COMPONENTELOR

### **Servicii Folosite de Ambele Fluxuri**

1. **FirestoreService**
   - Gestionarea cursei în Firebase
   - Stream-uri pentru actualizări în timp real

2. **RoutingService**
   - Calcularea rutelor
   - Distanță și durată

3. **PricingService**
   - Calcularea prețurilor
   - Tarife pe categorie

4. **GeocodingService**
   - Conversie adrese → coordonate GPS
   - Conversie coordonate GPS → adrese

### **Servicii Specifice Fluxului AI**

1. **VoiceOrchestrator**
   - Speech-to-Text (STT)
   - Gestionarea ascultării

2. **NaturalVoiceSynthesizer**
   - Text-to-Speech (TTS)
   - Răspunsuri vocale

3. **GeminiVoiceEngine**
   - Procesare AI conversatională
   - Extragere intenții și entități

4. **RideFlowManager**
   - Gestionarea flow-ului conversației
   - Coordonarea între AI, TTS, STT și servicii

---

## 📊 STĂRI ALE APLICAȚIEI

### **Stări Flux UI**

- `idle` → Utilizatorul este pe MapScreen
- `selecting_addresses` → Selectează adresele
- `calculating_route` → Calculează ruta
- `confirming_ride` → Confirmă rezervarea
- `searching_driver` → Caută șofer
- `driver_found` → Șofer găsit
- `ride_active` → Cursa este activă
- `ride_completed` → Cursa s-a finalizat

### **Stări Flux AI**

- `idle` → AI-ul nu este activ
- `listeningForInitialCommand` → Ascultă comanda inițială
- `processingCommand` → Procesează comanda
- `destinationConfirmed` → Destinația confirmată
- `awaitingConfirmation` → Așteaptă confirmare
- `awaitingAddressConfirmation` → Așteaptă confirmarea adreselor
- `searchingDrivers` → Caută șoferi
- `sendingToFirebase` → Trimite la Firebase
- `waitingForDriverResponse` → Așteaptă răspuns șofer
- `driverFound` → Șofer găsit
- `rideConfirmed` → Cursa confirmată
- `bookingFinalized` → Rezervarea finalizată

---

## 🔍 DETALII TEHNICE

### **Geocoding**

Ambele fluxuri folosesc același serviciu de geocoding:
```dart
// lib/services/geocoding_service.dart
GeocodingService.geocodeAddress(address) → Coordinates
GeocodingService.reverseGeocode(lat, lng) → Address
```

### **Calculare Preț**

Ambele fluxuri folosesc același serviciu de pricing:
```dart
// lib/services/pricing_service.dart
PricingService.calculateFare(
  distance: double,
  duration: double,
  category: RideCategory,
) → Map<String, double>
```

### **Firebase Integration**

Ambele fluxuri folosesc același serviciu Firestore:
```dart
// lib/services/firestore_service.dart
FirestoreService.requestRide(Ride ride) → String rideId
FirestoreService.getRideStream(String rideId) → Stream<Ride>
```

---

## ✅ CONCLUZIE

Ambele fluxuri (UI și AI) oferă aceeași funcționalitate, dar prin interfețe diferite:
- **Fluxul UI** este ideal pentru utilizatori care preferă interacțiunea tradițională
- **Fluxul AI** este ideal pentru utilizatori care preferă comandă vocală rapidă

Ambele converg către același rezultat: o cursă rezervată și un șofer găsit, folosind aceleași servicii backend și aceeași logică de business.

