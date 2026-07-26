import os

def search_text(term):
    print(f"Searching for {term}...")
    for r, d, files in os.walk('lib'):
        for f in files:
            if f.endswith('.dart'):
                path = os.path.join(r, f)
                try:
                    with open(path, encoding='utf-8') as file:
                        for idx, line in enumerate(file):
                            if term.lower() in line.lower():
                                print(f"{path}:{idx+1}: {line.strip()}")
                except Exception as e:
                    pass

search_text('evrim')
search_text('offline')
