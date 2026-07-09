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

@app.get("/stream")
async def stream_audio(id: str, background_tasks: BackgroundTasks):
    if not re.match(r'^[a-zA-Z0-9_-]{11}$', id):
        raise HTTPException(status_code=400, detail="Invalid video ID")

    try:
        url = f"https://www.youtube.com/watch?v={id}"
        temp_dir = tempfile.gettempdir()
        
        # SİBER KALKAN: Her istek için benzersiz dosya adı, çakışmayı önler
        unique_id = str(uuid.uuid4())[:8]
        file_path = os.path.join(temp_dir, f"{id}_{unique_id}.m4a")

        background_tasks.add_task(cleanup_old_files, temp_dir)

        download_opts = ydl_opts.copy()
        download_opts['outtmpl'] = file_path
        
        with yt_dlp.YoutubeDL(download_opts) as ydl:
            ydl.download([url])

        if not os.path.exists(file_path):
             raise HTTPException(status_code=404, detail="Stream indirme hatasi")
        
        return FileResponse(file_path, media_type="audio/mp4")

    except Exception as e:
        logging.error(f"Error streaming {id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
