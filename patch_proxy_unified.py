import re

path = r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\services\services.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace from `try { \n var yt = YoutubeExplode();` to `} catch (ytError) {`
start_idx = content.find("        try {\n          var yt = YoutubeExplode();")
if start_idx == -1:
    print("Could not find start index")
    exit(1)

# Find the end of the try block by looking for "        } catch (ytError) {"
end_idx = content.find("        } catch (ytError) {", start_idx)
if end_idx == -1:
    print("Could not find end index")
    exit(1)

old_code = content[start_idx:end_idx]

new_code = """        try {
          var yt = YoutubeExplode();
          Uri? finalStreamUrl;
          bool usedYoutubeExplode = false;
          dynamic ytStreamInfo;
          
          try {
            var manifest = await yt.videos.streamsClient.getManifest(videoId);
            var audioStreamList = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a')).toList();
            ytStreamInfo = audioStreamList.isNotEmpty ? audioStreamList.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b) : manifest.audioOnly.withHighestBitrate();
            finalStreamUrl = ytStreamInfo.url;
            usedYoutubeExplode = true;
          } catch (ytEx) {
            print('⚠️ YoutubeExplode Rate Limit: $ytEx');
            print('🔄 SİBER KALKAN: Piped Yedek (Fallback) Devrede...');
            
            final List<String> pipedInstances = [
              'https://api.piped.private.coffee',
              'https://pipedapi.kavin.rocks',
              'https://api.piped.privacydev.net',
              'https://piped-api.lunar.icu',
              'https://pipedapi.smnz.de'
            ];
            
            for (var instance in pipedInstances) {
              try {
                final response = await http.get(Uri.parse('$instance/streams/$videoId')).timeout(const Duration(seconds: 4));
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  if (data['audioStreams'] != null && (data['audioStreams'] as List).isNotEmpty) {
                    var audioStreams = data['audioStreams'] as List;
                    var bestStream = audioStreams.firstWhere(
                      (s) => s['format'] == 'M4A',
                      orElse: () => audioStreams.first,
                    );
                    finalStreamUrl = Uri.parse(bestStream['url'].toString());
                    print('✅ Piped Fallback Başarılı: $instance');
                    break;
                  }
                }
              } catch (_) {}
            }
          }
          
          if (finalStreamUrl == null) {
            throw Exception('Tüm akış motorları (YoutubeExplode + Piped) çöktü!');
          }
          
          Stream<List<int>> dataStream;
          
          if (usedYoutubeExplode) {
             dataStream = yt.videos.streamsClient.get(ytStreamInfo);
             request.response.headers.contentType = ContentType('audio', 'mp4');
             if (ytStreamInfo.size.totalBytes > 0) {
               request.response.contentLength = ytStreamInfo.size.totalBytes;
             }
             var rangeHeader = request.headers.value('range');
             if (rangeHeader != null && rangeHeader.startsWith('bytes=0-')) {
               request.response.statusCode = HttpStatus.partialContent;
               request.response.headers.add('Content-Range', 'bytes 0-${ytStreamInfo.size.totalBytes - 1}/${ytStreamInfo.size.totalBytes}');
             } else {
               request.response.statusCode = HttpStatus.ok;
             }
          } else {
             var client = http.Client();
             var streamRequest = http.Request('GET', finalStreamUrl);
             var streamResponse = await client.send(streamRequest);
             dataStream = streamResponse.stream;
             
             request.response.statusCode = streamResponse.statusCode;
             streamResponse.headers.forEach((key, value) {
               if (key.toLowerCase() != 'transfer-encoding') {
                 request.response.headers.set(key, value);
               }
             });
          }
          
          // 🚀 ÇİFT ÇEKİRDEK (Dual-Core): Depoya kaydet
          IOSink? fileSink;
          try {
             String storagePath = await StorageService.getOzsesDownloadPath();
             String permanentPath = '$storagePath/ozses_offline_$videoId.mp4';
             var file = File(permanentPath);
             fileSink = file.openWrite();
          } catch (_) {}
          
          dataStream.listen((data) {
             try { request.response.add(data); } catch (_) {}
             try { fileSink?.add(data); } catch (_) {}
          }, onDone: () async {
             try { await request.response.close(); } catch (_) {}
             try { await fileSink?.close(); } catch (_) {}
             yt.close();
             print('✅ Proxy Akışı (ve Kaydı) Tamamlandı: $videoId');
          }, onError: (e) {
             try { request.response.close(); } catch (_) {}
             try { fileSink?.close(); } catch (_) {}
             yt.close();
          });
"""

content = content.replace(old_code, new_code)
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Proxy structure unified!")
