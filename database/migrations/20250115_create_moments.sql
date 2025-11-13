-- Ensure PostGIS extension is available
create extension if not exists postgis;
create extension if not exists pgcrypto;

-- Enumerations
create type if not exists public.moment_media_type as enum ('photo', 'video', 'audio', 'text');
create type if not exists public.moment_visibility as enum ('public', 'private');
create type if not exists public.moment_status as enum ('draft', 'published', 'flagged', 'review');

-- Table definition
create table if not exists public.moments (
    id uuid primary key default gen_random_uuid(),
    profile_id uuid not null references public.profiles(id) on delete cascade,
    title text not null,
    description text,
    media_type public.moment_media_type not null default 'photo',
    media_url text,
    thumbnail_url text,
    tags text[] default '{}',
    visibility public.moment_visibility not null default 'public',
    status public.moment_status not null default 'published',
    location geometry(Point, 4326) not null,
    radius_m integer default 100,
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now())
);

create index if not exists moments_location_idx on public.moments using gist (location);

-- Trigger for updated_at
create or replace function public.moments_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists moments_handle_updated_at on public.moments;
create trigger moments_handle_updated_at
before update on public.moments
for each row
execute function public.moments_set_updated_at();

-- RLS policies
alter table public.moments enable row level security;

drop policy if exists "Moments owner full access" on public.moments;
create policy "Moments owner full access" on public.moments
  using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);

drop policy if exists "Moments public visibility" on public.moments;
create policy "Moments public visibility" on public.moments
  for select
  using (
    status = 'published'
    and visibility = 'public'
  );

-- Ensure bucket exists via storage API (manual step if running outside migration tooling)
-- select storage.create_bucket('moments', public := true) where not exists (
--   select 1 from storage.buckets where id = 'moments'
-- );
