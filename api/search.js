const axios = require('axios');

module.exports = async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    const query = req.query.q;
    if (!query) {
        return res.status(400).json({ error: "Missing 'q' parameter" });
    }

    try {
        const url = `https://www.youtube.com/results?search_query=${encodeURIComponent(query)}&sp=EgIQAQ%253D%253D`; // sp=EgIQAQ%3D%3D means Video only
        const response = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36'
            }
        });

        const html = response.data;
        const ytInitialDataMatch = html.match(/var ytInitialData = ({.*?});<\/script>/);
        
        if (!ytInitialDataMatch || ytInitialDataMatch.length < 2) {
            return res.status(500).json({ error: "Could not parse ytInitialData" });
        }

        const ytInitialData = JSON.parse(ytInitialDataMatch[1]);
        const results = [];
        
        const contents = ytInitialData.contents?.twoColumnSearchResultsRenderer?.primaryContents?.sectionListRenderer?.contents;
        if (contents) {
            for (let section of contents) {
                if (section.itemSectionRenderer && section.itemSectionRenderer.contents) {
                    for (let item of section.itemSectionRenderer.contents) {
                        if (item.videoRenderer) {
                            const video = item.videoRenderer;
                            results.push({
                                id: video.videoId,
                                title: video.title?.runs?.[0]?.text || "Unknown",
                                channel: video.ownerText?.runs?.[0]?.text || "Unknown",
                                thumbnail: video.thumbnail?.thumbnails?.[0]?.url || ''
                            });
                        }
                        if (results.length >= 15) break;
                    }
                }
                if (results.length >= 15) break;
            }
        }

        return res.status(200).json({
            status: 'basarili',
            oneriler: results,
            nextPageToken: ''
        });
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};
