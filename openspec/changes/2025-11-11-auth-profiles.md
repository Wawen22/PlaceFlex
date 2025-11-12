# 2025-11-11 — Sprint 0 Auth & Profile Setup

## Decisions
- Stack frontend: Flutter + Material 3; Map provider scelto: Mapbox (SDK Flutter) per personalizzazione e clustering vettoriale performante
- Auth flow PKCE con supabase_flutter 2.x, magic link email e OAuth Google

## Schema Updates
- `public.profiles`: aggiunti campi `username text unique`, `bio text`
- Trigger `profiles_handle_updated_at` per aggiornare `updated_at` su update

## App Implementation
- Scaffold progetto Flutter `placeflex_app` con configurazione `.env`
- Integrazione Supabase client e listener `auth.onAuthStateChange`
- UI Auth (`AuthPage`) con magic link + Google OAuth
- `HomeShell` con bottom nav e `ProfilePage` per editing nome/username/bio
- Repository dedicato per profili con auto-creazione record all'accesso
- Intent filter Android + URL Types iOS per deep link `io.placeflex.app://auth-callback`

## Tests & Tooling
- `flutter analyze` e `flutter test` eseguiti con successo
- Test placeholder in attesa di definire smoke test su flusso auth completo
