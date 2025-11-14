# Map viewport fetch + RPC filters

**Date**: 14 Nov 2025  
**Status**: ✅ Done (code + tests)

---

## Why
- La mappa caricava sempre i momenti entro 5 km dal centro → payload inutili e niente aggiornamento dinamico quando l’utente si spostava.
- I filtri UI agivano solo client-side: il backend inviava comunque tutti i media.
- Gli RPC PostGIS non esponevano ancora un filtro `media_types`, quindi non potevamo delegare la selezione al DB.

## What changed
1. **Database**
   - Nuova migration `20251114_update_moments_spatial_filters.sql`: `get_nearby_moments` e `get_moments_in_bounds` accettano `media_types moment_media_type[]`.
2. **Repository**
   - `MomentsRepository.getNearbyMoments` / `getMomentsInBounds` espongono `List<MomentMediaType>? mediaTypes` e passano il nuovo parametro RPC.
   - Unit test aggiornati con mock RPC (verifica dei parametri e conversione enums → stringhe).
3. **Map UX**
   - `MapScreen` ascolta `MapWidget.onCameraChangeListener/onMapIdleListener`, calcola i bounds reali (con padding) e chiama `get_moments_in_bounds`.
   - Debounce 600 ms, overlay “Aggiornamento area” e filtro server-side immediato quando l’utente tocca i toggle.
   - Fetch iniziale (fallback raggio) resta per bootstrap, poi tutto passa dal viewport.

## Follow-up / Next
1. Implementare cache icone marker + animazioni (resta il punto principale del backlog Priority 3).
2. Considerare progress indicator sulla bottom sheet se `_isViewportLoading` dura >1s.
3. Collegare i nuovi RPC alla parte web/admin quando introdurremo moderation tooling.

---

*Authored by Codex - 14/11/2025.*
