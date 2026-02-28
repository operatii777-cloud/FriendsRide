# Script automat pentru curățare repo cu BFG Repo-Cleaner
# Salvează acest fișier ca bfg_clean.ps1 în folderul proiectului
# Asigură-te că ai descărcat bfg.jar din https://rtyley.github.io/bfg-repo-cleaner/

# 1. Expiră toate referințele vechi
Write-Host "Expiră referințe vechi..."
git reflog expire --expire=now --all

# 2. Garbage collection agresiv
Write-Host "Rulează garbage collection..."
git gc --prune=now --aggressive

# 3. Șterge fișierele mari din istorie
Write-Host "Șterge fișiere .dill..."
java -jar bfg.jar --delete-files *.dill
Write-Host "Șterge fișiere .bin..."
java -jar bfg.jar --delete-files *.bin
Write-Host "Șterge foldere .dart_tool..."
java -jar bfg.jar --delete-folders .dart_tool
Write-Host "Șterge foldere build..."
java -jar bfg.jar --delete-folders build
Write-Host "Șterge foldere android/.gradle..."
java -jar bfg.jar --delete-folders android/.gradle

# 4. Expiră din nou referințele
Write-Host "Expiră referințe după curățare..."
git reflog expire --expire=now --all

# 5. Garbage collection final
Write-Host "Rulează garbage collection final..."
git gc --prune=now --aggressive

# 6. Push forțat pe GitHub
Write-Host "Push forțat pe GitHub..."
git push --force origin main

Write-Host "Curățare completă! Repo-ul tău este gata pentru push pe GitHub."
