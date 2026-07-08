import os

file_path = "lib/services/audio_handler.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Let's cleanly replace the play() function inside SiberAudioHandler from line 319 (try block)
# to just before catch (e)

import re

# Find the start of the play logic
start_marker = "    try {\n      String resolvedUrl = item.id;\n"
if start_marker not in content:
    print("Could not find start marker")
    exit(1)

start_idx = content.find(start_marker)

# Find catch block
end_marker = "    } catch (e) {"
end_idx = content.find(end_marker, start_idx)

if end_idx == -1:
    print("Could not find end marker")
    exit(1)

replacement = """    try {
      String resolvedUrl = item.id;

      // 🎯 SİBER OPERASYON: DİNAMİK AKIŞ ÇÖZÜCÜ
      if (item.id.startsWith('yt:')) {
        print("▶️ Siber Mühür Yakalandı: 'yt:' ID'li akış çözülüyor...");
        final videoId = item.id.substring(3);
        final bridge = OzsesBridge();
        final res = await bridge.getStreamUrl(videoId);

        if (_currentIndex != index) {
          print("⏭️ Hız: Kullanıcı başka şarkıya atladı, eski akış çözme işlemi iptal edildi.");
          return;
        }

        if (res['status'] == 'basarili' && res['stream_url'] != null) {
          resolvedUrl = res['stream_url'];
        } else {
          print("❌ Hata: Akış çözülemedi, kuyruktaki sıradaki şarkıya geçiliyor...");
          skipToNext();
          return;
        }
      }

      if (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://')) {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(resolvedUrl))).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException("Akış yüklenemedi veya dosya bağlantısı koptu.");
          },
        );
      } else {
        await _player.setAudioSource(AudioSource.file(resolvedUrl)).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Yerel dosya yüklenemedi: $resolvedUrl');
          },
        );
      }

      // 🎯 SİBER HAFIZA SIFIRLAMA
      _lastBass = -1.0;
      _lastTreble = -1.0;
      _lastVocal = -1.0;
      _lastTempo = -1.0;
      _lastVolume = -1.0;

      applySiberDSP();

      await _player.play();
"""

new_content = content[:start_idx] + replacement + content[end_idx:]

# Additionally, let's remove SiberStreamSource entirely since it is no longer used.
source_class_marker = "class SiberStreamSource extends StreamAudioSource {"
if source_class_marker in new_content:
    s_idx = new_content.find(source_class_marker)
    new_content = new_content[:s_idx].strip() + "\n"

with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_content)

print("Patch applied successfully.")
