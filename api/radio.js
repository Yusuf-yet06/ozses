const ytdl = require('@distube/ytdl-core');

module.exports = async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    const videoId = req.query.id;
    if (!videoId) {
        return res.status(400).json({ error: "Missing 'id' parameter" });
    }

    try {
        const url = `https://www.youtube.com/watch?v=${videoId}`;
        const info = await ytdl.getInfo(url);
        
        const relatedVideos = info.related_videos || [];
        const formattedRelated = relatedVideos.slice(0, 15).map(v => ({
            id: v.id,
            title: v.title,
            thumbnail: (v.thumbnails && v.thumbnails.length > 0) ? v.thumbnails[0].url : `https://i.ytimg.com/vi/${v.id}/hqdefault.jpg`,
            author: v.author ? (v.author.name || v.author) : 'Bilinmeyen Sanatçı'
        }));

        return res.status(200).json({
            status: 'basarili',
            related: formattedRelated
        });
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};
