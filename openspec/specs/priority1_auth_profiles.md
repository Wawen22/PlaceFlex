# Priorità 1 — Autenticazione & Profili Base

## Scope
- Onboarding tramite magic link email (OTP) e OAuth Google su Supabase Auth
- Gestione sessioni con PKCE + deep link custom `io.placeflex.app://auth-callback`
- Profilo utente con campi `display_name`, `username`, `bio`, `avatar_url`, `role`
- Editing profilo direttamente dall'app e persistente su Supabase

## User Stories
1. **Come explorer** voglio ricevere un magic link via email per accedere rapidamente da mobile.
2. **Come utente Google** voglio autenticarmi senza creare una nuova password.
3. **Come creator** voglio impostare nome, username e bio per presentarmi alla community.
4. **Come sistema** voglio creare automaticamente il record profilo per ogni nuovo utente autenticato.

## Acceptance Criteria
- Invio magic link restituisce feedback all'utente (`SnackBar`) e gestisce errori di Supabase Auth
- OAuth Google apre il browser/app esterna e, al ritorno, l'utente risulta autenticato (`AuthChangeEvent.signedIn`)
- Sessione mantenuta tra riavvii grazie a storage locale Supabase
- Profili salvati su tabella `public.profiles` con RLS `auth.uid() = id`
- Constraint univocità su `username`; messaggio dedicato in caso di conflitto (violazione `23505`)
- Aggiornamento profilo aggiorna automaticamente `updated_at`

## Data Model
```sql
create type user_role as enum ('explorer', 'creator', 'admin');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  username text unique,
  bio text,
  avatar_url text,
  role user_role default 'explorer',
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

Trigger `profiles_handle_updated_at` imposta `updated_at = now()` su ogni update.

## Frontend Implementation Notes
- `Supabase.initialize` con `FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce)`
- Listener `auth.onAuthStateChange` per sincronizzare UI e notificare eventi (signin/signout/password recovery)
- `ProfileRepository` incapsula `getOrCreateProfile` + `updateProfile`
- `ProfilePage` gestisce form con validazione (username 3-20 char alfanumerici, `_` o `.`; bio ≤160 char)
- `HomeShell` presenta bottom navigation con placeholder vista mappa e tab profilo

## Configuration
- `.env` locale con `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- Android: intent-filter custom scheme `io.placeflex.app://auth-callback`
- iOS: `CFBundleURLTypes` configurato con stesso schema
- Supabase dashboard: redirect URL consentito `io.placeflex.app://auth-callback`

## Open Questions / Next Steps
- Integrare provider Apple/Sign in with Apple prima della pubblicazione iOS
- Decidere naming strategy per suggerire automaticamente username alla prima login
- Gestire upload avatar (richiede Storage bocket + CDN)
- Collegare ruoli a permessi di moderazione nelle feature successive
