import re

path = r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\core\platform\mobile_platform.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace Future.any with firstSuccessful
content = content.replace('final bestItems = await Future.any(futures);', 'final bestItems = await firstSuccessful(futures);')
content = content.replace('return await Future.any(futures);', 'return await firstSuccessful(futures);')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("mobile_platform.dart patched successfully!")
