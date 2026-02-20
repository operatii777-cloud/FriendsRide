# 📊 Dashboard Manual Integration Guide

**Versiune:** 1.0  
**Data:** 2025-01-28

---

## 🎯 Overview

Dashboard Manual este destinat restaurante mici care nu au un sistem propriu de management și doresc să folosească FriendsRide Delivery prin interfața web manuală.

---

## 🚀 Accesare Dashboard

### **1. Autentificare**

1. Accesați: `https://dashboard.friendsride.com`
2. Autentificați-vă cu contul restaurantului
3. Accesați secțiunea "Delivery"

### **2. Prima Configurare**

După autentificare, veți fi ghidat prin:

- Configurare informații restaurant
- Setări livrare (taxă, timp estimat, zone)
- Generare API key (opțional, pentru integrare viitoare)

---

## 📋 Funcționalități

### **1. Menu Management**

#### **Adăugare Produs Manual**

1. Accesați tab-ul "Meniu"
2. Click pe "Adaugă produs"
3. Completați formularul:
   - Nume produs
   - Descriere
   - Preț
   - Categorie
   - Imagine (opțional)
   - Alergeni (opțional)
   - Modificări disponibile (opțional)

#### **Import CSV/Excel**

1. Pregătiți fișierul CSV cu următoarea structură:

```csv
name,description,price,category,imageUrl,isAvailable
Pizza Margherita,Pizza clasică,35.00,Pizza,https://...,true
Pizza Pepperoni,Pizza cu pepperoni,40.00,Pizza,https://...,true
```

2. Click pe "Import CSV"
3. Selectați fișierul
4. Verificați datele și confirmați importul

#### **Editare/Ștergere Produse**

- Click pe iconița de edit pentru a modifica un produs
- Click pe iconița de ștergere pentru a șterge un produs

---

### **2. Order Management**

#### **Vizualizare Comenzi**

Tab-ul "Comenzi" afișează toate comenzile:
- Filtrare după status (Toate, În așteptare, Gata, etc.)
- Detalii comandă (produse, total, adresă)
- Acțiuni rapide (marchează ca gata, etc.)

#### **Actualizare Status Comandă**

1. Găsiți comanda în listă
2. Click pe comanda pentru detalii
3. Click pe butonul de acțiune:
   - "Marchează ca se pregătește" - când începeți să pregătiți
   - "Marchează ca gata" - când comanda este gata pentru pickup

---

### **3. Settings**

#### **Informații Restaurant**

- Nume restaurant
- Descriere
- Adresă
- Telefon
- Email
- Tipuri bucătărie

#### **Setări Livrare**

- **Taxă livrare:** Preț fix sau bazat pe distanță
- **Timp estimat:** Timp mediu de livrare (minute)
- **Zone livrare:** Zonele în care livrați
- **Comandă minimă:** Valoarea minimă pentru comandă

#### **API Key Management**

- Vezi API key-ul actual
- Regenerează API key (dacă e compromis)
- Revocă API key (dezactivează)

---

## 📱 Mobile App

Dashboard-ul este disponibil și ca aplicație Flutter pentru restaurante:

1. Descărcați aplicația FriendsRide Restaurant
2. Autentificați-vă cu același cont
3. Accesați funcționalitățile de management

---

## 🔔 Notificări

Dashboard-ul trimite notificări pentru:

- Comenzi noi
- Actualizări status comandă
- Mesaje de la clienți
- Alerte importante

---

## 📊 Rapoarte

### **Rapoarte Disponibile**

- **Vânzări zilnice/săptămânale/lunare**
- **Produse populare**
- **Comenzi pe status**
- **Venituri și comisioane**

### **Export Date**

- Export CSV pentru rapoarte
- Export PDF pentru facturare
- Export Excel pentru analiză

---

## 🆘 Support

Pentru întrebări sau probleme:

---
- **Email:** dashboard-support@friendsride.com
- **Chat:** Disponibil în dashboard
- **Telefon:** +40 XXX XXX XXX

---

## 📚 Tutoriale Video

- [Cum adaugi produse în meniu](<https://docs.friendsride.com/tutorials/add-products>)
- [Cum gestionezi comenzi](<https://docs.friendsride.com/tutorials/manage-orders>)
- [Cum configurezi setările](<https://docs.friendsride.com/tutorials/settings>)
