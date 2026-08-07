// Siber Kalkan - Ozses Vercel Edge Function
// Render backend'e proxy yaparak YouTube audio stream çözer
// Vercel 7/24 uyanık kalır, Render uyusa bile Vercel onu uyandırır

const SIBER_API_KEY = process.env.SIBER_API_KEY || "AQ.Ab8RN6Kc0uQdBCezyM1J06Ii1-XDBdFcJwIByqkknpgaZlT1OQ_LOCAL";
const RENDER_BACKEND = "https://ozses.onrender.com";

module.exports = async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    // Siber Kalkan kontrolü
    const clientKey = req.query.apikey || req.headers['x-siber-key'];
    if (clientKey !== SIBER_API_KEY) {
        return res.status(403).json({ error: "Erişim Reddedildi! Siber Kalkan devrede." });
    }

    const videoId = req.query.id;
    if (!videoId) {
        return res.status(400).json({ error: "Missing 'id' parameter" });
    }

    try {
        // Render backend'e istek gönder (yt-dlp ile çalışıyor)
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 25000); // Render uyandırma süresi dahil

        const response = await fetch(`${RENDER_BACKEND}/stream?id=${videoId}`, {
            signal: controller.signal,
            headers: { 'User-Agent': 'OzsesSiberKalkan/1.0' }
        });
        clearTimeout(timeout);

        if (response.ok) {
            const data = await response.json();
            if (data.status === 'basarili' && data.stream_url) {
                return res.status(200).json({
                    status: 'basarili',
                    stream_url: data.stream_url,
                    title: data.title || 'Bilinmeyen',
                    source: 'vercel+render'
                });
            }
        }

        // Render başarısız olursa hata döndür
        return res.status(500).json({ 
            error: "Render backend yanıt vermedi. Sunucu uyanıyor olabilir, lütfen 30 saniye sonra tekrar deneyin." 
        });
    } catch (error) {
        if (error.name === 'AbortError') {
            return res.status(504).json({ error: "Sunucu uyanıyor, lütfen tekrar deneyin." });
        }
        return res.status(500).json({ error: error.message });
    }
};
