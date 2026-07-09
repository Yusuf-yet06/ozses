import re

path = r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\screens\discover_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove the Snackbars
old_snackbar1 = """        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Siber Ağ: Yurt interneti çok yavaş veya koptu! Önbellekteki veriler gösteriliyor.'),
            backgroundColor: Colors.redAccent));"""

old_snackbar2 = """        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Siber İstihbarat: Özel öneriler çekilemedi, çevrimdışı moda geçildi.'),
            backgroundColor: Colors.redAccent));"""

content = content.replace(old_snackbar1, "")
content = content.replace(old_snackbar2, "")

# 2. Replace the big red offline banner with a Spotify-like subtle banner
old_banner = """          // 🎯 SİBER ÇEVRİMDIŞI BİLDİRİMİ
          if (_isOfflineMode)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bağlantı Yok! Siber Önbellek Verileri Gösteriliyor. İndirme veya oynatma yapılamayabilir.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),"""

new_banner = """          // 🎯 SİBER ÇEVRİMDIŞI BİLDİRİMİ (Spotify Tarzı Kusursuz Deneyim)
          if (_isOfflineMode)
            Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.symmetric(vertical: 4),
              width: double.infinity,
              color: Colors.black87,
              child: const Center(
                child: Text(
                  'Çevrimdışı Mod. İndirilenler gösteriliyor.',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),"""

content = content.replace(old_banner, new_banner)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("discover_screen.dart patched successfully for Spotify-like offline UI!")
