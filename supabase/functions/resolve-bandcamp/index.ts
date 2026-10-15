import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { url } = await req.json();
    if (!url || !url.includes("bandcamp.com")) {
      return new Response(JSON.stringify({ error: "Invalid Bandcamp URL" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch the Bandcamp page to extract the track/album ID
    const response = await fetch(url, {
      headers: { "User-Agent": "Mozilla/5.0" },
    });
    const html = await response.text();

    // Extract track or album ID from meta tags or embedded data
    // Bandcamp pages contain: <meta property="og:video" content="...track=XXXXX..." />
    // or data-tralbum-id="XXXXX"
    let itemId: string | null = null;
    let itemType: "track" | "album" = "track";

    // Try og:video meta tag
    const ogVideoMatch = html.match(/property="og:video"[^>]*content="[^"]*?(track|album)=(\d+)/);
    if (ogVideoMatch) {
      itemType = ogVideoMatch[1] as "track" | "album";
      itemId = ogVideoMatch[2];
    }

    // Fallback: data-tralbum-id
    if (!itemId) {
      const tralbumMatch = html.match(/data-tralbum-id="(\d+)"/);
      if (tralbumMatch) {
        itemId = tralbumMatch[1];
        // Determine type from URL
        itemType = url.includes("/album/") ? "album" : "track";
      }
    }

    // Fallback: look in page source for "current":{"id":XXXXX
    if (!itemId) {
      const currentMatch = html.match(/"current"\s*:\s*\{[^}]*"id"\s*:\s*(\d+)/);
      if (currentMatch) {
        itemId = currentMatch[1];
        itemType = url.includes("/album/") ? "album" : "track";
      }
    }

    if (!itemId) {
      return new Response(JSON.stringify({ error: "Could not extract Bandcamp ID" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const embedUrl = `https://bandcamp.com/EmbeddedPlayer/${itemType}=${itemId}/size=large/bgcol=333333/linkcol=e99708/tracklist=false/artwork=small/transparent=true/`;

    return new Response(JSON.stringify({ embedUrl, itemId, itemType }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
