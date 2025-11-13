# 2025-11-13 - Email/Password Login Switch

## Context
- Gli utenti test stavano bloccati sulla schermata magic link perché l'OTP arrivava in ritardo e il flusso non permetteva di inserire una password.
- Il login Google verrà reintrodotto dopo aver completato il QA dei provider esterni.

## Decisions
- L'onboarding ora usa esclusivamente email + password (sign-up e login) tramite Supabase Auth.
- Il form AuthPage gestisce toggle login/registrazione, validazioni (email valida, password >= 8 caratteri, conferma password) e feedback via SnackBar.
- Google OAuth e magic link sono nascosti/disattivati fino alla milestone successiva.

## Impact
- `lib/features/auth/presentation/auth_page.dart` sostituisce il flusso magic link con campi password + conferma e chiama `signInWithPassword`/`signUp`.
- Spec `priority1_auth_profiles` aggiornata per riflettere il nuovo scope e la dismissione temporanea dei provider esterni.
- Supabase Dashboard deve avere attivo solo il provider email/password; Google può restare disabilitato.

## Follow-up
- Quando l'MVP sarà stabile, pianificare la riattivazione guidata di magic link + Google/Apple con relative checklist QA.
