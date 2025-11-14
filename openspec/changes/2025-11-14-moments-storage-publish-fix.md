# Moments publishing fix & OpenSpec refresh

**Date**: 14 Nov 2025  
**Status**: ✅ Completed in repo (awaiting commit)

---

## Why
- Il pulsante "Pubblica" falliva con `StorageException ... violates row-level security policy` perché l'app cercava di creare il bucket tramite anon key → non consentito con le policy attive.
- Gli OpenSpec non riflettevano ancora il requisito di creare/RLSare il bucket manualmente e mancava l'archiviazione della Priority 1 ormai consegnata.

## What changed
1. **MomentsRepository**
   - Rimosso `_ensureBucketExists()` e la chiamata `createBucket(...)` in `lib/features/moments/data/moments_repository.dart`.
   - Ora ci appoggiamo a un bucket pre-provisionato; la creazione resta documentata in `database/migrations/20250115_fix_storage_rls.sql`.
2. **Tests**
   - Aggiornati `test/features/moments/data/moments_repository_test.dart` eliminando stub/verify su `createBucket` mantenendo la coverage su upload payload.
3. **Docs**
   - Nuova guida operativa `database/APPLY_THIS_FIX.md` già presente per riepilogare le policy Storage da impostare (referenziata nello spec).

## OpenSpec updates
- `openspec/specs/priority2_creazione_momenti.md`
  - Stato marcato come *feature-complete* per foto/testo.
  - Nuova sezione di checklist Storage & RLS e nota che il bucket deve esistere (non viene più creato lato client).
- `openspec/specs/archive/priority1_auth_profiles.md`
  - Spostato in `specs/archive/` con nota di chiusura (auth + profili live).

## Next steps / Ideas
1. QA manuale/automazione per garantire che le policy restino configurate sugli ambienti (script di verifica Supabase?).
2. Quando introdurremo video/audio, estendere la checklist per includere eventuali trasformazioni (Edge Functions) e limiti di peso.
3. Preparare infrastruttura per marker animations (Priority 3 restante) e per filtri lato backend (rpc `get_moments_in_bounds` da collegare alla UI).

---

*Change record authored by Codex agent on 14/11/2025.*
