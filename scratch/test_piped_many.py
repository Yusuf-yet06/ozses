import urllib.request
import json

def test_piped():
    try:
        url = "https://pipedapi.kavin.rocks/streams/dQw4w9WgXcQ"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            print("Piped Kavin Rocks:", len(data.get('audioStreams', [])))
    except Exception as e:
        print("Piped Error:", e)

test_piped()
