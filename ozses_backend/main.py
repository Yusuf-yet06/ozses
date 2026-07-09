from fastapi import FastAPI, Request, HTTPException, Response, BackgroundTasks
from fastapi.responses import StreamingResponse, RedirectResponse, FileResponse
import tempfile
import os
import yt_dlp
import httpx
import logging
import re
import uuid
import time
import glob
import asyncio
from ytmusicapi import YTMusic

app = FastAPI()
ytmusic = YTMusic()
logging.basicConfig(level=logging.INFO)

ydl_opts = {
    'format': '140/m4a/bestaudio/best',
    'noplaylist': True,
    'no_warnings': True,
    'extract_flat': False,
    'socket_timeout': 10,
}

@app.get("/")
def read_root():
    return {"status": "OZSES API is running"}

@app.get("/search")
async def search_music(q: str):
    try:
        results = ytmusic.search(q, filter="songs", limit=15)
        formatted = []
        for r in results:
            formatted.append({
                "id": r.get("videoId"),
                "title": r.get("title"),
                "channel": ", ".join([a.get("name", "") for a in r.get("artists", [])]),
                "thumbnail": r.get("thumbnails", [{}])[-1].get("url", "") if r.get("thumbnails") else "",
                "duration": r.get("duration_seconds", 0)
            })
        return {"status": "basarili", "oneriler": formatted}
    except Exception as e:
        return {"status": "hata", "mesaj": str(e)}

def cleanup_old_files(temp_dir):
    try:
        now = time.time()
        for f in glob.glob(os.path.join(temp_dir, "*.m4a")):
            if os.stat(f).st_mtime < now - 3600: # 1 saatten eski
                os.remove(f)
    except:
        pass

def send_bytes_range_requests(file_path: str, request: Request):
    file_size = os.stat(file_path).st_size
    range_header = request.headers.get("range", "")
    
    if not range_header.startswith("bytes="):
        return FileResponse(file_path, media_type="audio/mp4")
    
    try:
        ranges = range_header.replace("bytes=", "").split("-")
        start = int(ranges[0]) if ranges[0] else 0
        end = int(ranges[1]) if len(ranges) > 1 and ranges[1] else file_size - 1
    except ValueError:
        return FileResponse(file_path, media_type="audio/mp4")
        
    start = max(0, min(start, file_size - 1))
    end = max(0, min(end, file_size - 1))
    chunk_length = end - start + 1
    
    def file_iterator():
        with open(file_path, "rb") as f:
            f.seek(start)
            bytes_left = chunk_length
            while bytes_left > 0:
                chunk = f.read(min(bytes_left, 65536))
                if not chunk:
                    break
                bytes_left -= len(chunk)
                yield chunk

    headers = {
        "Content-Range": f"bytes {start}-{end}/{file_size}",
        "Accept-Ranges": "bytes",
        "Content-Length": str(chunk_length),
        "Content-Type": "audio/mp4",
    }
    
    return StreamingResponse(file_iterator(), status_code=206, headers=headers)

@app.get("/stream")
async def stream_audio(id: str, request: Request, background_tasks: BackgroundTasks):
    if not re.match(r'^[a-zA-Z0-9_-]{11}$', id):
        raise HTTPException(status_code=400, detail="Invalid video ID")

    try:
        url = f"https://www.youtube.com/watch?v={id}"
        temp_dir = tempfile.gettempdir()
        
        # Dosya adı sabit olmalı ki Range istekleri aynı dosyayı bulabilsin!
        file_path = os.path.join(temp_dir, f"{id}.m4a")
        lock_path = file_path + ".lock"

        # Dosya silme görevini arka planda eski dosyalar için çalıştırıyoruz
        background_tasks.add_task(cleanup_old_files, temp_dir)

        # Eğer dosya iniyorsa veya inmemişse
        if not os.path.exists(file_path) or os.path.getsize(file_path) < 10000:
            if os.path.exists(lock_path):
                # Başka bir istek dosyayı indiriyor, bitmesini bekle
                wait_time = 0
                while os.path.exists(lock_path) and wait_time < 30:
                    await asyncio.sleep(0.5)
                    wait_time += 0.5
            else:
                # Kilidi oluştur ve indir
                with open(lock_path, 'w') as f:
                    f.write("locked")
                try:
                    download_opts = ydl_opts.copy()
                    download_opts['outtmpl'] = file_path
                    with yt_dlp.YoutubeDL(download_opts) as ydl:
                        ydl.download([url])
                finally:
                    if os.path.exists(lock_path):
                        os.remove(lock_path)

        if not os.path.exists(file_path):
             raise HTTPException(status_code=404, detail="Stream indirme hatasi")
        
        # M4A/MP4 için Range desteği şarttır, yoksa ExoPlayer (0) Source Error verir.
        return send_bytes_range_requests(file_path, request)

    except Exception as e:
        logging.error(f"Error streaming {id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
