#!/usr/bin/env python3
"""
OZSES V7 - Siber Web Karargahi Proxy Sunucusu (yt-dlp powered)
Hem Flutter web dosyalarini servis eder, hem de yt-dlp ile arama/stream yapar.
Piped/Invidious yerine dogrudan yt-dlp kullanir - CORS sorunu yok, her zaman calisir.
"""

import http.server
import socketserver
import urllib.parse
import json
import os
import sys
import subprocess
import threading
import urllib.request

PORT = 8081
WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")

# yt-dlp cache - tekrar sorguları hızlandırır
_cache = {}
_cache_lock = threading.Lock()

def run_ytdlp(args):
    """yt-dlp'yi çalıştırıp JSON çıktısını döndür."""
    try:
        result = subprocess.run(
            ["yt-dlp"] + args,
            capture_output=True,
            text=True,
            timeout=15
        )
        return result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return "", "TIMEOUT"
    except FileNotFoundError:
        return "", "yt-dlp not found"


def search_ytdlp(query, limit=20):
    """yt-dlp ile YouTube araması yap."""
    cache_key = f"search:{query}:{limit}"
    with _cache_lock:
        if cache_key in _cache:
            return _cache[cache_key]

    stdout, stderr = run_ytdlp([
        "--flat-playlist",
        "--dump-json",
        f"ytsearch{limit}:{query}"
    ])

    items = []
    for line in stdout.splitlines():
        line = line.strip()
        if line.startswith("{"):
            try:
                v = json.loads(line)
                thumbs = v.get("thumbnails", [])
                thumb = ""
                if thumbs:
                    # En iyi kalite thumbnail'i seç
                    best = max(thumbs, key=lambda t: (t.get("height", 0) or 0), default=thumbs[-1])
                    thumb = best.get("url", "")
                    # Temiz thumbnail URL
                    if not thumb:
                        vid_id = v.get("id", "")
                        thumb = f"https://i.ytimg.com/vi/{vid_id}/hqdefault.jpg"
                else:
                    vid_id = v.get("id", "")
                    if vid_id:
                        thumb = f"https://i.ytimg.com/vi/{vid_id}/hqdefault.jpg"

                items.append({
                    "id": v.get("id", ""),
                    "title": v.get("title", ""),
                    "channel": v.get("channel", v.get("uploader", "")),
                    "thumbnail": thumb,
                    "duration": v.get("duration", 0),
                    "view_count": v.get("view_count", 0),
                })
            except Exception:
                pass

    with _cache_lock:
        _cache[cache_key] = items
    return items


def get_stream_url(video_id):
    """yt-dlp ile ses stream URL'ini al."""
    cache_key = f"stream:{video_id}"
    with _cache_lock:
        if cache_key in _cache:
            return _cache[cache_key]

    stdout, stderr = run_ytdlp([
        "-f", "bestaudio/best",
        "-g",
        "--no-playlist",
        f"https://www.youtube.com/watch?v={video_id}"
    ])

    stream_url = stdout.strip().splitlines()[0] if stdout.strip() else ""

    with _cache_lock:
        _cache[cache_key] = stream_url
    return stream_url


class SiberProxyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def log_message(self, format, *args):
        pass  # Quiet mode - konsolu temiz tut

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)

        if parsed.path.startswith("/api/proxy/search"):
            self.handle_search(parsed)
        elif parsed.path.startswith("/api/proxy/stream_bytes"):
            self.handle_stream_bytes(parsed)
        elif parsed.path.startswith("/api/proxy/stream"):
            self.handle_stream(parsed)
        elif parsed.path.startswith("/api/proxy/kesfet"):
            self.handle_kesfet(parsed)
        elif parsed.path.startswith("/api/proxy/suggest"):
            self.handle_suggest(parsed)
        else:
            # Statik Flutter web dosyaları
            if parsed.path == "/" or not os.path.exists(os.path.join(WEB_DIR, parsed.path.lstrip("/"))):
                # SPA fallback - her route index.html'e yönlendir
                self.path = "/"
            super().do_GET()

    def handle_suggest(self, parsed):
        params = urllib.parse.parse_qs(parsed.query)
        query = params.get("q", [""])[0]
        if not query:
            self.send_json({"error": "Sorgu bos", "oneriler": []}, status=400)
            return
            
        try:
            url = f"http://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q={urllib.parse.quote(query)}"
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode('utf-8'))
                suggestions = data[1] if len(data) > 1 else []
                self.send_json({"status": "basarili", "oneriler": suggestions})
        except Exception as e:
            print(f"[SUGGEST ERROR] {e}")
            self.send_json({"error": str(e), "oneriler": []}, status=500)

    def send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", len(body))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(body)

    def prefetch_streams(self, items, max_items=5):
        def prefetch_worker():
            for item in items[:max_items]:
                vid = item.get("id")
                if vid:
                    # Sadece cache'i doldurur
                    get_stream_url(vid)
        threading.Thread(target=prefetch_worker, daemon=True).start()

    def handle_search(self, parsed):
        params = urllib.parse.parse_qs(parsed.query)
        query = params.get("q", ["populer sarkilar"])[0]

        print(f"[SEARCH] {query}")
        items = search_ytdlp(query, limit=20)

        if items:
            self.prefetch_streams(items)
            self.send_json({"status": "basarili", "oneriler": items, "nextPageToken": ""})
        else:
            self.send_json({"error": "Sonuc bulunamadi", "oneriler": []}, status=503)

    def handle_kesfet(self, parsed):
        queries = [
            "en cok dinlenen turkce pop sarkilar 2024 2025",
            "populer turkce muzik official video",
        ]
        all_items = []
        for q in queries:
            items = search_ytdlp(q, limit=15)
            all_items.extend(items)

        # Tekrarlı videoları kaldır
        seen = set()
        unique = []
        for item in all_items:
            if item["id"] not in seen:
                seen.add(item["id"])
                unique.append(item)

        print(f"[KESFET] {len(unique)} video bulundu")
        self.prefetch_streams(unique, max_items=10)
        self.send_json({"status": "basarili", "oneriler": unique[:30], "nextPageToken": ""})

    
    def handle_stream_bytes(self, parsed):
        params = urllib.parse.parse_qs(parsed.query)
        video_id = params.get("id", [""])[0]

        if not video_id:
            self.send_response(400)
            self.end_headers()
            return

        print(f"[STREAM BYTES] {video_id}")
        stream_url = get_stream_url(video_id)

        if not stream_url:
            self.send_response(503)
            self.end_headers()
            return

        req = urllib.request.Request(stream_url)
        # Pass range header if present
        if 'Range' in self.headers:
            req.add_header('Range', self.headers['Range'])
        req.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')

        try:
            with urllib.request.urlopen(req) as response:
                self.send_response(response.getcode())
                for k, v in response.headers.items():
                    if k.lower() not in ['transfer-encoding', 'connection', 'server']:
                        self.send_header(k, v)
                self.end_headers()
                while True:
                    chunk = response.read(65536)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
        except Exception as e:
            print(f"[STREAM ERROR] {e}")
            if not self.headers.get('Range'):
                self.send_response(500)
                self.end_headers()

    def handle_stream(self, parsed):
        params = urllib.parse.parse_qs(parsed.query)
        video_id = params.get("id", [""])[0]

        if not video_id:
            self.send_json({"error": "id parametresi eksik"}, status=400)
            return

        print(f"[STREAM] {video_id}")
        stream_url = get_stream_url(video_id)

        if stream_url:
            self.send_json({"status": "basarili", "stream_url": stream_url})
        else:
            self.send_json({"error": "Stream URL alinamadi"}, status=503)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()


if __name__ == "__main__":
    if not os.path.exists(WEB_DIR):
        print(f"[HATA] Web build klasoru bulunamadi: {WEB_DIR}")
        print("[BILGI] Once 'flutter build web' komutunu calistirin.")
        sys.exit(1)

    # yt-dlp kontrol
    stdout, stderr = run_ytdlp(["--version"])
    if not stdout.strip():
        print("[HATA] yt-dlp bulunamadi! Lutfen yukleyin: pip install yt-dlp")
        sys.exit(1)
    print(f"[OK] yt-dlp: {stdout.strip()}")

    print("=" * 55)
    print("   OZSES V7 - SIBER WEB KARARGAHI BASLATILIYOR")
    print("=" * 55)
    print(f"[OK] Uygulama: http://localhost:{PORT}")
    print(f"[OK] yt-dlp ile YouTube entegrasyonu aktif")
    print("[!] Kapatmak icin Ctrl+C basin")
    print("")

    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), SiberProxyHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[OK] Sunucu kapatildi.")
