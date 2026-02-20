# 🧪 CUM SĂ TESTEZI APLICAȚIA FĂRĂ AUTENTIFICARE REALĂ

## 📋 REZUMAT

Acest ghid te ajută să testezi aplicația FriendsRide simulând o cursă completă de la **"Prelungirea Ghencea 45 bloc D4"** la **"Aeroport Otopeni - Sosiri"**, atât ca șofer cât și ca pasager, atât prin modulul fizic (UI) cât și prin modulul AI.

---

## 🚀 METODA 1: TESTARE AUTOMATĂ (SCRIPT)

### Pași:

1. **Activează modul de testare:**
   ```bash
   flutter run --dart-define=TEST_MODE=true
   ```

2. **Rulează scriptul de testare:**
   ```bash
   dart test_ride_simulation.dart
   ```

3. **Rezultat:**
   - Scriptul simulează toate pașii automat
   - Vezi output-ul în consolă
   - Nu necesită interacțiune manuală

---

## 🎮 METODA 2: TESTARE MANUALĂ CU CONTURI DE TEST

### Pregătire:

1. **Creează conturi de test în Firebase Console:**
   - Mergi la Firebase Console → Authentication → Users
   - Creează manual sau folosește scriptul

2. **Conturi predefinite:**
   - **Pasager:** `pasager.test@friendsride.ro` / `Test123456`
   - **Șofer:** `sofer.test@friendsride.ro` / `Test123456`

### Testare Pasager - UI:

Vezi ghidul complet în `GHID_TESTARE_MANUALA.md` → TEST 1

### Testare Pasager - AI:

Vezi ghidul complet în `GHID_TESTARE_MANUALA.md` → TEST 2

### Testare Șofer:

Vezi ghidul complet în `GHID_TESTARE_MANUALA.md` → TEST 3

---

## 🔧 METODA 3: TESTARE CU HELPER (COD)

### Folosește `TestModeHelper`:

```dart
import 'package:friendsride_app/utils/test_mode_helper.dart';

// Autentificare rapidă ca pasager
final credential = await TestModeHelper.quickLogin('passenger');

// Autentificare rapidă ca șofer
final credential = await TestModeHelper.quickLogin('driver');

// Creează o cursă de test
final rideId = await TestModeHelper.createTestRide(
  passengerId: 'PASSENGER_ID',
  driverId: 'DRIVER_ID', // opțional
);

// Simulează mișcarea șoferului
await TestModeHelper.simulateDriverMovement(
  driverId: 'DRIVER_ID',
  targetLat: 44.5711,
  targetLng: 26.0858,
);
```

---

## 📱 METODA 4: TESTARE ÎN APLICAȚIE (UI HIDDEN)

### Adaugă buton de testare în aplicație:

1. **Deschide `lib/screens/map_screen.dart`**
2. **Adaugă buton de testare (doar în debug mode):**
   ```dart
   if (kDebugMode)
     FloatingActionButton(
       onPressed: () async {
         await TestModeHelper.quickLogin('passenger');
         // Sau 'driver'
       },
       child: Icon(Icons.bug_report),
     ),
   ```

3. **Folosește butonul pentru testare rapidă**

---

## 🎯 SCENARII DE TESTARE

### Scenariu 1: Pasager UI → Șofer Acceptă

1. Loghează-te ca pasager
2. Creează cursa prin UI
3. Loghează-te ca șofer (pe alt device/emulator)
4. Acceptă cursa
5. Simulează mișcarea șoferului
6. Finalizează cursa

### Scenariu 2: Pasager AI → Șofer Acceptă

1. Loghează-te ca pasager
2. Creează cursa prin AI
3. Loghează-te ca șofer (pe alt device/emulator)
4. Acceptă cursa
5. Simulează mișcarea șoferului
6. Finalizează cursa

### Scenariu 3: Test Complet End-to-End

1. Pornește 2 emulatoare/dispozitive
2. Device 1: Pasager (UI sau AI)
3. Device 2: Șofer
4. Testează întregul flux în paralel

---

## ✅ CHECKLIST TESTARE

### Funcționalități de Testat:

- [ ] **Autentificare:**
  - [ ] Login cu cont de test
  - [ ] Registration (dacă nu există cont)
  - [ ] Persistență sesiune

- [ ] **Pasager UI:**
  - [ ] Selectare adrese
  - [ ] Calculare rută
  - [ ] Calculare preț
  - [ ] Creare cursă
  - [ ] Tracking șofer
  - [ ] Finalizare cursă

- [ ] **Pasager AI:**
  - [ ] Activare AI
  - [ ] Comandă vocală
  - [ ] Procesare AI
  - [ ] Confirmare AI
  - [ ] Creare cursă
  - [ ] Tracking șofer
  - [ ] Finalizare cursă

- [ ] **Șofer:**
  - [ ] Activare mod șofer
  - [ ] Primire notificări
  - [ ] Acceptare cursă
  - [ ] Navigare către pasager
  - [ ] Navigare către destinație
  - [ ] Finalizare cursă

---

## 🐛 DEBUGGING

### Dacă testarea nu funcționează:

1. **Verifică Firebase:**
   - Conturile există în Authentication
   - Firestore Rules permit testarea
   - Proiectul Firebase este corect

2. **Verifică Cod:**
   - `TEST_MODE` este activat
   - `TestModeHelper` este importat corect
   - Nu există erori de compilare

3. **Verifică Logs:**
   - Deschide consola Flutter
   - Caută mesaje de eroare
   - Verifică debug prints

---

## 📚 DOCUMENTE RELATE

- `GHID_TESTARE_MANUALA.md` - Ghid detaliat pentru testare manuală
- `test_ride_simulation.dart` - Script de testare automată
- `lib/utils/test_mode_helper.dart` - Helper pentru testare

---

**Document creat:** 2025-01-XX  
**Status:** Ghid complet pentru toate metodele de testare

