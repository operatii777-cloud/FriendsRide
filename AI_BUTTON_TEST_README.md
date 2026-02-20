# 🧪 AI Button Test Suite

Acest director conține scripturile complete pentru testarea funcționalității butonului AI end-to-end, inclusiv simularea utilizatorului virtual și verificarea procesării adreselor.

## 📁 Fișiere incluse

### Scripturi de test
- **`test_ai_button_end_to_end.dart`** - Test principal end-to-end cu scenarii complete
- **`test_ai_button_integration.dart`** - Teste de integrare cu aplicația reală
- **`test_ai_button_virtual_user.dart`** - Simulator utilizator virtual pentru testare

### Scripturi de rulare
- **`run_ai_button_tests.sh`** - Script Bash pentru Linux/macOS
- **`run_ai_button_tests.ps1`** - Script PowerShell pentru Windows
- **`test_ai_button_e2e.sh`** - Script Bash simplu pentru testare rapidă
- **`test_ai_button_e2e.ps1`** - Script PowerShell simplu pentru testare rapidă

## 🚀 Cum să rulezi testele

### Opțiunea 1: Script complet (Recomandat)
```bash
# Linux/macOS
chmod +x run_ai_button_tests.sh
./run_ai_button_tests.sh

# Windows PowerShell
.\run_ai_button_tests.ps1
```

### Opțiunea 2: Script simplu
```bash
# Linux/macOS
chmod +x test_ai_button_e2e.sh
./test_ai_button_e2e.sh

# Windows PowerShell
.\test_ai_button_e2e.ps1
```

### Opțiunea 3: Teste individuale
```bash
# Test end-to-end
flutter test test_ai_button_end_to_end.dart

# Test utilizator virtual
flutter test test_ai_button_virtual_user.dart

# Test integrare
flutter test test_ai_button_integration.dart
```

## 🎯 Ce testează scripturile

### 1. Test End-to-End (`test_ai_button_end_to_end.dart`)
- ✅ Apăsarea butonului AI
- ✅ Pornirea interacțiunii vocale
- ✅ Procesarea comenzilor vocale
- ✅ Generarea răspunsurilor AI
- ✅ Procesarea adreselor
- ✅ Inițierea fluxului de cursă
- ✅ Confirmarea cursei

### 2. Test Utilizator Virtual (`test_ai_button_virtual_user.dart`)
- 🤖 Simularea utilizatorului virtual
- 🎤 Simularea comenzilor vocale
- 🧠 Simularea răspunsurilor AI
- 📍 Simularea procesării adreselor
- 🚗 Simularea fluxului de cursă
- ⚡ Testarea scenariilor de urgență

### 3. Test Integrare (`test_ai_button_integration.dart`)
- 🔗 Integrarea cu aplicația reală
- 🎯 Testarea widget-urilor UI
- 🎤 Testarea overlay-ului vocal
- 🔄 Testarea stărilor aplicației

## 📊 Scenarii de test

### Scenarii de bază
1. **Cerere cursă simplă**: "Vreau să merg la Piața Unirii"
2. **Pickup și destinație**: "Ia-mă de la Gara de Nord la Aeroportul Otopeni"
3. **Adresă românească**: "Du-mă la Strada Victoriei numărul 10"
4. **Centru comercial**: "Vreau să merg la Centrul Comercial Băneasa"
5. **Adresă complexă**: "Du-mă la Universitatea Politehnica București"

### Scenarii speciale
6. **Urgență**: "Am o urgență, du-mă la spitalul cel mai apropiat"
7. **Clarificare**: Testarea răspunsurilor la comenzi ambigue
8. **Confirmare**: Testarea fluxului de confirmare a cursei

## 🎭 Utilizator Virtual

Simulatorul de utilizator virtual (`VirtualUserSimulator`) oferă:

### Funcționalități
- 🎤 **Simularea comenzilor vocale** cu delay realist
- 🧠 **Generarea răspunsurilor AI** contextuale
- 📍 **Procesarea adreselor** din comenzi
- 🚗 **Simularea fluxului de cursă** complet
- ⚡ **Gestionarea scenariilor de urgență**

### Stări simulate
- `idle` - Starea inițială
- `listeningForInitialCommand` - Ascultă comanda inițială
- `processingCommand` - Procesează comanda
- `awaitingConfirmation` - Așteaptă confirmarea
- `searchingDrivers` - Caută șoferi
- `driverFound` - Șofer găsit

## 📈 Rapoarte de test

### Raport HTML interactiv
- 📊 Dashboard cu statistici
- 📝 Log-uri detaliate pentru fiecare test
- 🎯 Rezultate vizuale cu culori
- 📱 Design responsive

### Raport text
- 📄 Format simplu pentru citire
- 🔍 Log-uri complete
- 📊 Statistici de performanță
- ⏱️ Timpii de execuție

### Log-uri individuale
- 📁 Un fișier pentru fiecare test
- 🔍 Debugging detaliat
- 📊 Metrici de performanță
- ❌ Erori detaliate

## ⚙️ Configurare

### Variabile de mediu
```bash
# Calea către Flutter
FLUTTER_PATH="C:\Users\flori\AppData\Local\dev\bin\flutter.bat"

# Directorul proiectului
PROJECT_DIR="c:\friendsride_app"

# Directorul pentru rapoarte
REPORT_DIR="test_reports"
```

### Parametri opționali
```bash
# PowerShell
.\run_ai_button_tests.ps1 -Verbose -SkipBuild

# Bash
./run_ai_button_tests.sh --verbose --skip-build
```

## 🐛 Debugging

### Probleme comune
1. **Flutter nu este găsit**
   - Verifică calea către `flutter.bat`
   - Adaugă Flutter în PATH

2. **Testele eșuează**
   - Verifică log-urile din `test_reports/`
   - Rulează `flutter analyze` pentru erori

3. **Build-ul eșuează**
   - Rulează `flutter clean`
   - Rulează `flutter pub get`

### Log-uri utile
- `flutter_analyze.log` - Analiza codului
- `android_build.log` - Build Android
- `web_build.log` - Build Web
- `performance_build.log` - Metrici de performanță

## 📚 Exemple de utilizare

### Test rapid
```bash
# Rulează doar testele unitare
flutter test test_ai_button_end_to_end.dart
```

### Test complet
```bash
# Rulează toate testele cu rapoarte
./run_ai_button_tests.sh
```

### Test cu parametri
```bash
# PowerShell cu verbose
.\run_ai_button_tests.ps1 -Verbose

# Bash cu skip build
./run_ai_button_tests.sh --skip-build
```

## 🎯 Rezultate așteptate

### Teste de succes
- ✅ Toate testele unitare trec
- ✅ Build-ul Android și Web funcționează
- ✅ Performanța este sub 60s
- ✅ Analiza Flutter nu are erori

### Metrici de performanță
- 🚀 Startup time: < 5s
- 🏗️ Build time: < 60s
- 🧪 Test execution: < 30s
- 📊 Success rate: > 95%

## 🔧 Personalizare

### Adăugarea de scenarii noi
Editează `test_ai_button_virtual_user.dart`:
```dart
final List<VoiceTestScenario> _scenarios = [
  // Adaugă scenarii noi aici
  VoiceTestScenario(
    name: 'Noul scenariu',
    command: 'Comanda vocală',
    expectedDestination: 'Destinația așteptată',
    responseKeywords: ['cuvinte', 'cheie'],
  ),
];
```

### Modificarea testelor
Editează fișierele de test pentru a adăuga verificări noi sau a modifica comportamentul.

## 📞 Suport

Pentru probleme sau întrebări:
1. Verifică log-urile din `test_reports/`
2. Rulează `flutter doctor` pentru diagnosticare
3. Verifică configurația Firebase și Mapbox
4. Asigură-te că toate dependențele sunt instalate

---

**🎉 Testele sunt gata pentru utilizare! Rulează `./run_ai_button_tests.sh` sau `.\run_ai_button_tests.ps1` pentru a începe.**
