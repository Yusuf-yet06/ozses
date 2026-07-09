import re

files = [
  r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\screens\home_screen.dart',
  r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\screens\discover_screen.dart'
]

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # In home_screen.dart, look for item.title and item.artist inside Text()
    # and replace them with Text(..., maxLines: 1, overflow: TextOverflow.ellipsis)
    # We can just do simple string replacements.

    # 1. Text(item.title,
    content = content.replace('Text(\n                                      item.title,\n                                      style: const TextStyle(', 
                              'Text(\n                                      item.title,\n                                      maxLines: 1, overflow: TextOverflow.ellipsis,\n                                      style: const TextStyle(')
    content = content.replace('Text(item.title, style:', 'Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style:')
    content = content.replace('Text(\n                                item.title,', 'Text(\n                                item.title, maxLines: 1, overflow: TextOverflow.ellipsis,')

    # 2. Text(item.artist
    content = content.replace('Text(\n                                      item.artist ?? "Bilinmeyen",\n                                      style: const TextStyle(',
                              'Text(\n                                      item.artist ?? "Bilinmeyen",\n                                      maxLines: 1, overflow: TextOverflow.ellipsis,\n                                      style: const TextStyle(')
    
    # 3. Text(item.name
    content = content.replace('Text(\n                              item.name,', 'Text(\n                              item.name, maxLines: 1, overflow: TextOverflow.ellipsis,')
    content = content.replace('Text(item["name"],', 'Text(item["name"], maxLines: 1, overflow: TextOverflow.ellipsis,')
    
    # 4. Text(title,
    content = content.replace('Text(title, style: const TextStyle(color: Colors.white70', 'Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70')
    content = content.replace('Text(\n                            title,', 'Text(\n                            title, maxLines: 1, overflow: TextOverflow.ellipsis,')
    content = content.replace('Text(title, style: const TextStyle(color: Colors.white)', 'Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
