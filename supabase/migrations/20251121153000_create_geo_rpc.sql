-- Enable PostGIS
create extension if not exists postgis;

-- Function to get nearby moments
create or replace function get_nearby_moments(
  center_lat double precision,
  center_lon double precision,
  radius_meters double precision,
  result_limit int default 100,
  media_types text[] default null
)
returns setof moments
language plpgsql
as $$
begin
  return query
  select *
  from moments m
  where st_dwithin(
    m.location::geography,
    st_point(center_lon, center_lat)::geography,
    radius_meters
  )
  and (media_types is null or m.media_type::text = any(media_types))
  order by st_distance(
    m.location::geography,
    st_point(center_lon, center_lat)::geography
  )
  limit result_limit;
end;
$$;

-- Function to get moments in bounds
create or replace function get_moments_in_bounds(
  sw_lat double precision,
  sw_lon double precision,
  ne_lat double precision,
  ne_lon double precision,
  result_limit int default 100,
  media_types text[] default null
)
returns setof moments
language plpgsql
as $$
begin
  return query
  select *
  from moments m
  where m.location && st_makeenvelope(sw_lon, sw_lat, ne_lon, ne_lat, 4326)
  and (media_types is null or m.media_type::text = any(media_types))
  limit result_limit;
end;
$$;
