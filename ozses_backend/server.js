const express = require('express');
const cors = require('cors');
const { spawn } = require('child_process');
const http = require('http');
const https = require('https');
const app = express();

app.use(cors());

// URL önbelleği
const urlCache = new Map();
const CACHE_TTL = 4 * 60 * 60 * 1000; // 4 saat

function getCachedUrl(videoId) {
    const entry = urlCache.get(videoId);
    if (entry && Date.now() < entry.expiry) return entry.url;
    urlCache.delete(videoId);
    return null;
}

function setCachedUrl(videoId, streamUrl) {
    urlCache.set(videoId, { url: streamUrl, expiry: Date.now() + CACHE_TTL });
    if (urlCache.size > 500) urlCache.delete(urlCache.keys().next().value);
}

// URL'den client tipini tespit et ve uygun User-Agent döndür
function getMatchingUserAgent(streamUrl) {
    if (!streamUrl) return 'Mozilla/5.0';
    if (streamUrl.includes('c=ANDROID_MUSIC')) return 'com.google.android.apps.youtube.music/5.17.51 (Linux; U; Android 11; en_US) gzip';
    if (streamUrl.includes('c=ANDROID_VR')) return 'com.google.android.apps.youtube.vr.vr/1.57.42 (Linux; U; Android 11; en_US) gzip';
    if (streamUrl.includes('c=ANDROID')) return 'com.google.android.youtube/19.02.35 (Linux; U; Android 11; en_US) gzip';
    if (streamUrl.includes('c=IOS')) return 'com.google.ios.youtube/19.02.1 (iPhone16,2; U; CPU iOS 17_3_1 like Mac OS X;)';
    if (streamUrl.includes('c=TVHTML5')) return 'Mozilla/5.0 (SMART-TV; LINUX; Tizen 6.0)';
    return 'com.google.android.apps.youtube.vr.vr/1.57.42 (Linux; U; Android 11; en_US) gzip';
}

// yt-dlp ile ses URL'sini çöz
function resolveStreamUrl(videoId) {
    return new Promise((resolve, reject) => {
        const cached = getCachedUrl(videoId);
        if (cached) return resolve(cached);

        console.log(`[ÇÖZÜCÜ] yt-dlp: ${videoId}`);
        const proc = spawn('yt-dlp', [
            '--no-check-certificates',
            '-f', 'bestaudio',
            '-g',
            `https://www.youtube.com/watch?v=${videoId}`
        ]);

        let stdout = '', stderr = '';
        proc.stdout.on('data', (d) => { stdout += d.toString(); });
        proc.stderr.on('data', (d) => { stderr += d.toString(); });

        proc.on('close', (code) => {
            const streamUrl = stdout.trim();
            if (code === 0 && streamUrl) {
                setCachedUrl(videoId, streamUrl);
                console.log(`[OK] ${videoId} -> c=${streamUrl.match(/c=([A-Z_]+)/)?.[1] || '?'}`);
                resolve(streamUrl);
            } else {
                console.error(`[FAIL] ${videoId}: ${stderr.substring(0, 150)}`);
                reject(new Error(stderr.substring(0, 150)));
            }
        });

        setTimeout(() => { proc.kill(); reject(new Error('timeout')); }, 30000);
    });
}

// Sağlık kontrolü
app.get('/', (req, res) => {
    res.json({ status: 'aktif', motor: 'Özses Audio Relay', cache: urlCache.size });
});

// JSON ile URL döndür (test için)
app.get('/resolve', async (req, res) => {
    const videoId = req.query.id;
    if (!videoId) return res.status(400).json({ status: 'hata', mesaj: 'id gerekli' });
    try {
        const streamUrl = await resolveStreamUrl(videoId);
        res.json({ status: 'basarili', stream_url: streamUrl });
    } catch (e) {
        res.status(500).json({ status: 'hata', mesaj: e.message });
    }
});

// AUDIO RELAY — Google'dan sesi çekip telefona aktarır
app.get('/audio/:videoId', async (req, res) => {
    const videoId = req.params.videoId;
    console.log(`🎵 [RELAY] ${videoId}`);

    let streamUrl;
    try {
        streamUrl = await resolveStreamUrl(videoId);
    } catch (e) {
        return res.status(502).json({ status: 'hata', mesaj: e.message });
    }

    const doRelay = (targetUrl, isRetry = false) => {
        const userAgent = getMatchingUserAgent(targetUrl);
        const client = new URL(targetUrl).protocol === 'https:' ? https : http;
        const headers = { 'User-Agent': userAgent };
        if (req.headers.range) headers['Range'] = req.headers.range;

        const proxyReq = client.request(targetUrl, {
            method: 'GET', headers, rejectUnauthorized: false,
        }, (proxyRes) => {
            console.log(`[RELAY] ${proxyRes.statusCode} ${videoId}${isRetry ? ' (retry)' : ''}`);

            // 403 alırsa cache temizle, tekrar dene (1 kez)
            if (proxyRes.statusCode === 403 && !isRetry) {
                urlCache.delete(videoId);
                resolveStreamUrl(videoId)
                    .then(newUrl => doRelay(newUrl, true))
                    .catch(() => { if (!res.headersSent) res.status(502).end(); });
                return;
            }

            const h = {};
            ['content-type', 'content-length', 'content-range', 'accept-ranges'].forEach(k => {
                if (proxyRes.headers[k]) h[k] = proxyRes.headers[k];
            });
            h['Access-Control-Allow-Origin'] = '*';
            res.writeHead(proxyRes.statusCode, h);
            proxyRes.pipe(res);
        });

        proxyReq.on('error', () => { if (!res.headersSent) res.status(502).end(); });
        req.on('close', () => proxyReq.destroy());
        proxyReq.end();
    };

    doRelay(streamUrl);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Özses Audio Relay | Port ${PORT}`);
});
