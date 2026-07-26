import os

path = r'lib\screens\discover_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

out_lines = []
skip = False
for i, line in enumerate(lines):
    if line.strip() == 'Future<void> _loadSearchHistory() async {' and i > 600:
        skip = True
    
    if skip:
        # Check if we've reached a method that is NOT duplicated, e.g. `_fetchGenresSequentially`
        if line.strip() == '// 🎯 SİBER HAMLE: Otonom Alt Listeleri Sessizce ve Sırayla Çek (Ağı Yormadan)' and i > 600:
            skip = False
            out_lines.append(line)
            continue
    
    if not skip:
        out_lines.append(line)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(out_lines)

print("Duplicates removed from discover_screen.dart")
