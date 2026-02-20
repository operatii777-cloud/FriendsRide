# 🧪 GHID DE TESTARE - FIXURI IMPLEMENTATE

## 📋 PREGĂTIRE

### Conturi de Test:
- **Pasager:** `pasager.test@friendsride.ro` / `Test123456`
- **Șofer:** `sofer.test@friendsride.ro` / `Test123456`

### Ruta de Test:
- **De la:** Prelungirea Ghencea 45 bloc D4, București
- **La:** Aeroport Otopeni - Sosiri, București
- **Distanță:** ~15 km (validă)

---

## 🧪 TEST 1: VALIDARE CURSĂ DUPLICATĂ

### Scenariu:
1. Loghează-te ca pasager
2. Creează o cursă prin AI sau UI
3. Înainte ca cursa să fie finalizată, încearcă să creezi o a doua cursă

### Rezultat Așteptat:
- ✅ Prima cursă: Creată cu succes
- ❌ A doua cursă: Eșuează cu mesaj **"Ai deja o cursă activă. Anulează-o înainte de a crea una nouă."**

### Verificări:
- [ ] Mesajul de eroare apare clar
- [ ] A doua cursă nu este creată în Firebase
- [ ] Prima cursă rămâne activă

---

## 🧪 TEST 2: VALIDARE COORDONATE

### Scenariu A: Coordonate Valide
1. Selectează adrese valide (București → Otopeni)
2. Creează cursa

### Rezultat Așteptat:
- ✅ Cursa este creată cu succes

### Scenariu B: Coordonate Invalide (Out of Range)
1. Simulează coordonate invalide (lat > 90 sau lng > 180)
2. Încearcă să creezi cursa

### Rezultat Așteptat:
- ❌ Eșuează cu mesaj **"Coordonatele pickup sunt invalide."** sau **"Coordonatele destinației sunt invalide."**

### Verificări:
- [ ] Coordonate valide: Cursa este creată
- [ ] Coordonate invalide: Eșuează cu mesaj clar
- [ ] Coordonate null: Eșuează cu mesaj **"Coordonatele sunt incomplete."**

---

## 🧪 TEST 3: VALIDARE DISTANȚĂ

### Scenariu A: Distanță Prea Mică (< 100m)
1. Selectează două adrese foarte apropiate (același bloc)
2. Încearcă să creezi cursa

### Rezultat Așteptat:
- ❌ Eșuează cu mesaj **"Distanța este prea mică. Distanța minimă este 100 metri."**

### Scenariu B: Distanță Prea Mare (> 200km)
1. Selectează destinație foarte departe (ex: București → Cluj)
2. Încearcă să creezi cursa

### Rezultat Așteptat:
- ❌ Eșuează cu mesaj **"Distanța este prea mare. Distanța maximă este 200 km."**

### Scenariu C: Distanță Validă (100m - 200km)
1. Selectează destinație la distanță normală (ex: București → Otopeni, ~15km)
2. Creează cursa

### Rezultat Așteptat:
- ✅ Cursa este creată cu succes

### Verificări:
- [ ] Distanță < 100m: Eșuează cu mesaj clar
- [ ] Distanță > 200km: Eșuează cu mesaj clar
- [ ] Distanță validă: Cursa este creată

---

## 🧪 TEST 4: FIX PASSENGERID

### Scenariu:
1. Loghează-te ca pasager
2. Creează cursă prin AI
3. Verifică în Firebase că `passengerId` este setat corect

### Rezultat Așteptat:
- ✅ `passengerId` = User ID real (nu string gol)
- ✅ `passengerId` corespunde cu user-ul autentificat

### Verificări:
- [ ] `passengerId` nu este string gol `''`
- [ ] `passengerId` este user ID real din Firebase Auth
- [ ] Dacă user-ul nu este autentificat, se aruncă excepție

### Cum să verifici în Firebase:
1. Mergi la Firebase Console → Firestore → `ride_requests`
2. Găsește cursa creată
3. Verifică că `passengerId` este setat corect

---

## 🧪 TEST 5: GEOCODING PENTRU OPRIRI

### Scenariu:
1. Adaugă opriri intermediare (ex: "Piața Unirii", "Gara de Nord")
2. Creează cursa
3. Verifică coordonatele opririlor în Firebase

### Rezultat Așteptat:
- ✅ Coordonatele opririlor sunt reale (nu default București center)
- ✅ Geocoding real este apelat pentru fiecare oprire
- ⚠️ Dacă geocoding eșuează, se folosește fallback

### Verificări:
- [ ] Coordonatele opririlor nu sunt toate 44.4268, 26.1025 (default)
- [ ] Coordonatele corespund cu locațiile reale
- [ ] Geocoding este apelat pentru fiecare oprire

### Cum să verifici:
1. Creează cursă cu opriri
2. Mergi la Firebase Console → Firestore → `ride_requests`
3. Verifică `stops` array - coordonatele ar trebui să fie diferite pentru fiecare oprire

---

## 🧪 TEST 6: ERROR HANDLING ȘI TIMEOUT

### Scenariu A: Timeout la Calculare Preț
1. Simulează conexiune lentă
2. Creează cursă prin AI
3. Observă comportamentul când calcularea prețului durează mult

### Rezultat Așteptat:
- ⏱️ După 30 secunde: Timeout cu mesaj clar
- ✅ Aplicația continuă cu preț default dacă timeout

### Scenariu B: Eroare la Creare Cursă
1. Simulează eroare Firebase (ex: offline)
2. Încearcă să creezi cursa

### Rezultat Așteptat:
- ❌ Eșuează cu mesaj clar: **"Nu am putut crea cursa: [detalii eroare]"**
- ✅ Utilizatorul primește feedback clar

### Verificări:
- [ ] Timeout-uri funcționează corect (30 secunde)
- [ ] Mesaje de eroare sunt clare și utile
- [ ] Aplicația nu se blochează la erori
- [ ] Navigarea este gestionată corect chiar dacă apar erori

---

## 🧪 TEST 7: CONVERSIE COMPLETĂ DE DATE

### Scenariu:
1. Creează cursă prin AI
2. Verifică că toate datele sunt convertite corect

### Rezultat Așteptat:
- ✅ Toate câmpurile sunt populate corect
- ✅ Coordonatele sunt incluse
- ✅ Prețul este calculat corect

### Verificări:
- [ ] `pickupLocation` și `destination` sunt setate
- [ ] Coordonatele (`pickupLatitude`, etc.) sunt setate
- [ ] `estimatedPrice` este calculat
- [ ] `category` este setat corect

---

## 📊 CHECKLIST FINAL

### Fixuri Testate:
- [ ] ✅ Validare cursă duplicată
- [ ] ✅ Validare coordonate
- [ ] ✅ Validare distanță
- [ ] ✅ Fix passengerId
- [ ] ✅ Geocoding pentru opriri
- [ ] ✅ Error handling
- [ ] ✅ Timeout pentru operațiuni lungi
- [ ] ✅ Conversie completă de date

### Rezultate:
- [ ] Toate fixurile funcționează corect
- [ ] Mesajele de eroare sunt clare
- [ ] Aplicația nu se blochează
- [ ] Datele sunt salvate corect în Firebase

---

## 🐛 Dacă Găsești Probleme

### Cum să raportezi:
1. Notează exact ce ai făcut
2. Notează ce s-a întâmplat (vs. ce ar trebui să se întâmple)
3. Include mesajele de eroare (dacă există)
4. Include screenshot-uri (dacă e relevant)

### Exemple de probleme:
- ❌ "Cursa duplicată a fost creată" → Fix-ul nu funcționează
- ❌ "passengerId este gol în Firebase" → Fix-ul nu funcționează
- ❌ "Coordonatele default sunt folosite pentru opriri" → Geocoding nu funcționează

---

**Document creat:** 2025-01-XX  
**Status:** Ghid complet pentru testare manuală

