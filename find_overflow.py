import re

files = [
  r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\screens\home_screen.dart',
  r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\screens\discover_screen.dart'
]

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all Text( widgets and see if they have overflow
    matches = re.finditer(r'Text\(\s*[^,]+,\s*(.*?)\)', content, re.DOTALL)
    print(f"\nChecking {filepath}:")
    for m in matches:
        args = m.group(1)
        # Check if it has style but no overflow, especially in Row/Column
        if 'overflow' not in args and ('style' in args or 'maxLines' in args):
            snippet = m.group(0)
            if len(snippet) > 80:
                snippet = snippet[:80] + "..."
            # Print first line of snippet
            print(f"Missing overflow: {snippet.split(chr(10))[0]}")
