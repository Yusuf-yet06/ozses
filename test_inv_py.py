import requests

def test_invidious():
    instances = [
        'https://inv.nadeko.net', 
        'https://invidious.nerdvpn.de', 
        'https://invidious.f5.si', 
        'https://invidious.tiekoetter.com'
    ]
    video_id = '8s8m9rG_fSA'
    
    for instance in instances:
        try:
            print(f"Testing {instance}...")
            url = f"{instance}/api/v1/videos/{video_id}"
            res = requests.get(url, timeout=10)
            if res.status_code == 200:
                data = res.json()
                if 'adaptiveFormats' in data:
                    formats = data['adaptiveFormats']
                    audio = next((f for f in formats if f['type'].startswith('audio')), None)
                    if audio:
                        stream_url = audio['url']
                        print("SUCCESS found audio URL!")
                        # Test if stream works
                        stream_res = requests.head(stream_url, timeout=10)
                        print("Stream HEAD Status:", stream_res.status_code)
                    else:
                        print("No audio format")
                else:
                    print("No adaptiveFormats")
            else:
                print("Failed:", res.status_code)
        except Exception as e:
            print("Error:", e)

test_invidious()
