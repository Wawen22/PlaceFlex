# 📍 PlaceFlex

Una piattaforma social basata sulla geolocalizzazione per condividere momenti autentici legati a luoghi specifici.

## 🚀 Quick Start

### Prerequisiti
- Flutter SDK 3.35.7+
- Android Studio con Android SDK (API 31+)
- Account Supabase

### Setup

```powershell
# Clone e dipendenze
flutter pub get

# Configura Supabase
copy .env.example .env
# Modifica .env con le tue credenziali

# Avvia l'app
flutter run
```

## 🛠️ Sviluppo

### Test
```powershell
flutter test
```

### Build
```powershell
# Android
flutter build apk --release
```

## 📚 Documentazione

- **[Setup Windows](setup_windows_flutter.md)** - Guida completa per ambiente di sviluppo
- **[Redesign 2026](docs/REDESIGN_2026.md)** - Roadmap e specifiche tecniche

## 🏗️ Architettura

```
lib/
├── app/          # Configurazione e routing
├── core/         # Utilities e servizi condivisi
└── features/     # Feature modulari
```

## 🔧 Tech Stack

- **Framework**: Flutter 3.35.7
- **Backend**: Supabase (Auth, Storage, PostgreSQL)
- **Mappe**: Mapbox GL
- **State Management**: Provider/Riverpod
- **Architettura**: Clean Architecture

## 📝 License

Questo progetto è proprietario.

---

Made with 💙 by the PlaceFlex Team
