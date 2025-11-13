# Priorità 3 — Integrazione Mapbox e mappa momenti

## Obiettivi
- Visualizzare i momenti pubblici su una mappa interattiva con clustering dinamico.
- Consentire agli utenti di filtrare i momenti per raggio e stato dalla vista mappa.
- Integrare la navigazione dalla mappa alla scheda dettaglio momento.

## Deliverable principali
1. **SDK Mapbox Flutter** configurato con chiave API via `.env` (`MAPBOX_ACCESS_TOKEN`).
2. **MapScreen** dedicata con:
   - MapboxMap centrata sull'area corrente dell'utente.
   - Layer di marker clusterizzati (zoom 12-18) basati sui momenti pubblici.
   - Pulsante FAB per ricalibrare la posizione corrente.
3. **Feed dati**:
   - Endpoint `MomentsRepository.getNearbyMoments({radius, center})` che interroga PostgREST usando `ST_DWithin`.
   - Cache in-memory breve (es. 60s) per evitare richieste ripetute.
4. **UI/UX**:
   - Bottom sheet che mostra lista momenti nel viewport.
   - Tap su marker → apre scheda dettaglio con titolo, anteprima foto e CTA "Vedi momento".
5. **Permessi & fallback**:
   - Gestione permessi location come in `CreateMomentPage` con fallback manuale a coordinate Milano centro.

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
