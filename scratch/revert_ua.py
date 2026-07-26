import re

def revert_ua():
    file_path = r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\services\services.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Revert the User-Agent we added
    old_block = '''          var client = http.Client();
          var streamRequest = http.Request('GET', finalStreamUrl!);
          // 🚀 SİBER HAMLE: 403 Hatalarını Aşmak İçin Gerçek Tarayıcı Kılığına Giriyoruz!
          streamRequest.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';
          streamRequest.headers['Accept'] = '*/*';
          streamRequest.headers['Connection'] = 'keep-alive';'''
          
    new_block = '''          var client = http.Client();
          var streamRequest = http.Request('GET', finalStreamUrl!);'''
          
    content = content.replace(old_block, new_block)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Reverted User-Agent in services.dart")

if __name__ == '__main__':
    revert_ua()
