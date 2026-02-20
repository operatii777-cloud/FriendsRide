# 🔧 Ghid de Instalare Android SDK pentru FriendsRide

## 🚨 Problemă Identificată

Android SDK-ul este incomplet. Lipsesc componente esențiale pentru build:
- ❌ `cmdline-tools` - Instrumente de linie de comandă
- ❌ `build-tools` - Instrumente de build (inclusiv `aapt`)
- ❌ `platforms` - Platforme Android (Android 33/34)
- ❌ Licențe neacceptate

**SDK actual:** `C:\Users\flori\AppData\Local\Android\Sdk`
**Conținut actual:** Doar `platform-tools` (ADB)

---

## ✅ SOLUȚIE 1: Instalare Command Line Tools (RAPIDĂ - 10 minute)

### Pasul 1: Descarcă Command Line Tools

1. **Accesează:** https://developer.android.com/studio#command-line-tools-only
2. **Descarcă:** "Command Line Tools for Windows" (latest version)
3. **Salvează:** `commandlinetools-win-XXXXX_latest.zip` (aproximativ 150 MB)

### Pasul 2: Instalare

**Deschide PowerShell ca Administrator și rulează:**

```powershell
# 1. Setează calea SDK
$ANDROID_SDK = "C:\Users\flori\AppData\Local\Android\Sdk"

# 2. Creează directorul pentru cmdline-tools
New-Item -Path "$ANDROID_SDK\cmdline-tools\latest" -ItemType Directory -Force

# 3. Extrage ZIP-ul descărcat
# IMPORTANT: Extrage conținutul din ZIP în "$ANDROID_SDK\cmdline-tools\latest"
# Ar trebui să ai: bin/, lib/, NOTICE.txt, source.properties

# 4. Verifică instalarea
dir "$ANDROID_SDK\cmdline-tools\latest\bin"
# Trebuie să vezi: sdkmanager.bat, avdmanager.bat

# 5. Acceptă licențele
& "$ANDROID_SDK\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
# Apasă 'y' pentru fiecare licență

# 6. Instalează componentele necesare
& "$ANDROID_SDK\cmdline-tools\latest\bin\sdkmanager.bat" "platform-tools" "platforms;android-34" "build-tools;34.0.0" "ndk;27.0.12077973"

# 7. Verifică instalarea
& "$ANDROID_SDK\cmdline-tools\latest\bin\sdkmanager.bat" --list_installed
```

### Pasul 3: Setează Variabilele de Mediu (PERMANENT)

**Deschide PowerShell ca Administrator:**

```powershell
# Setează ANDROID_HOME permanent
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Users\flori\AppData\Local\Android\Sdk", "User")

# Setează ANDROID_SDK_ROOT permanent
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "C:\Users\flori\AppData\Local\Android\Sdk", "User")

# Adaugă în PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$newPath = "$currentPath;C:\Users\flori\AppData\Local\Android\Sdk\cmdline-tools\latest\bin;C:\Users\flori\AppData\Local\Android\Sdk\platform-tools"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")

# IMPORTANT: Închide și redeschide terminalul pentru a aplica variabilele
```

### Pasul 4: Verifică Flutter

**Deschide un terminal NOU și rulează:**

```powershell
C:\Users\flori\AppData\Local\dev\bin\flutter.bat doctor -v
```

Ar trebui să vezi:
```
[√] Android toolchain - develop for Android devices
    • Android SDK at C:\Users\flori\AppData\Local\Android\Sdk
    • Platform android-34, build-tools 34.0.0
    • All Android licenses accepted.
```

### Pasul 5: Rulează Aplicația

```powershell
cd C:\friendsride_app
C:\Users\flori\AppData\Local\dev\bin\flutter.bat run -d 2201116TG
```

---

## ✅ SOLUȚIE 2: Instalare Android Studio (COMPLETĂ - 30 minute)

### Avantaje:
- ✅ Instalează automat toate componentele SDK
- ✅ Acceptă automat licențele
- ✅ Oferă GUI pentru management SDK
- ✅ Emulator Android inclus

### Dezavantaje:
- ❌ Download mare (~1 GB)
- ❌ Ocupă mult spațiu (~3-4 GB)

### Pași:

1. **Descarcă Android Studio:**
   - https://developer.android.com/studio
   
2. **Instalează:**
   - Rulează installerul
   - Selectează "Standard Installation"
   - Acceptă toate licențele

3. **Configurează SDK:**
   - Deschide Android Studio
   - Tools → SDK Manager
   - SDK Platforms: Instalează "Android 13 (API 33)" și "Android 14 (API 34)"
   - SDK Tools: Verifică că sunt instalate:
     - Android SDK Build-Tools 34.0.0
     - NDK (Side by side) 27.0.12077973
     - Android SDK Command-line Tools
     - Android SDK Platform-Tools

4. **Setează calea SDK în Flutter:**
   ```powershell
   C:\Users\flori\AppData\Local\dev\bin\flutter.bat config --android-sdk "C:\Users\flori\AppData\Local\Android\Sdk"
   ```

5. **Verifică:**
   ```powershell
   C:\Users\flori\AppData\Local\dev\bin\flutter.bat doctor
   ```

---

## 🎯 SOLUȚIE RECOMANDATĂ PENTRU TINE

**Pentru testare rapidă:** Folosește **SOLUȚIA 1** (Command Line Tools)
- ⚡ Mai rapid (10 minute)
- 💾 Mai puțin spațiu (~500 MB)
- ✅ Suficient pentru build și run

**Pentru development pe termen lung:** Instalează **SOLUȚIA 2** (Android Studio)
- 🔧 Unelte complete de development
- 🎨 UI/Layout Inspector
- 📱 Emulator Android

---

## 📞 Verificare Rapidă

După instalare, rulează în PowerShell:

```powershell
# Verifică SDK
dir "C:\Users\flori\AppData\Local\Android\Sdk"

# Ar trebui să vezi:
# - cmdline-tools
# - platform-tools
# - platforms
# - build-tools
# - ndk

# Verifică Flutter
C:\Users\flori\AppData\Local\dev\bin\flutter.bat doctor -v

# Ar trebui să vezi:
# [√] Android toolchain - develop for Android devices
```

---

## ⚡ CE URMEAZĂ DUPĂ INSTALARE

```powershell
# 1. Clean build
cd C:\friendsride_app
C:\Users\flori\AppData\Local\dev\bin\flutter.bat clean

# 2. Get dependencies
C:\Users\flori\AppData\Local\dev\bin\flutter.bat pub get

# 3. Run pe device
C:\Users\flori\AppData\Local\dev\bin\flutter.bat run -d 2201116TG
```

---

**Status:** 🔴 **SDK INCOMPLET - NECESITĂ INTERVENȚIE MANUALĂ**

**Acțiune necesară:** Descarcă și instalează Command Line Tools sau Android Studio conform pașilor de mai sus.

