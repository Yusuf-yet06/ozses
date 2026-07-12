"""
ÖZSES V7 - Siber Karargah Backend
Render.com üzerinde çalışır.
Endpoints: /search, /stream, /radio
"""

from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import yt_dlp
import json

app = FastAPI(title="Özses Siber Karargah")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# yt-dlp ortak ayarlar (bot gibi görünme, oauth ve po_token bypass denemeleri)
YDL_BASE_OPTS = {
    'quiet': True,
    'no_warnings': True,
    'cookiefile': 'cookies.txt', # Siber Kalkan: Gerçek İnsan Kimliği Aktif!
    'extractor_args': {
        'youtube': {
            'client': ['ios', 'tv', 'web_embedded'],
            'player_skip': ['webpage', 'configs']
        }
    },
    'http_headers': {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
        'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
    }
}


@app.get("/")
def root():
    return {"status": "online", "service": "Özses Siber Karargah"}


@app.get("/search")
def search(q: str = Query(..., description="Arama sorgusu")):
    try:
        ydl_opts = {
            **YDL_BASE_OPTS,
            'extract_flat': True,
            'playlistend': 20,
        }
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            result = ydl.extract_info(f"ytsearch20:{q}", download=False)
            entries = result.get('entries', []) if result else []

            oneriler = []
            for e in entries:
                if not e: continue
                oneriler.append({
                    'videoId': e.get('id', ''),
                    'title': e.get('title', ''),
                    'artist': e.get('uploader', e.get('channel', '')),
                    'thumbnail': e.get('thumbnail', f"https://i.ytimg.com/vi/{e.get('id', '')}/hqdefault.jpg"),
                    'duration': e.get('duration', 0),
                })
            return {"status": "basarili", "oneriler": oneriler}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@app.get("/stream")
def stream(id: str = Query(..., description="YouTube video ID")):
    try:
        ydl_opts = {
            **YDL_BASE_OPTS,
            'format': 'bestaudio[ext=m4a]/bestaudio/best',
        }
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(
                f"https://www.youtube.com/watch?v={id}",
                download=False
            )
            if not info:
                raise HTTPException(status_code=404, detail="Video bulunamadı")

            stream_url = info.get('url')
            if not stream_url:
                formats = info.get('formats', [])
                audio_formats = [f for f in formats if f.get('vcodec') == 'none' and f.get('url')]
                if audio_formats:
                    best = max(audio_formats, key=lambda f: f.get('abr', 0) or 0)
                    stream_url = best['url']

            if not stream_url:
                raise HTTPException(status_code=404, detail="Stream URL bulunamadı")

            return {
                "status": "basarili",
                "stream_url": stream_url,
                "title": info.get('title', ''),
                "ext": info.get('ext', 'm4a'),
            }
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@app.get("/radio")
def radio(id: str = Query(..., description="YouTube video ID")):
    try:
        ydl_opts = {
            **YDL_BASE_OPTS,
            'extract_flat': True,
            'playlistend': 25,
        }
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            result = ydl.extract_info(
                f"https://www.youtube.com/watch?v={id}&list=RD{id}",
                download=False
            )
            entries = result.get('entries', []) if result else []
            oneriler = []
            for e in entries:
                if not e or e.get('id') == id: continue
                oneriler.append({
                    'videoId': e.get('id', ''),
                    'title': e.get('title', ''),
                    'artist': e.get('uploader', e.get('channel', '')),
                    'thumbnail': e.get('thumbnail', f"https://i.ytimg.com/vi/{e.get('id', '')}/hqdefault.jpg"),
                    'duration': e.get('duration', 0),
                })
            return {"status": "basarili", "oneriler": oneriler}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))
