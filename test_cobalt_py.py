import requests

def test_cobalt():
    url = "https://api.cobalt.tools/"
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    }
    payload = {
        "url": "https://www.youtube.com/watch?v=8s8m9rG_fSA",
        "isAudioOnly": True,
        "aFormat": "mp3"
    }
    try:
        response = requests.post(url, json=payload, headers=headers)
        print("api.cobalt.tools:", response.status_code, response.text)
    except Exception as e:
        print("Error:", e)

    url2 = "https://co.wuk.sh/"
    try:
        response = requests.post(url2, json=payload, headers=headers)
        print("co.wuk.sh:", response.status_code, response.text)
    except Exception as e:
        print("Error:", e)
        
test_cobalt()
