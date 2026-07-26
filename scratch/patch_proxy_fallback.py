import re

def patch_proxy_fallback():
    file_path = r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\services\services.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # The goal is to replace the streamRequest sending logic
    old_logic = '''          var streamResponse = await client.send(streamRequest);
          dataStream = streamResponse.stream;

          request.response.statusCode = streamResponse.statusCode;
          streamResponse.headers.forEach((key, value) {
            if (key.toLowerCase() != 'transfer-encoding') {
              request.response.headers.set(key, value);
            }
          });
          
          if (streamResponse.statusCode != 200 && streamResponse.statusCode != 206) {
            print('❌ HATA: Hedef sunucu ${streamResponse.statusCode} döndürdü. Yönlendirme iptal ediliyor.');
            try { await request.response.close(); } catch (_) {}
            return;
          }'''
          
    new_logic = '''          var streamResponse = await client.send(streamRequest);
          
          if (streamResponse.statusCode == 403 || streamResponse.statusCode == 400 || streamResponse.statusCode == 429) {
            print('⚠️ SİBER KALKAN: YouTube ($finalStreamUrl) ${streamResponse.statusCode} verdi! YEREL SİBER SUNUCUMUZA (RENDER) GEÇİLİYOR...');
            try {
              var renderUrl = Uri.parse('https://ozses.onrender.com/stream?id=$videoId');
              var renderRequest = http.Request('GET', renderUrl);
              streamResponse = await client.send(renderRequest).timeout(const Duration(seconds: 50));
            } catch (e) {
              print('⚠️ Render Sunucusu da yanıt vermedi: $e');
            }
          }

          dataStream = streamResponse.stream;

          request.response.statusCode = streamResponse.statusCode;
          streamResponse.headers.forEach((key, value) {
            if (key.toLowerCase() != 'transfer-encoding') {
              request.response.headers.set(key, value);
            }
          });
          
          if (streamResponse.statusCode != 200 && streamResponse.statusCode != 206) {
            print('❌ HATA: Hedef sunucu ${streamResponse.statusCode} döndürdü. Yönlendirme iptal ediliyor.');
            try { await request.response.close(); } catch (_) {}
            return;
          }'''

    if old_logic in content:
        content = content.replace(old_logic, new_logic)
        print("Patched successfully!")
    else:
        print("Could not find the target codeblock!")
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    patch_proxy_fallback()
