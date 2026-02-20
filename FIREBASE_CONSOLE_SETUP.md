# 🔥 FIREBASE CONSOLE CONFIGURATION GUIDE

## 📧 1. Authentication Settings

### Navigare: Firebase Console → Authentication → Settings

#### ✅ User Actions:
```
✅ Enable Email verification (opțional, pentru securitate suplimentară)
✅ Enable Password reset
✅ Set custom action URL (opțional)
```

#### 🔐 Sign-in Methods:
```
✅ Email/Password: ENABLED
✅ Email link (passwordless): DISABLED (deocamdată)
✅ Anonymous: DISABLED
✅ Google: DISABLED (pentru viitor)
```

#### 🌐 Authorized Domains:
```
✅ localhost (pentru development)
✅ yourdomain.com (pentru production - când lansezi)
✅ Firebase hosting domain (dacă folosești)
```

## 📋 2. Firestore Security Rules

### Navigare: Firebase Console → Firestore Database → Rules

**ÎNLOCUIEȘTE regulile existente cu versiunea din `firestore_security_rules_enhanced.rules`**

### 🔒 Reguli de Securitate Implementate:

#### Users Collection:
- ✅ Citire: Doar utilizatori autentificați
- ✅ Creare/Editare: Doar proprietarul contului
- ✅ Ștergere: Interzis (păstrează istoricul)

#### Ride Requests:
- ✅ Citire: Toți utilizatorii autentificați
- ✅ Creare: Utilizatori autentificați
- ✅ Editare: Pasager, șofer sau participanți la cursă
- ✅ Ștergere: Doar pasagerul (proprietarul cursei)

#### Chat Messages:
- ✅ Citire: Toți utilizatorii autentificați
- ✅ Creare: Utilizatori autentificați
- ✅ Editare/Ștergere: Doar expeditorul mesajului

#### Driver Locations:
- ✅ Citire: Toți utilizatorii autentificați
- ✅ Scriere: Doar șoferul propriu-zis
- ✅ Ștergere: Doar șoferul propriu-zis

#### Ride History:
- ✅ Citire: Doar participanții la cursă
- ✅ Creare: Utilizatori autentificați
- ✅ Editare/Ștergere: Interzis (istoric imutabil)

## 🎯 3. Authentication Templates (Opțional)

### Navigare: Firebase Console → Authentication → Templates

#### 📧 Email Verification Template:
```
Subject: Verificați adresa de email pentru FriendsRide
Body: Bună ziua! Vă rugăm să verificați adresa de email făcând click pe linkul de mai jos...
```

#### 🔑 Password Reset Template:
```
Subject: Resetare parolă FriendsRide
Body: Ați solicitat resetarea parolei pentru contul FriendsRide...
```

## 🧪 4. Testing Security Rules

### Teste Recomandate:
1. **Utilizator neautentificat** - ar trebui să eșueze toate operațiile
2. **Utilizator autentificat** - ar trebui să poată citi datele publice
3. **Proprietarul datelor** - ar trebui să poată edita propriile date
4. **Utilizator străin** - ar trebui să nu poată edita datele altora

### Comenzi de Test:
```bash
# Test citire utilizator neautentificat
firebase firestore:rules:test --project=your-project-id

# Test cu utilizator autentificat
firebase firestore:rules:test --project=your-project-id --token=user-token
```

## 📱 5. Mobile App Configuration

### Android (android/app/build.gradle):
```gradle
android {
    defaultConfig {
        applicationId "com.yourcompany.friendsride"
        minSdkVersion 21
        targetSdkVersion 33
    }
}
```

### iOS (ios/Runner/Info.plist):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.friendsride</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.yourcompany.friendsride</string>
        </array>
    </dict>
</array>
```

## 🚀 6. Deployment Checklist

### Pre-deployment:
- [ ] Regulile Firestore sunt testate local
- [ ] Toate metodele de autentificare sunt configurate
- [ ] Domeniile autorizate sunt setate corect
- [ ] Template-urile de email sunt personalizate

### Post-deployment:
- [ ] Testezi autentificarea pe device-ul fizic
- [ ] Verifici că regulile de securitate funcționează
- [ ] Testezi resetarea parolei
- [ ] Verifici că email-urile de verificare sunt trimise

## 🔍 7. Monitoring & Analytics

### Firebase Console → Analytics:
- ✅ Urmărește evenimentele de autentificare
- ✅ Monitorizează erorile de autentificare
- ✅ Analizează comportamentul utilizatorilor

### Firebase Console → Authentication → Users:
- ✅ Verifică utilizatorii activi
- ✅ Monitorizează încercările de autentificare eșuate
- ✅ Urmărește verificările de email

## 📞 8. Support & Troubleshooting

### Probleme Comune:
1. **"Permission denied"** - Verifică regulile Firestore
2. **"Invalid domain"** - Verifică domeniile autorizate
3. **"User not found"** - Verifică că utilizatorul există în Firebase
4. **"Network error"** - Verifică conexiunea la internet

### Resurse:
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
