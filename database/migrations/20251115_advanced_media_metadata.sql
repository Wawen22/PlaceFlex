-- Advanced media metadata & constraints for moments

do $$
begin
  create type public.moment_media_processing_status
    as enum ('ready', 'queued', 'processing', 'failed');
exception
  when duplicate_object then null;
end
$$;

alter table if exists public.moments
  add column if not exists media_size_bytes bigint,
  add column if not exists media_duration_ms integer,
  add column if not exists media_processing_status public.moment_media_processing_status default 'ready',
  add column if not exists media_processing_error text;

-- Ensure media sizes obey per-type limits once provided by the client
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'moments_media_size_limits'
      and conrelid = 'public.moments'::regclass
  ) then
    alter table public.moments
      add constraint moments_media_size_limits
        check (
          media_size_bytes is null
          or media_size_bytes <= case media_type
            when 'photo' then 6291456    -- 6 MB
            when 'video' then 83886080   -- 80 MB
            when 'audio' then 20971520   -- 20 MB
            when 'text'  then 262144     -- 256 KB
            else 83886080
          end
        );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'moments_media_duration_positive'
      and conrelid = 'public.moments'::regclass
  ) then
    alter table public.moments
      add constraint moments_media_duration_positive
        check (media_duration_ms is null or media_duration_ms >= 0);
  end if;
end
$$;
