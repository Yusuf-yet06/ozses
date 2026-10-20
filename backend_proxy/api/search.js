const ytSearch = require('yt-search');

module.exports = async (req, res) => {
    // CORS headers
    res.setHeader('Access-Control-Allow-Credentials', true);
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    try {
        const query = req.query.q;
        const apikey = req.query.apikey;

        if (!query) {
            return res.status(400).json({ error: 'Query (q) parameter is required' });
        }

        // SİBER KALKAN API KONTROLÜ
        if (apikey !== process.env.SIBER_API_KEY && apikey !== 'siber_secret_key_v7') {
            return res.status(403).json({ error: 'Siber Kalkan: Geçersiz API Anahtarı' });
        }

        const r = await ytSearch(query);
        const videos = r.videos.slice(0, 15);

        const formattedItems = videos.map(v => ({
            id: v.videoId,
            title: v.title,
            channel: v.author.name,
            thumbnail: v.thumbnail
        }));

        return res.status(200).json({
            status: 'basarili',
            oneriler: formattedItems
        });
    } catch (error) {
        console.error('Search API Error:', error);
        return res.status(500).json({ error: error.message });
    }
};
