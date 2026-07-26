import re
import os

filepath = r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\screens\home_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Replace _showTimerDialog with _showSiberSleepBottomSheet
old_timer = """  void _showTimerDialog(BuildContext context, Color themeColor) {
    final TextEditingController tc = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: themeColor.withValues(alpha: 0.5)),
        ),
        title: Text('UYKU ZAMANLAYICI',
            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _timerOption(context, '15 Dakika', 15, themeColor),
              _timerOption(context, '30 Dakika', 30, themeColor),
              _timerOption(context, '60 Dakika', 60, themeColor),
              const Divider(color: Colors.white24),
              TextField(
                controller: tc,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Manuel dakika girin...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: themeColor.withValues(alpha: 0.5))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: themeColor)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.play_circle_fill, color: themeColor),
                    onPressed: () {
                      final int? minutes = int.tryParse(tc.text);
                      if (minutes != null && minutes > 0) {
                        startSleepTimer(minutes);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Sistem $minutes dakika sonra mühürlenecek.'),
                              backgroundColor: themeColor),
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _timerOption(context, 'İptal Et', 0, themeColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timerOption(
      BuildContext context, String title, int minutes, Color themeColor) {
    return ListTile(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
      onTap: () {
        startSleepTimer(minutes);
        if (minutes > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Sistem $minutes dakika sonra mühürlenecek.'),
                backgroundColor: themeColor),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Zamanlayıcı iptal edildi.'),
                backgroundColor: Colors.redAccent),
          );
        }
        Navigator.pop(context);
      },
    );
  }"""

new_sleep_sheet = """  // 🎯 SİBER HAMLE: Gelişmiş Uyku Zamanlayıcı (Müzik Çalardaki Gibi Premium Bottom Sheet)
  void _showSiberSleepBottomSheet(Color themeColor) {
    final TextEditingController tc = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(top: BorderSide(color: themeColor.withValues(alpha: 0.5), width: 2)),
              boxShadow: [
                BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.nights_stay_rounded, color: themeColor, size: 28),
                        const SizedBox(width: 10),
                        Text('SİBER UYKU MODU',
                            style: TextStyle(
                                color: themeColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildSleepCard(context, '15 Dakika', 'Hafif kestirme', 15, themeColor),
                          const SizedBox(height: 10),
                          _buildSleepCard(context, '30 Dakika', 'Standart uyku', 30, themeColor),
                          const SizedBox(height: 10),
                          _buildSleepCard(context, '60 Dakika', 'Derin uyku döngüsü', 60, themeColor),
                          const SizedBox(height: 10),
                          _buildSleepCard(context, 'Uyku Modunu İptal Et', 'Zamanlayıcıyı durdurur', 0, Colors.redAccent),
                          
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(color: Colors.white24),
                          ),
                          
                          // Manuel Giriş
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer_rounded, color: themeColor),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: tc,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: 'Manuel dakika gir...',
                                      hintStyle: TextStyle(color: Colors.white38),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.play_arrow_rounded, color: themeColor, size: 30),
                                  onPressed: () {
                                    final int? minutes = int.tryParse(tc.text);
                                    if (minutes != null && minutes > 0) {
                                      startSleepTimer(minutes);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Sistem $minutes dakika sonra kapanacak.'), backgroundColor: themeColor),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSleepCard(BuildContext context, String title, String subtitle, int minutes, Color color) {
    return InkWell(
      onTap: () {
        startSleepTimer(minutes);
        if (minutes > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sistem $minutes dakika sonra kapanacak.'), backgroundColor: color),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Zamanlayıcı iptal edildi.'), backgroundColor: Colors.redAccent),
          );
        }
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(minutes == 0 ? Icons.alarm_off_rounded : Icons.access_time_rounded, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24)
          ],
        ),
      ),
    );
  }"""

start_idx = content.find("  void _showTimerDialog(BuildContext context, Color themeColor) {")
if start_idx != -1:
    end_idx = content.find("  void _showCreateDialog(BuildContext context, Color themeColor) {", start_idx)
    content = content[:start_idx] + new_sleep_sheet + "\n\n" + content[end_idx:]
    print("Replaced _showTimerDialog successfully.")
else:
    print("Could not find _showTimerDialog")

# 2. Redesign _buildSiberPanel
old_siber_panel = """  Widget _buildSiberPanel(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5), // Buzul Cam Etkisi
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: themeColor,
                collapsedIconColor: Colors.white70,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: Icon(Icons.settings, color: themeColor, size: 20),
                ),
                title: const Text(
                  'ARAÇLAR VE AYARLAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Column(
                      children: [
                        _buildNeonButton(
                          icon: Icons.waves,
                          label: 'DİNLEME MODU',
                          themeColor: themeColor,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ListeningModeScreen(),
                              ),
                            );
                          },
                        ),

                        _buildNeonButton(
                          icon: Icons.folder_special,
                          label: 'CİHAZDAN MÜZİK EKLE',
                          themeColor: themeColor,
                          onPressed: _scanFolderForMusic,
                        ),
                        // 🎯 SİBER HAMLE: Otonom Yapay Zeka Butonu
                        _buildNeonButton(
                          icon: Icons.auto_fix_high,
                          label: 'YAPAY ZEKA LİSTELERİ YAP',
                          themeColor: Colors.amber, // Zeka olduğunu belli eden altın renk
                          onPressed: () => _generateAIPlaylists(themeColor),
                        ),
                        _buildNeonButton(
                          icon: Icons.timer_outlined,
                          label: 'UYKU ZAMANLAYICI',
                          themeColor: themeColor,
                          onPressed: () =>
                              _showTimerDialog(context, themeColor),
                        ),


                        _buildNeonButton(
                          icon: Icons.graphic_eq_rounded,
                          label: 'SİBER SES STÜDYOSU',
                          themeColor: themeColor,
                          onPressed: () => _showCyberStudioBottomSheet(themeColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }"""

new_siber_panel = """  Widget _buildSiberPanel(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5), // Buzul Cam Etkisi
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: themeColor,
                collapsedIconColor: Colors.white70,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: Icon(Icons.settings_suggest_rounded, color: themeColor, size: 20),
                ),
                title: const Text(
                  'ARAÇLAR VE SİSTEM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Column(
                      children: [
                        _buildNeonButton(
                          icon: Icons.auto_fix_high_rounded,
                          label: 'YAPAY ZEKA LİSTELERİ YAP',
                          themeColor: Colors.amber, // Zeka
                          onPressed: () => _generateAIPlaylists(themeColor),
                        ),
                        _buildNeonButton(
                          icon: Icons.folder_special_rounded,
                          label: 'CİHAZDAN MÜZİK EKLE',
                          themeColor: themeColor,
                          onPressed: _scanFolderForMusic,
                        ),
                        _buildNeonButton(
                          icon: Icons.nights_stay_rounded,
                          label: 'UYKU MODU (SİBER ZAMANLAYICI)',
                          themeColor: Colors.indigoAccent,
                          onPressed: () => _showSiberSleepBottomSheet(themeColor),
                        ),
                        _buildNeonButton(
                          icon: Icons.palette_rounded,
                          label: 'SİBER TEMA MERKEZİ',
                          themeColor: Colors.pinkAccent,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tema Merkezi yakında aktifleşecek!')));
                          },
                        ),
                        _buildNeonButton(
                          icon: Icons.backup_rounded,
                          label: 'ARŞİV YEDEKLEME',
                          themeColor: Colors.lightBlueAccent,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arşiv Yedekleme ve Dışa Aktarma modülü başlatılıyor...')));
                          },
                        ),
                        _buildNeonButton(
                          icon: Icons.graphic_eq_rounded,
                          label: 'SİBER SES STÜDYOSU',
                          themeColor: Colors.cyanAccent,
                          onPressed: () => _showCyberStudioBottomSheet(themeColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }"""

start_idx = content.find("  Widget _buildSiberPanel(Color themeColor) {")
if start_idx != -1:
    end_idx = content.find("  // 🎯 SİBER HAMLE: Playlist Oluşturma Tipi Seçim Ekranı", start_idx)
    content = content[:start_idx] + new_siber_panel + "\n\n" + content[end_idx:]
    print("Replaced _buildSiberPanel successfully.")
else:
    print("Could not find _buildSiberPanel")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done patching Drawer.")
