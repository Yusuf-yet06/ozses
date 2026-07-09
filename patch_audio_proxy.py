import os
path = r'lib\services\audio_handler.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_str = "resolvedUrl = 'http://127.0.0.1:${OzsesBridge.proxyPort}/$videoId';"
new_str = "resolvedUrl = 'https://ozses.onrender.com/stream?id=$videoId';"

if old_str in content:
    content = content.replace(old_str, new_str)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("REPLACED!")
else:
    print("NOT FOUND")
