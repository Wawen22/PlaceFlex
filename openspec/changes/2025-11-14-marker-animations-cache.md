# Marker animations & icon cache

**Date**: 14 Nov 2025  
**Status**: ✅ Landed (map polish)

---

## Why
- Marker icons venivano ridisegnati a ogni refresh → perdita di performance e `style.addImage` continuo.
- Nessun feedback visivo quando un utente toccava un marker o quando appariva un nuovo momento sulla mappa.
- Priorità 3 lasciava aperta la voce “Marker Animations / Performance” nel backlog nice-to-have.

## What changed
1. **Icon cache**
   - `lib/features/map/presentation/map_screen.dart` mantiene ora cache in memoria (`_CachedIcon`) per marker per tipo/tema e per cluster (bucketizzati).
   - Le immagini vengono ri-registrate automaticamente quando Mapbox ricarica lo style (listener `onStyleLoadedListener`).
   - Gli RPC server-side filtrano già per media type, quindi la mappa crea solo le icone necessarie.
2. **Viewport UX**
   - `MapWidget` usa direttamente i callback `onCameraChangeListener`/`onMapIdleListener`; `_fetchMomentsForCurrentViewport` applica throttle a 600 ms con badge “Aggiornamento area”.
3. **Marker animations**
   - Nuovi helper `_animateMarkerEntrance` (bounce elastico quando vengono creati) e `_playMarkerTapFeedback` (scale 1.2x → 1.0x sui tap).
   - Tap logic ora usa mapping `annotation.id → momentId`, quindi niente più confronti sulle coordinate.

## Follow-up
- Rimane opzionale il “pulse continuo / stagger delay” per i marker idling (non urgente ma previsto in spec).
- Progressive loading delle annotazioni e ottimizzazione delle immagini cluster oltre i bucket attuali.

---

*Authored by Codex agent — 14/11/2025.*
