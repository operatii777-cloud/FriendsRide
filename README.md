# 🚗 FriendsRide - Intelligent Ride-Sharing App

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-10.0-orange.svg)](https://firebase.google.com/)
[![Mapbox](https://img.shields.io/badge/Mapbox-10.0-lightblue.svg)](https://mapbox.com/)
[![Analyze](https://img.shields.io/badge/flutter%20analyze-0%20issues-brightgreen.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**FriendsRide** este o aplicație de ride-sharing inteligentă care conectează pasagerii cu șoferi parteneri, oferind o experiență vocală avansată cu AI, navigație în timp real, funcționalități sociale (cadouri, referral, social login) și notificări smart.

---

## 🌟 Caracteristici Principale

### 🎤 Asistent Vocal AI (PR #1 — îmbunătățit)
- **Sincronizare TTS-STT perfectă** — STT nu mai pornește în timp ce TTS vorbește
- **Control vocal complet** — Rezervă curse prin comenzi vocale naturale
- **Beep-uri de feedback** — Indicații audio clare pentru start/stop ascultare
- **Flux AI end-to-end** — Salut → Destinație → Confirmare → Pickup → Cursă

### 🎁 Gift Ride — Cadouri de Cursă (PR #3 — nou)
- **Trimite curse cadou** — Oferi o cursă unui prieten sau familiar
- **Cod unic de revendicare** — Format `GFTxxxxxx`, valabil 365 zile
- **Revendicare simplă** — Destinatarul introduce codul la checkout
- **Gestionare cadouri** — Vizualizează cadourile trimise și statusul lor
- **State machine** — `pending → claimed / expired / cancelled`

### 👥 Sistem Referral (PR #3 — nou)
- **Cod personal** — Fiecare utilizator are un cod unic `FRxxxxxxxx`
- **Recompense duble** — Invitantul primește 15 RON, invitatul 10 RON
- **Statistici live** — Total, completate, câștiguri acumulate
- **Share nativ** — Distribuie codul prin orice aplicație instalată
- **Protecție auto-referral** — Sistemul previne abuzurile

### 🔐 Social Login (PR #3 — nou)
- **Google Sign-In** — Autentificare cu un singur tap
- **Apple Sign-In** — Suport complet iOS (Sign in with Apple)
- **Facebook Login** — Autentificare via Facebook
- **Fallback email/parolă** — Clasic, cu recuperare parolă

### 📅 Curse Programate + Notificări (PR #3 — nou)
- **Programare curse** — Setează cursă pentru o dată/oră viitoare
- **Notificări locale** — Reminder automat cu 30 min înainte
- **Toggle notificări** — Activează/dezactivează per cursă
- **Gestionare listă** — Adaugă, modifică, șterge curse programate

### 🧭 Onboarding Wizard (PR #3 — nou)
- **Tutorial pas cu pas** — 4 ecrane animate pentru utilizatori noi
- **Prezentare funcționalități** — Hartă, vocal AI, plăți, siguranță
- **Skip oricând** — Utilizatorul poate sări tutorialul

### 🗺️ Hartă Interactivă + Heatmap Cerere (PR #3 — nou)
- **Heatmap vizual** — Gradient color pentru densitatea cererii (verde → galben → roșu)
- **Grilă suprapusă** — Ajutor vizual pentru zone de cerere
- **Date tempo real** — `HeatmapPoint` cu latitudine, longitudine, intensitate
- **POI-uri inteligente** — Clustering GPU, zoom gates, max 200 POI-uri

### 💸 Ride Sharing Avansat (PR #3 — îmbunătățit)
- **Algoritm Haversine** — Distanță precisă între coordonate GPS
- **Prag compatibilitate** — Pickup < 2 km + Destinație < 2 km
- **Matching static testabil** — `RideSharingService.areRoutesCompatible(s1, s2)`
- **Mesaje sistem automate** — Notificare în chat la match confirmat
- **Reducere 30%** — Cost partajat calculat automat

### 🔔 Multiple Stops + Surge Pricing (PR #3 — nou)
- **Multiple opriri** — Adaugă până la N opriri intermediare pe traseu
- **Surge pricing transparent** — Widget dedicat care explică multiplicatorul prețului
- **Acceptance timer** — Countdown animat pentru acceptarea cursei de șofer

### 🎨 Sistem Design Unificat (PR #3 — nou)
- **`AppColors`** — Paletă cromatică centralizată (primary, secondary, background, surface, error, textHint, border)
- **`AppTextStyles`** — Tipografie consistentă (heading1-4, bodySmall/Medium/Large, button)
- **Dark/Light mode ready** — Structură pregătită pentru teme multiple

---

## Functionalitati Verificate si Implementate

### PromotionService in UI
- PromotionWidget integrat direct in ecranul de rezervare cursa (ride_request_screen)
- Utilizatorul introduce codul promotional inainte de confirmare; discount aplicat automat
- Accesibil cu screen readers (Semantics wrapper)

### Transmitere ride_preferences
- Modelul Ride include campul optional ridePreferences (serializat in Firestore)
- Preferintele utilizatorului sunt incarcate la initierea ecranului de rezervare
- Stocate la users/{userId}.ridePreferences, editabile din profilul de cont

### Loyalty Program Automatizat
- LoyaltyProgramService.updateLoyaltyAfterRide() apelat automat dupa finalizarea cursei
- Upgrade tier automat: Bronze -> Silver -> Gold -> Platinum -> Diamond
- Fara actiune manuala necesara din partea utilizatorului

### Driver Incentives - Ecran Dedicat (DriverIncentivesScreen)
- Ecran complet cu taburi Active / Completate
- Card rezumat cu numar de incentives si castiguri potentiale in RON
- Bottom sheet cu detalii per incentive (progres, recompensa, data expirare)
- Navigare directa din Driver Dashboard

### Price Estimate - Vizibil in UI
- EnhancedPriceEstimateWidget afisat in RideConfirmationView
- Afiseaza preturile pentru toate categoriile (Standard, Familie, Ecologic, Premium)
- price_estimate_service.dart cu calcul complet (baza + per-km + per-minut + surge)

### Surge Map - Widget Dedicat (SurgeMapWidget)
- Widget separat de heatmap, dedicat zonelor de surge pricing
- Date live din Firestore (colectia surge_zones) prin Stream
- Animatie pulsatorie pentru zone cu surge ridicat (>2x)
- Legenda vizuala: verde (normal) -> galben -> portocaliu -> rosu

### Accesibilitate (Semantics / Screen Reader)
- Semantics adaugat in: PromotionWidget, LoyaltyTierWidget, DriverIncentivesScreen, SurgeMapWidget
- Labels descriptive pentru VoiceOver (iOS) si TalkBack (Android)
- Butoane si widget-uri critice cu etichete clare

### Protectie Date (GDPR) - Audit Firestore
- Comentariu de audit complet in firestore.rules cu principii GDPR aplicate
- Reguli noi: loyalty_programs (owner-only), promotions (read-only client),
  promotion_uses (creare client, fara modificare), surge_zones (backend-only write)
- Subcollection users/{userId}/preferences protejata exclusiv pentru proprietar
- Deny-by-default: colectii fara reguli explicite sunt interzise

### Compatibilitate Platforme
- Android: API 24+ (confirmat functional)
- iOS: iOS 12+ (confirmat functional)
- Web: Flutter Web + PWA manifest (index.html, manifest.json)
- Linux: CMakeLists.txt configurat
- Windows: Visual Studio runner configurat

---

## 📁 Structura Proiectului

```
lib/
├── main.dart                          # Entry point + routes
├── theme/
│   ├── app_colors.dart                # ✨ Nou: paleta de culori centralizată
│   └── app_text_styles.dart           # ✨ Nou: stiluri text unificate
├── models/
│   ├── gift_ride_model.dart           # ✨ Nou: model cadou cursă
│   ├── referral_model.dart            # ✨ Nou: model referral + ReferralStats
│   ├── ride_model.dart
│   ├── ride_sharing_model.dart
│   └── ...
├── services/
│   ├── gift_ride_service.dart         # ✨ Nou: trimitere, revendicare, anulare
│   ├── referral_service.dart          # ✨ Nou: coduri referral, statistici, recompense
│   ├── local_notifications_service.dart # ✨ Nou: notificări locale programate
│   ├── social_auth_service.dart       # ✨ Nou: Google/Apple/Facebook auth
│   ├── ride_sharing_service.dart      # ✅ Îmbunătățit: matching avansat + static API
│   ├── firestore_service.dart
│   └── ...
├── screens/
│   ├── gift_ride_screen.dart          # ✨ Nou: UI trimitere + vizualizare cadouri
│   ├── referral_screen.dart           # ✨ Nou: UI cod referral + statistici + listă
│   ├── onboarding_wizard_screen.dart  # ✨ Nou: tutorial utilizatori noi
│   ├── social_login_screen.dart       # ✨ Nou: ecran login social
│   ├── scheduled_ride_notifications_screen.dart # ✨ Nou: curse programate
│   └── ...
├── widgets/
│   ├── acceptance_timer_widget.dart   # ✨ Nou: countdown acceptare șofer
│   ├── heatmap_widget.dart            # ✨ Nou: heatmap cerere cu CustomPainter
│   ├── multiple_stops_widget.dart     # ✨ Nou: opriri multiple pe traseu
│   ├── surge_pricing_transparency_widget.dart # ✨ Nou: explicație surge pricing
│   └── ...
├── utils/
│   └── logger.dart                    # ✨ Nou: logger structurat (debug/info/warning/error)
└── voice/                             # ✅ Îmbunătățit: PR #1 sync TTS-STT
    ├── ai/
    ├── core/
    ├── integration/
    ├── passenger/
    ├── ride/
    └── tts/
```

---

## 🚀 Instalare și Configurare

### Cerințe de Sistem
- **Android**: 7.0 (API level 24) sau mai nou
- **iOS**: 12.0 sau mai nou
- **Flutter**: 3.16+ / **Dart**: 3.2+

### Instalare
```bash
git clone https://github.com/operatii777-cloud/FriendsRide.git
cd FriendsRide
flutter pub get

# Configurează Firebase (google-services.json + GoogleService-Info.plist)
# Configurează Mapbox token în lib/utils/mapbox_config.dart
# Configurează Gemini API key

flutter run
```

### Variabile de Mediu
```bash
MAPBOX_ACCESS_TOKEN=pk.xxx
GEMINI_API_KEY=AIzaSy...
```

---

## 🎤 Fluxul Vocal AI

```
Utilizator apasă buton AI
  → TTS: "Bună ziua! Unde doriți să mergeți?"
  → STT pornește (după ce TTS termină — fix PR #1)
  → Utilizator: "La aeroport"
  → AI confirmă destinația
  → STT pentru pickup (dacă necesar)
  → Cursă rezervată
```

**Comenzi vocale disponibile:**
| Comandă | Acțiune |
|---------|---------|
| `"Solicită cursă"` | Începe rezervarea |
| `"Către [destinație]"` | Setează destinația |
| `"De la [adresă]"` | Setează pickup |
| `"Anulează"` | Anulează cursa curentă |
| `"Unde sunt?"` | Afișează locația curentă |
| `"Sună șoferul"` | Apelează șoferul activ |

---

## 🎁 Flux Gift Ride

```
Expeditor → completează formular (nume, email/telefon, sumă, mesaj)
  → GiftRideService.sendGiftRide() → cod unic generat + salvat în Firestore
  → Destinatar primește codul (email/SMS extern)
  → Destinatar → introduce codul la checkout
  → GiftRideService.claimGiftRide(cod, userId) → suma creditată
```

---

## 👥 Flux Referral

```
Utilizator A → ReferralService.getReferralCode(uid) → cod "FR12345678"
  → Share nativ → Utilizator B se înregistrează cu codul
  → ReferralService.processReferralCode(cod, newUserId)
  → Referral creat în Firestore
  → Utilizator B face prima cursă → rewardedAt setat
  → A primește 15 RON + B primește 10 RON
```

---

## 🧪 Testare

```bash
# Toate testele
flutter test

# Test matching ride sharing
flutter test test/ride_sharing_service_test.dart

# Analiză cod (0 issues)
flutter analyze --no-fatal-infos

# Integration tests
flutter test integration_test/
```

**Stare curentă analiză:**
```
No issues found! ✅  (0 errors, 0 warnings, 0 infos)
```

---

## 📊 Servicii Principale

| Serviciu | Responsabilitate |
|---------|----------------|
| `FirestoreService` | CRUD Firestore cu retry logic |
| `GiftRideService` | Cadouri curse (creare, revendicare, anulare) |
| `ReferralService` | Coduri referral, statistici, recompense |
| `RideSharingService` | Matching pasageri (algoritm Haversine) |
| `LocalNotificationsService` | Notificări locale programate |
| `SocialAuthService` | Google / Apple / Facebook autentificare |
| `RoutingService` | Calculare trasee Mapbox |
| `VoiceOrchestrator` | Sincronizare TTS ↔ STT |
| `GeminiVoiceEngine` | Procesare AI comenzi vocale |
| `RealTimeTrackingService` | Tracking GPS timp real |

---

## 🌍 Localizare

| Fișier | Limbă | Strings |
|--------|-------|---------|
| `lib/l10n/app_ro.arb` | Română (implicită) | 223+ |
| `lib/l10n/app_en.arb` | Engleză | 223+ |

Schimbare limbă: **Meniu hamburger → Limba**. Alegerea se salvează automat.

---

## 📈 Performanță

- **GPU rendering** — Mapbox + CustomPainter pentru heatmap
- **Clustering POI** — Max 200 POI-uri, zoom gates
- **TTS-STT sync** — Eliminat race condition (PR #1)
- **Lazy loading** — Servicii inițializate la cerere
- **Logger structurat** — `Logger.debug/info/warning/error` cu tag și stack trace

---

## 🔧 Routes Înregistrate în main.dart

```dart
routes: {
  '/onboarding': (_) => const OnboardingWizardScreen(),
  '/login':      (_) => const SocialLoginScreen(),
  '/referral':   (_) => const ReferralScreen(),
  '/gift-ride':  (_) => const GiftRideScreen(),
  '/scheduled-rides': (_) => const ScheduledRideNotificationsScreen(),
}
```

---

## 📚 Documentație

- **[AI Implementation Guide](VOICE_IMPLEMENTATION_GUIDE.md)**
- **[Complete Mapbox Setup](COMPLETE_MAPBOX_SETUP.md)**
- **[Firebase Setup Guide](FIREBASE_CONSOLE_SETUP_GUIDE.md)**
- **[Flux End-to-End](FLUX_APLICATIE_END_TO_END.md)**

---

## 🤝 Contribuții

1. Fork repository-ul
2. Creează ramură: `git checkout -b feature/NumeFeature`
3. Commit: `git commit -m 'Add NumeFeature'`
4. Push: `git push origin feature/NumeFeature`
5. Deschide Pull Request

**Before PR:** `flutter analyze --no-fatal-infos` trebuie să returneze `No issues found!`

---

## 📄 Licență

MIT License — vezi [LICENSE](LICENSE).

---

## 📞 Contact

- **Email**: support@friendsride.com
- **GitHub**: https://github.com/operatii777-cloud/FriendsRide

---

*FriendsRide — Conectând oamenii prin tehnologie inteligentă 🚗✨*
*Ultima actualizare: Martie 2026 — PR #1 (Voice sync) + PR #3 (Gift, Referral, Social Login, Scheduled Rides, Heatmap, Onboarding)*
---

## ✅ Funcționalități Verificate și Implementate

### 🎁 PromotionService în UI
- **PromotionWidget** integrat în ecranul de rezervare cursă – utilizatorul poate introduce un cod promoțional direct la booking
- Discount-ul aplicat reduce automat costul total al cursei
- Accesibil cu screen readers (Semantics)

### 🏅 Transmitere ride_preferences
- **Modelul ** include câmpul opțional  (serializat în Firestore)
- Preferințele salvate ale utilizatorului sunt încărcate automat la deschiderea ecranului de rezervare
- Stocate la  – editabile din profilul de cont

### 🏆 Loyalty Program Automatizat
-  apelat automat la finalizarea cursei
- Upgrade tier automat: Bronze → Silver → Gold → Platinum → Diamond

### 🚗 Driver Incentives – Ecran Dedicat ()
- Ecran complet cu taburi Active / Completate
- Card rezumat cu câștiguri potențiale
- Bottom sheet cu detalii per incentive
- Navigare directă din Dashboard-ul șoferului

### 💰 Price Estimate – Vizibil în UI
-  afișat în  – arată prețurile per categorie
-  – calcul complet cu bază, per-km, per-minut, surge

### 🔥 Surge Map – Widget Dedicat
- **** – widget separat de heatmap, streaming date live din 
- Animație pulsatorie pentru zone cu surge ridicat
- Legendă vizuală: verde (normal) → galben → portocaliu → roșu

### ♿ Accesibilitate (Semantics)
-  adăugat în: , , , 
- Labels pentru VoiceOver (iOS) și TalkBack (Android)

### 🔐 Protecție Date (GDPR) – Audit Firestore
- Comentariu de audit complet în  (principii GDPR, deny-by-default)
- Reguli noi:  (owner-only),  (read-only),  (backend-only write)
- Subcollection  protejată exclusiv pentru proprietar

### 📱 Compatibilitate Platforme
- ✅ Android (API 24+), ✅ iOS (12+), ✅ Web (Flutter Web / PWA)
- ✅ Linux (CMakeLists.txt), ✅ Windows (Visual Studio runner)

🚗 FriendsRide - Intelligent Ride-Sharing App

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-10.0-orange.svg)](https://firebase.google.com/)
[![Mapbox](https://img.shields.io/badge/Mapbox-10.0-lightblue.svg)](https://mapbox.com/)
[![Analyze](https://img.shields.io/badge/flutter%20analyze-0%20issues-brightgreen.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**FriendsRide** este o aplicație de ride-sharing inteligentă care conectează pasagerii cu șoferi parteneri, oferind o experiență vocală avansată cu AI, navigație în timp real, funcționalități sociale (cadouri, referral, social login) și notificări smart.

---

## 🌟 Caracteristici Principale

### 🎤 Asistent Vocal AI (PR #1 — îmbunătățit)
- **Sincronizare TTS-STT perfectă** — STT nu mai pornește în timp ce TTS vorbește
- **Control vocal complet** — Rezervă curse prin comenzi vocale naturale
- **Beep-uri de feedback** — Indicații audio clare pentru start/stop ascultare
- **Flux AI end-to-end** — Salut → Destinație → Confirmare → Pickup → Cursă

### 🎁 Gift Ride — Cadouri de Cursă (PR #3 — nou)
- **Trimite curse cadou** — Oferi o cursă unui prieten sau familiar
- **Cod unic de revendicare** — Format `GFTxxxxxx`, valabil 365 zile
- **Revendicare simplă** — Destinatarul introduce codul la checkout
- **Gestionare cadouri** — Vizualizează cadourile trimise și statusul lor
- **State machine** — `pending → claimed / expired / cancelled`

### 👥 Sistem Referral (PR #3 — nou)
- **Cod personal** — Fiecare utilizator are un cod unic `FRxxxxxxxx`
- **Recompense duble** — Invitantul primește 15 RON, invitatul 10 RON
- **Statistici live** — Total, completate, câștiguri acumulate
- **Share nativ** — Distribuie codul prin orice aplicație instalată
- **Protecție auto-referral** — Sistemul previne abuzurile

### 🔐 Social Login (PR #3 — nou)
- **Google Sign-In** — Autentificare cu un singur tap
- **Apple Sign-In** — Suport complet iOS (Sign in with Apple)
- **Facebook Login** — Autentificare via Facebook
- **Fallback email/parolă** — Clasic, cu recuperare parolă

### 📅 Curse Programate + Notificări (PR #3 — nou)
- **Programare curse** — Setează cursă pentru o dată/oră viitoare
- **Notificări locale** — Reminder automat cu 30 min înainte
- **Toggle notificări** — Activează/dezactivează per cursă
- **Gestionare listă** — Adaugă, modifică, șterge curse programate

### 🧭 Onboarding Wizard (PR #3 — nou)
- **Tutorial pas cu pas** — 4 ecrane animate pentru utilizatori noi
- **Prezentare funcționalități** — Hartă, vocal AI, plăți, siguranță
- **Skip oricând** — Utilizatorul poate sări tutorialul

### 🗺️ Hartă Interactivă + Heatmap Cerere (PR #3 — nou)
- **Heatmap vizual** — Gradient color pentru densitatea cererii (verde → galben → roșu)
- **Grilă suprapusă** — Ajutor vizual pentru zone de cerere
- **Date tempo real** — `HeatmapPoint` cu latitudine, longitudine, intensitate
- **POI-uri inteligente** — Clustering GPU, zoom gates, max 200 POI-uri

### 💸 Ride Sharing Avansat (PR #3 — îmbunătățit)
- **Algoritm Haversine** — Distanță precisă între coordonate GPS
- **Prag compatibilitate** — Pickup < 2 km + Destinație < 2 km
- **Matching static testabil** — `RideSharingService.areRoutesCompatible(s1, s2)`
- **Mesaje sistem automate** — Notificare în chat la match confirmat
- **Reducere 30%** — Cost partajat calculat automat

### 🔔 Multiple Stops + Surge Pricing (PR #3 — nou)
- **Multiple opriri** — Adaugă până la N opriri intermediare pe traseu
- **Surge pricing transparent** — Widget dedicat care explică multiplicatorul prețului
- **Acceptance timer** — Countdown animat pentru acceptarea cursei de șofer

### 🎨 Sistem Design Unificat (PR #3 — nou)
- **`AppColors`** — Paletă cromatică centralizată (primary, secondary, background, surface, error, textHint, border)
- **`AppTextStyles`** — Tipografie consistentă (heading1-4, bodySmall/Medium/Large, button)
- **Dark/Light mode ready** — Structură pregătită pentru teme multiple

---

## 📁 Structura Proiectului

```
lib/
├── main.dart                          # Entry point + routes
├── theme/
│   ├── app_colors.dart                # ✨ Nou: paleta de culori centralizată
│   └── app_text_styles.dart           # ✨ Nou: stiluri text unificate
├── models/
│   ├── gift_ride_model.dart           # ✨ Nou: model cadou cursă
│   ├── referral_model.dart            # ✨ Nou: model referral + ReferralStats
│   ├── ride_model.dart
│   ├── ride_sharing_model.dart
│   └── ...
├── services/
│   ├── gift_ride_service.dart         # ✨ Nou: trimitere, revendicare, anulare
│   ├── referral_service.dart          # ✨ Nou: coduri referral, statistici, recompense
│   ├── local_notifications_service.dart # ✨ Nou: notificări locale programate
│   ├── social_auth_service.dart       # ✨ Nou: Google/Apple/Facebook auth
│   ├── ride_sharing_service.dart      # ✅ Îmbunătățit: matching avansat + static API
│   ├── firestore_service.dart
│   └── ...
├── screens/
│   ├── gift_ride_screen.dart          # ✨ Nou: UI trimitere + vizualizare cadouri
│   ├── referral_screen.dart           # ✨ Nou: UI cod referral + statistici + listă
│   ├── onboarding_wizard_screen.dart  # ✨ Nou: tutorial utilizatori noi
│   ├── social_login_screen.dart       # ✨ Nou: ecran login social
│   ├── scheduled_ride_notifications_screen.dart # ✨ Nou: curse programate
│   └── ...
├── widgets/
│   ├── acceptance_timer_widget.dart   # ✨ Nou: countdown acceptare șofer
│   ├── heatmap_widget.dart            # ✨ Nou: heatmap cerere cu CustomPainter
│   ├── multiple_stops_widget.dart     # ✨ Nou: opriri multiple pe traseu
│   ├── surge_pricing_transparency_widget.dart # ✨ Nou: explicație surge pricing
│   └── ...
├── utils/
│   └── logger.dart                    # ✨ Nou: logger structurat (debug/info/warning/error)
└── voice/                             # ✅ Îmbunătățit: PR #1 sync TTS-STT
    ├── ai/
    ├── core/
    ├── integration/
    ├── passenger/
    ├── ride/
    └── tts/
```

---

## 🚀 Instalare și Configurare

### Cerințe de Sistem
- **Android**: 7.0 (API level 24) sau mai nou
- **iOS**: 12.0 sau mai nou
- **Flutter**: 3.16+ / **Dart**: 3.2+

### Instalare
```bash
git clone https://github.com/operatii777-cloud/FriendsRide.git
cd FriendsRide
flutter pub get

# Configurează Firebase (google-services.json + GoogleService-Info.plist)
# Configurează Mapbox token în lib/utils/mapbox_config.dart
# Configurează Gemini API key

flutter run
```

### Variabile de Mediu
```bash
MAPBOX_ACCESS_TOKEN=pk.xxx
GEMINI_API_KEY=AIzaSy...
```

---

## 🎤 Fluxul Vocal AI

```
Utilizator apasă buton AI
  → TTS: "Bună ziua! Unde doriți să mergeți?"
  → STT pornește (după ce TTS termină — fix PR #1)
  → Utilizator: "La aeroport"
  → AI confirmă destinația
  → STT pentru pickup (dacă necesar)
  → Cursă rezervată
```

**Comenzi vocale disponibile:**
| Comandă | Acțiune |
|---------|---------|
| `"Solicită cursă"` | Începe rezervarea |
| `"Către [destinație]"` | Setează destinația |
| `"De la [adresă]"` | Setează pickup |
| `"Anulează"` | Anulează cursa curentă |
| `"Unde sunt?"` | Afișează locația curentă |
| `"Sună șoferul"` | Apelează șoferul activ |

---

## 🎁 Flux Gift Ride

```
Expeditor → completează formular (nume, email/telefon, sumă, mesaj)
  → GiftRideService.sendGiftRide() → cod unic generat + salvat în Firestore
  → Destinatar primește codul (email/SMS extern)
  → Destinatar → introduce codul la checkout
  → GiftRideService.claimGiftRide(cod, userId) → suma creditată
```

---

## 👥 Flux Referral

```
Utilizator A → ReferralService.getReferralCode(uid) → cod "FR12345678"
  → Share nativ → Utilizator B se înregistrează cu codul
  → ReferralService.processReferralCode(cod, newUserId)
  → Referral creat în Firestore
  → Utilizator B face prima cursă → rewardedAt setat
  → A primește 15 RON + B primește 10 RON
```

---

## 🧪 Testare

```bash
# Toate testele
flutter test

# Test matching ride sharing
flutter test test/ride_sharing_service_test.dart

# Analiză cod (0 issues)
flutter analyze --no-fatal-infos

# Integration tests
flutter test integration_test/
```

**Stare curentă analiză:**
```
No issues found! ✅  (0 errors, 0 warnings, 0 infos)
```

---

## 📊 Servicii Principale

| Serviciu | Responsabilitate |
|---------|----------------|
| `FirestoreService` | CRUD Firestore cu retry logic |
| `GiftRideService` | Cadouri curse (creare, revendicare, anulare) |
| `ReferralService` | Coduri referral, statistici, recompense |
| `RideSharingService` | Matching pasageri (algoritm Haversine) |
| `LocalNotificationsService` | Notificări locale programate |
| `SocialAuthService` | Google / Apple / Facebook autentificare |
| `RoutingService` | Calculare trasee Mapbox |
| `VoiceOrchestrator` | Sincronizare TTS ↔ STT |
| `GeminiVoiceEngine` | Procesare AI comenzi vocale |
| `RealTimeTrackingService` | Tracking GPS timp real |

---

## 🌍 Localizare

| Fișier | Limbă | Strings |
|--------|-------|---------|
| `lib/l10n/app_ro.arb` | Română (implicită) | 223+ |
| `lib/l10n/app_en.arb` | Engleză | 223+ |

Schimbare limbă: **Meniu hamburger → Limba**. Alegerea se salvează automat.

---

## 📈 Performanță

- **GPU rendering** — Mapbox + CustomPainter pentru heatmap
- **Clustering POI** — Max 200 POI-uri, zoom gates
- **TTS-STT sync** — Eliminat race condition (PR #1)
- **Lazy loading** — Servicii inițializate la cerere
- **Logger structurat** — `Logger.debug/info/warning/error` cu tag și stack trace

---

## 🔧 Routes Înregistrate în main.dart

```dart
routes: {
  '/onboarding': (_) => const OnboardingWizardScreen(),
  '/login':      (_) => const SocialLoginScreen(),
  '/referral':   (_) => const ReferralScreen(),
  '/gift-ride':  (_) => const GiftRideScreen(),
  '/scheduled-rides': (_) => const ScheduledRideNotificationsScreen(),
}
```

---

## 📚 Documentație

- **[AI Implementation Guide](VOICE_IMPLEMENTATION_GUIDE.md)**
- **[Complete Mapbox Setup](COMPLETE_MAPBOX_SETUP.md)**
- **[Firebase Setup Guide](FIREBASE_CONSOLE_SETUP_GUIDE.md)**
- **[Flux End-to-End](FLUX_APLICATIE_END_TO_END.md)**

---

## 🤝 Contribuții

1. Fork repository-ul
2. Creează ramură: `git checkout -b feature/NumeFeature`
3. Commit: `git commit -m 'Add NumeFeature'`
4. Push: `git push origin feature/NumeFeature`
5. Deschide Pull Request

**Before PR:** `flutter analyze --no-fatal-infos` trebuie să returneze `No issues found!`

---

## 📄 Licență

MIT License — vezi [LICENSE](LICENSE).

---

## 📞 Contact

- **Email**: support@friendsride.com
- **GitHub**: https://github.com/operatii777-cloud/FriendsRide

---

*FriendsRide — Conectând oamenii prin tehnologie inteligentă 🚗✨*
*Ultima actualizare: Martie 2026 — PR #1 (Voice sync) + PR #3 (Gift, Referral, Social Login, Scheduled Rides, Heatmap, Onboarding)*

