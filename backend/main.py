from fastapi import FastAPI, APIRouter, HTTPException, Query
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
import os
import logging
from pathlib import Path
from pydantic import BaseModel
from typing import List, Optional
import uuid
from datetime import datetime
import asyncio
import random
import yt_dlp
import time

ROOT_DIR = Path(__file__).parent

# Create the main app without a prefix
app = FastAPI()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Fallback user agents in case fake_useragent is missing
FALLBACK_USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/120.0.6099.119 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
]

class StealthYouTubeProxy:
    def __init__(self):
        self.user_agents = FALLBACK_USER_AGENTS
    
    def _get_random_user_agent(self):
        """Get random user agent for rotation"""
        return random.choice(self.user_agents)
    
    async def _human_delay(self):
        """Simulate human-like delay between requests"""
        delay = random.uniform(0.1, 0.5)  # 100-500ms
        await asyncio.sleep(delay)
    
    def _get_ydl_opts(self, search_mode=False):
        """Get yt-dlp options with stealth configuration"""
        opts = {
            'quiet': True,
            'no_warnings': True,
            'extract_flat': search_mode,
            'format': 'bestaudio/best',
            'nocheckcertificate': True,
            'extractor_retries': 3,
            'socket_timeout': 30,
            'cookiefile': 'cookies.txt' if os.path.exists('cookies.txt') else None,
            'extractor_args': {
                'youtube': {
                    'client': ['ios', 'tv', 'web_embedded'],
                    'player_skip': ['webpage', 'configs']
                }
            },
            'http_headers': {
                'User-Agent': self._get_random_user_agent(),
                'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
            }
        }
        return opts
    
    async def get_stream_url(self, video_id: str):
        """Get audio stream URL with quality selection"""
        try:
            await self._human_delay()
            
            ydl_opts = self._get_ydl_opts()
            ydl_opts['format'] = 'bestaudio[ext=m4a]/bestaudio/best'
            
            url = f"https://www.youtube.com/watch?v={video_id}"
            
            logger.info(f"Getting stream URL for: {video_id}")
            
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = await asyncio.to_thread(ydl.extract_info, url, download=False)
                
                if not info:
                    raise HTTPException(status_code=404, detail="Video not found")
                
                # Get the best audio format
                stream_url = info.get('url')
                if not stream_url:
                    formats = info.get('formats', [])
                    audio_formats = [f for f in formats if f.get('vcodec') == 'none' and f.get('url')]
                    if audio_formats:
                        best_audio = max(audio_formats, key=lambda f: f.get('abr', 0) or 0)
                        stream_url = best_audio['url']
                
                if not stream_url:
                    raise HTTPException(status_code=404, detail="Stream URL not found")
                
                return {
                    "status": "basarili",
                    "stream_url": stream_url,
                    "title": info.get('title', ''),
                }
                
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Stream extraction error: {str(e)}")
            # Retry on bot detection
            if "403" in str(e) or "429" in str(e) or "Sign in" in str(e):
                logger.warning("Bot detection triggered, retrying with different UA...")
                await asyncio.sleep(random.uniform(1, 3))
                # Sadece 1 kere retry atalım
                ydl_opts = self._get_ydl_opts()
                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    info = await asyncio.to_thread(ydl.extract_info, url, download=False)
                    stream_url = info.get('url')
                    if stream_url:
                        return {"status": "basarili", "stream_url": stream_url}
            raise HTTPException(status_code=500, detail=f"Stream extraction failed: {str(e)}")

# Initialize stealth proxy
stealth_proxy = StealthYouTubeProxy()

@app.get("/")
async def root():
    return {
        "message": "Özses Siber Karargah Proxy API",
        "status": "online"
    }

# GET endpoint for backward compatibility with existing flutter app
@app.get("/stream")
async def get_stream_get(id: str = Query(..., description="YouTube video ID")):
    return await stealth_proxy.get_stream_url(id)

# POST endpoint for new integration
class StreamRequest(BaseModel):
    video_id: str

@app.post("/stream")
async def get_stream_post(request: StreamRequest):
    return await stealth_proxy.get_stream_url(request.video_id)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
