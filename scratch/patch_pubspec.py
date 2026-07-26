import os

path = r'pubspec.yaml'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_git = """  youtube_explode_dart:
    git:
      url: https://github.com/Hexer10/youtube_explode_dart.git
      ref: master"""
new_local = """  youtube_explode_dart:
    path: packages/youtube_explode_dart"""

content = content.replace(old_git, new_local)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Patched pubspec.yaml!")
