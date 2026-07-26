import requests

def test_apis():
    videoId = '8s8m9rG_fSA'
    apis = [
        f'https://api.vkrdownloader.vercel.app/server?v={videoId}',
        f'https://ytstream-download-youtube-videos.p.rapidapi.com/dl?id={videoId}' # Needs rapidapi key
    ]
    
    try:
        res = requests.get(apis[0])
        print("VKR:", res.status_code, res.text[:200])
    except Exception as e:
        print("VKR Error:", e)

test_apis()
