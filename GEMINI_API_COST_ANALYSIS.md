# 📊 Analiză Costuri Gemini API pentru FriendsRide

## 🎯 Modelul Folosit
- **Model Actual**: `gemini-pro` (API v1)
- **Istoric**:
  1. **Inițial**: `gemini-pro` (modelul original folosit)
  2. **Încercare**: `gemini-1.5-flash` (am încercat să trecem pentru costuri mai mici)
  3. **Problema**: `gemini-1.5-flash` nu era disponibil în v1beta pentru `generateContent` (eroare 404)
  4. **Revenire**: `gemini-pro` (modelul stabil și disponibil)

## 💰 Prețuri Gemini API (estimare 2024)

### 📊 Comparație Prețuri: Gemini Pro vs Gemini 1.5 Flash

| Model | Input (per milion tokeni) | Output (per milion tokeni) | Observații |
|-------|---------------------------|----------------------------|------------|
| **Gemini Pro** | ~$0.50 | ~$1.50 | Model complet, mai precis, mai lent |
| **Gemini 1.5 Flash** | ~$0.075 | ~$0.30 | Model rapid, optimizat pentru viteză, mai ieftin |

### ⚠️ Diferență de Cost: **6-7x mai scump pentru Pro!**

**Exemplu pentru 1 milion tokeni:**
- **Flash**: $0.075 (input) + $0.30 (output) = **$0.375**
- **Pro**: $0.50 (input) + $1.50 (output) = **$2.00**
- **Diferență**: Pro costă **~5.3x mai mult** decât Flash

### 💰 Prețuri Gemini Pro (modelul actual folosit)

#### Prețuri Standard:
- **Input (prompt)**: ~$0.50 per milion tokeni
- **Output (răspuns)**: ~$1.50 per milion tokeni

### Tier Gratuit (Google AI Studio):
- **15 RPM** (requests per minute)
- **1,500 RPD** (requests per day)
- **1M tokeni/zi** pentru input
- **1M tokeni/zi** pentru output

## 📈 Utilizare în FriendsRide

### 1. Procesarea Comenzilor Vocale (`processVoiceInput`)
- **Când**: La fiecare comandă vocală a utilizatorului
- **Frecvență**: ~1-2 apeluri per comandă de cursă
- **Tokeni Input**: ~200-400 tokeni (prompt + context)
- **Tokeni Output**: ~50-150 tokeni (răspuns JSON)

### 2. Clarificarea Adreselor (`clarifyAddressForGeocoding`)
- **Când**: Doar când geocoding-ul standard eșuează (~10-20% din cazuri)
- **Frecvență**: ~0.1-0.2 apeluri per comandă de cursă
- **Tokeni Input**: ~150-250 tokeni (prompt pentru clarificare)
- **Tokeni Output**: ~50-100 tokeni (JSON cu adresă + coordonate)

## 💵 Estimare Costuri

### Scenariu 1: Utilizare Mică (100 curse/lună)
- **Comenzi vocale**: 100 curse × 1.5 apeluri = 150 apeluri
- **Clarificări adrese**: 100 curse × 0.15 apeluri = 15 apeluri
- **Total apeluri**: 165 apeluri/lună

**Tokeni estimați:**
- Input: 165 × 300 tokeni = 49,500 tokeni (~0.05M)
- Output: 165 × 100 tokeni = 16,500 tokeni (~0.02M)

**Cost estimat (cu Gemini Pro):**
- Input: 0.05M × $0.50 = **$0.025**
- Output: 0.02M × $1.50 = **$0.03**
- **Total: ~$0.055/lună** (în tier-ul gratuit!)

**Cost estimat (cu Gemini Flash - dacă ar fi disponibil):**
- Input: 0.05M × $0.075 = **$0.00375**
- Output: 0.02M × $0.30 = **$0.006**
- **Total: ~$0.01/lună** (în tier-ul gratuit!)

### Scenariu 2: Utilizare Medie (1,000 curse/lună)
- **Comenzi vocale**: 1,000 × 1.5 = 1,500 apeluri
- **Clarificări adrese**: 1,000 × 0.15 = 150 apeluri
- **Total apeluri**: 1,650 apeluri/lună

**Tokeni estimați:**
- Input: 1,650 × 300 = 495,000 tokeni (~0.5M)
- Output: 1,650 × 100 = 165,000 tokeni (~0.17M)

**Cost estimat (cu Gemini Pro):**
- Input: 0.5M × $0.50 = **$0.25**
- Output: 0.17M × $1.50 = **$0.255**
- **Total: ~$0.505/lună** (încă în tier-ul gratuit!)

**Cost estimat (cu Gemini Flash - dacă ar fi disponibil):**
- Input: 0.5M × $0.075 = **$0.0375**
- Output: 0.17M × $0.30 = **$0.051**
- **Total: ~$0.09/lună** (încă în tier-ul gratuit!)

### Scenariu 3: Utilizare Mare (10,000 curse/lună)
- **Comenzi vocale**: 10,000 × 1.5 = 15,000 apeluri
- **Clarificări adrese**: 10,000 × 0.15 = 1,500 apeluri
- **Total apeluri**: 16,500 apeluri/lună

**Tokeni estimați:**
- Input: 16,500 × 300 = 4,950,000 tokeni (~5M)
- Output: 16,500 × 100 = 1,650,000 tokeni (~1.65M)

**Cost estimat (cu Gemini Pro):**
- Input: 5M × $0.50 = **$2.50**
- Output: 1.65M × $1.50 = **$2.475**
- **Total: ~$4.975/lună** (depășește tier-ul gratuit, dar cost rezonabil)

**Cost estimat (cu Gemini Flash - dacă ar fi disponibil):**
- Input: 5M × $0.075 = **$0.375**
- Output: 1.65M × $0.30 = **$0.495**
- **Total: ~$0.87/lună** (depășește tier-ul gratuit, dar cost foarte mic!)

### Scenariu 4: Utilizare Foarte Mare (100,000 curse/lună)
- **Comenzi vocale**: 100,000 × 1.5 = 150,000 apeluri
- **Clarificări adrese**: 100,000 × 0.15 = 15,000 apeluri
- **Total apeluri**: 165,000 apeluri/lună

**Tokeni estimați:**
- Input: 165,000 × 300 = 49,500,000 tokeni (~50M)
- Output: 165,000 × 100 = 16,500,000 tokeni (~16.5M)

**Cost estimat (cu Gemini Pro):**
- Input: 50M × $0.50 = **$25.00**
- Output: 16.5M × $1.50 = **$24.75**
- **Total: ~$49.75/lună**

**Cost estimat (cu Gemini Flash - dacă ar fi disponibil):**
- Input: 50M × $0.075 = **$3.75**
- Output: 16.5M × $0.30 = **$4.95**
- **Total: ~$8.70/lună**

## 🎁 Optimizări Implementate

### 1. Procesare Locală Inteligentă
- Multe comenzi simple sunt procesate local (fără API)
- Reducere estimată: **30-50%** din apeluri API

### 2. Fallback Local pentru Adrese
- Când API-ul eșuează, folosim clarificare locală
- Reducere estimată: **10-20%** din apeluri API pentru clarificare

### 3. Cache și Reutilizare
- Contextul conversației este reutilizat
- Reducere estimată: **5-10%** din tokeni

## 📊 Concluzie

### ✅ Costuri cu Gemini Pro (modelul actual)
- Pentru **majoritatea aplicațiilor** (până la 10,000 curse/lună): **~$5/lună**
- Pentru **aplicații mari** (100,000 curse/lună): **~$50/lună**
- **Tier-ul gratuit** acoperă până la ~500-1,000 curse/lună

### 💰 Costuri cu Gemini Flash (dacă ar fi disponibil)
- Pentru **majoritatea aplicațiilor** (până la 10,000 curse/lună): **sub $1/lună**
- Pentru **aplicații mari** (100,000 curse/lună): **~$9/lună**
- **Tier-ul gratuit** acoperă până la ~1,000-2,000 curse/lună

### ⚖️ De ce folosim Gemini Pro?
- **Istoric**: Inițial foloseam deja `gemini-pro` (modelul original)
- **Încercare Flash**: Am încercat să trecem la `gemini-1.5-flash` pentru costuri mai mici (5-6x mai ieftin)
- **Problema**: `gemini-1.5-flash` nu este disponibil în API v1beta pentru `generateContent` (am primit eroare 404)
- **Revenire la Pro**: Am revenit la `gemini-pro` care este:
  - **Disponibil**: Modelul standard și stabil în API v1
  - **Precis**: Oferă răspunsuri mai precise (important pentru recunoașterea adreselor)
  - **Cost rezonabil**: Chiar dacă e mai scump decât Flash, costurile rămân foarte mici pentru majoritatea aplicațiilor

### 💡 Recomandări
1. **Folosește tier-ul gratuit** pentru testare și lansare inițială
2. **Monitorizează utilizarea** în Google AI Studio dashboard
3. **Optimizează prompt-urile** pentru a reduce tokeni (deja făcut!)
4. **Folosește fallback-ul local** când este posibil (deja implementat!)

### 🚀 Comparație cu Alte Servicii
- **OpenAI GPT-4**: ~$30-60 per milion tokeni (mult mai scump!)
- **Gemini Pro**: ~$0.50-1.50 per milion tokeni (**20-120x mai ieftin decât GPT-4!**)
- **Gemini 1.5 Flash**: ~$0.075-0.30 per milion tokeni (**100-400x mai ieftin decât GPT-4!**)

## 📝 Notă Importantă
Prețurile pot varia în funcție de:
- Regiunea ta
- Volumul de utilizare (discount-uri pentru volume mari)
- Actualizările Google AI

**Verifică prețurile actuale**: https://ai.google.dev/pricing

