import os
import subprocess

# Reset search_page.dart from git
subprocess.run(['git', 'checkout', 'lib/src/reverse_engineering/pages/search_page.dart'], cwd='packages/youtube_explode_dart')

path = r'packages\youtube_explode_dart\lib\src\reverse_engineering\pages\search_page.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("?.getT<String>('text')", "?['text']?.toString()")
content = content.replace(".getT<String>('text')", "['text'].toString()")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Cleanly Patched!")
