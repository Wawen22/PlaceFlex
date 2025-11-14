-- Update spatial RPC to support optional media type filters

create or replace function get_nearby_moments(
  center_lat double precision,
  center_lon double precision,
  radius_meters double precision default 5000,
  result_limit integer default 200,
  media_types moment_media_type[] default null
)
returns setof moments
language sql
stable
as $$
  select *
  from moments
  where status = 'published'
    and visibility = 'public'
    and ST_DWithin(
      location::geography,
      ST_SetSRID(ST_MakePoint(center_lon, center_lat), 4326)::geography,
      radius_meters
    )
    and (
      media_types is null
      or media_type = any(media_types)
    )
  order by created_at desc
  limit result_limit;
$$;

create or replace function get_moments_in_bounds(
  sw_lat double precision,
  sw_lon double precision,
  ne_lat double precision,
  ne_lon double precision,
  result_limit integer default 200,
  media_types moment_media_type[] default null
)
returns setof moments
language sql
stable
as $$
  select *
  from moments
  where status = 'published'
    and visibility = 'public'
    and ST_Contains(
      ST_MakeEnvelope(sw_lon, sw_lat, ne_lon, ne_lat, 4326),
      location
    )
    and (
      media_types is null
      or media_type = any(media_types)
    )
  order by created_at desc
  limit result_limit;
$$;
