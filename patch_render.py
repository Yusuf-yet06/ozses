import os

def replace_in_file(path, old, new):
    if not os.path.exists(path):
        return
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    if old in content:
        content = content.replace(old, new)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Replaced in {path}")

files = [
    r'lib\core\platform\mobile_platform.dart',
    r'lib\core\platform\windows_platform.dart',
    r'lib\services\audio_handler.dart',
    r'lib\services\ozses_service.dart',
    r'lib\services\services.dart',
    r'lib\services\siber_kopru.dart',
]

for file in files:
    replace_in_file(file, 'http://127.0.0.1:8080/stream?id=', 'https://ozses.onrender.com/stream?id=')
