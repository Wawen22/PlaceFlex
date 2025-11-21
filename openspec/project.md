# Project Context

## Purpose
PlaceFlex è un'app mobile che trasforma luoghi fisici in bacheche di ricordi condivisi. L'obiettivo dell'MVP è validare discovery locale, creazione rapida di momenti multimediali e moderazione automatica per contenuti generati dagli utenti.

## Tech Stack
- Flutter 3 + Dart 3 per l'app mobile cross-platform
- Supabase (Auth, Postgres/PostGIS, Storage, Realtime, Edge Functions)
- Mapbox SDK per mappe vettoriali e clusterizzazione (integrazione successiva alla Priorità 1)
- Flutter DotEnv + Supabase Flutter SDK per la configurazione runtime
- Geolocator + permessi runtime per reperire coordinate precise dei momenti
- Image Picker per selezionare media da galleria (camera in roadmap)

## Project Conventions

### Code Style
- Dart style ufficiale con `flutter format`; nomi dei file in snake_case, classi in PascalCase
- Cartelle organizzate per feature (`features/auth`, `features/profile`, ecc.) e layer (presentation/data/models)

### Architecture Patterns
- Architettura modulare per feature con repository per l'accesso ai dati Supabase
- Gestione dello stato locale con `StatefulWidget` e controller dedicati; GoRouter verrà introdotto quando necessario per navigazione avanzata
- Supabase Auth gestito tramite stream `onAuthStateChange`
- Repository dedicati (`ProfileRepository`, `MomentsRepository`) che incapsulano accesso a Supabase PostgREST & Storage

### Testing Strategy
- Smoke test minimi per ora (`flutter test`), con piano di estendere a widget test sui flussi core (auth, profilo) man mano che le UI si stabilizzano
- Analisi statica con `flutter analyze` integrata nel workflow

### Git Workflow
- Branch principale `main` protetto; feature branches per sviluppo
- Convenzione commit: prefisso in inglese (es. `feat:`, `fix:`, `chore:`) seguito da descrizione concisa

## Domain Context
- Focus su contenuti geolocalizzati: ogni momento è legato a coordinate precise e visibile principalmente in loco
- Profili utente con ruoli (`explorer`, `creator`, `admin`) già modellati in Supabase per future estensioni di permessi

## Important Constraints
- Supabase è il backend vincolante per Auth, DB, Storage
- Geolocalizzazione e privacy conformi GDPR: consenso esplicito e minimizzazione dati
- Mappe devono essere performanti con clusterizzazione responsive tra zoom 12-18
- Storage bucket `moments` pubblico per CDN (gestito in creazione se mancante)

## External Dependencies
- Supabase project `gbttlyrczgabuzggctzy`
- Mapbox (chiavi da configurare per mappe vettoriali)
- Provider OAuth: Google (configurazione redirect `io.placeflex.app://auth-callback` richiesta)
- Futuri provider: OneSignal per push, Sentry/PostHog per monitoring

## Current Status (Updated: 2025-11-21)
- **Auth**: Implemented (Email/Password) with `AuthRepository`.
- **Map**: Backend implemented, Mapbox configured, Filters and Feed integrated.
- **Moments**: Creation flow (Media Capture, Upload) and Discovery (Feed) implemented.
- **Profile**: Completed. Premium UI implemented with Parallax Header and Grid Gallery.

