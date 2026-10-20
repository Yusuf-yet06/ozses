const express = require('express');
const { execFile, spawn } = require('child_process');
const Database = require('better-sqlite3');
const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');

// ═══════════════════════════════════════════════════════════════
// 🔥 ÖZSES V8 — Merkezi Ses Karargahı (Hibrit Mimari)
// ═══════════════════════════════════════════════════════════════
const app = express();
const PORT = 8080;
const API_KEY = 'siber_secret_key_v7';
const YT_API_KEY = process.env.YT_API_KEY || '';
const COOKIE_DIR = path.join(__dirname, 'cookies');
const DB_PATH = path.join(__dirname, 'cache.db');

// ── SQLite Önbellek ──────────────────────────────────────────
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL'); // Performans için WAL modu
db.exec(`
  CREATE TABLE IF NOT EXISTS yt_map (
    spotify_key TEXT PRIMARY KEY,
    youtube_id  TEXT NOT NULL,
    created_at  INTEGER DEFAULT (unixepoch())
  );
  CREATE TABLE IF NOT EXISTS stream_cache (
    video_id    TEXT PRIMARY KEY,
    stream_url  TEXT NOT NULL,
    created_at  INTEGER DEFAULT (unixepoch())
  );
  CREATE TABLE IF NOT EXISTS radio_cache (
    video_id    TEXT PRIMARY KEY,
    results     TEXT NOT NULL,
    created_at  INTEGER DEFAULT (unixepoch())
  );
`);

// ── Prepared Statements (Performans) ─────────────────────────
const stmts = {
  getYtMap:      db.prepare('SELECT youtube_id FROM yt_map WHERE spotify_key = ? AND created_at > unixepoch() - 2592000'),
  setYtMap:      db.prepare('INSERT OR REPLACE INTO yt_map (spotify_key, youtube_id) VALUES (?, ?)'),
  getStream:     db.prepare('SELECT stream_url FROM stream_cache WHERE video_id = ? AND created_at > unixepoch() - 18000'),
  setStream:     db.prepare('INSERT OR REPLACE INTO stream_cache (video_id, stream_url) VALUES (?, ?)'),
  getRadio:      db.prepare('SELECT results FROM radio_cache WHERE video_id = ? AND created_at > unixepoch() - 86400'),
  setRadio:      db.prepare('INSERT OR REPLACE INTO radio_cache (video_id, results) VALUES (?, ?)'),
  countYtMap:    db.prepare('SELECT COUNT(*) as c FROM yt_map'),
  countStream:   db.prepare('SELECT COUNT(*) as c FROM stream_cache'),
  countRadio:    db.prepare('SELECT COUNT(*) as c FROM radio_cache'),
};

// ── Webshare Rotating Proxy Havuzu ───────────────────────────
const PROXY_USER = 'oseuvvox';
const PROXY_PASS = '2hnwnqg3ixbg';
const PROXY_LIST_URL = 'https://proxy.webshare.io/api/v2/proxy/list/download/ksfagbmvnckdtywlnpcunakxdmjosyglpvbnhehn/-/any/username/direct/-/?plan_id=14172753';

let proxyPool = [];
let proxyIdx = 0;

function getNextProxy() {
  if (proxyPool.length === 0) return null;
  const raw = proxyPool[proxyIdx % proxyPool.length];
  proxyIdx++;
  // Webshare format: IP:PORT veya IP:PORT:USER:PASS
  const parts = raw.split(':');
  if (parts.length >= 2) {
    return `http://${PROXY_USER}:${PROXY_PASS}@${parts[0]}:${parts[1]}`;
  }
  return null;
}

// ── Cookie Dosyası Havuzu (Round-Robin) ──────────────────────
let cookieFiles = [];
let cookieIdx = 0;

function getNextCookie() {
  if (cookieFiles.length === 0) return null;
  const f = cookieFiles[cookieIdx % cookieFiles.length];
  cookieIdx++;
  return f;
}

// ── Yardımcı: yt-dlp Promise Wrapper ─────────────────────────
function runYtdlp(args, timeoutMs = 15000) {
  return new Promise((resolve, reject) => {
    const proc = execFile('yt-dlp', args, { timeout: timeoutMs, maxBuffer: 1024 * 1024 * 5 }, (err, stdout, stderr) => {
      if (err) return reject(new Error(stderr || err.message));
      resolve(stdout.trim());
    });
  });
}

// ── Yardımcı: YouTube Data API ile arama ─────────────────────
async function searchYouTubeAPI(query) {
  return new Promise((resolve, reject) => {
    const url = `https://www.googleapis.com/youtube/v3/search?part=snippet&q=${encodeURIComponent(query)}&type=video&videoCategoryId=10&maxResults=1&key=${YT_API_KEY}`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (json.items && json.items.length > 0 && json.items[0].id) {
            resolve(json.items[0].id.videoId);
          } else {
            reject(new Error('YouTube arama sonuç bulunamadı'));
          }
        } catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

// ── Yardımcı: Proxy üzerinden URL fetch (pipe) ──────────────
async function proxyFetch(url, headers, res) {
  try {
    const fetch = (await import('node-fetch')).default;
    const fetchRes = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0',
        ...headers
      },
      redirect: 'follow', // Yönlendirmeleri (302) otomatik takip et (403 yememek için)
      compress: false     // Sıkıştırmayı kapat ki pipe bozulmasın
    });

    if (!fetchRes.ok) {
      throw new Error(`Upstream yanıt vermedi: ${fetchRes.status} ${fetchRes.statusText}`);
    }

    res.status(fetchRes.status);
    fetchRes.headers.forEach((val, key) => {
      res.setHeader(key, val);
    });

    // Sesi doğrudan HTTP yanıtına akıt (boru)
    fetchRes.body.pipe(res);
    
    return fetchRes.body; // Event listener'lar için
  } catch (err) {
    console.error('❌ Proxy fetch hatası:', err.message);
    if (!res.headersSent) res.status(502).json({ error: 'Ses akışı bağlantı hatası' });
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════
// 🛡️ MIDDLEWARE
// ═══════════════════════════════════════════════════════════════

// API Key doğrulama
app.use('/api', (req, res, next) => {
  const key = req.headers['x-api-key'] || req.query.apikey;
  if (key !== API_KEY) {
    return res.status(403).json({ error: 'Yetkisiz erişim', code: 'FORBIDDEN' });
  }
  next();
});

// Rate Limiter (IP başına dakikada 60 istek)
const rateMap = new Map();
app.use('/api', (req, res, next) => {
  const ip = req.ip || req.connection.remoteAddress;
  const now = Date.now();
  const window = 60000;
  const max = 60;
  if (!rateMap.has(ip)) rateMap.set(ip, []);
  const ts = rateMap.get(ip).filter(t => now - t < window);
  ts.push(now);
  rateMap.set(ip, ts);
  if (ts.length > max) {
    return res.status(429).json({ error: 'Çok fazla istek, biraz bekle gardaş' });
  }
  next();
});

// Rate map temizliği (her 5 dakika)
setInterval(() => {
  const now = Date.now();
  for (const [ip, ts] of rateMap) {
    const filtered = ts.filter(t => now - t < 60000);
    if (filtered.length === 0) rateMap.delete(ip);
    else rateMap.set(ip, filtered);
  }
}, 300000);

// ═══════════════════════════════════════════════════════════════
// 🎵 STREAM ENDPOINT — Büyük İllüzyon'un Kalbi
// ═══════════════════════════════════════════════════════════════
app.get('/api/stream/:videoId', async (req, res) => {
  let videoId = decodeURIComponent(req.params.videoId);
  const startTime = Date.now();
  
  console.log(`🎵 Stream isteği: ${videoId}`);
  
  // ── Adım 1: Spotify → YouTube ID Eşleştirme ──────────────
  if (videoId.startsWith('spotify:')) {
    const searchQuery = videoId.replace('spotify:', '').trim();
    
    // Önbellek kontrol
    const cached = stmts.getYtMap.get(videoId);
    if (cached) {
      console.log(`  ✅ Cache hit (Spotify→YT): ${cached.youtube_id}`);
      videoId = cached.youtube_id;
    } else {
      console.log(`  🔍 Spotify→YouTube aranıyor: "${searchQuery}"`);
      try {
        // Önce Resmi YouTube API ile ara (hızlı)
        const ytId = await searchYouTubeAPI(searchQuery);
        stmts.setYtMap.run(req.params.videoId, ytId);
        videoId = ytId;
        console.log(`  ✅ YouTube ID bulundu: ${ytId}`);
      } catch (apiErr) {
        console.log(`  ⚠️ YT API hatası, yt-dlp ile deneniyor...`);
        try {
          // Fallback: yt-dlp search
          const cookie = getNextCookie();
          const args = ['--default-search', 'ytsearch1', '--get-id', '--no-warnings'];
          // if (cookie) args.push('--cookies', cookie);
          const ytId = await runYtdlp([...args, searchQuery], 10000);
          if (ytId && ytId.length === 11) {
            stmts.setYtMap.run(req.params.videoId, ytId);
            videoId = ytId;
          } else {
            return res.status(404).json({ error: 'Şarkı bulunamadı' });
          }
        } catch (dlpErr) {
          return res.status(404).json({ error: 'Şarkı eşleştirme başarısız', detail: dlpErr.message });
        }
      }
    }
  }
  
  // ── Adım 2: Stream URL Çöz (Önbellekli) ──────────────────
  let streamUrl = null;
  
  // Önbellek kontrol (5 saat TTL)
  const cachedStream = stmts.getStream.get(videoId);
  if (cachedStream) {
    streamUrl = cachedStream.stream_url;
    console.log(`  ✅ Cache hit (Stream URL): ${streamUrl.substring(0, 60)}...`);
  }
  
  // Önbellekte yoksa veya süresi dolmuşsa → yt-dlp veya Piped ile çöz
  if (!streamUrl) {
    const cookie = getNextCookie();
    let ytSuccess = false;
    for (let attempt = 1; attempt <= 3; attempt++) {
      const proxy = getNextProxy();
      const args = [
        '-g', '-f', 'bestaudio[ext=m4a]/bestaudio',
        '--no-warnings', '--no-check-certificate',
        // --extractor-args removed for native visionOS fallback
        '--user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0',
      ];
      if (proxy) args.push('--proxy', proxy);
      args.push(`https://www.youtube.com/watch?v=${videoId}`);
      
      try {
        console.log(`  🔗 yt-dlp Deneme ${attempt}/3 (proxy: ${proxy ? 'evet' : 'hayır'})`);
        streamUrl = await runYtdlp(args, 10000); // 10 saniye timeout per attempt
        
        if (streamUrl && streamUrl.startsWith('http')) {
          stmts.setStream.run(videoId, streamUrl);
          console.log(`  ✅ yt-dlp URL çözüldü (${Date.now() - startTime}ms)`);
          ytSuccess = true;
          break; // Başarılı, döngüden çık
        }
      } catch (err) {
        console.log(`  ⚠️ yt-dlp başarısız (Deneme ${attempt}): ${err.message}`);
      }
    }

    if (!ytSuccess) {
      console.error(`  ⚠️ Tüm yt-dlp denemeleri başarısız oldu. YEDEK MOTOR (Piped API) devreye giriyor...`);
      
      const pipedInstances = [
        'https://pipedapi.kavin.rocks',
        'https://pipedapi.smnz.de',
        'https://pipedapi.lunar.icu'
      ];
      
      const fetch = (await import('node-fetch')).default;
      for (const instance of pipedInstances) {
        try {
          console.log(`  🔄 Piped deneniyor: ${instance}`);
          const res = await fetch(`${instance}/streams/${videoId}`, { timeout: 8000 });
          if (res.ok) {
            const data = await res.json();
            if (data.audioStreams && data.audioStreams.length > 0) {
              const stream = data.audioStreams.find(s => s.mimeType && (s.mimeType.includes('mp4a') || s.mimeType.includes('mp4'))) || data.audioStreams[0];
              streamUrl = stream.url;
              console.log(`  ✅ Piped üzerinden URL bulundu!`);
              stmts.setStream.run(videoId, streamUrl);
              break;
            }
          }
        } catch (e) {
          console.log(`  ❌ Piped başarısız (${instance}): ${e.message}`);
        }
      }
      
      if (!streamUrl || !streamUrl.startsWith('http')) {
        console.error('❌ TÜM MOTORlar ÇÖKTÜ! Video çözülemedi.');
        if (!res.headersSent) res.status(502).json({ error: 'Stream çözme hatası' });
        return;
      }
    }
  }
  
  // ── Adım 3: Çözülen URL'yi Telefona Akıt veya Yönlendir ─
  if (!streamUrl.includes('googlevideo.com')) {
    console.log(`  📡 Piped Proxy tespit edildi. Telefona 302 Redirect atılıyor...`);
    return res.redirect(302, streamUrl);
  }

  const rangeHeader = req.headers.range;
  const fetchHeaders = {};
  if (rangeHeader) fetchHeaders['Range'] = rangeHeader;
  
  console.log(`  📡 Ses akıtılıyor... (${Date.now() - startTime}ms)`);
  
  const upstreamStream = await proxyFetch(streamUrl, fetchHeaders, res);
  
  req.on('close', () => {
    if (upstreamStream && typeof upstreamStream.destroy === 'function') {
      upstreamStream.destroy();
    }
  });
});

// ── YENİ: STREAM KONTROL ENDPOINT'İ (Flutter'ın Çökmesini Önler) ──
app.get('/api/stream_check/:videoId', async (req, res) => {
  const videoId = req.params.videoId;
  const apikey = req.query.apikey;
  if (apikey !== VPS_SECRET) return res.status(403).json({ error: 'Yetkisiz' });

  let streamUrl = getCachedStream(videoId);
  if (streamUrl) {
    return res.json({ status: 'ok', url: `http://167.172.190.129:8080/api/stream/${videoId}?apikey=${VPS_SECRET}` });
  }

  // Cache'de yoksa, yt-dlp ile çözmeye çalış
  let ytSuccess = false;
  for (let attempt = 1; attempt <= 3; attempt++) {
    const proxy = getNextProxy();
    const cookie = getNextCookie();
    const args = [
      '-g', '-f', 'bestaudio[ext=m4a]/bestaudio',
      '--no-warnings', '--no-check-certificate',
      // --extractor-args removed for native visionOS fallback
      '--user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0',
    ];
    // if (cookie) args.push('--cookies', cookie);
    if (proxy) args.push('--proxy', proxy);
    args.push(`https://www.youtube.com/watch?v=${videoId}`);
    
    try {
      streamUrl = await runYtdlp(args, 10000);
      if (streamUrl && streamUrl.startsWith('http')) {
        stmts.setStream.run(videoId, streamUrl);
        ytSuccess = true;
        break;
      }
    } catch (e) {}
  }

  if (ytSuccess) {
    return res.json({ status: 'ok', url: `http://167.172.190.129:8080/api/stream/${videoId}?apikey=${VPS_SECRET}` });
  }

  return res.status(502).json({ status: 'error', error: 'VPS stream çözemedi' });
});

// ═══════════════════════════════════════════════════════════════
// 📻 RADIO ENDPOINT — Otonom Şarkı Önerileri
// ═══════════════════════════════════════════════════════════════
app.get('/api/radio/:videoId', async (req, res) => {
  const { videoId } = req.params;
  console.log(`📻 Radyo isteği: ${videoId}`);
  
  // Önbellek kontrol (24 saat)
  const cached = stmts.getRadio.get(videoId);
  if (cached) {
    console.log(`  ✅ Cache hit (Radyo)`);
    return res.json({ status: 'basarili', oneriler: JSON.parse(cached.results) });
  }
  
  const cookie = getNextCookie();
  const proxy = getNextProxy();
  
  const args = [
    '--flat-playlist', '--dump-json',
    '--no-warnings', '--no-check-certificate',
    '--playlist-end', '15',
    '--user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0',
  ];
  // if (cookie) args.push('--cookies', cookie);
  if (proxy) args.push('--proxy', proxy);
  args.push(`https://www.youtube.com/watch?v=${videoId}&list=RD${videoId}`);
  
  try {
    const output = await runYtdlp(args, 20000);
    
    const items = output.split('\n')
      .filter(line => line.trim().startsWith('{'))
      .map(line => {
        try {
          const d = JSON.parse(line);
          return {
            id: d.id,
            title: d.title || 'Bilinmeyen',
            channel: d.uploader || d.channel || 'Bilinmeyen',
            thumbnail: d.thumbnail || `https://i.ytimg.com/vi/${d.id}/hqdefault.jpg`,
            duration: d.duration || 0,
          };
        } catch { return null; }
      })
      .filter(Boolean)
      .filter(item => item.id && item.id !== videoId);
    
    if (items.length > 0) {
      stmts.setRadio.run(videoId, JSON.stringify(items));
    }
    
    console.log(`  ✅ ${items.length} şarkı önerisi bulundu`);
    res.json({ status: 'basarili', oneriler: items });
    
  } catch (e) {
    console.error(`  ❌ Radyo hatası: ${e.message}`);
    res.status(500).json({ status: 'hata', oneriler: [], error: e.message });
  }
});

// ═══════════════════════════════════════════════════════════════
// 💚 HEALTH CHECK
// ═══════════════════════════════════════════════════════════════
app.get('/health', (req, res) => {
  res.json({
    status: '🟢 ÖZSES V8 Karargah Aktif',
    uptime: Math.floor(process.uptime()) + 's',
    proxies: proxyPool.length,
    cookies: cookieFiles.length,
    cache: {
      spotifyMappings: stmts.countYtMap.get().c,
      streamUrls: stmts.countStream.get().c,
      radioEntries: stmts.countRadio.get().c,
    },
    memory: Math.round(process.memoryUsage().rss / 1024 / 1024) + ' MB',
  });
});

// Kök endpoint
app.get('/', (req, res) => {
  res.json({ name: 'ÖZSES V8', status: 'aktif', docs: '/health' });
});

// ═══════════════════════════════════════════════════════════════
// 🚀 BAŞLATMA
// ═══════════════════════════════════════════════════════════════
async function loadProxies() {
  try {
    const fetch = (await import('node-fetch')).default;
    const resp = await fetch(PROXY_LIST_URL);
    const text = await resp.text();
    proxyPool = text.trim().split('\n').filter(line => line.trim() && !line.startsWith('#'));
    console.log(`✅ ${proxyPool.length} proxy yüklendi (Webshare)`);
  } catch (e) {
    console.error('⚠️ Proxy yükleme hatası (cookie ile devam ediliyor):', e.message);
  }
}

function loadCookies() {
  try {
    if (!fs.existsSync(COOKIE_DIR)) {
      fs.mkdirSync(COOKIE_DIR, { recursive: true });
      console.log('📁 Cookie dizini oluşturuldu:', COOKIE_DIR);
    }
    const files = fs.readdirSync(COOKIE_DIR).filter(f => f.endsWith('.txt'));
    cookieFiles = files.map(f => path.join(COOKIE_DIR, f));
    console.log(`✅ ${cookieFiles.length} cookie dosyası yüklendi`);
    if (cookieFiles.length === 0) {
      console.warn('⚠️ Cookie dosyası bulunamadı! yt-dlp cookie\'siz çalışacak.');
    }
  } catch (e) {
    console.error('❌ Cookie yükleme hatası:', e.message);
    cookieFiles = [];
  }
}

async function main() {
  console.log('═══════════════════════════════════════════');
  console.log('  🔥 ÖZSES V8 — Merkezi Ses Karargahı');
  console.log('═══════════════════════════════════════════');
  
  loadCookies();
  await loadProxies();
  
  // Proxy listesini her saat yenile
  setInterval(loadProxies, 3600000);
  
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Sunucu aktif: http://0.0.0.0:${PORT}`);
    console.log(`📡 Stream:  /api/stream/:videoId`);
    console.log(`📻 Radyo:   /api/radio/:videoId`);
    console.log(`💚 Sağlık:  /health`);
    console.log('═══════════════════════════════════════════');
  });
}

main().catch(e => {
  console.error('💥 Sunucu başlatma hatası:', e);
  process.exit(1);
});
