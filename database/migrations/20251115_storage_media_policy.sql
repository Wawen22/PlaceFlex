-- Enforce storage limits & folder ownership for the `moments` bucket

alter table if exists storage.objects enable row level security;

create or replace function public.moments_media_is_allowed(
  metadata jsonb,
  object_name text
)
returns boolean
language plpgsql
as $$
declare
  mime text := coalesce(metadata->>'mimetype', '');
  size bigint := coalesce(nullif(metadata->>'size', '')::bigint, 0);
  extension text := case
    when position('.' in object_name) > 0 then
      lower(split_part(
        object_name,
        '.',
        array_length(string_to_array(object_name, '.'), 1)
      ))
    else
      ''
  end;
begin
  if mime like 'image/%' or extension = any(array['jpg','jpeg','png','gif','webp','heic']) then
    return size <= 6291456;
  elsif mime like 'video/%' or extension = any(array['mp4','mov','m4v','webm']) then
    return size <= 83886080;
  elsif mime like 'audio/%' or extension = any(array['aac','m4a','mp3','wav','ogg']) then
    return size <= 20971520;
  elsif mime = 'text/plain' or extension = any(array['txt','md']) then
    return size <= 262144;
  end if;

  return size <= 83886080;
end;
$$;

do $$
begin
  if exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in (
        'Users can upload to own folder',
        'Users can update own files',
        'Users can delete own files',
        'Public read access'
      )
  ) then
    drop policy if exists "Users can upload to own folder" on storage.objects;
    drop policy if exists "Users can update own files" on storage.objects;
    drop policy if exists "Users can delete own files" on storage.objects;
    drop policy if exists "Public read access" on storage.objects;
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'moments_media_public_select'
  ) then
    create policy "moments_media_public_select"
      on storage.objects
      for select
      using (bucket_id = 'moments');
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'moments_media_owner_insert'
  ) then
    create policy "moments_media_owner_insert"
      on storage.objects
      for insert
      with check (
        bucket_id = 'moments'
        and auth.uid()::text = (storage.foldername(name))[1]
        and public.moments_media_is_allowed(metadata, name)
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'moments_media_owner_update'
  ) then
    create policy "moments_media_owner_update"
      on storage.objects
      for update
      using (
        bucket_id = 'moments'
        and auth.uid()::text = (storage.foldername(name))[1]
      )
      with check (
        bucket_id = 'moments'
        and auth.uid()::text = (storage.foldername(name))[1]
        and public.moments_media_is_allowed(metadata, name)
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'moments_media_owner_delete'
  ) then
    create policy "moments_media_owner_delete"
      on storage.objects
      for delete
      using (
        bucket_id = 'moments'
        and auth.uid()::text = (storage.foldername(name))[1]
      );
  end if;
end
$$;
