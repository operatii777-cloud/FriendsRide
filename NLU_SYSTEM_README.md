# 🧠 Sistemul Natural Language Understanding (NLU) - FriendsRide

## 📍 **DESCRIERE GENERALĂ**

Sistemul NLU (Natural Language Understanding) implementat în FriendsRide permite AI-ului să **înțeleagă intențiile** utilizatorilor din comenzi vocale naturale, nu doar să recunoască cuvinte cheie. Acesta poate interpreta diferite moduri de a exprima aceeași intenție și să extragă entitățile relevante.

## 🎯 **FUNCȚIONALITĂȚI PRINCIPALE**

### **1. 🚗 RECUNOAȘTEREA INTENȚIILOR (INTENT RECOGNITION)**

#### **BOOK_RIDE - Rezervarea unei curse**

```dart
// Utilizatorul poate spune:
"vreau să merg la" → Intent: BOOK_RIDE
"du-mă la" → Intent: BOOK_RIDE  
"vreau să comand o cursă la" → Intent: BOOK_RIDE
"vreau la" → Intent: BOOK_RIDE
"vreau să mă duc la" → Intent: BOOK_RIDE
"caut o cursă la" → Intent: BOOK_RIDE
"rezervă o cursă la" → Intent: BOOK_RIDE
"vreau să fac o comandă" → Intent: BOOK_RIDE
"comandă cursă" → Intent: BOOK_RIDE
"rezervare cursă" → Intent: BOOK_RIDE
"vreau să plec la" → Intent: BOOK_RIDE
"să merg la" → Intent: BOOK_RIDE
"să mă duc la" → Intent: BOOK_RIDE
```

#### **FIND_NEAREST_TRANSPORT - Căutarea transportului cel mai apropiat**
```dart
// Utilizatorul poate spune:
"care este cea mai apropiată stație de metrou" → Intent: FIND_NEAREST_TRANSPORT
"unde este cea mai apropiată stație" → Intent: FIND_NEAREST_TRANSPORT
"stația de metrou cea mai apropiată" → Intent: FIND_NEAREST_TRANSPORT
"gara cea mai apropiată" → Intent: FIND_NEAREST_TRANSPORT
"autobuzul cel mai apropiat" → Intent: FIND_NEAREST_TRANSPORT
"tramvaiul cel mai apropiat" → Intent: FIND_NEAREST_TRANSPORT
"stația cea mai apropiată" → Intent: FIND_NEAREST_TRANSPORT
"transportul cel mai apropiat" → Intent: FIND_NEAREST_TRANSPORT
"metroul cel mai apropiat" → Intent: FIND_NEAREST_TRANSPORT
"găsește stația" → Intent: FIND_NEAREST_TRANSPORT
"caut stația" → Intent: FIND_NEAREST_TRANSPORT
"unde este stația" → Intent: FIND_NEAREST_TRANSPORT
```

#### **LOCATE_PLACE - Localizarea unui loc**
```dart
// Utilizatorul poate spune:
"vreau la aeroport" → Intent: LOCATE_PLACE
"unde este" → Intent: LOCATE_PLACE
"caut" → Intent: LOCATE_PLACE
"arătă-mi" → Intent: LOCATE_PLACE
"localizează" → Intent: LOCATE_PLACE
"găsește" → Intent: LOCATE_PLACE
"poziția" → Intent: LOCATE_PLACE
"locația" → Intent: LOCATE_PLACE
"adresa" → Intent: LOCATE_PLACE
"coordonatele" → Intent: LOCATE_PLACE
"pe hartă" → Intent: LOCATE_PLACE
"în zonă" → Intent: LOCATE_PLACE
```

#### **SCHEDULE_RIDE - Programarea unei curse**
```dart
// Utilizatorul poate spune:
"acum" → Intent: SCHEDULE_RIDE
"imediat" → Intent: SCHEDULE_RIDE
"peste 10 minute" → Intent: SCHEDULE_RIDE
"peste o oră" → Intent: SCHEDULE_RIDE
"mâine" → Intent: SCHEDULE_RIDE
"azi" → Intent: SCHEDULE_RIDE
"programează" → Intent: SCHEDULE_RIDE
"planifică" → Intent: SCHEDULE_RIDE
"rezervă pentru" → Intent: SCHEDULE_RIDE
"la ce oră" → Intent: SCHEDULE_RIDE
"când" → Intent: SCHEDULE_RIDE
"program" → Intent: SCHEDULE_RIDE
```

#### **PAYMENT_INFO - Informații despre plată**
```dart
// Utilizatorul poate spune:
"cât costă" → Intent: PAYMENT_INFO
"prețul" → Intent: PAYMENT_INFO
"tariful" → Intent: PAYMENT_INFO
"plătesc cu" → Intent: PAYMENT_INFO
"metoda de plată" → Intent: PAYMENT_INFO
"card" → Intent: PAYMENT_INFO
"numerar" → Intent: PAYMENT_INFO
"voucher" → Intent: PAYMENT_INFO
"cod promoțional" → Intent: PAYMENT_INFO
"factura" → Intent: PAYMENT_INFO
"chitanța" → Intent: PAYMENT_INFO
"plata" → Intent: PAYMENT_INFO
```

#### **EMERGENCY - Situații de urgență**
```dart
// Utilizatorul poate spune:
"ajutor" → Intent: EMERGENCY
"urgență" → Intent: EMERGENCY
"pericol" → Intent: EMERGENCY
"accident" → Intent: EMERGENCY
"bolnav" → Intent: EMERGENCY
"rănit" → Intent: EMERGENCY
"cheamă ajutor" → Intent: EMERGENCY
"sosire rapidă" → Intent: EMERGENCY
"imediat" → Intent: EMERGENCY
"rapid" → Intent: EMERGENCY
"urgent" → Intent: EMERGENCY
"sănătate" → Intent: EMERGENCY
```

#### **VOICE_CONTROL - Control vocal**
```dart
// Utilizatorul poate spune:
"hey friendsride" → Intent: VOICE_CONTROL
"ascultă" → Intent: VOICE_CONTROL
"oprește" → Intent: VOICE_CONTROL
"taci" → Intent: VOICE_CONTROL
"mai tare" → Intent: VOICE_CONTROL
"mai încet" → Intent: VOICE_CONTROL
"mai rapid" → Intent: VOICE_CONTROL
"mai lent" → Intent: VOICE_CONTROL
"arată harta" → Intent: VOICE_CONTROL
"ascunde harta" → Intent: VOICE_CONTROL
"mărește" → Intent: VOICE_CONTROL
"micșorează" → Intent: VOICE_CONTROL
```

#### **APP_CONTROL - Control aplicație**
```dart
// Utilizatorul poate spune:
"meniu principal" → Intent: APP_CONTROL
"setări" → Intent: APP_CONTROL
"istoric" → Intent: APP_CONTROL
"profil" → Intent: APP_CONTROL
"ajutor" → Intent: APP_CONTROL
"deschide" → Intent: APP_CONTROL
"închide" → Intent: APP_CONTROL
"schimbă" → Intent: APP_CONTROL
"resetează" → Intent: APP_CONTROL
"configurare" → Intent: APP_CONTROL
"preferințe" → Intent: APP_CONTROL
```

#### **MULTILINGUAL - Control multilingv**
```dart
// Utilizatorul poate spune:
"schimbă limba" → Intent: MULTILINGUAL
"limba română" → Intent: MULTILINGUAL
"limba engleză" → Intent: MULTILINGUAL
"tradu în română" → Intent: MULTILINGUAL
"tradu în engleză" → Intent: MULTILINGUAL
"english" → Intent: MULTILINGUAL
"română" → Intent: MULTILINGUAL
"limba" → Intent: MULTILINGUAL
"traducere" → Intent: MULTILINGUAL
"idiom" → Intent: MULTILINGUAL
"language" → Intent: MULTILINGUAL
```

### **2. 🔍 EXTRAGEREA ENTITĂȚILOR (ENTITY EXTRACTION)**

#### **🎯 Destinația**
```dart
// Pattern-uri pentru extragerea destinației:
"la " → "la Mall Băneasa" → destination: "Mall Băneasa"
"până la " → "până la universitate" → destination: "universitate"
"spre " → "spre centru" → destination: "centru"
"către " → "către aeroport" → destination: "aeroport"
"în " → "în sectorul 1" → destination: "sectorul 1"
"pe " → "pe strada Victoriei" → destination: "strada Victoriei"
```

#### **🕐 Timpul**
```dart
// Pattern-uri pentru extragerea timpului:
"acum" → time: "acum"
"imediat" → time: "imediat"
"peste 10 minute" → time: "peste 10 minute"
"peste o oră" → time: "peste o oră"
"mâine" → time: "mâine"
"azi" → time: "azi"
"dimineața" → time: "dimineața"
"prânzul" → time: "prânzul"
"seara" → time: "seara"
"noaptea" → time: "noaptea"
```

#### **💰 Metoda de plată**
```dart
// Pattern-uri pentru extragerea metodei de plată:
"card" → payment_method: "card"
"numerar" → payment_method: "numerar"
"bani" → payment_method: "bani"
"voucher" → payment_method: "voucher"
"cod promoțional" → payment_method: "cod promoțional"
"paypal" → payment_method: "paypal"
"apple pay" → payment_method: "apple pay"
"google pay" → payment_method: "google pay"
```

### **3. 🎯 PROCESAREA COMENZILOR VOCALE**

#### **Exemplu complet de procesare:**
```dart
// Comanda utilizatorului:
"Vreau să merg la Mall Băneasa acum cu cardul"

// Rezultatul procesării:
{
  'intent': 'BOOK_RIDE',
  'entities': {
    'destination': 'Mall Băneasa',
    'time': 'acum',
    'payment_method': 'cardul'
  },
  'confidence': 0.9,
  'suggestions': [
    'Specifică destinația: "Vreau să merg la Mall Băneasa"',
    'Specifică timpul: "Vreau să merg acum la universitate"',
    'Specifică metoda de plată: "Vreau să merg cu cardul la aeroport"'
  ],
  'response': 'Înțeleg că vrei să mergi la Mall Băneasa. Să verific disponibilitatea...'
}
```

## 🚀 **UTILIZAREA SISTEMULUI NLU**

### **1. Funcția principală:**
```dart
import '../voice/ai/ai_vocabulary.dart';

// Procesează o comandă vocală
final result = AIVocabulary.processVoiceCommand("Vreau să merg la universitate");

// Verifică intenția
if (result['intent'] == 'BOOK_RIDE') {
  // Procesează rezervarea cursei
  final destination = result['entities']['destination'];
  print('Rezervare cursă pentru: $destination');
}
```

### **2. Recunoașterea intenției:**
```dart
// Identifică intenția din comandă
final intent = AIVocabulary.recognizeIntent("Du-mă la aeroport");
print('Intent: $intent'); // Output: Intent: BOOK_RIDE
```

### **3. Extragerea entităților:**
```dart
// Extrage entitățile din comandă
final entities = AIVocabulary.extractEntities("Vreau să merg la Mall AFI peste o oră");
print('Entities: $entities'); 
// Output: Entities: {destination: Mall AFI, time: peste o oră}
```

### **4. Calcularea încrederii:**
```dart
// Calculează încrederea în recunoașterea intenției
final confidence = AIVocabulary._calculateConfidence("Vreau să merg la universitate", "BOOK_RIDE");
print('Confidence: ${(confidence * 100).toStringAsFixed(1)}%');
// Output: Confidence: 80.0%
```

## 🧪 **TESTAREA SISTEMULUI NLU**

### **1. Ecranul de test integrat:**
Ecranul `NLUTestScreen` permite testarea tuturor funcționalităților NLU:

- **Input personalizat**: Scrie comenzi personalizate
- **Comenzi predefinite**: 15 comenzi de test cu scenarii reale
- **Analiză detaliată**: Afișează intent, entități, încredere, sugestii
- **Vizualizare intuitivă**: Coduri de culoare pentru diferite tipuri de informații

### **2. Comenzi de test incluse:**
```dart
List<String> _testCommands = [
  'Vreau să merg la Mall Băneasa',
  'Du-mă la universitate',
  'Care este cea mai apropiată stație de metrou?',
  'Vreau să comand o cursă la aeroport',
  'Unde este cea mai apropiată gară?',
  'Vreau să merg acum la centru',
  'Cât costă o cursă la spital?',
  'Rezervă o cursă pentru mâine dimineață',
  'Vreau să plătesc cu cardul',
  'Hey FriendsRide, ajutor!',
  'Schimbă limba în engleză',
  'Care este cea mai apropiată stație de tramvai?',
  'Vreau să mă duc la restaurant',
  'Găsește cea mai apropiată farmacie',
  'Vreau să fac o comandă urgentă',
];
```

### **3. Rularea testului:**
```bash
# Navighează la ecranul NLU Test
# Sau rulează direct:
flutter run lib/screens/nlu_test_screen.dart
```

## 📊 **STATISTICI SISTEM NLU**

| Componentă | Detalii | Statistici |
|------------|---------|------------|
| **🎯 Intenții** | 9 tipuri de intenții recunoscute | **9 intenții** |
| **🔍 Pattern-uri** | 100+ pattern-uri de recunoaștere | **100+ pattern-uri** |
| **📝 Entități** | 3 tipuri de entități extrase | **3 tipuri** |
| **🎨 Sugestii** | Sugestii contextuale pentru fiecare intenție | **Contextuale** |
| **📊 Încredere** | Calculul încrederii în recunoaștere | **0.0 - 1.0** |
| **🔄 Flexibilitate** | Multiple moduri de a exprima aceeași intenție | **Înaltă** |

## 🎯 **EXEMPLE DE UTILIZARE PRACTICĂ**

### **1. Scenariul 1: Rezervare cursă simplă**
```
Utilizator: "Vreau să merg la universitate"
AI: "Înțeleg că vrei să rezervi o cursă. Unde vrei să mergi?"
Utilizator: "La universitate"
AI: "Înțeleg că vrei să mergi la universitate. Să verific disponibilitatea..."
```

### **2. Scenariul 2: Căutare transport**
```
Utilizator: "Care este cea mai apropiată stație de metrou?"
AI: "Să găsesc cea mai apropiată stație de transport pentru tine..."
```

### **3. Scenariul 3: Comandă cu entități multiple**
```
Utilizator: "Vreau să merg la Mall Băneasa acum cu cardul"
AI: "Înțeleg că vrei să mergi la Mall Băneasa. Să verific disponibilitatea..."
```

## 🔧 **CONFIGURAREA ȘI PERSONALIZAREA**

### **1. Adăugarea de noi intenții:**
```dart
// În AIVocabulary.recognizeIntent()
if (_containsAny(lowerCommand, [
  'noua intenție',
  'altă comandă',
])) {
  return 'NEW_INTENT';
}
```

### **2. Adăugarea de noi entități:**
```dart
// În AIVocabulary.extractEntities()
final newEntityPatterns = [
  'pattern1',
  'pattern2',
];

for (final pattern in newEntityPatterns) {
  if (lowerCommand.contains(pattern)) {
    entities['new_entity'] = pattern;
    break;
  }
}
```

### **3. Personalizarea răspunsurilor:**
```dart
// În AIVocabulary._generateResponse()
case 'NEW_INTENT':
  return 'Răspuns personalizat pentru noua intenție';
```

## 🚀 **AVANTAJELE SISTEMULUI NLU**

### **1. 🎯 Înțelegere naturală:**
- Utilizatorii pot vorbi natural, nu cu comenzi rigide
- Multiple moduri de a exprima aceeași intenție
- Recunoașterea contextului și intenției

### **2. 🔍 Extragere inteligentă:**
- Identificarea automată a destinațiilor
- Recunoașterea timpului și programării
- Detectarea metodei de plată preferate

### **3. 📊 Încredere și sugestii:**
- Calculul încrederii în recunoaștere
- Sugestii contextuale pentru îmbunătățirea comenzilor
- Feedback inteligent pentru utilizatori

### **4. 🌍 Flexibilitate multilingvă:**
- Suport pentru română și engleză
- Pattern-uri adaptate la fiecare limbă
- Traduceri contextuale

## 🔮 **DEZVOLTĂRI VIITOARE**

### **1. 🧠 Machine Learning:**
- Învățarea din interacțiunile utilizatorilor
- Îmbunătățirea automată a recunoașterii
- Adaptarea la stilul vocal individual

### **2. 🌐 Suport multilingv extins:**
- Suport pentru mai multe limbi
- Traduceri automatice în timp real
- Adaptarea la dialecte regionale

### **3. 🎭 Personalizare avansată:**
- Profiluri vocale individuale
- Preferințe de comunicare
- Adaptarea la stilul de viață

### **4. 🔗 Integrare cu alte sisteme:**
- Conectarea cu calendarul personal
- Integrarea cu aplicații de navigare
- Sincronizarea cu preferințele de transport

---

## 📚 **RESURSE ȘI REFERINȚE**

- **Documentația Flutter**: [https://docs.flutter.dev/](https://docs.flutter.dev/)
- **Pattern Matching în Dart**: [https://dart.dev/guides/language/language-tour#pattern-matching](https://dart.dev/guides/language/language-tour#pattern-matching)
- **Natural Language Processing**: [https://en.wikipedia.org/wiki/Natural_language_processing](https://en.wikipedia.org/wiki/Natural_language_processing)
- **Intent Recognition**: [https://en.wikipedia.org/wiki/Intent_recognition](https://en.wikipedia.org/wiki/Intent_recognition)

---

**🎉 Sistemul NLU este gata pentru utilizare și poate fi testat imediat!**
