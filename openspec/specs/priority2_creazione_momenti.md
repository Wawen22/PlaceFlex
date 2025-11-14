# Priorità 2 - Creazione Momenti (Media + Metadata + CDN)

> **Status**: ✅ Foto/Testo live + video compressi lato client e note vocali (Nov 2025). RLS/storage hardened il 15 Nov.

## Scope
- Creare e pubblicare momenti con titolo, descrizione, tag, visibilità, coordinate GPS e raggio
- Supporto completo a foto, video compressi lato client (720p) e note vocali AAC; fallback testo puro
- Persistenza momenti in tabella public.moments con metadata aggiuntivi (size/duration/processing status) per query spaziali

## User Stories
1. **Come creator** voglio allegare una foto al momento direttamente dalla galleria per mostrarla ad altri utenti nelle vicinanze.
2. **Come utente** voglio impostare visibilità pubblica/privata in modo da controllare chi può vedere i miei momenti.
3. **Come sistema** voglio salvare i momenti con geolocalizzazione accurata per abilitarne la discovery sulla mappa.

## Acceptance Criteria
- Tipi supportati: `Foto` (galleria), `Video` (galleria max 2 min) e `Audio` (recorder integrato), `Testo`
- Compressione client per foto/video con feedback visivo e barra di progresso (preparazione/upload/salvataggio)
- Limiti peso enforced (foto 6MB, video 80MB, audio 20MB) via constraint + policy; errori mostrati in UI
- Note vocali registrate in AAC 96 kbps, preview riproducibile prima della pubblicazione
- `CreateMomentPage2026` mantiene wizard 3 step con segmented button per tipo/visibilit� e pannello metadata
- Inserimento record con `media_size_bytes`, `media_duration_ms`, `media_processing_status`; owner RLS invariata
- Geolocalizzazione: auto detect + input manuale
- Snackbar finale + refresh mappa

## Data Model
```sql
create type moment_media_type as enum ('photo', 'video', 'audio', 'text');
create type moment_visibility as enum ('public', 'private');
create type moment_status as enum ('draft', 'published', 'flagged', 'review');
create type moment_media_processing_status as enum ('ready', 'queued', 'processing', 'failed');

create table public.moments (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  media_type moment_media_type not null default 'photo',
  media_url text,
  thumbnail_url text,
  media_size_bytes bigint,
  media_duration_ms integer,
  media_processing_status moment_media_processing_status default 'ready',
  media_processing_error text,
  tags text[] default '{}',
  visibility moment_visibility not null default 'public',
  status moment_status not null default 'published',
  location geometry(Point, 4326) not null,
  radius_m integer default 100,
  created_at timestamptz default timezone('utc', now()),
  updated_at timestamptz default timezone('utc', now()),
  constraint moments_media_size_limits check (
    media_size_bytes is null or
    media_size_bytes <= case media_type
      when 'photo' then 6291456
      when 'video' then 83886080
      when 'audio' then 20971520
      else 262144
    end
  )
);

create index moments_location_idx on public.moments using gist (location);
```

Trigger `moments_handle_updated_at` mantiene `updated_at` coerente. RLS attive:
- Inserimento/Aggiornamento/Eliminazione consentiti solo al proprietario (`auth.uid() = profile_id`)
- Select pubblica per momenti pubblicati + visibili, oppure proprietario

## Frontend Implementation Notes
- `CreateMomentPage2026`: wizard in 3 step con progress bar superiore + linear progress sul CTA finale
- Segmented button per scegliere foto/video/audio/testo, preview e meta info (dimensione/durata) dentro card
- `MomentMediaProcessor` usa `flutter_image_compress` e `video_compress` per foto/video, genera thumbnail; audio registrato con `record` + playback `audioplayers`
- `MomentsRepository` accetta `PreparedMomentMedia`, pubblica su Storage con callback di progresso e salva i metadata
- Nota vocale: bottone start/stop, timer live, playback prima dell'invio
- Geolocalizzazione invariata + validazione input manuale

## Configuration
- Bucket `moments` deve esistere e restare pubblico; migrazione `20251115_storage_media_policy.sql` crea le nuove policy con funzione `moments_media_is_allowed`
- Migrazione `20251115_advanced_media_metadata.sql` aggiunge colonne, constraint e tipo `moment_media_processing_status`
- Android: permessi `ACCESS_FINE/COARSE_LOCATION`, `CAMERA`, `READ/WRITE_EXTERNAL_STORAGE`, `RECORD_AUDIO`
- iOS: `NSLocationWhenInUse`, `NSCamera`, `NSPhotoLibrary`, `NSMicrophoneUsageDescription`
- Edge Functions: placeholder `supabase/functions/media-transcode` pronto per orchestrare pipeline ffmpeg (oggi risponde con stub)
- `.env` invariato

### Storage & RLS Checklist
1. Creare bucket `moments` (public)
2. Applicare le policy create dalla migrazione `20251115_storage_media_policy.sql`
3. Validare upload con file oltre i limiti per assicurarsi che constraint/policy blocchino + UI mostri errore
4. Deploy placeholder Edge Function; aggiornarla quando la pipeline ffmpeg sar� pronta
5. QA manuale completato (foto>6MB, video>80MB, audio>20MB)

## Open Questions / Next Steps
- Edge Function `media-transcode`: collegare storage webhooks e pipeline ffmpeg reale per queue/process
- Aggiornare `media_processing_status` una volta completata la transcodifica server-side
- Collegare publish flow alla mappa/feed con filtri media (Priority 3)
