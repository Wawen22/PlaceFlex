# media-transcode (placeholder)

Edge Function stub used to reserve the endpoint that will orchestrate heavy
media compression/transcoding once CDN costs increase. For now it simply echoes
the payload so that clients/tests can verify the webhook invocation without
performing any expensive work.

## Deployment checklist

1. Configure the function in Supabase:
   ```bash
   supabase functions deploy media-transcode --no-verify-jwt
   ```
2. Provide the service-role key as `SUPABASE_SERVICE_ROLE_KEY` when invoking the
   endpoint from backend jobs (never from the client).
3. Wire Postgres triggers / storage webhooks at a later stage once the actual
   ffmpeg pipeline is ready.

## TODO
- Stream uploads from the `moments` bucket, run ffmpeg in a managed worker, then
  push optimized assets back into the CDN bucket.
- Update `public.moments.media_processing_status` once the job finishes.
