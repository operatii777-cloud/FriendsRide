# 🗑️ AUDIT CACHE - PARTIȚIA C
## Raport Cache-uri Ștersibile

**Data:** $(Get-Date -Format "dd-MM-yyyy HH:mm")  
**Spațiu total C:** 241.66 GB folosit / 9.64 GB liber  
**Spațiu total:** 251.3 GB

---

## ✅ CACHE-URI SIGUR DE ȘTERS (14.59 GB)

### **1. Gradle Cache - 7.73 GB** ⭐⭐⭐
- **Path:** `C:\Users\flori\.gradle\caches`
- **Sigur de șters:** ✅ DA
- **Impact:** Gradle va re-descărca dependențele la următorul build
- **Comandă ștergere:**
  ```powershell
  Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches"
  ```

### **2. Temp Files - 3.15 GB** ⭐⭐⭐
- **Path:** `C:\Users\flori\AppData\Local\Temp`
- **Sigur de șters:** ✅ DA
- **Impact:** Fișiere temporare vechi, se vor regenere automat
- **Comandă ștergere:**
  ```powershell
  Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Temp\*" -ErrorAction SilentlyContinue
  ```

### **3. NPM Cache - 1.99 GB** ⭐⭐⭐
- **Path:** `C:\Users\flori\AppData\Local\npm-cache`
- **Sigur de șters:** ✅ DA
- **Impact:** NPM va re-descărca pachetele la următorul `npm install`
- **Comandă ștergere:**
  ```powershell
  Remove-Item -Recurse -Force "$env:LOCALAPPDATA\npm-cache"
  ```

### **4. Pub Cache - 1.3 GB** ⭐⭐⭐
- **Path:** `C:\Users\flori\AppData\Local\Pub`
- **Sigur de șters:** ✅ DA
- **Impact:** Flutter/Dart va re-descărca pachetele la următorul `flutter pub get`
- **Comandă ștergere:**
  ```powershell
  Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub"
  ```

### **5. Chrome Cache - 0.42 GB** ⭐⭐
- **Path:** `C:\Users\flori\AppData\Local\Google\Chrome\User Data\Default\Cache`
- **Sigur de șters:** ✅ DA
- **Impact:** Chrome va re-descărca paginile web (mai lent la prima accesare)
- **Comandă ștergere:**
  ```powershell
  Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
  ```

---

## ⚠️ CACHE-URI APLICAȚII (Verificare Necesară)

### **1. Nomic.ai / GPT4All - 21.92 GB** ⚠️⚠️⚠️
- **Path:** `C:\Users\flori\AppData\Local\nomic.ai`
- **Ce este:** GPT4All - aplicație open-source pentru chatbot-uri AI locale
- **Conținut:**
  - **Model AI:** `deepseek-coder-33b-instruct.Q5_K_M.gguf` - **22.4 GB** (99% din spațiu)
  - **Cache QML:** ~0.5 MB (53 fișiere) - ✅ SIGUR DE ȘTERS
  - **Log-uri:** ~0.1 MB - ✅ SIGUR DE ȘTERS
  - **Config:** ~0.1 MB - ⚠️ PĂSTREAZĂ
- **Recomandare:**
  - ✅ **Cache și log-uri pot fi șterse** (~1 MB total)
  - ⚠️ **Modelul AI (22.4 GB) poate fi șters DAR:**
    - Va trebui re-descărcat (va dura mult timp)
    - Consumă mult internet (22+ GB)
    - Dacă folosești GPT4All, păstrează-l
    - Dacă NU folosești GPT4All, poți șterge tot directorul
- **Comandă ștergere cache/log-uri (sigur):**
  ```powershell
  # Șterge doar cache-urile și log-urile (sigur)
  Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nomic.ai\GPT4All\cache" -ErrorAction SilentlyContinue
  Remove-Item -Force "$env:LOCALAPPDATA\nomic.ai\GPT4All\*.txt" -ErrorAction SilentlyContinue
  ```
- **Comandă ștergere completă (dacă NU folosești GPT4All):**
  ```powershell
  # ATENȚIE: Șterge tot, inclusiv modelul AI (22.4 GB)
  Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nomic.ai" -ErrorAction SilentlyContinue
  ```

### **2. Dart Server Cache - 1 GB** ⭐⭐
- **Path:** `C:\Users\flori\AppData\Local\.dartServer`
- **Sigur de șters:** ✅ DA (se va regenera)
- **Impact:** Dart Language Server va reindexa proiectele
- **Comandă ștergere:**
  ```powershell
  Remove-Item -Recurse -Force "$env:LOCALAPPDATA\.dartServer"
  ```

### **3. Playwright Cache - 0.98 GB** ⭐⭐
- **Path:** `C:\Users\flori\AppData\Local\ms-playwright`
- **Sigur de șters:** ✅ DA
- **Impact:** Playwright va re-descărca browsere la următorul test
- **Comandă ștergere:**
  ```powershell
  Remove-Item -Recurse -Force "$env:LOCALAPPDATA\ms-playwright"
  ```

### **4. Perplexity Cache - 1.22 GB** ⚠️
- **Path:** `C:\Users\flori\AppData\Local\Perplexity`
- **Sigur de șters:** ⚠️ VERIFICARE NECESARĂ
- **Impact:** Poate conține date de sesiune
- **Recomandare:** Verifică manual

### **5. LM Studio Updater - 0.5 GB** ⭐
- **Path:** `C:\Users\flori\AppData\Local\lm-studio-updater`
- **Sigur de șters:** ✅ DA
- **Impact:** Updater-ul va re-descărca la următoarea actualizare
- **Comandă ștergere:**
  ```powershell
  Remove-Item -Recurse -Force "$env:LOCALAPPDATA\lm-studio-updater"
  ```

---

## 📊 SUMAR

| Categorie | Spațiu | Sigur de șters |
|-----------|--------|----------------|
| **Cache-uri sigure** | **14.59 GB** | ✅ DA |
| **Cache-uri aplicații** | **25.62 GB** | ⚠️ Verificare |
| **TOTAL POTENȚIAL** | **~40 GB** | - |

---

## 🚀 COMANDĂ RAPIDĂ PENTRU ȘTERGERE CACHE-URI SIGURE

```powershell
# Șterge toate cache-urile sigure (14.59 GB)
Write-Host "Ștergere cache-uri sigure..." -ForegroundColor Yellow

# Gradle Cache
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches" -ErrorAction SilentlyContinue
Write-Host "✅ Gradle Cache șters" -ForegroundColor Green

# Temp Files
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Temp\*" -ErrorAction SilentlyContinue
Write-Host "✅ Temp Files șterse" -ForegroundColor Green

# NPM Cache
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\npm-cache" -ErrorAction SilentlyContinue
Write-Host "✅ NPM Cache șters" -ForegroundColor Green

# Pub Cache
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub" -ErrorAction SilentlyContinue
Write-Host "✅ Pub Cache șters" -ForegroundColor Green

# Chrome Cache
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" -ErrorAction SilentlyContinue
Write-Host "✅ Chrome Cache șters" -ForegroundColor Green

# Dart Server Cache
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\.dartServer" -ErrorAction SilentlyContinue
Write-Host "✅ Dart Server Cache șters" -ForegroundColor Green

# Playwright Cache
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\ms-playwright" -ErrorAction SilentlyContinue
Write-Host "✅ Playwright Cache șters" -ForegroundColor Green

# LM Studio Updater
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\lm-studio-updater" -ErrorAction SilentlyContinue
Write-Host "✅ LM Studio Updater Cache șters" -ForegroundColor Green

Write-Host "" -ForegroundColor Green
Write-Host "✅ Cache-uri sigure șterse! Spațiu eliberat: ~15 GB" -ForegroundColor Green
```

---

## ⚠️ ATENȚIE

1. **Nomic.ai / GPT4All (21.92 GB)** - Conține model AI descărcat
   - Dacă **FOLOSEȘTI** GPT4All: Șterge doar cache/log-uri (~1 MB)
   - Dacă **NU FOLOSEȘTI** GPT4All: Poți șterge tot (22.4 GB eliberat)
2. **Perplexity (1.22 GB)** - Verifică manual înainte de ștergere
3. **Backup înainte** - Dacă ești nesigur, fă backup la fișierele importante

---

## 📝 NOTĂ

După ștergerea cache-urilor:
- Gradle: Va re-descărca dependențele la următorul build (poate dura câteva minute)
- NPM: Va re-descărca pachetele la următorul `npm install`
- Flutter: Va re-descărca pachetele la următorul `flutter pub get`
- Chrome: Va re-descărca paginile web (mai lent la prima accesare)

**Recomandare:** Șterge cache-urile sigure (14.59 GB) și verifică manual cache-urile aplicațiilor înainte de ștergere.

