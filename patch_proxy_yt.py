import re

path = r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\services\services.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# We need to replace the entire try block inside the proxy
old_block_pattern = r"var client = http\.Client\(\);.*?if \(streamResponse\.statusCode == 200\) \{"
new_block = """          var ytStream = yt.videos.streamsClient.get(streamInfo);
          
          request.response.headers.contentType = ContentType('audio', 'mp4');
          if (streamInfo.size.totalBytes > 0) {
            request.response.contentLength = streamInfo.size.totalBytes;
          }
          
          var rangeHeader = request.headers.value('range');
          if (rangeHeader != null && rangeHeader.startsWith('bytes=0-')) {
            request.response.statusCode = HttpStatus.partialContent;
            request.response.headers.add('Content-Range', 'bytes 0-${streamInfo.size.totalBytes - 1}/${streamInfo.size.totalBytes}');
          } else {
            request.response.statusCode = HttpStatus.ok;
          }
          
          // 🚀 ÇİFT ÇEKİRDEK (Dual-Core): Depoya kaydet
          IOSink? fileSink;
          if (true) {"""

# Let's do a more precise replacement by finding the block
start_index = content.find('var reqHeaders = <String, String>{')
end_index = content.find('if (streamResponse.statusCode == 200) {')

if start_index != -1 and end_index != -1:
    old_code = content[start_index:end_index + len('if (streamResponse.statusCode == 200) {')]
    content = content.replace(old_code, new_block)
    
    # Also replace streamResponse.stream.listen with ytStream.listen
    content = content.replace('streamResponse.stream.listen((data) {', 'ytStream.listen((data) {')
    
    # And remove client.close()
    content = content.replace('client.close();', '')

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Proxy patched to use YoutubeExplode streamsClient directly!")
else:
    print("Could not find the target block to replace.")
