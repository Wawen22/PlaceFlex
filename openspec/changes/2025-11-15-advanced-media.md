# Advanced media publish (video/audio) – 15 Nov 2025

**Status**: ✅ merged in repo  
**Scope**: Priority 2, estensione CreateMomentPage/MomentsRepository a foto+video+audio con limiti peso.

## Why
- Dovevamo sbloccare upload video/note vocali prima del polish Priority 3 e documentare i nuovi constraint.
- Mancavano colonne per tracciare size/duration + stato di processing (in vista delle future Edge Functions).
- Storage RLS non impediva upload over-size → rischio costi/CDN.

## What
1. **Flutter**
   - `CreateMomentPage2026` ora offre i 4 tipi (foto/video/audio/testo), preview con metadata e progress bar sull’azione “Pubblica”.
   - Registrazione audio integrata (`record` + `audioplayers`), compressione foto/video con `MomentMediaProcessor`, feedback errori quando si superano i limiti.
   - UI aggiornata con barra stato (preparazione/upload/salvataggio) e card metadata (size/durata).
2. **Repository & model**
   - Nuovo `PreparedMomentMedia`, callback di progresso e salvataggio `media_size_bytes`, `media_duration_ms`, `media_processing_status`.
   - Tests aggiornati per il nuovo payload.
3. **Backend**
   - Migrazioni `20251115_advanced_media_metadata.sql` (colonne + constraint + enum) e `20251115_storage_media_policy.sql` con funzione `moments_media_is_allowed`.
   - Placeholder Edge Function `supabase/functions/media-transcode`.
4. **Docs**
   - `priority2_creazione_momenti.md` riscritta con limiti peso, nuova checklist storage e riferimenti alle migrazioni.

## Test / QA
- `flutter test test/features/moments/data/moments_repository_test.dart`
- Manuale: upload foto 5MB (OK), video 60MB (OK), video 100MB (bloccato), audio 15MB (OK), audio 25MB (bloccato con snackbar).
- Verifica manuale nuove policy su bucket `moments`.
