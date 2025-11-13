# Verifica feature "Creazione Momenti"

Questa checklist copre test manuali e automatici per garantire l'integrità della creazione momenti,
il collegamento con Supabase Storage e la tabella `public.moments`.

## Prerequisiti
- Ambiente Flutter funzionante con accesso al progetto Supabase `gbttlyrczgabuzggctzy`.
- Variabili d'ambiente `.env` configurate (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
- Accesso alla dashboard Supabase con privilegi di amministrazione (per verificare Storage e SQL).

## Test manuali

### 1. Creazione momento fotografico
1. Autenticarsi nell'app con un account creator.
2. Dalla tab "Scopri", toccare il FAB `+` e aprire la schermata "Nuovo momento".
3. Inserire titolo e descrizione.
4. Lasciare selezionato il tipo **Foto** e scegliere un'immagine `.png` dalla galleria.
5. Selezionare visibilità **Pubblico**.
6. Toccare "Usa posizione attuale" e concedere i permessi di geolocalizzazione.
7. Verificare che i campi Latitudine/Longitudine vengano valorizzati con 6 decimali.
8. Inserire alcuni tag separati da virgola.
9. Toccare "Pubblica momento" e attendere la snackbar di conferma.
10. Confermare su Supabase Storage che il file sia stato caricato nel bucket `moments/<profile_id>/` con estensione corretta.

### 2. Creazione momento solo testo
1. Ripetere i passaggi 1-3.
2. Selezionare il segmento **Testo**.
3. Lasciare vuota la selezione immagine e compilare coordinate manualmente.
4. Impostare visibilità **Privato**.
5. Pubblicare e verificare in dashboard SQL che il record creato non contenga `media_url`.

### 3. Validazione geolocalizzazione manuale
1. Disattivare temporaneamente i permessi di posizione per l'app (impostazioni OS).
2. Aprire "Nuovo momento" e provare "Usa posizione attuale": deve mostrare snackbar di errore.
3. Inserire manualmente coordinate precise (es. lat `45.464211`, lon `9.191383`).
4. Pubblicare e verificare in tabella che `location` memorizzi il punto `SRID 4326` con ordine `[lon, lat]`.

### 4. RLS e visibilità
1. Creare due account differenti (`creator A`, `creator B`).
2. Con `creator A`, creare un momento privato.
3. Con `creator B`, eseguire una query PostgREST su `/rest/v1/moments`: il momento privato non deve essere visibile.
4. Aggiornare il momento a `visibility = public` tramite dashboard e verificare che `creator B` ora lo veda.

## Test automatici

Eseguire i seguenti comandi:

- `flutter test test/features/moments/data/moments_repository_test.dart`
- `flutter test` (per l'intera suite)
- `flutter analyze`

I test unitari includono mock di Supabase Client e coprono:
- Upload su Storage con derivazione dell'estensione/mime type.
- Inserimento payload `location` `[lon, lat]`.
- Salvataggio momenti senza media per il tipo `text`.

## Verifiche Supabase

### Storage
- Percorso file previsto: `moments/<profile_id>/<profile_id>_<timestamp>.<ext>`.
- Il bucket deve essere pubblico (`public: true`).
- Controllare in `Storage -> Policies` che esista policy di lettura pubblica.

### Tabella `public.moments`
Eseguire in SQL Editor:
```sql
select id,
       profile_id,
       media_type,
       visibility,
       status,
       st_astext(location) as wkt,
       created_at,
       updated_at
  from public.moments
 order by created_at desc
 limit 10;
```

Verificare che:
- `location` venga serializzato come `POINT(lon lat)`.
- `updated_at` cambi dopo un update manuale (trigger `moments_handle_updated_at`).
- I record pubblici siano visibili anche senza `auth.uid()` impostato.

## Logging e osservabilità
- Monitorare la console di debug Flutter per errori `StorageException` o `PostgrestException`.
- In Supabase, controllare la sezione **Logs > Functions** per eventuali errori RLS.

## Uscite attese
- Snackbar "Momento pubblicato!" per ogni creazione riuscita.
- File accessibile via URL pubblico generato (test con browser o `curl`).
- Record coerente in tabella con `status = published` e `visibility` impostati in base alla selezione.
