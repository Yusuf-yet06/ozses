import os

file_path = "siber_proxy.py"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

import re

# We will add a new handle_stream_bytes function to SiberProxyHandler
# And register it in do_GET

new_func = """
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

        import urllib.request
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

"""

if "handle_stream_bytes" not in content:
    content = content.replace("def handle_stream(", new_func + "    def handle_stream(")
    
    # Add routing
    content = content.replace("elif parsed.path.startswith(\"/api/proxy/stream\"):", "elif parsed.path.startswith(\"/api/proxy/stream_bytes\"):\n            self.handle_stream_bytes(parsed)\n        elif parsed.path.startswith(\"/api/proxy/stream\"):")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("siber_proxy.py updated.")
