# 🧪 GHID COMPLET DE TESTARE MANUALĂ - FRIENDSRIDE

## 📋 PREGĂTIRE

### Conturi de Test (Creează-le în Firebase Console):

**Cont Pasager:**
- Email: `pasager.test@friendsride.ro`
- Parolă: `Test123456`

**Cont Șofer:**
- Email: `sofer.test@friendsride.ro`
- Parolă: `Test123456`

### Ruta de Test:
- **De la:** Prelungirea Ghencea 45 bloc D4, București
- **La:** Aeroport Otopeni - Sosiri, București
- **Distanță:** ~15 km
- **Durată estimată:** ~25-30 minute

---

## 🧪 TEST 1: PASAJER - MODUL UI (INTERFAȚA MANUALĂ)

### Pași de Urmărit:

1. **Autentificare**
   - Deschide aplicația
   - Loghează-te cu: `pasager.test@friendsride.ro` / `Test123456`
   - ✅ Verifică: Navigare automată la MapScreen

2. **Selectare Adresă de Plecare**
   - Apasă pe câmpul "De la"
   - Scrie: `Prelungirea Ghencea 45 bloc D4`
   - Selectează sugestia corectă
   - ✅ Verifică: Adresa apare pe hartă cu marker verde

3. **Selectare Destinație**
   - Apasă pe câmpul "La"
   - Scrie: `Aeroport Otopeni Sosiri`
   - Selectează sugestia corectă
   - ✅ Verifică: 
     - Adresa apare pe hartă cu marker roșu
     - Ruta se calculează automat
     - Prețul se afișează

4. **Confirmare Cursă**
   - Verifică prețul afișat
   - Apasă "Confirmă cursa"
   - ✅ Verifică: Navigare la `SearchingForDriverScreen`

5. **Așteptare Șofer**
   - ✅ Verifică: 
     - Mesaj "Se caută șoferi disponibili..."
     - Progress indicator activ

6. **Cursa Acceptată (Simulează manual în Firebase)**
   - Mergi în Firebase Console → Firestore → `rides`
   - Găsește cursa creată
   - Modifică `status` la `accepted`
   - Adaugă `driverId` (ID-ul contului șofer)
   - ✅ Verifică: Navigare automată la `ActiveRideScreen`

7. **Tracking Șofer**
   - ✅ Verifică:
     - Marker-ul șoferului apare pe hartă
     - Mașina se mișcă smooth
     - ETA se actualizează în timp real
     - Distanța se actualizează

8. **Finalizare Cursă**
   - Când șoferul ajunge la destinație (simulează în Firebase)
   - Modifică `status` la `completed`
   - ✅ Verifică: Navigare la `RideSummaryScreen`

---

## 🤖 TEST 2: PASAJER - MODUL AI (BUTONUL VOCAL)

### Pași de Urmărit:

1. **Autentificare**
   - Deschide aplicația
   - Loghează-te cu: `pasager.test@friendsride.ro` / `Test123456`
   - ✅ Verifică: Navigare automată la MapScreen

2. **Activare AI**
   - Apasă butonul AI (floating button)
   - ✅ Verifică: 
     - Overlay vocal apare
     - AI spune: "Salutare! Unde doriți să mergeți?"

3. **Comandă Vocală**
   - Spune clar: **"Vreau să merg la Aeroport Otopeni Sosiri"**
   - ✅ Verifică:
     - AI procesează comanda
     - Overlay-ul arată "AI PROCESEAZĂ" (portocaliu)
     - AI răspunde cu confirmarea

4. **Confirmare AI**
   - AI va întreba: "Doriți să mergeți la Aeroport Otopeni - Sosiri. Confirmați?"
   - Spune: **"Da, confirm"**
   - ✅ Verifică:
     - AI calculează prețul
     - AI anunță prețul: "Cursa costă aproximativ X lei"
     - AI cere confirmare finală

5. **Confirmare Finală**
   - Spune: **"Da, trimite"**
   - ✅ Verifică:
     - AI trimite cererea
     - Navigare la `SearchingForDriverScreen`
     - Mesaj: "Se caută șoferi disponibili..."

6. **Restul Fluxului**
   - Continuă ca la TEST 1 (pașii 6-8)

---

## 🚗 TEST 3: ȘOFER - MODUL UI

### Pași de Urmărit:

1. **Autentificare ca Șofer**
   - Deschide aplicația
   - Loghează-te cu: `sofer.test@friendsride.ro` / `Test123456`
   - ✅ Verifică: Navigare automată la MapScreen

2. **Activare Mod Șofer**
   - Deschide drawer (meniu lateral)
   - Apasă "Devino Șofer" sau "Mod Șofer"
   - ✅ Verifică:
     - Status se schimbă la "Disponibil"
     - Marker-ul tău apare pe hartă ca șofer

3. **Primire Cerere Cursă**
   - Așteaptă sau simulează manual:
     - Mergi în Firebase Console → Firestore → `rides`
     - Creează o cursă cu `status: pending`
     - Setează `passengerId` (ID-ul contului pasager)
   - ✅ Verifică:
     - Notificare apare
     - Cererea apare în lista de curse disponibile

4. **Acceptare Cursă**
   - Apasă pe cererea de cursă
   - Vezi detaliile (pickup, destinație, preț)
   - Apasă "Acceptă cursă"
   - ✅ Verifică:
     - Status cursei se schimbă la `accepted`
     - Navigare la `ActiveRideScreen`
     - Ruta se calculează automat

5. **Navigare către Pasager**
   - ✅ Verifică:
     - Ruta către pickup se afișează
     - Camera urmărește poziția ta
     - ETA către pasager se actualizează

6. **Ridicare Pasager**
   - Când ajungi la pickup (simulează manual):
     - Modifică `status` la `in_progress` în Firebase
   - ✅ Verifică:
     - Status se actualizează
     - Ruta către destinație se calculează

7. **Navigare către Destinație**
   - ✅ Verifică:
     - Ruta către destinație se afișează
     - Camera urmărește poziția ta
     - ETA către destinație se actualizează

8. **Finalizare Cursă**
   - Când ajungi la destinație (simulează manual):
     - Modifică `status` la `completed` în Firebase
   - ✅ Verifică:
     - Navigare la `RideSummaryScreen`
     - Prețul final se afișează

---

## 🔧 SIMULARE MANUALĂ ÎN FIREBASE

### Pentru a simula progresul cursei fără șofer real:

1. **Creează Cursă:**
   ```json
   {
     "id": "test-ride-123",
     "passengerId": "ID_PASAJER",
     "driverId": "ID_SOFER",
     "startAddress": "Prelungirea Ghencea 45 bloc D4",
     "destinationAddress": "Aeroport Otopeni - Sosiri",
     "status": "pending",
     "timestamp": "2025-01-XX..."
   }
   ```

2. **Actualizează Status:**
   - `pending` → `accepted` (când șoferul acceptă)
   - `accepted` → `in_progress` (când șoferul ridică pasagerul)
   - `in_progress` → `completed` (când ajunge la destinație)

3. **Actualizează Poziția Șoferului:**
   - Mergi la `driver_locations/{driverId}`
   - Actualizează `position` cu coordonate noi
   - Simulează mișcarea către destinație

---

## ✅ CHECKLIST FINAL

### Test Pasager UI:
- [ ] Autentificare reușită
- [ ] Selectare adrese funcționează
- [ ] Ruta se calculează corect
- [ ] Prețul se afișează corect
- [ ] Cursa se creează în Firebase
- [ ] Tracking șofer funcționează
- [ ] Cursa se finalizează corect

### Test Pasager AI:
- [ ] Butonul AI funcționează
- [ ] AI înțelege comanda vocală
- [ ] AI procesează corect adresa
- [ ] AI calculează prețul
- [ ] AI trimite cererea
- [ ] Tracking șofer funcționează
- [ ] Cursa se finalizează corect

### Test Șofer:
- [ ] Mod șofer se activează
- [ ] Primește notificări pentru curse
- [ ] Poate accepta curse
- [ ] Navigare funcționează
- [ ] Tracking poziție funcționează
- [ ] Cursa se finalizează corect

---

**Document creat:** 2025-01-XX  
**Status:** Ghid complet pentru testare manuală

