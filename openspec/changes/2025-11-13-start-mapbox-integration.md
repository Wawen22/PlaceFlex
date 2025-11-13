# 2025-11-13 - Start Priority 3: Mapbox Integration

## Context
- Priorità 1 (Auth & Profiles) e Priorità 2 (Moments Creation) completate al 100%
- UI/UX Redesign 2026 completato con design system moderno
- L'app ora necessita della vista mappa per discovery locale dei momenti
- Gli utenti devono poter vedere i momenti pubblici nelle vicinanze

## Decisions
- Iniziare implementazione Priorità 3: Integrazione Mapbox
- Utilizzo di `mapbox_maps_flutter` (>=2.0.0) per SDK moderno
- Implementazione progressiva in sprint:
  1. Setup SDK e configurazione base
  2. MapScreen con posizione corrente
  3. Nearby moments query (ST_DWithin)
  4. Clustering dinamico e markers
  5. UI bottom sheet e dettaglio

## Implementation Plan

### Sprint 1: Foundation (Current)
- [ ] Aggiungere `mapbox_maps_flutter` a pubspec.yaml
- [ ] Configurare `MAPBOX_ACCESS_TOKEN` in .env
- [ ] Setup Android: ACCESS_FINE_LOCATION permissions
- [ ] Setup iOS: NSLocationWhenInUseUsageDescription
- [ ] Verificare funzionamento base con mappa vuota

### Sprint 2: Data Layer
- [ ] Implementare `MomentsRepository.getNearbyMoments()`
- [ ] Query PostGIS con ST_DWithin per raggio personalizzabile
- [ ] Convertire risultati in GeoJSON FeatureCollection
- [ ] Cache in-memory (60s) per ridurre chiamate

### Sprint 3: UI Layer
- [ ] Creare `MapScreen` con MapboxMap controller
- [ ] Integrare nel `HomeShell` come tab principale
- [ ] Posizionamento automatico su location utente
- [ ] FAB per recenter su posizione corrente
- [ ] Loading states e error handling

### Sprint 4: Clustering & Interactions
- [ ] Implementare clustering con GeoJSONSource
- [ ] SymbolLayer per singoli markers
- [ ] CircleLayer per cluster con contatori
- [ ] Tap handlers per navigare a dettaglio momento
- [ ] Bottom sheet con lista momenti nel viewport

### Sprint 5: Polish & Performance
- [ ] Ottimizzazioni performance (max 200 features)
- [ ] Bounding box queries per viewport
- [ ] Analytics tracking (map_opened, marker_tapped)
- [ ] Accessibility labels
- [ ] Testing su device reali

## Technical Considerations
- Mapbox renderer v11 (ultimo stabile)
- Custom style per brand PlaceFlex
- PostGIS già configurato con indice GIST su location
- RLS policies esistenti permettono query pubblica momenti

## Success Criteria
- Mappa funzionante con posizione utente
- Momenti visualizzati come markers
- Tap su marker → navigazione a dettaglio
- Performance 60fps su mid-range devices
- Clustering responsive tra zoom 12-18

## Risks & Mitigations
- **Costi Mapbox**: Monitorare da dashboard, implementare caching aggressivo
- **Permessi location**: Riutilizzare logica esistente con fallback
- **Performance**: Limitare features per viewport, usare bounding box

## Dependencies
- Supabase PostGIS ready (indice già presente)
- Moments table con RLS configurata
- Geolocator già integrato per permission handling

## Follow-up
- Considerare Maplibre come alternativa open-source post-MVP
- Pianificare filtri avanzati (tipo contenuto, data, autore)
- Heat map per densità momenti in aree popolari
