# ðŸš— FriendsRide - Intelligent Ride-Sharing App

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-10.0-orange.svg)](https://firebase.google.com/)
[![Mapbox](https://img.shields.io/badge/Mapbox-10.0-lightblue.svg)](https://mapbox.com/)
[![Analyze](https://img.shields.io/badge/flutter%20analyze-0%20issues-brightgreen.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**FriendsRide** este o aplicaÈ›ie de ride-sharing inteligentÄƒ care conecteazÄƒ pasagerii cu È™oferi parteneri, oferind o experienÈ›Äƒ vocalÄƒ avansatÄƒ cu AI, navigaÈ›ie Ã®n timp real, funcÈ›ionalitÄƒÈ›i sociale (cadouri, referral, social login) È™i notificÄƒri smart.

---

## ðŸŒŸ Caracteristici Principale

### ðŸŽ¤ Asistent Vocal AI (PR #1 â€” Ã®mbunÄƒtÄƒÈ›it)
- **Sincronizare TTS-STT perfectÄƒ** â€” STT nu mai porneÈ™te Ã®n timp ce TTS vorbeÈ™te
- **Control vocal complet** â€” RezervÄƒ curse prin comenzi vocale naturale
- **Beep-uri de feedback** â€” IndicaÈ›ii audio clare pentru start/stop ascultare
- **Flux AI end-to-end** â€” Salut â†’ DestinaÈ›ie â†’ Confirmare â†’ Pickup â†’ CursÄƒ

### ðŸŽ Gift Ride â€” Cadouri de CursÄƒ (PR #3 â€” nou)
- **Trimite curse cadou** â€” Oferi o cursÄƒ unui prieten sau familiar
- **Cod unic de revendicare** â€” Format `GFTxxxxxx`, valabil 365 zile
- **Revendicare simplÄƒ** â€” Destinatarul introduce codul la checkout
- **Gestionare cadouri** â€” VizualizeazÄƒ cadourile trimise È™i statusul lor
- **State machine** â€” `pending â†’ claimed / expired / cancelled`

### ðŸ‘¥ Sistem Referral (PR #3 â€” nou)
- **Cod personal** â€” Fiecare utilizator are un cod unic `FRxxxxxxxx`
- **Recompense duble** â€” Invitantul primeÈ™te 15 RON, invitatul 10 RON
- **Statistici live** â€” Total, completate, cÃ¢È™tiguri acumulate
- **Share nativ** â€” Distribuie codul prin orice aplicaÈ›ie instalatÄƒ
- **ProtecÈ›ie auto-referral** â€” Sistemul previne abuzurile

### ðŸ” Social Login (PR #3 â€” nou)
- **Google Sign-In** â€” Autentificare cu un singur tap
- **Apple Sign-In** â€” Suport complet iOS (Sign in with Apple)
- **Facebook Login** â€” Autentificare via Facebook
- **Fallback email/parolÄƒ** â€” Clasic, cu recuperare parolÄƒ

### ðŸ“… Curse Programate + NotificÄƒri (PR #3 â€” nou)
- **Programare curse** â€” SeteazÄƒ cursÄƒ pentru o datÄƒ/orÄƒ viitoare
- **NotificÄƒri locale** â€” Reminder automat cu 30 min Ã®nainte
- **Toggle notificÄƒri** â€” ActiveazÄƒ/dezactiveazÄƒ per cursÄƒ
- **Gestionare listÄƒ** â€” AdaugÄƒ, modificÄƒ, È™terge curse programate

### ðŸ§­ Onboarding Wizard (PR #3 â€” nou)
- **Tutorial pas cu pas** â€” 4 ecrane animate pentru utilizatori noi
- **Prezentare funcÈ›ionalitÄƒÈ›i** â€” HartÄƒ, vocal AI, plÄƒÈ›i, siguranÈ›Äƒ
- **Skip oricÃ¢nd** â€” Utilizatorul poate sÄƒri tutorialul

### ðŸ—ºï¸ HartÄƒ InteractivÄƒ + Heatmap Cerere (PR #3 â€” nou)
- **Heatmap vizual** â€” Gradient color pentru densitatea cererii (verde â†’ galben â†’ roÈ™u)
- **GrilÄƒ suprapusÄƒ** â€” Ajutor vizual pentru zone de cerere
- **Date tempo real** â€” `HeatmapPoint` cu latitudine, longitudine, intensitate
- **POI-uri inteligente** â€” Clustering GPU, zoom gates, max 200 POI-uri

### ðŸ’¸ Ride Sharing Avansat (PR #3 â€” Ã®mbunÄƒtÄƒÈ›it)
- **Algoritm Haversine** â€” DistanÈ›Äƒ precisÄƒ Ã®ntre coordonate GPS
- **Prag compatibilitate** â€” Pickup < 2 km + DestinaÈ›ie < 2 km
- **Matching static testabil** â€” `RideSharingService.areRoutesCompatible(s1, s2)`
- **Mesaje sistem automate** â€” Notificare Ã®n chat la match confirmat
- **Reducere 30%** â€” Cost partajat calculat automat

### ðŸ”” Multiple Stops + Surge Pricing (PR #3 â€” nou)
- **Multiple opriri** â€” AdaugÄƒ pÃ¢nÄƒ la N opriri intermediare pe traseu
- **Surge pricing transparent** â€” Widget dedicat care explicÄƒ multiplicatorul preÈ›ului
- **Acceptance timer** â€” Countdown animat pentru acceptarea cursei de È™ofer

### ðŸŽ¨ Sistem Design Unificat (PR #3 â€” nou)
- **`AppColors`** â€” PaletÄƒ cromaticÄƒ centralizatÄƒ (primary, secondary, background, surface, error, textHint, border)
- **`AppTextStyles`** â€” Tipografie consistentÄƒ (heading1-4, bodySmall/Medium/Large, button)
- **Dark/Light mode ready** â€” StructurÄƒ pregÄƒtitÄƒ pentru teme multiple

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

## ðŸ“ Structura Proiectului

```
lib/
â”œâ”€â”€ main.dart                          # Entry point + routes
â”œâ”€â”€ theme/
â”‚   â”œâ”€â”€ app_colors.dart                # âœ¨ Nou: paleta de culori centralizatÄƒ
â”‚   â””â”€â”€ app_text_styles.dart           # âœ¨ Nou: stiluri text unificate
â”œâ”€â”€ models/
â”‚   â”œâ”€â”€ gift_ride_model.dart           # âœ¨ Nou: model cadou cursÄƒ
â”‚   â”œâ”€â”€ referral_model.dart            # âœ¨ Nou: model referral + ReferralStats
â”‚   â”œâ”€â”€ ride_model.dart
â”‚   â”œâ”€â”€ ride_sharing_model.dart
â”‚   â””â”€â”€ ...
â”œâ”€â”€ services/
â”‚   â”œâ”€â”€ gift_ride_service.dart         # âœ¨ Nou: trimitere, revendicare, anulare
â”‚   â”œâ”€â”€ referral_service.dart          # âœ¨ Nou: coduri referral, statistici, recompense
â”‚   â”œâ”€â”€ local_notifications_service.dart # âœ¨ Nou: notificÄƒri locale programate
â”‚   â”œâ”€â”€ social_auth_service.dart       # âœ¨ Nou: Google/Apple/Facebook auth
â”‚   â”œâ”€â”€ ride_sharing_service.dart      # âœ… ÃŽmbunÄƒtÄƒÈ›it: matching avansat + static API
â”‚   â”œâ”€â”€ firestore_service.dart
â”‚   â””â”€â”€ ...
â”œâ”€â”€ screens/
â”‚   â”œâ”€â”€ gift_ride_screen.dart          # âœ¨ Nou: UI trimitere + vizualizare cadouri
â”‚   â”œâ”€â”€ referral_screen.dart           # âœ¨ Nou: UI cod referral + statistici + listÄƒ
â”‚   â”œâ”€â”€ onboarding_wizard_screen.dart  # âœ¨ Nou: tutorial utilizatori noi
â”‚   â”œâ”€â”€ social_login_screen.dart       # âœ¨ Nou: ecran login social
â”‚   â”œâ”€â”€ scheduled_ride_notifications_screen.dart # âœ¨ Nou: curse programate
â”‚   â””â”€â”€ ...
â”œâ”€â”€ widgets/
â”‚   â”œâ”€â”€ acceptance_timer_widget.dart   # âœ¨ Nou: countdown acceptare È™ofer
â”‚   â”œâ”€â”€ heatmap_widget.dart            # âœ¨ Nou: heatmap cerere cu CustomPainter
â”‚   â”œâ”€â”€ multiple_stops_widget.dart     # âœ¨ Nou: opriri multiple pe traseu
â”‚   â”œâ”€â”€ surge_pricing_transparency_widget.dart # âœ¨ Nou: explicaÈ›ie surge pricing
â”‚   â””â”€â”€ ...
â”œâ”€â”€ utils/
â”‚   â””â”€â”€ logger.dart                    # âœ¨ Nou: logger structurat (debug/info/warning/error)
â””â”€â”€ voice/                             # âœ… ÃŽmbunÄƒtÄƒÈ›it: PR #1 sync TTS-STT
    â”œâ”€â”€ ai/
    â”œâ”€â”€ core/
    â”œâ”€â”€ integration/
    â”œâ”€â”€ passenger/
    â”œâ”€â”€ ride/
    â””â”€â”€ tts/
```

---

## ðŸš€ Instalare È™i Configurare

### CerinÈ›e de Sistem
- **Android**: 7.0 (API level 24) sau mai nou
- **iOS**: 12.0 sau mai nou
- **Flutter**: 3.16+ / **Dart**: 3.2+

### Instalare
```bash
git clone https://github.com/operatii777-cloud/FriendsRide.git
cd FriendsRide
flutter pub get

# ConfigureazÄƒ Firebase (google-services.json + GoogleService-Info.plist)
# ConfigureazÄƒ Mapbox token Ã®n lib/utils/mapbox_config.dart
# ConfigureazÄƒ Gemini API key

flutter run
```

### Variabile de Mediu
```bash
MAPBOX_ACCESS_TOKEN=pk.xxx
GEMINI_API_KEY=AIzaSy...
```

---

## ðŸŽ¤ Fluxul Vocal AI

```
Utilizator apasÄƒ buton AI
  â†’ TTS: "BunÄƒ ziua! Unde doriÈ›i sÄƒ mergeÈ›i?"
  â†’ STT porneÈ™te (dupÄƒ ce TTS terminÄƒ â€” fix PR #1)
  â†’ Utilizator: "La aeroport"
  â†’ AI confirmÄƒ destinaÈ›ia
  â†’ STT pentru pickup (dacÄƒ necesar)
  â†’ CursÄƒ rezervatÄƒ
```

**Comenzi vocale disponibile:**
| ComandÄƒ | AcÈ›iune |
|---------|---------|
| `"SolicitÄƒ cursÄƒ"` | ÃŽncepe rezervarea |
| `"CÄƒtre [destinaÈ›ie]"` | SeteazÄƒ destinaÈ›ia |
| `"De la [adresÄƒ]"` | SeteazÄƒ pickup |
| `"AnuleazÄƒ"` | AnuleazÄƒ cursa curentÄƒ |
| `"Unde sunt?"` | AfiÈ™eazÄƒ locaÈ›ia curentÄƒ |
| `"SunÄƒ È™oferul"` | ApeleazÄƒ È™oferul activ |

---

## ðŸŽ Flux Gift Ride

```
Expeditor â†’ completeazÄƒ formular (nume, email/telefon, sumÄƒ, mesaj)
  â†’ GiftRideService.sendGiftRide() â†’ cod unic generat + salvat Ã®n Firestore
  â†’ Destinatar primeÈ™te codul (email/SMS extern)
  â†’ Destinatar â†’ introduce codul la checkout
  â†’ GiftRideService.claimGiftRide(cod, userId) â†’ suma creditatÄƒ
```

---

## ðŸ‘¥ Flux Referral

```
Utilizator A â†’ ReferralService.getReferralCode(uid) â†’ cod "FR12345678"
  â†’ Share nativ â†’ Utilizator B se Ã®nregistreazÄƒ cu codul
  â†’ ReferralService.processReferralCode(cod, newUserId)
  â†’ Referral creat Ã®n Firestore
  â†’ Utilizator B face prima cursÄƒ â†’ rewardedAt setat
  â†’ A primeÈ™te 15 RON + B primeÈ™te 10 RON
```

---

## ðŸ§ª Testare

```bash
# Toate testele
flutter test

# Test matching ride sharing
flutter test test/ride_sharing_service_test.dart

# AnalizÄƒ cod (0 issues)
flutter analyze --no-fatal-infos

# Integration tests
flutter test integration_test/
```

**Stare curentÄƒ analizÄƒ:**
```
No issues found! âœ…  (0 errors, 0 warnings, 0 infos)
```

---

## ðŸ“Š Servicii Principale

| Serviciu | Responsabilitate |
|---------|----------------|
| `FirestoreService` | CRUD Firestore cu retry logic |
| `GiftRideService` | Cadouri curse (creare, revendicare, anulare) |
| `ReferralService` | Coduri referral, statistici, recompense |
| `RideSharingService` | Matching pasageri (algoritm Haversine) |
| `LocalNotificationsService` | NotificÄƒri locale programate |
| `SocialAuthService` | Google / Apple / Facebook autentificare |
| `RoutingService` | Calculare trasee Mapbox |
| `VoiceOrchestrator` | Sincronizare TTS â†” STT |
| `GeminiVoiceEngine` | Procesare AI comenzi vocale |
| `RealTimeTrackingService` | Tracking GPS timp real |

---

## ðŸŒ Localizare

| FiÈ™ier | LimbÄƒ | Strings |
|--------|-------|---------|
| `lib/l10n/app_ro.arb` | RomÃ¢nÄƒ (implicitÄƒ) | 223+ |
| `lib/l10n/app_en.arb` | EnglezÄƒ | 223+ |

Schimbare limbÄƒ: **Meniu hamburger â†’ Limba**. Alegerea se salveazÄƒ automat.

---

## ðŸ“ˆ PerformanÈ›Äƒ

- **GPU rendering** â€” Mapbox + CustomPainter pentru heatmap
- **Clustering POI** â€” Max 200 POI-uri, zoom gates
- **TTS-STT sync** â€” Eliminat race condition (PR #1)
- **Lazy loading** â€” Servicii iniÈ›ializate la cerere
- **Logger structurat** â€” `Logger.debug/info/warning/error` cu tag È™i stack trace

---

## ðŸ”§ Routes ÃŽnregistrate Ã®n main.dart

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

## ðŸ“š DocumentaÈ›ie

- **[AI Implementation Guide](VOICE_IMPLEMENTATION_GUIDE.md)**
- **[Complete Mapbox Setup](COMPLETE_MAPBOX_SETUP.md)**
- **[Firebase Setup Guide](FIREBASE_CONSOLE_SETUP_GUIDE.md)**
- **[Flux End-to-End](FLUX_APLICATIE_END_TO_END.md)**

---

## ðŸ¤ ContribuÈ›ii

1. Fork repository-ul
2. CreeazÄƒ ramurÄƒ: `git checkout -b feature/NumeFeature`
3. Commit: `git commit -m 'Add NumeFeature'`
4. Push: `git push origin feature/NumeFeature`
5. Deschide Pull Request

**Before PR:** `flutter analyze --no-fatal-infos` trebuie sÄƒ returneze `No issues found!`

---

## ðŸ“„ LicenÈ›Äƒ

MIT License â€” vezi [LICENSE](LICENSE).

---

## ðŸ“ž Contact

- **Email**: support@friendsride.com
- **GitHub**: https://github.com/operatii777-cloud/FriendsRide

---

*FriendsRide â€” ConectÃ¢nd oamenii prin tehnologie inteligentÄƒ ðŸš—âœ¨*
*Ultima actualizare: Martie 2026 â€” PR #1 (Voice sync) + PR #3 (Gift, Referral, Social Login, Scheduled Rides, Heatmap, Onboarding)*
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

Ÿš— FriendsRide - Intelligent Ride-Sharing App

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-10.0-orange.svg)](https://firebase.google.com/)
[![Mapbox](https://img.shields.io/badge/Mapbox-10.0-lightblue.svg)](https://mapbox.com/)
[![Analyze](https://img.shields.io/badge/flutter%20analyze-0%20issues-brightgreen.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**FriendsRide** este o aplicaÈ›ie de ride-sharing inteligentÄƒ care conecteazÄƒ pasagerii cu È™oferi parteneri, oferind o experienÈ›Äƒ vocalÄƒ avansatÄƒ cu AI, navigaÈ›ie Ã®n timp real, funcÈ›ionalitÄƒÈ›i sociale (cadouri, referral, social login) È™i notificÄƒri smart.

---

## ðŸŒŸ Caracteristici Principale

### ðŸŽ¤ Asistent Vocal AI (PR #1 â€” Ã®mbunÄƒtÄƒÈ›it)
- **Sincronizare TTS-STT perfectÄƒ** â€” STT nu mai porneÈ™te Ã®n timp ce TTS vorbeÈ™te
- **Control vocal complet** â€” RezervÄƒ curse prin comenzi vocale naturale
- **Beep-uri de feedback** â€” IndicaÈ›ii audio clare pentru start/stop ascultare
- **Flux AI end-to-end** â€” Salut â†’ DestinaÈ›ie â†’ Confirmare â†’ Pickup â†’ CursÄƒ

### ðŸŽ Gift Ride â€” Cadouri de CursÄƒ (PR #3 â€” nou)
- **Trimite curse cadou** â€” Oferi o cursÄƒ unui prieten sau familiar
- **Cod unic de revendicare** â€” Format `GFTxxxxxx`, valabil 365 zile
- **Revendicare simplÄƒ** â€” Destinatarul introduce codul la checkout
- **Gestionare cadouri** â€” VizualizeazÄƒ cadourile trimise È™i statusul lor
- **State machine** â€” `pending â†’ claimed / expired / cancelled`

### ðŸ‘¥ Sistem Referral (PR #3 â€” nou)
- **Cod personal** â€” Fiecare utilizator are un cod unic `FRxxxxxxxx`
- **Recompense duble** â€” Invitantul primeÈ™te 15 RON, invitatul 10 RON
- **Statistici live** â€” Total, completate, cÃ¢È™tiguri acumulate
- **Share nativ** â€” Distribuie codul prin orice aplicaÈ›ie instalatÄƒ
- **ProtecÈ›ie auto-referral** â€” Sistemul previne abuzurile

### ðŸ” Social Login (PR #3 â€” nou)
- **Google Sign-In** â€” Autentificare cu un singur tap
- **Apple Sign-In** â€” Suport complet iOS (Sign in with Apple)
- **Facebook Login** â€” Autentificare via Facebook
- **Fallback email/parolÄƒ** â€” Clasic, cu recuperare parolÄƒ

### ðŸ“… Curse Programate + NotificÄƒri (PR #3 â€” nou)
- **Programare curse** â€” SeteazÄƒ cursÄƒ pentru o datÄƒ/orÄƒ viitoare
- **NotificÄƒri locale** â€” Reminder automat cu 30 min Ã®nainte
- **Toggle notificÄƒri** â€” ActiveazÄƒ/dezactiveazÄƒ per cursÄƒ
- **Gestionare listÄƒ** â€” AdaugÄƒ, modificÄƒ, È™terge curse programate

### ðŸ§­ Onboarding Wizard (PR #3 â€” nou)
- **Tutorial pas cu pas** â€” 4 ecrane animate pentru utilizatori noi
- **Prezentare funcÈ›ionalitÄƒÈ›i** â€” HartÄƒ, vocal AI, plÄƒÈ›i, siguranÈ›Äƒ
- **Skip oricÃ¢nd** â€” Utilizatorul poate sÄƒri tutorialul

### ðŸ—ºï¸ HartÄƒ InteractivÄƒ + Heatmap Cerere (PR #3 â€” nou)
- **Heatmap vizual** â€” Gradient color pentru densitatea cererii (verde â†’ galben â†’ roÈ™u)
- **GrilÄƒ suprapusÄƒ** â€” Ajutor vizual pentru zone de cerere
- **Date tempo real** â€” `HeatmapPoint` cu latitudine, longitudine, intensitate
- **POI-uri inteligente** â€” Clustering GPU, zoom gates, max 200 POI-uri

### ðŸ’¸ Ride Sharing Avansat (PR #3 â€” Ã®mbunÄƒtÄƒÈ›it)
- **Algoritm Haversine** â€” DistanÈ›Äƒ precisÄƒ Ã®ntre coordonate GPS
- **Prag compatibilitate** â€” Pickup < 2 km + DestinaÈ›ie < 2 km
- **Matching static testabil** â€” `RideSharingService.areRoutesCompatible(s1, s2)`
- **Mesaje sistem automate** â€” Notificare Ã®n chat la match confirmat
- **Reducere 30%** â€” Cost partajat calculat automat

### ðŸ”” Multiple Stops + Surge Pricing (PR #3 â€” nou)
- **Multiple opriri** â€” AdaugÄƒ pÃ¢nÄƒ la N opriri intermediare pe traseu
- **Surge pricing transparent** â€” Widget dedicat care explicÄƒ multiplicatorul preÈ›ului
- **Acceptance timer** â€” Countdown animat pentru acceptarea cursei de È™ofer

### ðŸŽ¨ Sistem Design Unificat (PR #3 â€” nou)
- **`AppColors`** â€” PaletÄƒ cromaticÄƒ centralizatÄƒ (primary, secondary, background, surface, error, textHint, border)
- **`AppTextStyles`** â€” Tipografie consistentÄƒ (heading1-4, bodySmall/Medium/Large, button)
- **Dark/Light mode ready** â€” StructurÄƒ pregÄƒtitÄƒ pentru teme multiple

---

## ðŸ“ Structura Proiectului

```
lib/
â”œâ”€â”€ main.dart                          # Entry point + routes
â”œâ”€â”€ theme/
â”‚   â”œâ”€â”€ app_colors.dart                # âœ¨ Nou: paleta de culori centralizatÄƒ
â”‚   â””â”€â”€ app_text_styles.dart           # âœ¨ Nou: stiluri text unificate
â”œâ”€â”€ models/
â”‚   â”œâ”€â”€ gift_ride_model.dart           # âœ¨ Nou: model cadou cursÄƒ
â”‚   â”œâ”€â”€ referral_model.dart            # âœ¨ Nou: model referral + ReferralStats
â”‚   â”œâ”€â”€ ride_model.dart
â”‚   â”œâ”€â”€ ride_sharing_model.dart
â”‚   â””â”€â”€ ...
â”œâ”€â”€ services/
â”‚   â”œâ”€â”€ gift_ride_service.dart         # âœ¨ Nou: trimitere, revendicare, anulare
â”‚   â”œâ”€â”€ referral_service.dart          # âœ¨ Nou: coduri referral, statistici, recompense
â”‚   â”œâ”€â”€ local_notifications_service.dart # âœ¨ Nou: notificÄƒri locale programate
â”‚   â”œâ”€â”€ social_auth_service.dart       # âœ¨ Nou: Google/Apple/Facebook auth
â”‚   â”œâ”€â”€ ride_sharing_service.dart      # âœ… ÃŽmbunÄƒtÄƒÈ›it: matching avansat + static API
â”‚   â”œâ”€â”€ firestore_service.dart
â”‚   â””â”€â”€ ...
â”œâ”€â”€ screens/
â”‚   â”œâ”€â”€ gift_ride_screen.dart          # âœ¨ Nou: UI trimitere + vizualizare cadouri
â”‚   â”œâ”€â”€ referral_screen.dart           # âœ¨ Nou: UI cod referral + statistici + listÄƒ
â”‚   â”œâ”€â”€ onboarding_wizard_screen.dart  # âœ¨ Nou: tutorial utilizatori noi
â”‚   â”œâ”€â”€ social_login_screen.dart       # âœ¨ Nou: ecran login social
â”‚   â”œâ”€â”€ scheduled_ride_notifications_screen.dart # âœ¨ Nou: curse programate
â”‚   â””â”€â”€ ...
â”œâ”€â”€ widgets/
â”‚   â”œâ”€â”€ acceptance_timer_widget.dart   # âœ¨ Nou: countdown acceptare È™ofer
â”‚   â”œâ”€â”€ heatmap_widget.dart            # âœ¨ Nou: heatmap cerere cu CustomPainter
â”‚   â”œâ”€â”€ multiple_stops_widget.dart     # âœ¨ Nou: opriri multiple pe traseu
â”‚   â”œâ”€â”€ surge_pricing_transparency_widget.dart # âœ¨ Nou: explicaÈ›ie surge pricing
â”‚   â””â”€â”€ ...
â”œâ”€â”€ utils/
â”‚   â””â”€â”€ logger.dart                    # âœ¨ Nou: logger structurat (debug/info/warning/error)
â””â”€â”€ voice/                             # âœ… ÃŽmbunÄƒtÄƒÈ›it: PR #1 sync TTS-STT
    â”œâ”€â”€ ai/
    â”œâ”€â”€ core/
    â”œâ”€â”€ integration/
    â”œâ”€â”€ passenger/
    â”œâ”€â”€ ride/
    â””â”€â”€ tts/
```

---

## ðŸš€ Instalare È™i Configurare

### CerinÈ›e de Sistem
- **Android**: 7.0 (API level 24) sau mai nou
- **iOS**: 12.0 sau mai nou
- **Flutter**: 3.16+ / **Dart**: 3.2+

### Instalare
```bash
git clone https://github.com/operatii777-cloud/FriendsRide.git
cd FriendsRide
flutter pub get

# ConfigureazÄƒ Firebase (google-services.json + GoogleService-Info.plist)
# ConfigureazÄƒ Mapbox token Ã®n lib/utils/mapbox_config.dart
# ConfigureazÄƒ Gemini API key

flutter run
```

### Variabile de Mediu
```bash
MAPBOX_ACCESS_TOKEN=pk.xxx
GEMINI_API_KEY=AIzaSy...
```

---

## ðŸŽ¤ Fluxul Vocal AI

```
Utilizator apasÄƒ buton AI
  â†’ TTS: "BunÄƒ ziua! Unde doriÈ›i sÄƒ mergeÈ›i?"
  â†’ STT porneÈ™te (dupÄƒ ce TTS terminÄƒ â€” fix PR #1)
  â†’ Utilizator: "La aeroport"
  â†’ AI confirmÄƒ destinaÈ›ia
  â†’ STT pentru pickup (dacÄƒ necesar)
  â†’ CursÄƒ rezervatÄƒ
```

**Comenzi vocale disponibile:**
| ComandÄƒ | AcÈ›iune |
|---------|---------|
| `"SolicitÄƒ cursÄƒ"` | ÃŽncepe rezervarea |
| `"CÄƒtre [destinaÈ›ie]"` | SeteazÄƒ destinaÈ›ia |
| `"De la [adresÄƒ]"` | SeteazÄƒ pickup |
| `"AnuleazÄƒ"` | AnuleazÄƒ cursa curentÄƒ |
| `"Unde sunt?"` | AfiÈ™eazÄƒ locaÈ›ia curentÄƒ |
| `"SunÄƒ È™oferul"` | ApeleazÄƒ È™oferul activ |

---

## ðŸŽ Flux Gift Ride

```
Expeditor â†’ completeazÄƒ formular (nume, email/telefon, sumÄƒ, mesaj)
  â†’ GiftRideService.sendGiftRide() â†’ cod unic generat + salvat Ã®n Firestore
  â†’ Destinatar primeÈ™te codul (email/SMS extern)
  â†’ Destinatar â†’ introduce codul la checkout
  â†’ GiftRideService.claimGiftRide(cod, userId) â†’ suma creditatÄƒ
```

---

## ðŸ‘¥ Flux Referral

```
Utilizator A â†’ ReferralService.getReferralCode(uid) â†’ cod "FR12345678"
  â†’ Share nativ â†’ Utilizator B se Ã®nregistreazÄƒ cu codul
  â†’ ReferralService.processReferralCode(cod, newUserId)
  â†’ Referral creat Ã®n Firestore
  â†’ Utilizator B face prima cursÄƒ â†’ rewardedAt setat
  â†’ A primeÈ™te 15 RON + B primeÈ™te 10 RON
```

---

## ðŸ§ª Testare

```bash
# Toate testele
flutter test

# Test matching ride sharing
flutter test test/ride_sharing_service_test.dart

# AnalizÄƒ cod (0 issues)
flutter analyze --no-fatal-infos

# Integration tests
flutter test integration_test/
```

**Stare curentÄƒ analizÄƒ:**
```
No issues found! âœ…  (0 errors, 0 warnings, 0 infos)
```

---

## ðŸ“Š Servicii Principale

| Serviciu | Responsabilitate |
|---------|----------------|
| `FirestoreService` | CRUD Firestore cu retry logic |
| `GiftRideService` | Cadouri curse (creare, revendicare, anulare) |
| `ReferralService` | Coduri referral, statistici, recompense |
| `RideSharingService` | Matching pasageri (algoritm Haversine) |
| `LocalNotificationsService` | NotificÄƒri locale programate |
| `SocialAuthService` | Google / Apple / Facebook autentificare |
| `RoutingService` | Calculare trasee Mapbox |
| `VoiceOrchestrator` | Sincronizare TTS â†” STT |
| `GeminiVoiceEngine` | Procesare AI comenzi vocale |
| `RealTimeTrackingService` | Tracking GPS timp real |

---

## ðŸŒ Localizare

| FiÈ™ier | LimbÄƒ | Strings |
|--------|-------|---------|
| `lib/l10n/app_ro.arb` | RomÃ¢nÄƒ (implicitÄƒ) | 223+ |
| `lib/l10n/app_en.arb` | EnglezÄƒ | 223+ |

Schimbare limbÄƒ: **Meniu hamburger â†’ Limba**. Alegerea se salveazÄƒ automat.

---

## ðŸ“ˆ PerformanÈ›Äƒ

- **GPU rendering** â€” Mapbox + CustomPainter pentru heatmap
- **Clustering POI** â€” Max 200 POI-uri, zoom gates
- **TTS-STT sync** â€” Eliminat race condition (PR #1)
- **Lazy loading** â€” Servicii iniÈ›ializate la cerere
- **Logger structurat** â€” `Logger.debug/info/warning/error` cu tag È™i stack trace

---

## ðŸ”§ Routes ÃŽnregistrate Ã®n main.dart

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

## ðŸ“š DocumentaÈ›ie

- **[AI Implementation Guide](VOICE_IMPLEMENTATION_GUIDE.md)**
- **[Complete Mapbox Setup](COMPLETE_MAPBOX_SETUP.md)**
- **[Firebase Setup Guide](FIREBASE_CONSOLE_SETUP_GUIDE.md)**
- **[Flux End-to-End](FLUX_APLICATIE_END_TO_END.md)**

---

## ðŸ¤ ContribuÈ›ii

1. Fork repository-ul
2. CreeazÄƒ ramurÄƒ: `git checkout -b feature/NumeFeature`
3. Commit: `git commit -m 'Add NumeFeature'`
4. Push: `git push origin feature/NumeFeature`
5. Deschide Pull Request

**Before PR:** `flutter analyze --no-fatal-infos` trebuie sÄƒ returneze `No issues found!`

---

## ðŸ“„ LicenÈ›Äƒ

MIT License â€” vezi [LICENSE](LICENSE).

---

## ðŸ“ž Contact

- **Email**: support@friendsride.com
- **GitHub**: https://github.com/operatii777-cloud/FriendsRide

---

*FriendsRide â€” ConectÃ¢nd oamenii prin tehnologie inteligentÄƒ ðŸš—âœ¨*
*Ultima actualizare: Martie 2026 â€” PR #1 (Voice sync) + PR #3 (Gift, Referral, Social Login, Scheduled Rides, Heatmap, Onboarding)*

