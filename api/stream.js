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
        
        const audioFormat = ytdl.chooseFormat(info.formats, { quality: 'highestaudio', filter: 'audioonly' });
        
        if (audioFormat && audioFormat.url) {
            return res.status(200).json({
                status: 'basarili',
                stream_url: audioFormat.url,
                title: info.videoDetails.title
            });
        } else {
            return res.status(404).json({ error: "No audio format found" });
        }
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};
