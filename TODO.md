# FriendsRide – TODO și Jurnal de implementare

Acest fișier ține evidența taskurilor finalizate și a celor în curs/de făcut pentru aplicația FriendsRide. Înaintea fiecărei implementări:

- Verificăm lista de taskuri (finalizate, active, rămase) și suprapunerile.
- Recitim regulile din `.cursorrules` și `CURSOR_RULES.md` (auto‑analyze, zero erori/avertismente, aliasuri import, context.mounted etc.).
- Formulăm strategia de implementare (pași, servicii existente, DI/pattern-urile proiectului).
- După fiecare etapă: rulăm `flutter analyze` și corectăm la ZERO erori/avertismente.
- Dacă apare o cerință neprevăzută, o propunem ca nou task în această listă și cerem confirmare înainte să o adăugăm.

## Backlog prioritizat (curent)

1. [DONE] Phone number verification (OTP) – Firebase Auth cu `verifyPhoneNumber`, UI OTP, fallback re‑send
2. [DONE] Local notifications (foreground/background) cu acțiuni (navighează, acceptă/refuză, chat)
3. [PENDING] Driver–passenger matching: reguli de prioritizare și coadă (proximity, rating, ETA, categorii)
4. [PENDING] AI Voice – integrare Gemini chat stateful (consolidat cu voice booking)
5. [PENDING] Voice booking end‑to‑end (intents, confirmări, fallback UI, extra shortcuts)
6. [PENDING] Driver dashboard – KPI și metrici administrative (rute, venit, rată acceptare, timpi)
7. [PENDING] Accessibility banner + screen reader hints (contrast, semantic labels)
8. [PENDING] Local nav telemetry (reroute time, TTS failures, frame timing)
9. [PENDING] Call anonymization driver ↔ pasager (bridge nr. intermediar)

## Finalizate recent

- [DONE] Local notifications service (`LocalNotificationsService`) + integrare în `FirebaseService` (onMessage heads‑up)
- [DONE] Phone number verification (OTP) – UI toggle email/telefon, `verifyPhoneNumber`, code sent/auto‑complete, signInWithCredential
- [DONE] Tunnel/GPS‑loss smoothing + „ETA în pauză” (banner și watchdog)
- [DONE] Route corridor prefetch (tiles/style) în navigație
- [DONE] Resume/recover pe app resume (re‑atașare listeneri, redraw overlays)
- [DONE] Passenger recenter polish (hint + FAB)
- [DONE] Lane guidance + banner mare high‑contrast
- [DONE] Speed limit + overspeed haptics (persistență preferință)
- [DONE] Reroute policy (debounce/histerezis, păstrează camera, UX)
- [DONE] Refresh periodic trafic/culoare traseu
- [DONE] „Alege intrare” (chips) aproape de destinație (șofer)
- [DONE] „Share arrival” + „Call passenger” în panoul de sosire

## Anulate/Îmbinate

- [CANCELLED] Voice shortcuts standalone → integrat în „Voice booking end‑to‑end”.
- [GROUPED] Gemini integration + Voice booking implementate în aceeași etapă (AI voice stack unificat).

## Note de implementare

- Folosim exclusiv serviciile existente din `lib/services/` (ex.: `RoutingService`, `FirestoreService`, `OfflineManager`, `NavigationService`, `TtsService`).
- Pentru Mapbox: verificăm tipurile corecte (ex.: `textField` string), tokens, și evităm API-uri depreciate.
- Importuri cu alias pentru a evita coliziuni (`as app_offline` etc.).
- UI: păstrăm consistența cu temele și accesibilitatea (high‑contrast, text scaling).

## Jurnal activitate (rezumat)

- 2025‑09‑04: Local notifications service + hook în Firebase handlers; analiză: 0 issues.
- 2025‑09‑04: Phone OTP login + verificare – implementat în `lib/screens/auth_screen.dart`; analiză: 0 issues.
- 2025‑09‑04: GPS‑loss smoothing + banner ETA, corridor prefetch, resume/recover, recenter hint; analiză: 0 issues.
- 2025‑09‑04: Prioritizare backlog; marcat „arrival chips” și „share arrival/call” ca DONE; Voice shortcuts consolidat.

---

Ultima actualizare a fișierului: 2025‑09‑04


