import re

path = r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\services\services.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add Accept-Ranges header
old_code = """             request.response.headers.contentType = ContentType('audio', 'mp4');
             if (ytStreamInfo.size.totalBytes > 0) {
               request.response.contentLength = ytStreamInfo.size.totalBytes;
             }
             var rangeHeader = request.headers.value('range');
             if (rangeHeader != null && rangeHeader.startsWith('bytes=0-')) {"""

new_code = """             request.response.headers.contentType = ContentType('audio', 'mp4');
             request.response.headers.add('Accept-Ranges', 'bytes');
             if (ytStreamInfo.size.totalBytes > 0) {
               request.response.contentLength = ytStreamInfo.size.totalBytes;
             }
             var rangeHeader = request.headers.value('range');
             if (rangeHeader != null && rangeHeader.startsWith('bytes=0-')) {"""

content = content.replace(old_code, new_code)
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Accept-Ranges header added!")
