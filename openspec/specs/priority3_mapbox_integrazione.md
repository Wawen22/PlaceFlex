# Priorità 3 — Integrazione Mapbox e mappa momenti

**Status**: 🟢 95% Complete (Nov 13, 2025)  
**Remaining**: Marker animations, Performance optimizations (post-MVP)

## ✅ Implementazioni Completate

### Core Features (85% → 95%)
- ✅ **Mapbox SDK Integration** - Configurato con .env e strings.xml Android
- ✅ **MapScreen** - Mappa interattiva con dark/light theme
- ✅ **Custom Marker Icons** - 4 varianti per tipo media (photo/video/audio/text)
- ✅ **Filter System** - Toggle UI con glassmorphism per filtrare per tipo
- ✅ **Clustering Intelligente** - Grid-based algorithm, zoom threshold 13.0
- ✅ **Cluster Tap Handling** - Zoom to bounds con animazione smooth
- ✅ **User Location Marker** - Blue circle pulsante + accuracy radius
- ✅ **Real-time Position Stream** - Aggiornamento posizione ogni 10m
- ✅ **PostGIS RPC Functions** - get_nearby_moments, get_moments_in_bounds
- ✅ **Marker Tap Interaction** - Bottom sheet con dettagli momento

### Recent Additions (Nov 13, 2025)
- ✅ **Cluster Expansion**: Tap su cluster → zoom to bounds animation (800ms, padding 100/50)
- ✅ **User Location Tracking**: CircleAnnotationManager con position stream
- ✅ **Accuracy Visualization**: Cerchio semi-trasparente per GPS uncertainty
- ✅ **Smart Zoom Calculation**: Target zoom basato su cluster span (empirico)

### Recent Additions (Nov 14, 2025)
- ✅ **Viewport-based Loading**: la mappa ora usa `get_moments_in_bounds` con bounding box reale + padding. Debounce da 600ms e overlay "Aggiornamento area".
- ✅ **Filtri Server-side**: gli RPC `get_nearby_moments` e `get_moments_in_bounds` accettano `media_types[]`; i toggle UI aggiornano subito il server.
- ✅ **UX Feedback**: indicatori top-right quando il fetch viewport è in corso (+ throttling per evitare spam di richieste).
- ✅ **Marker Icon Cache & Tap Feedback**: icone dei momenti riusabili via LRU cache, animazione bounce-on-appear e feedback di scala sui tap.

### Files Modified
- `lib/features/map/presentation/map_screen.dart` (878 LOC)
  - `_clusterData` Map per tracciare cluster → momenti
  - `_handleMarkerTap()` distingue cluster vs marker singoli
  - `_zoomToCluster()` calcola bounds e anima camera
  - `_initializeUserLocationMarker()` con CircleAnnotationManager
  - `_updateUserLocationMarker()` per real-time updates
  - Position stream listener (10m distance filter)

## ⏳ Remaining (5% - Post-MVP)

### Nice-to-Have Features
- [ ] **Marker Animations** (2-3 hours)
  - ✅ Bounce on appear + tap feedback (Nov 14, 2025)
  - Pulse animation continua (1.0→1.2→1.0, 2s loop)
  - Stagger delay per multiple markers / idle glow

- [ ] **Performance Optimizations** (4-6 hours)
  - ✅ Icon cache manager (LRU, max 50 entries) e ri-registrazione automatica delle immagini
  - ✅ Viewport-based loading (replace radius query) — resta progressive loading e prioritizzazione visiva
  - Debounce map movement (300ms) → parzialmente coperto via throttle fetch (600ms)
  - Progressive loading (visible markers first)

- [ ] **Advanced Features** (Post-MVP)
  - Heatmap layer per densità
  - Route drawing tra momenti
  - Offline map tiles
  - Custom map style branded

## Obiettivi Originali

**Status Originali**: Tutti completati ✅

## Deliverable principali

**Status**: ✅ Tutti completati al 95%

1. ✅ **SDK Mapbox Flutter** configurato con chiave API via `.env` (`MAPBOX_ACCESS_TOKEN`)
2. ✅ **MapScreen** dedicata con:
   - ✅ MapboxMap centrata sull'area corrente dell'utente
   - ✅ Layer di marker clusterizzati (zoom threshold 13.0) basati sui momenti pubblici
   - ✅ Pulsante FAB per ricalibrare la posizione corrente
   - ✅ **NEW**: Cluster tap handling con zoom to bounds
   - ✅ **NEW**: User location marker con real-time tracking
3. ✅ **Feed dati**:
   - ✅ Endpoint `MomentsRepository.getNearbyMoments({radius, center})` usando RPC PostGIS `ST_DWithin`
   - ✅ **NEW**: `getMomentsInBounds()` per viewport queries (preparato)
4. ✅ **UI/UX**:
   - ✅ Bottom sheet che mostra dettagli momento con glassmorphism design
   - ✅ Tap su marker → apre scheda dettaglio con titolo, descrizione, tags
   - ✅ **NEW**: Filter chips interattivi (photo/video/audio/text)
   - ✅ **NEW**: Status bar con contatore momenti
5. ✅ **Permessi & fallback**:
   - ✅ Gestione permessi location con fallback Milano centro

## Considerazioni tecniche
- Utilizzare `mapbox_maps_flutter` (>=1.0.0) con renderer v10.
- Creare provider di stile custom per brand PlaceFlex (palette, POI minimali).
- Gestire conversione coordinate PostGIS → GeoJSON FeatureCollection lato client.
- Introdurre modello `MomentFeature` con proprietà `Moment` + `LatLng`.
- Ottimizzare cluster con `GeoJSONSource` + `SymbolLayer` & `CircleLayer` per contatori.

## Sequenza attività
1. **Setup SDK**
   - Aggiungere dipendenze `mapbox_maps_flutter`, `collection` (per raggruppamenti) e definire token in `.env`.
   - Aggiornare AndroidManifest (`ACCESS_FINE_LOCATION`, `MAPBOX_DOWNLOADS_TOKEN` se necessario) e Info.plist.
2. **Repository**
   - Implementare metodo `fetchMomentsWithinBounds({southWest, northEast})` usando RPC Supabase o query PostgREST con `ST_MakeEnvelope`.
   - Estendere DTO `Moment` con helper `toGeoJsonFeature()`.
3. **Presentation layer**
   - Creare `MapMomentsController` (ChangeNotifier) per gestire stato caricamento, errori, risultati.
   - Aggiungere nuova voce nel `HomeShell` per navigare alla mappa.
   - Implementare Map screen con bottom sheet (DraggableScrollableSheet) per lista momenti.
4. **Analytics & Telemetria**
   - Tracciare eventi "map_opened", "map_marker_tapped" per future integrazioni (placeholder log).
5. **Accessibilità**
   - Fornire etichette semantiche ai marker, fallback lista quando Mapbox non disponibile.

## Testing
- **Unit test** per `MomentsRepository.fetchMomentsWithinBounds` con query param generati correttamente.
- **Widget test** per `MapScreen` (mock Mapbox controller) assicurando stato loading/error.
- **Manuale**: verifica su emulatori Android/iOS con token Mapbox reale, cluster e markers coerenti.

## Rischi & mitigazioni
- **Costi Mapbox**: impostare limiti di richiesta e caching; monitorare da dashboard Mapbox.
- **Permessi location**: riutilizzare logica `Geolocator` con fallback coordinate statiche.
- **Prestazioni**: usare bounding box server-side per ridurre payload; limitare a 200 features per call.

## Dipendenze esterne
- Mapbox account PlaceFlex + token con scope `styles:read`, `maps:read`.
- Supabase PostGIS (assicurarsi indici su `location`).
