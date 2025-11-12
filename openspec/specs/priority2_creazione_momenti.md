# Priorità 2 — Creazione Momenti (Media + Metadata + CDN)

## Scope
- Creare e pubblicare momenti con titolo, descrizione, tag, visibilità e coordinate GPS
- Supporto iniziale per media fotografici (upload su Supabase Storage) e momenti solo testo
- Persistenza momenti in tabella `public.moments` con geodati (geometry Point 4326) per query spaziali

## User Stories
1. **Come creator** voglio allegare una foto al momento direttamente dalla galleria per mostrarla ad altri utenti nelle vicinanze.
2. **Come utente** voglio impostare visibilità pubblica/privata in modo da controllare chi può vedere i miei momenti.
3. **Come sistema** voglio salvare i momenti con geolocalizzazione accurata per abilitarne la discovery sulla mappa.

## Acceptance Criteria
- Selezione media da galleria disponibile per tipo `Foto`; tipo `Testo` non richiede file
- Upload automatico su bucket Supabase Storage `moments` con URL pubblico restituito al client
- Inserimento record su `public.moments` con RLS: proprietario gestisce CRUD, selezione pubblica per momenti `status='published'` e `visibility='public'`
- Geolocalizzazione: tentativo di auto-rilevamento (Geolocator); se negato l'utente può inserire coordinate manualmente
- UI conferma la pubblicazione con Snackbar e ritorna alla home

## Data Model
```sql
create type moment_media_type as enum ('photo', 'video', 'audio', 'text');
create type moment_visibility as enum ('public', 'private');
create type moment_status as enum ('draft', 'published', 'flagged', 'review');

create table public.moments (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  media_type moment_media_type not null default 'photo',
  media_url text,
  thumbnail_url text,
  tags text[] default '{}',
  visibility moment_visibility not null default 'public',
  status moment_status not null default 'published',
  location geometry(Point, 4326) not null,
  radius_m integer default 100,
  created_at timestamptz default timezone('utc', now()),
  updated_at timestamptz default timezone('utc', now())
);

create index moments_location_idx on public.moments using gist (location);
```

Trigger `moments_handle_updated_at` mantiene `updated_at` coerente. RLS attive:
- Inserimento/Aggiornamento/Eliminazione consentiti solo al proprietario (`auth.uid() = profile_id`)
- Select pubblica per momenti pubblicati + visibili, oppure proprietario

## Frontend Implementation Notes
- Nuova pagina `CreateMomentPage` con form step unico, pulsante FAB nella tab "Scopri"
- `SegmentedButton` per selezionare tipo contenuto (foto/testo) e visibilità
- Upload file tramite `image_picker` → `MomentsRepository.createMoment` che gestisce bucket e `uploadBinary`
- Coordinate ottenute via `geolocator`; se permesso negato, input manuale obbligatorio
- Tags accettati come stringa separata da virgole e salvati come `text[]`

## Configuration
- Bucket Storage `moments` creato automaticamente se assente (`public: true`)
- Android: permessi `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`
- iOS: `NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`
- `.env` invariato (usa Supabase URL/Anon Key esistenti)

## Open Questions / Next Steps
- Implementare compressione/thumbnail server-side per media (funzioni Edge)
- Validare dimensione massima upload e mostrare feedback di progresso
- Aggiungere supporto a video/audio con encoding lato client/server
- Legare momenti alla mappa/ feed locale e filtri raggio (Priorità 3)
