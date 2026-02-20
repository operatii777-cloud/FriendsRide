# 🎤 FriendsRide Voice AI System

## 🎯 **Descriere Generală**

Sistemul vocal FriendsRide funcționează **EXACT ca interacțiunea cu Gemini Voice**, oferind o experiență vocală naturală și inteligentă pentru rezervarea cursei.

## 🚀 **Caracteristici Principale**

### ✅ **STT Perfect (Speech-to-Text)**

- **Detectare instantanee** a cuvintelor
- **Recunoaștere perfectă** a adreselor și POI-urilor
- **Limba română** nativă
- **Timeout configurat** (3 secunde pentru confirmări)

### ✅ **AI Instant (Gemini Integration)**

- **Procesare instantanee** ca Gemini Voice
- **Înțelegere perfectă** a contextului
- **Identificare inteligentă** a intențiilor
- **Răspunsuri naturale** și rapide

### ✅ **TTS Natural (Text-to-Speech)**

- **Vocea naturală** ca Gemini Voice
- **Emoții vocale** (happy, confident, calm, urgent)
- **Pauze naturale** între propoziții
- **Flow instant** fără pauze artificiale

### ✅ **Flow Complet al Curselor**

- **Rezervări vocale** complete
- **Confirmări naturale** (da, confirm, repetarea destinației)
- **Căutarea șoferilor** vocală
- **Finalizarea rezervării** prin voce

## 📁 **Arhitectura Sistemului**

```text
lib/voice/
├── ai/                          # 🧠 AI Engine
│   ├── gemini_voice_engine.dart # Motorul principal Gemini
│   └── gemini_config.dart       # Configurația API
├── tts/                         # 🗣️ Text-to-Speech
│   └── natural_voice_synthesizer.dart # TTS natural
├── core/                        # 🎤 Core Voice
│   └── voice_orchestrator.dart  # Orchestrator STT+TTS
├── ride/                        # 🚗 Ride Management
│   └── ride_flow_manager.dart   # Managerul cursei
├── states/                      # 🎯 State Management
│   └── voice_interaction_states.dart # Stările sistemului
├── widgets/                     # 🎨 UI Components
│   └── voice_interaction_widget.dart # Widget-ul principal
├── integration/                 # 🔗 App Integration
│   └── app_integration.dart     # Integrarea cu app-ul
├── main_voice_integration.dart  # 🎯 Integration Principal
└── README.md                    # 📚 Documentația
```

## 🚀 **Instalare și Configurare**

### 1. **Dependințe**

Toate dependințele sunt deja în `pubspec.yaml`:

```yaml
flutter_tts: ^4.2.3
speech_to_text: ^7.3.0
http: ^1.1.0
provider: ^6.0.5
```

### 2. **Configurarea Gemini API**

```dart
// În lib/voice/config/gemini_config.dart
static const String _developmentApiKey = 'YOUR_ACTUAL_GEMINI_API_KEY';
```

**Obține API Key de la:** [https://makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)

### 3. **Integrarea în Main App**

```dart
// În main.dart
import 'package:friendsride_app/voice/integration/app_integration.dart';

void main() {
  runApp(
    AppVoiceIntegration.wrapMaterialApp(
      context: context,
      child: MyApp(),
    ),
  );
}
```

## 🎤 **Utilizare**

### **1. Interacțiunea Vocală de Bază**

```dart
// În orice screen
import 'package:friendsride_app/voice/integration/app_integration.dart';

class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> with VoiceIntegrationMixin {
  @override
  Widget buildVoiceIntegratedScreen() {
    return Scaffold(
      body: Column(
        children: [
          // Conținutul screen-ului
          Expanded(child: YourContent()),
          
          // Widget-ul vocal
          addVoiceWidget(),
        ],
      ),
    );
  }
}
```

### **2. Control Programatic**

```dart
// Începe interacțiunea vocală
await startVoiceInteraction();

// Oprește interacțiunea vocală
await stopVoiceInteraction();

// Verifică disponibilitatea
if (isVoiceSystemAvailable) {
  // Voice system-ul e disponibil
}
```

### **3. Widget Flotant**

```dart
// Adaugă buton flotant
AppVoiceIntegration.addVoiceWidget(
  context: context,
  child: YourScreen(),
  showAsOverlay: true,
);
```

## 🎯 **Flow-ul Conversației**

### **1. Inițializarea**

```
🎤 User: "Hey FriendsRide"
🗣️ AI: "Bună! Sunt asistentul vocal FriendsRide. Cum vă pot ajuta?"
```

### **2. Destinația**

```
🎤 User: "Vreau să merg la aeroport"
🧠 AI: Procesează cu Gemini
🗣️ AI: "Am înțeles! Doriți să mergeți la aeroport. Confirmați?"
```

### **3. Confirmarea**

```
🎤 User: "da" sau "la aeroport" (repetarea = confirmare)
✅ AI: Confirmă și caută șoferi
🗣️ AI: "Am găsit 3 șoferi disponibili! Cursa costă aproximativ 45 lei. Confirmați rezervarea?"
```

### **4. Finalizarea**

```
🎤 User: "da" sau "confirm"
✅ AI: Finalizează rezervarea
🗣️ AI: "Excelent! Cursa a fost rezervată cu succes! Șoferul va ajunge în 5 minute."
```

## 🔧 **Configurații Avansate**

### **1. Timeout-uri**

```dart
// În voice_orchestrator.dart
await _voice.listen(
  timeoutSeconds: 15,    // Pentru comenzi inițiale
  timeoutSeconds: 3,     // Pentru confirmări
  localeId: 'ro_RO',     // Limba română
);
```

### **2. Emoții Vocale**

```dart
// În natural_voice_synthesizer.dart
await _tts.speakWithEmotion(
  'Perfect! Cursa confirmată!',
  VoiceEmotion.happy,
);
```

### **3. Retry Logic**

```dart
// În gemini_config.dart
'errorConfig': {
  'maxRetries': 3,        // Reîncercări
  'retryDelay': 1000,     // Pauza între reîncercări (ms)
  'timeout': 30000,       // Timeout API (ms)
}
```

## 🚨 **Troubleshooting**

### **1. "Speech Recognition not available"**

- Verifică permisiunile microfonului
- Asigură-te că `speech_to_text` e inițializat
- Verifică că device-ul suportă speech recognition

### **2. "Gemini API error"**

- Verifică API key-ul în `gemini_config.dart`
- Asigură-te că ai conexiune la internet
- Verifică că API key-ul e valid și activ

### **3. "TTS not working"**

- Verifică că `flutter_tts` e inițializat
- Asigură-te că device-ul suportă TTS
- Verifică că limba română e disponibilă

### **4. "Voice system not initialized"**

- Verifică că toate componentele sunt create
- Asigură-te că Provider-ul e configurat corect
- Verifică că nu există erori în console

## 📊 **Performance și Optimizări**

### **1. Caching**

- Răspunsurile Gemini sunt cache-uite
- Intent-urile vocale sunt pre-procesate
- TTS-ul folosește cache pentru răspunsuri comune

### **2. Async Processing**

- Toate operațiunile sunt asincrone
- UI-ul nu se blochează
- Background processing pentru AI

### **3. Error Recovery**

- Retry automat pentru API calls
- Fallback responses pentru erori
- Graceful degradation

## 🔮 **Funcționalități Viitoare**

### **1. Detectarea "salut"**

- "Hey FriendsRide" pentru activare
- Background listening
- Battery optimization

### **2. Multi-language Support**

- Suport pentru mai multe limbi
- Auto-detection a limbii
- Localization complet

### **3. Advanced AI Features**

- Context memory pe sesiuni
- Learning din interacțiuni
- Personalization

## 📞 **Suport și Contribuții**

### **1. Issues**

- Raportează bug-uri în GitHub Issues
- Include log-uri și steps to reproduce
- Specifică device-ul și OS-ul

### **2. Contribuții**

- Fork repository-ul
- Creează feature branch
- Submit PR cu descriere detaliată

### **3. Contact**

- Email: support@friendsride.com
- GitHub: [https://github.com/friendsride](https://github.com/friendsride)
- Discord: [https://discord.gg/friendsride](https://discord.gg/friendsride)

## 📄 **Licență**

Acest sistem vocal este parte din FriendsRide și este licențiat sub MIT License.

---

**🎉 Mulțumesc că folosești FriendsRide Voice AI System!**

**🚗 Condu sigur și folosește-ți vocea pentru a rezerva cursele!**
