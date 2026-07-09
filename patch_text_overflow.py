import re

files = [
  r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\screens\home_screen.dart',
  r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\screens\discover_screen.dart',
  r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\ui\widgets\mini_player.dart'
]

for filepath in files:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except:
        continue
    
    # We want to find Text(something, style: ...) and add overflow: TextOverflow.ellipsis, maxLines: 1 if it doesn't have it
    # We'll use a simple regex that matches Text( ... ) and if 'overflow:' is not in it, we add it.
    
    def replacer(match):
        full_text = match.group(0)
        inner = match.group(1)
        if 'overflow:' not in full_text and 'maxLines:' not in full_text and 'textAlign:' not in full_text:
            # check if it's not a short hardcoded string
            if inner.startswith('"') and inner.endswith('"') and len(inner) < 15:
                return full_text
            
            # insert overflow and maxLines before the closing parenthesis
            # find the last parenthesis
            last_paren = full_text.rfind(')')
            if last_paren != -1:
                return full_text[:last_paren] + ", overflow: TextOverflow.ellipsis, maxLines: 1" + full_text[last_paren:]
        return full_text
    
    new_content = re.sub(r'Text\((.*?)\)', replacer, content, flags=re.DOTALL)
    
    # Let's also wrap Text widgets inside Row that are causing overflows with Expanded.
    # Actually, wrapping with Expanded is harder with Regex. Let's just rely on TextOverflow first.
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Patched {filepath}")
