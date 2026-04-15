# <img src="LavoraMi/Assets.xcassets/AppIcon-iOS-Default-1024x1024@1x.png" alt="Icon" width="30px" height="30px"> LavoraMi

<div align="center">

[![iOS](https://img.shields.io/badge/iOS-17.4%2B-blue.svg?style=flat)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0%2B-orange.svg?style=flat)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat)](LICENSE)
[![Repository](https://img.shields.io/badge/GitHub-LavoraMi--iOS-black?style=flat&logo=github)](https://github.com/Andrea-Filice/LavoraMi-iOS)

Un'app iOS intuitiva per monitorare i lavori di manutenzione del trasporto pubblico.

 **[Segnala un Bug](https://github.com/Andrea-Filice/LavoraMi-iOS/issues)** • **[Richiedi una Feature](https://github.com/Andrea-Filice/LavoraMi-iOS/issues)**

</div>

---

## 📋 Indice

- [Panoramica](#-panoramica)
- [Caratteristiche](#-caratteristiche)
- [Requisiti](#-requisiti)
- [Installazione](#-installazione)
- [Architettura](#-architettura)
- [Contributi](#-contributi)
- [Licenza](#-licenza)

---

## 🎯 Panoramica

**LavoraMi** è un'applicazione iOS progettata per fornire informazioni in tempo reale sui lavori di manutenzione che interessano le reti di trasporto pubblico. L'app consente agli utenti di:

- Visualizzare i lavori in corso e pianificati
- Tracciare il progresso dei lavori con timeline interattive
- Consultare le linee di trasporto interessate
- Ricevere notifiche sullo stato dei lavori

Perfetta per pendolari che desiderano rimanere sempre informati sulle interruzioni e le modifiche ai servizi di trasporto.

---

## ✨ Caratteristiche

### 📱 Interfaccia Utente
- **Tab Navigation** - Navigazione intuitiva tra sezioni
  - 🏠 **Home** - Visualizzazione riepilogativa dei lavori
  - 🚇 **Linee** - Dettagli specifici per ogni linea di trasporto
  - ⚙️ **Impostazioni** - Localizzazione geografica dei lavori

### 🔔 Notifiche
- Avvisi in tempo reale sullo stato dei lavori
- Notifiche personalizzabili per linee specifiche
- Gestione centralizzata delle notifiche

### 🗺️ Integrazione Mappe
- Visualizzazione dei lavori su mappa interattiva
- Indicazione geografica delle stazioni interessate
- Integrazione con MapKit di Apple

### 🎨 Design Moderno
- Interfaccia nativa SwiftUI
- Design responsivo e accessibility-focused
- Supporto per modalità scura

---

## 📋 Requisiti

- **iOS** 17.0 o superiore
- **Xcode** 26.0 o superiore
- **Swift** 6.0 o superiore
- **Dispositivo** iPhone o simulatore iOS

---

## 🚀 Installazione

### Clonare il Repository
```bash
git clone https://github.com/Andrea-Filice/LavoraMi-iOS.git
cd LavoraMi-iOS
```

### Aprire in Xcode
```bash
open LavoraMi.xcodeproj
```

### Compilare e Eseguire
1. Selezionare il dispositivo target (iPhone simulato o reale)
2. Premere `Cmd + R` per compilare ed eseguire
3. L'app si avvierà automaticamente sul dispositivo

### Requisiti di Build
- Nessuna dipendenza esterna richiesta (build autoportante)
- Tutte le librerie utilizzate sono native di Apple

---

## 🏗️ Architettura

### Architettura MVVM
L'app segue il pattern **Model-View-ViewModel**:

```
┌─────────────────────────────────────┐
│           SwiftUI Views             │
│    (MainView, LinesView, MapView)   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       WorkViewModel                 │
│   (Business Logic & State)          │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│          Data Layer                 │
│  (StationsDB, NotificationManager)  │
└─────────────────────────────────────┘
```

### Componenti Principali

| File | Descrizione |
|------|-------------|
| `WorkViewModel.swift` | Gestione dello stato e della logica di business |
| `StationsDB.swift` | Database locale e persistenza dei dati |
| `NotificationManager.swift` | Gestione delle notifiche push |
| `AppDelegate.swift` | Configurazione dell'applicazione |
| `ContentView.swift` | View principale con tab navigation |

---

## 🤝 Contributi

I contributi sono benvenuti! Per contribuire:

1. **Fork** il repository
2. **Crea un branch** per la tua feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** le tue modifiche (`git commit -m 'Add AmazingFeature'`)
4. **Push** al branch (`git push origin feature/AmazingFeature`)
5. **Apri una Pull Request**

### Linee Guida per i Contributi
- Seguire lo stile di codice Swift
- Includere commenti per codice complesso
- Testare le modifiche prima di inviare la PR
- Aggiornare la documentazione se necessario


---

## 🐛 Segnalazione Bug

Hai trovato un bug? Per favore, [apri un issue](https://github.com/Andrea-Filice/LavoraMi-iOS/issues) con:
- Descrizione del problema
- Passaggi per riprodurlo
- Comportamento atteso vs. reale
- Versione iOS e dispositivo

---

## 💡 Richieste di Feature

Hai un'idea per migliorare LavoraMi? [Suggerisci una feature](https://github.com/Andrea-Filice/LavoraMi-iOS/issues) descrivendo:
- L'idea e il beneficio per l'utente
- Possibili casi d'uso
- Eventuali alternative considerate

---

## 📄 Licenza

Questo progetto è licenziato sotto la Licenza MIT - vedi il file [LICENSE](LICENSE) per i dettagli.

```
MIT License

Copyright (c) 2026 Andrea Filice

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or copies
of the Software, and to permit persons to whom the Software is furnished to
do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 👨‍💻 Autore

**Andrea Filice**
- 🔗 [GitHub](https://github.com/Andrea-Filice)
- 📧 Contattami attraverso il repository

---

<div align="center">

**Fatto con ❤️ per chi ama la mobilità urbana milanese**

[![GitHub Stars](https://img.shields.io/github/stars/Andrea-Filice/LavoraMi-iOS?style=social)](https://github.com/Andrea-Filice/LavoraMi-iOS)
[![GitHub Followers](https://img.shields.io/github/followers/Andrea-Filice?style=social)](https://github.com/Andrea-Filice)

</div>
