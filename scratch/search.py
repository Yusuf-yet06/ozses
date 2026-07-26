import os
for r, d, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(r, f)
            content = open(path, encoding='utf-8', errors='ignore').read()
            if 'rim d' in content.lower():
                print(path)
