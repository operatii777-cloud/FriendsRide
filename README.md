# 🚗 FriendsRide - Intelligent Ride-Sharing App

[![Flutter](https://img.shields.io/badge/Flutter-3.16-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-10.0-orange.svg)](https://firebase.google.com/)
[![Mapbox](https://img.shields.io/badge/Mapbox-10.0-lightblue.svg)](https://mapbox.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**FriendsRide** este o aplicație de ride-sharing inteligentă care conectează pasagerii cu șoferi parteneri, oferind o experiență vocală avansată cu AI, navigație în timp real și funcționalități de siguranță.

## 🌟 Caracteristici Principale

### 🎤 Asistent Vocal AI
- **Control vocal complet** - Rezervă curse prin comenzi vocale
- **Procesare inteligentă** - AI înțelege destinații și confirmări
- **Sincronizare perfectă** - TTS-STT sincronizat pentru conversații naturale
- **Beep-uri de feedback** - Indicații audio pentru interacțiune

### 🗺️ Hartă Interactivă
- **POI-uri inteligente** - Restaurante, hoteluri, aeroporturi, gări
- **Clustering optimizat** - Randare GPU pentru performanță
- **Trasee în timp real** - Navigație cu trafic live
- **Zoom gates** - Optimizări pentru performanță

### 👥 Două Moduri de Utilizare
- **Mod Pasager** - Rezervă curse, urmărește în timp real
- **Mod Șofer** - Acceptă curse, gestionează câștigurile

### 🛡️ Siguranță și Securitate
- **Verificare șoferi** - Background check și documente
- **Partajare locație** - Siguranță în timpul cursei
- **Sistem urgență** - Buton panic și contacte de urgență
- **Rating și feedback** - Sistem de evaluare comunitar

## 📱 Capturi de Ecran

### Ecranul Principal
- Hartă interactivă cu POI-uri
- Buton AI pentru comenzi vocale
- Adrese pickup și destinație
- Trasee în timp real

### Asistentul Vocal
- Interfață vocală intuitivă
- Feedback audio în timp real
- Procesare inteligentă a comenzilor
- Sincronizare perfectă TTS-STT

### Modul Șofer
- Dashboard cu curse disponibile
- Tracking în timp real
- Gestionare câștiguri
- Rating și feedback

## 🚀 Instalare și Configurare

### Cerințe de Sistem
- **Android**: 7.0 (API level 24) sau mai nou
- **iOS**: 12.0 sau mai nou
- **Flutter**: 3.16 sau mai nou
- **Dart**: 3.2 sau mai nou

### Instalare Development
```bash
# Clonează repository-ul
git clone https://github.com/your-username/friendsride_app.git
cd friendsride_app

# Instalează dependențele
flutter pub get

# Configurează Firebase
# Copiază firebase_options.dart în lib/
# Actualizează google-services.json (Android) și GoogleService-Info.plist (iOS)

# Configurează Mapbox
# Actualizează MAPBOX_ACCESS_TOKEN în lib/utils/mapbox_config.dart

# Rulează aplicația
flutter run
```

### Configurare Firebase
1. Creează un proiect Firebase
2. Activează Authentication, Firestore, Storage
3. Configurează regulile de securitate
4. Actualizează firebase_options.dart

### Configurare Mapbox
1. Creează cont Mapbox
2. Generează acces token
3. Actualizează MAPBOX_ACCESS_TOKEN

## 🏗️ Arhitectura Aplicației

### Structura Proiectului
```
lib/
├── main.dart                 # Entry point
├── config/                   # Configurări aplicație
├── models/                   # Modele de date
├── providers/                # State management
├── screens/                  # Ecrane aplicație
├── services/                 # Servicii backend
├── voice/                    # Sistem vocal AI
│   ├── ai/                   # Gemini Voice Engine
│   ├── core/                 # Voice Orchestrator
│   ├── integration/          # FriendsRide Integration
│   ├── passenger/            # Passenger Controller
│   ├── ride/                 # Ride Flow Manager
│   └── tts/                  # Text-to-Speech
├── widgets/                  # Widget-uri reutilizabile
├── utils/                    # Utilitare
└── l10n/                     # Localizare
```

### Servicii Principale
- **FirestoreService** - Gestionare date Firebase
- **RoutingService** - Calculare trasee
- **GeocodingService** - Geocoding adrese
- **VoiceOrchestrator** - Orchestrare TTS/STT
- **GeminiVoiceEngine** - AI processing
- **RealTimeTrackingService** - Tracking timp real

## 🎤 Sistemul Vocal AI

### Componente
- **VoiceOrchestrator** - Sincronizare TTS-STT
- **GeminiVoiceEngine** - Procesare AI cu fallback local
- **RideFlowManager** - Gestionare flux curse vocal
- **FriendsRideVoiceIntegration** - Integrare cu UI

### Fluxul Conversației
1. **Salut** - AI salută utilizatorul
2. **Destinație** - Utilizator specifică destinația
3. **Confirmare** - AI confirmă destinația
4. **Pickup** - AI detectează locația curentă
5. **Căutare** - AI caută șoferi disponibili
6. **Finalizare** - AI finalizează rezervarea

### Comenzi Vocale Disponibile
- `"Solicită cursă"` - Începe rezervarea
- `"Către [destinație]"` - Specifică destinația
- `"De la [adresă]"` - Specifică pickup-ul
- `"Anulează"` - Anulează cursa
- `"Unde sunt?"` - Afișează locația
- `"Sună șoferul"` - Contactează șoferul

## 🗺️ Sistemul de Hartă

### Tehnologii
- **Mapbox Maps** - Randare hartă
- **SymbolLayer + Clustering** - Optimizare POI-uri
- **Real-time routing** - Trasee în timp real
- **GPS tracking** - Localizare precisă

### Optimizări Performanță
- **GPU rendering** - Randare hardware
- **Zoom gates** - Randare condițională
- **Limitare POI-uri** - Max 200 POI-uri
- **Cache inteligent** - Cache pentru geocoding

## 📊 Funcționalități Avansate

### Sistemul de POI-uri
- **Categorii**: Restaurante, hoteluri, transport, shopping
- **Clustering**: Grupare automată pentru performanță
- **Interacțiune**: Selecție prin touch
- **Detalii**: Informații complete despre POI-uri

### Sistemul de Trasee
- **Algoritm optim** - Cel mai bun traseu
- **Trafic real-time** - Considerare trafic
- **Alternative** - Trasee alternative
- **Recalculare** - Recalculare automată

### Sistemul de Plată
- **Automată** - Procesare automată
- **Sigură** - Criptare end-to-end
- **Multiple metode** - Card, PayPal, Apple/Google Pay
- **Chitanțe** - Chitanțe automate

## 🧪 Testare

### Teste Unitare
```bash
# Rulează toate testele
flutter test

# Teste specifice
flutter test test/voice/
flutter test test/services/
```

### Teste Integration
```bash
# Teste end-to-end
flutter test integration_test/
```

### Teste AI
```bash
# Teste sistem vocal
dart test_ai_button_end_to_end.dart
dart test_real_devices_ai_flow.dart
```

## 📈 Performanță

### Optimizări Implementate
- **Lazy loading** - Încărcare la cerere
- **Background services** - Servicii în background
- **Cache inteligent** - Cache pentru date
- **Debouncing** - Optimizare input-uri

### Monitorizare
- **Performance monitor** - Monitorizare performanță
- **Crash reporting** - Raportare erori
- **Analytics** - Analitică utilizare
- **Real-time tracking** - Tracking în timp real

## 🌍 Localizare și Traducere

### Limbi Suportate
- **Română** (ro) - Limba principală (implicită)
- **Engleză** (en) - Suport complet pentru toate funcționalitățile

### Funcționalități de Traducere
- **Schimbare limbă dinamică** - Prin meniul hamburger → "Limba"
- **Traducere completă a interfeței** - Toate butoanele, meniurile și textele
- **Conținut tradus** - Ecranele "Despre" și "Juridic" complet traduse
- **Persistența alegerii** - Limba selectată se păstrează între sesiuni

### Fișiere Localizare
- `lib/l10n/app_ro.arb` - 223 traduceri în română
- `lib/l10n/app_en.arb` - 223 traduceri în engleză
- `lib/l10n/app_localizations.dart` - Generator automat Flutter
- `lib/providers/locale_provider.dart` - Gestionare limbă

### Elemente Traduse
- ✅ **Meniu principal** - Toate opțiunile din hamburger menu (18 elemente)
- ✅ **Ecranul "Despre"** - Titluri, butoane, texte explicative (12 elemente)
- ✅ **Ecranul "Juridic"** - Termeni și condiții, politica de confidențialitate (33 elemente)
- ✅ **Sistemul vocal AI** - Mesaje și confirmări (158 elemente existente)
- ✅ **Interfața de navigare** - Butoane și etichete
- ✅ **Mesaje de eroare** - Feedback pentru utilizatori

### Statistici Traducere
- **Total string-uri**: 223 (100% traduse)
- **Limbi suportate**: Română (implicită), Engleză
- **Persistența**: Alegerile utilizatorului se salvează automat
- **Acoperire**: 100% din interfața utilizatorului

## 🔧 Configurare Development

### Variabile de Mediu
```bash
# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key

# Mapbox
MAPBOX_ACCESS_TOKEN=your-mapbox-token

# Gemini AI
GEMINI_API_KEY=your-gemini-key
```

### Scripts Utile
```bash
# Clean și rebuild
flutter clean && flutter pub get

# Analiză cod
flutter analyze

# Formatare cod
dart format .

# Teste cu coverage
flutter test --coverage
```

## 📚 Documentație

### Ghiduri Disponibile
- **[Manual de Utilizare](USER_MANUAL.md)** - Ghid complet utilizator (actualizat cu funcționalități de traducere)
- **[AI Implementation Guide](VOICE_IMPLEMENTATION_GUIDE.md)** - Implementare AI
- **[Mapbox Setup Guide](MAPBOX_SETUP_GUIDE.md)** - Configurare Mapbox
- **[Firebase Setup Guide](FIREBASE_CONSOLE_SETUP_GUIDE.md)** - Configurare Firebase
- **[Ghid de Traducere](USER_MANUAL.md#ghid-de-traducere-și-localizare)** - Instrucțiuni pentru schimbarea limbii

### API Documentation
- **[Voice AI API](lib/voice/)** - Documentație sistem vocal
- **[Services API](lib/services/)** - Documentație servicii
- **[Models API](lib/models/)** - Documentație modele

## 🤝 Contribuții

### Cum să Contribui
1. Fork repository-ul
2. Creează o ramură pentru feature (`git checkout -b feature/AmazingFeature`)
3. Commit modificările (`git commit -m 'Add some AmazingFeature'`)
4. Push la ramură (`git push origin feature/AmazingFeature`)
5. Deschide un Pull Request

### Guidelines
- Folosește `dart format` pentru formatare
- Adaugă teste pentru funcționalități noi
- Actualizează documentația
- Respectă convențiile de cod

## 📄 Licență

Acest proiect este licențiat sub licența MIT - vezi fișierul [LICENSE](LICENSE) pentru detalii.

## 👥 Echipa

- **Frontend Development** - Flutter, Dart
- **Backend Development** - Firebase, Firestore
- **AI/ML Development** - Gemini AI, Voice Processing
- **DevOps** - CI/CD, Deployment

## 📞 Contact

- **Email**: support@friendsride.com
- **Website**: https://friendsride.com
- **Documentație**: https://docs.friendsride.com

## 🙏 Mulțumiri

- **Flutter Team** - Pentru framework-ul excelent
- **Firebase Team** - Pentru backend-ul robust
- **Mapbox Team** - Pentru hărțile interactive
- **Google AI** - Pentru Gemini AI
- **Comunitatea Flutter** - Pentru suport și feedback

---

**FriendsRide** - Conectând oamenii prin tehnologie inteligentă 🚗✨