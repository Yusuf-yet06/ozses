import requests
import time

def test_render():
    url = "https://ozses.onrender.com/stream?id=8s8m9rG_fSA"
    print(f"Testing Render: {url}")
    start = time.time()
    try:
        res = requests.get(url, stream=True)
        print("Render Status:", res.status_code)
        print("Time taken for headers:", time.time() - start)
        if res.status_code == 200:
            bytes_read = 0
            for chunk in res.iter_content(chunk_size=1024):
                if chunk:
                    bytes_read += len(chunk)
                    if bytes_read > 100000:
                        break
            print("Successfully read bytes:", bytes_read)
        else:
            print("Render error body:", res.text)
    except Exception as e:
        print("Error:", e)

test_render()
