export const config = {
  runtime: 'edge',
};

export default async function handler(req) {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
      },
    });
  }

  const url = new URL(req.url);
  const videoId = url.searchParams.get('id');

  if (!videoId) {
    return new Response(JSON.stringify({ error: "Missing 'id' parameter" }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    // Proxy to VPS using nip.io to bypass Vercel's direct IP block
    const vpsUrl = `http://167-172-190-129.nip.io:3000/api/stream?id=${videoId}`;
    
    // Fetch from VPS
    const response = await fetch(vpsUrl);
    
    // Create response with same headers
    const headers = new Headers(response.headers);
    headers.set('Access-Control-Allow-Origin', '*');
    
    return new Response(response.body, {
      status: response.status,
      headers: headers
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
