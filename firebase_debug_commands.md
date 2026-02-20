# 🔧 FIREBASE DEBUG COMMANDS & UTILITIES

## 🚀 FLUTTER COMMANDS

### Build & Run Commands
```bash
# Clean și rebuild complet
flutter clean
flutter pub get
flutter build apk --debug

# Run cu debug detaliat
flutter run --debug
flutter run --verbose

# Run pe device specific
flutter devices
flutter run -d <device-id>
```

### Debug Specific Issues
```bash
# Check Firebase configuration
flutter doctor -v
flutter pub deps

# Analyze pentru probleme
flutter analyze
flutter test

# Check pentru Firebase plugins
flutter pub deps | grep firebase
```

## 🔥 FIREBASE CLI COMMANDS

### Authentication Commands
```bash
# Install Firebase CLI (dacă nu e instalat)
npm install -g firebase-tools

# Login în Firebase
firebase login

# List proiectele
firebase projects:list

# Set project activ
firebase use <project-id>

# Check configurația
firebase projects:list
```

### Firestore Rules Testing
```bash
# Test local pentru Firestore rules
firebase emulators:start --only firestore
firebase emulators:start --only auth,firestore

# Deploy rules în testing mode
firebase deploy --only firestore:rules
firebase deploy --only firestore:rules --project <project-id>

# Check diferențele în rules
firebase firestore:rules:get
```

### Backup & Restore
```bash
# Export Firestore data
firebase firestore:export gs://<project-id>.appspot.com/backups
gcloud firestore export gs://<project-id>.appspot.com/backups

# Import Firestore data
firebase firestore:import gs://<project-id>.appspot.com/backups
```

## 🧪 TESTING COMMANDS

### Local Testing
```bash
# Start Firebase emulators
firebase emulators:start

# Start doar Authentication emulator
firebase emulators:start --only auth

# Start cu port specific
firebase emulators:start --only firestore --port 8080
```

### Integration Testing
```bash
# Run integration tests
flutter drive --target=test_driver/app.dart

# Run unit tests
flutter test
flutter test test/auth_test.dart

# Run tests cu coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📊 MONITORING COMMANDS

### Performance Monitoring
```bash
# Enable performance monitoring
flutter packages get
flutter run --release

# Check performance logs
adb logcat | grep -i performance
```

### Crash Reporting
```bash
# Force crash pentru testing
# Adaugă în cod: FirebaseCrashlytics.instance.crash();

# Check crash logs
firebase crashlytics:symbols:upload

# Upload symbols pentru iOS
firebase crashlytics:symbols:upload --app=<ios-app-id>
```

## 🔍 DEBUG CONFIGURATION

### Environment Variables
```bash
# Set pentru development
export FLUTTER_ENV=development
export FIREBASE_PROJECT=friendsride-dev

# Set pentru production
export FLUTTER_ENV=production
export FIREBASE_PROJECT=friendsride-prod
```

### Debug Logging în Dart
```dart
// Adaugă în main.dart pentru debug detaliat
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable debug logging
  await Firebase.initializeApp();
  
  // Pentru Authentication debug
  FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true, // Doar pentru testing
  );
  
  runApp(MyApp());
}
```

## 🔐 SECURITY TESTING

### Security Rules Testing
```bash
# Test cu Firebase CLI
firebase emulators:exec --only firestore "npm test"

# Specific security test
firebase firestore:rules:test --project=<project-id>
```

### Manual Security Commands
```bash
# Test unauthenticated access
curl -X GET \
  "[https://firestore.googleapis.com/v1/projects/<project-id>/databases/(default)/documents/users/test123](https://firestore.googleapis.com/v1/projects/<project-id>/databases/(default)/documents/users/test123)" \
  -H "Authorization: Bearer <invalid-token>"

# Expected: 401 Unauthorized
```

### Authentication Testing
```bash
# Test cu curl pentru authentication
curl -X POST \
  "[https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=<api-key>](https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=<api-key>)" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword",
    "returnSecureToken": true
  }'
```

## 📱 DEVICE TESTING

### Android Debugging
```bash
# Check Android logs
adb logcat | grep -i firebase
adb logcat | grep -i flutter

# Clear app data
adb shell pm clear com.yourcompany.friendsride

# Install fresh build
flutter install
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### iOS Debugging
```bash
# iOS simulator logs
xcrun simctl logfilter booted --subsystem com.yourcompany.friendsride

# Check iOS device logs
idevicelogfilter -u <device-id> com.yourcompany.friendsride

# Clear iOS app data
xcrun simctl uninstall booted com.yourcompany.friendsride
```

## 🌐 NETWORK DEBUGGING

### Network Testing Commands
```bash
# Test connectivity to Firebase
ping firestore.googleapis.com
nslookup identitytoolkit.googleapis.com

# Test specific Firebase endpoints
curl -I [https://firestore.googleapis.com](https://firestore.googleapis.com)
curl -I [https://identitytoolkit.googleapis.com](https://identitytoolkit.googleapis.com)
```

### Proxy Configuration (pentru testing)
```bash
# Set proxy pentru Flutter
export HTTP_PROXY=[http://localhost:8888](http://localhost:8888)
export HTTPS_PROXY=[http://localhost:8888](http://localhost:8888)

# Clear proxy
unset HTTP_PROXY HTTPS_PROXY
```

## 📋 QUICK DEBUG CHECKLIST

### Verificări Rapide:
```bash
# 1. Check Flutter doctor
flutter doctor

# 2. Check Firebase configuration
cat android/app/google-services.json
cat ios/Runner/GoogleService-Info.plist

# 3. Check dependencies
flutter pub deps | grep firebase

# 4. Check for conflicts
flutter clean && flutter pub get

# 5. Test basic build
flutter build apk --debug
```

### Common Issues Commands:
```bash
# Fix gradle issues
cd android && ./gradlew clean
flutter clean && flutter pub get

# Fix iOS issues
cd ios && pod install
flutter clean && cd ios && pod install

# Fix Firebase plugin issues
flutter pub cache repair
flutter pub upgrade
```

## 🚨 EMERGENCY DEBUGGING

### Rapid Problem Resolution:
```bash
# Complete reset
flutter clean
flutter pub cache clean
flutter pub get
cd android && ./gradlew clean
cd ../ios && pod install

# Check Firebase status
curl -I [https://status.firebase.google.com](https://status.firebase.google.com)

# Verify authentication
firebase auth:export users.json --format=json
```

### Last Resort Commands:
```bash
# Completely reinstall Flutter
git clone [https://github.com/flutter/flutter.git](https://github.com/flutter/flutter.git)
export PATH="$PWD/flutter/bin:$PATH"
flutter doctor

# Reinstall Firebase CLI
npm uninstall -g firebase-tools
npm install -g firebase-tools@latest
```

## 📞 SUPPORT RESOURCES

- **Firebase Status**: [https://status.firebase.google.com](https://status.firebase.google.com)
- **Flutter Status**: [https://status.flutter.dev](https://status.flutter.dev)
- **Firebase Console**: [https://console.firebase.google.com](https://console.firebase.google.com)
- **Firebase Support**: [https://firebase.google.com/support](https://firebase.google.com/support)

---

**💡 Tip**: Păstrează aceste comenzi într-un loc accesibil pentru debugging rapid!



