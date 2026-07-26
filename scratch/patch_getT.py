import os

path = r'packages\youtube_explode_dart\lib\src\reverse_engineering\pages\search_page.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("?.getT<String>('text')", "?['text']")
content = content.replace(".getT<String>('text')", "['text']")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Patched!")
