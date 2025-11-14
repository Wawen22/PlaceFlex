# Priorità 1 - Autenticazione & Profili Base

> **Status**: ✅ Completed & Archived (Nov 2025). Auth + profile editing are live in app build `v0.5.0`. Reactivate this spec only if we expand auth providers or profile capabilities.

## Scope
- Onboarding tramite email + password (sign-up e login) su Supabase Auth con deep link custom `io.placeflex.app://auth-callback`
- Magic link e OAuth Google rinviati a una milestone successiva, riattivati solo dopo validazione dell'MVP
- Gestione sessioni con PKCE + deep link custom `io.placeflex.app://auth-callback`
- Profilo utente con campi `display_name`, `username`, `bio`, `avatar_url`, `role`
- Editing profilo direttamente dall'app e persistente su Supabase

## User Stories
1. **Come explorer** voglio autenticarmi con email e password per accedere da qualsiasi device senza passare dalla mail.
2. **Come nuovo utente** voglio creare un account direttamente dall'app scegliendo una password sicura.
3. **Come creator** voglio impostare nome, username e bio per presentarmi alla community.
4. **Come sistema** voglio creare automaticamente il record profilo per ogni nuovo utente autenticato.

## Acceptance Criteria
- Login email/password mostra errori contestuali (email valida, password >= 8 caratteri) e feedback di successo
- Sign-up crea l'utente, mostra eventuale necessità di conferma email e porta l'utente autenticato nella home
- Toggle tra login e registrazione senza perdere i dati inseriti; le password vengono sempre verificate lato client
- Google OAuth e magic link risultano disabilitati finché non viene completato il QA dedicato
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
- Supabase dashboard: redirect URL consentito `io.placeflex.app://auth-callback` e provider email/password attivato (Google disattivato temporaneamente)

## Open Questions / Next Steps
- Riattivare magic link / OAuth Google dopo aver definito UX e test QA
- Integrare provider Apple/Sign in with Apple prima della pubblicazione iOS
- Decidere naming strategy per suggerire automaticamente username alla prima login
- Gestire upload avatar (richiede Storage bocket + CDN)
- Collegare ruoli a permessi di moderazione nelle feature successive
