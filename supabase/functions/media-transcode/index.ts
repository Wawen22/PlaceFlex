import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
  const payload = await req.json().catch(() => ({}));

  console.log("[media-transcode] received payload", payload);

  return new Response(
    JSON.stringify({
      status: "queued",
      message:
        "Transcode pipeline not yet implemented – this Edge Function is a placeholder.",
      received: payload,
    }),
    {
      headers: { "Content-Type": "application/json" },
    },
  );
});
