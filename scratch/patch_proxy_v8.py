import re
import sys

def patch_services():
    file_path = r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\services\services.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove Render ping delay completely. Just use YoutubeExplode as the primary source!
    render_block_pattern = r'''\s*try\s*\{\s*print\('🚀 İlk Hedef: Kendi Sunucumuz \(Render Backend\) kontrol ediliyor\.\.\.'\);.*?\} catch \(e\) \{\s*print\('⚠️ Render Sunucusu Yanıt Vermedi veya Hatalı: \$e'\);\s*try\s*\{'''
    
    # We will replace the whole render ping block with just the YoutubeExplode block
    new_yt_block = '''        try {
            print('🎯 Proxy: YoutubeExplode (Yerel Motor) Devrede...');
            try {'''
    
    content = re.sub(render_block_pattern, new_yt_block, content, flags=re.DOTALL)
    
    # 2. Add User-Agent to the proxy streamRequest
    client_pattern = r'''var client = http\.Client\(\);\s*var streamRequest = http\.Request\('GET', finalStreamUrl!\);'''
    new_client = '''var client = http.Client();
          var streamRequest = http.Request('GET', finalStreamUrl!);
          // 🚀 SİBER HAMLE: 403 Hatalarını Aşmak İçin Gerçek Tarayıcı Kılığına Giriyoruz!
          streamRequest.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';
          streamRequest.headers['Accept'] = '*/*';
          streamRequest.headers['Connection'] = 'keep-alive';'''
          
    content = content.replace(
        "var client = http.Client();\n          var streamRequest = http.Request('GET', finalStreamUrl!);", 
        new_client
    )
    
    # 3. Remove the final render fallback
    final_render_pattern = r'''if \(finalStreamUrl == null\) \{\s*print\('⚠️ Cobalt başarısız! KENDİ SİBER KARARGAHIMIZ \(RENDER BACKEND\) DEVREDE\.\.\.'\);\s*try \{\s*// Kendi Render sunucumuz\s*final renderUrl = Uri\.parse\('https://ozses\.onrender\.com/stream\?id=\$videoId'\);\s*// Sadece HEAD.*?finalStreamUrl = renderUrl;\s*print\('✅ Kendi Sunucumuz \(Render\) Fallback Başarılı: \$finalStreamUrl'\);\s*\} catch \(e\) \{\s*print\('⚠️ Kendi Sunucumuz Hatası: \$e'\);\s*\}\s*\}'''
    content = re.sub(final_render_pattern, "", content, flags=re.DOTALL)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Patch applied to services.dart")

if __name__ == '__main__':
    patch_services()
