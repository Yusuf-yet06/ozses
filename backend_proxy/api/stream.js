// Siber Kalkan - Ozses Vercel Stream Çözücü V2
// Çoklu motor: ytdl-core + Cobalt + Piped + Invidious
const ytdl = require('@distube/ytdl-core');

const SIBER_API_KEY = process.env.SIBER_API_KEY || "siber_secret_key_v7";
const HARDCODED_KEY = "siber_secret_key_v7";

// Cobalt API ile stream çöz
async function tryCobalt(videoId) {
    const cobaltInstances = [
        'https://api.cobalt.tools/api/json',
        'https://cobalt.hyper.lol/api/json',
    ];
    
    for (const instance of cobaltInstances) {
        try {
            const resp = await fetch(instance, {
                method: 'POST',
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                },
                body: JSON.stringify({
                    url: `https://www.youtube.com/watch?v=${videoId}`,
                    audioFormat: 'mp3',
                    isAudioOnly: true,
                    filenameStyle: 'basic',
                }),
                signal: AbortSignal.timeout(8000),
            });
            
            if (resp.ok) {
                const data = await resp.json();
                if (data.url) {
                    return { status: 'basarili', stream_url: data.url, source: 'cobalt' };
                }
            }
        } catch (e) {
            console.log(`Cobalt ${instance} hatası: ${e.message}`);
        }
    }
    return null;
}

// Piped API ile stream çöz
async function tryPiped(videoId) {
    const pipedInstances = [
        'https://pipedapi.kavin.rocks',
        'https://pipedapi.moomoo.me',
        'https://api.piped.projectsegfau.lt',
        'https://pipedapi.smnz.de',
        'https://pipedapi.adminforge.de',
    ];
    
    for (const instance of pipedInstances) {
        try {
            const resp = await fetch(`${instance}/streams/${videoId}`, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                },
                signal: AbortSignal.timeout(6000),
            });
            
            if (resp.ok) {
                const data = await resp.json();
                const audioStreams = data.audioStreams || [];
                if (audioStreams.length > 0) {
                    const best = audioStreams.reduce((a, b) => 
                        (a.bitrate || 0) > (b.bitrate || 0) ? a : b
                    );
                    return { status: 'basarili', stream_url: best.url, source: `piped-${instance}` };
                }
            }
        } catch (e) {
            console.log(`Piped ${instance} hatası: ${e.message}`);
        }
    }
    return null;
}

// Invidious API ile stream çöz  
async function tryInvidious(videoId) {
    const invidiousInstances = [
        'https://invidious.nerdvpn.de',
        'https://inv.nadeko.net',
        'https://invidious.protokolla.fi',
        'https://invidious.jing.rocks',
    ];
    
    for (const instance of invidiousInstances) {
        try {
            const resp = await fetch(`${instance}/api/v1/videos/${videoId}`, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                },
                signal: AbortSignal.timeout(6000),
            });
            
            if (resp.ok) {
                const data = await resp.json();
                const adaptiveFormats = data.adaptiveFormats || [];
                const audioFormats = adaptiveFormats.filter(f => 
                    f.type && f.type.includes('audio')
                );
                
                if (audioFormats.length > 0) {
                    const best = audioFormats.reduce((a, b) => 
                        (a.bitrate || 0) > (b.bitrate || 0) ? a : b
                    );
                    return { status: 'basarili', stream_url: best.url, source: `invidious-${instance}` };
                }
                
                const formatStreams = data.formatStreams || [];
                if (formatStreams.length > 0) {
                    return { status: 'basarili', stream_url: formatStreams[0].url, source: `invidious-${instance}` };
                }
            }
        } catch (e) {
            console.log(`Invidious ${instance} hatası: ${e.message}`);
        }
    }
    return null;
}

// ytdl-core ile stream çöz
async function tryYtdl(videoId) {
    try {
        const info = await ytdl.getInfo(videoId);
        const format = ytdl.chooseFormat(info.formats, { filter: 'audioonly', quality: 'highestaudio' });
        if (format && format.url) {
            return { status: 'basarili', stream_url: format.url, source: 'vercel-ytdl-core' };
        }
    } catch (e) {
        console.log(`ytdl-core hatası: ${e.message}`);
    }
    return null;
}

module.exports = async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');
    
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    // Siber Kalkan kontrolü
    const clientKey = req.query.apikey || req.headers['x-siber-key'];
    if (clientKey !== SIBER_API_KEY && clientKey !== HARDCODED_KEY) {
        return res.status(403).json({ error: "Erişim Reddedildi! Siber Kalkan devrede." });
    }

    const videoId = req.query.id;
    if (!videoId) {
        return res.status(400).json({ error: "Missing 'id' parameter" });
    }

    console.log(`🎯 Stream çözme başladı: ${videoId}`);

    // Tüm motorları paralel çalıştır, ilk başarılı olan kazanır
    const results = await Promise.allSettled([
        tryCobalt(videoId),
        tryPiped(videoId),
        tryInvidious(videoId),
        tryYtdl(videoId),
    ]);

    for (const result of results) {
        if (result.status === 'fulfilled' && result.value && result.value.status === 'basarili') {
            console.log(`✅ Stream çözüldü: ${result.value.source}`);
            return res.status(200).json(result.value);
        }
    }

    // Hiçbiri başarılı olmadıysa hata dön
    console.log(`🛑 Tüm motorlar çöktü: ${videoId}`);
    return res.status(500).json({ error: "Tüm stream motorları çöktü", videoId });
};
