import 'dart:io';
import 'dart:math';

class RadarFilter {
  static const List<String> _allowedExtensions = [
    '.mp3',
    '.wav',
    '.flac',
    '.m4a',
    '.aac'
  ];

  static bool isMusicFile(FileSystemEntity file) {
    if (file is! File) return false;
    final String path = file.path.toLowerCase();

    // Uzantı Kontrolü
    bool hasValidExtension =
        _allowedExtensions.any((ext) => path.endsWith(ext));
    if (!hasValidExtension) return false;

    // Boyut Kontrolü (100KB altı ses kayıtlarını eler)
    try {
      final int fileSize = file.lengthSync();
      return fileSize > (100 * 1024);
    } catch (e) {
      return false;
    }
  }
}

/// ⚡ SİBER C++ MİMARİLİ HAFİF AKIŞ & SHORTS FİLTRE MOTORU
/// Ekstra arka plan uyanıklığı (wake-lock) harcamadan, YouTube ve Spotify'dan
/// halihazırda çekilen verilerin arasına değişkenlik (jitter) katarak süzgeç uygular.
/// 75 saniye altı Shorts/Reels/Teaser/Kesit içerikleri O(N) karakter taramasıyla eler.
class SiberStreamFilterEngine {
  static const int minFullTrackSeconds = 75;
  static final Random _rng = Random();

  static const List<String> _shortMarkers = [
    '#shorts',
    '#short',
    'shorts',
    'teaser',
    'snippet',
    'önizleme',
    'onizleme',
    'tanıtım',
    'tanitim',
    'fragman',
    'kesit',
    'reels',
    '#reels',
    '#tiktok',
    'tiktok viral kesit',
    '30 saniye',
    'durum videosu',
    'whatsapp durum',
  ];

  static const List<String> _variableArtistSearchModifiers = [
    'şarkıları',
    'en yeni şarkıları',
    'popüler parçalar',
    'hit şarkılar',
    'orijinal klip ve şarkılar',
    'albüm kayıtları',
    'en çok dinlenenler',
  ];

  static const List<String> _variableAlbumModifiers = [
    'full albüm',
    'resmi albüm',
    'yeni albüm',
    'albüm şarkıları',
  ];

  /// Her istekte sabit kalıp yerine organik değişkenlik gösteren sorgu üretir.
  static String buildVariableArtistQuery(String artist, {bool forRefresh = false}) {
    final clean = artist.trim();
    if (!forRefresh) return '$clean şarkıları';
    final mod = _variableArtistSearchModifiers[
        _rng.nextInt(_variableArtistSearchModifiers.length)];
    return '$clean $mod';
  }

  static String buildVariableAlbumQuery(String artist) {
    final clean = artist.trim();
    final mod =
        _variableAlbumModifiers[_rng.nextInt(_variableAlbumModifiers.length)];
    return '$clean $mod';
  }

  /// Süre verisini ("3:45", 210, "0:55" vb.) saniyeye çevirir.
  /// Bilinmiyorsa -1 döner.
  static int parseDurationSeconds(dynamic rawDuration) {
    if (rawDuration == null) return -1;
    if (rawDuration is int) return rawDuration;
    if (rawDuration is double) return rawDuration.round();
    if (rawDuration is Duration) return rawDuration.inSeconds;

    final str = rawDuration.toString().trim();
    if (str.isEmpty) return -1;

    // Sadece sayıysa
    final asInt = int.tryParse(str);
    if (asInt != null) return asInt;

    // "MM:SS" veya "HH:MM:SS" formatı
    if (str.contains(':')) {
      final parts = str.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0].trim()) ?? 0;
        final s = int.tryParse(parts[1].trim()) ?? 0;
        return (m * 60) + s;
      } else if (parts.length == 3) {
        final h = int.tryParse(parts[0].trim()) ?? 0;
        final m = int.tryParse(parts[1].trim()) ?? 0;
        final s = int.tryParse(parts[2].trim()) ?? 0;
        return (h * 3600) + (m * 60) + s;
      }
    }
    return -1;
  }

  /// Başlık ve süre üzerinden Shorts / Teaser / Kesit olup olmadığını denetler.
  static bool isShortOrTeaserTrack(dynamic trackMap, {bool strictDuration = false}) {
    if (trackMap is! Map) return true;

    final title = (trackMap['title'] ?? trackMap['baslik'] ?? '')
        .toString()
        .toLowerCase();
    if (title.isEmpty) return true;

    for (final marker in _shortMarkers) {
      if (title.contains(marker)) return true;
    }

    final sec = parseDurationSeconds(trackMap['duration']);
    if (sec > 0 && sec < minFullTrackSeconds) {
      return true;
    }
    if (strictDuration && sec <= 0) {
      return true;
    }

    return false;
  }

  /// Türkçe karakter toleranslı hızlı metin normalizasyonu
  static String normalizeTr(String input) {
    final sb = StringBuffer();
    final lower = input.toLowerCase();
    for (int i = 0; i < lower.length; i++) {
      final ch = lower[i];
      switch (ch) {
        case 'ı':
          sb.write('i');
          break;
        case 'ğ':
          sb.write('g');
          break;
        case 'ü':
          sb.write('u');
          break;
        case 'ş':
          sb.write('s');
          break;
        case 'ö':
          sb.write('o');
          break;
        case 'ç':
          sb.write('c');
          break;
        default:
          sb.write(ch);
      }
    }
    return sb.toString();
  }

  /// Gelen şarkı listesini Shorts/Teaser içeriklerden arındırır ve tekrarları temizler.
  static List<Map<String, dynamic>> filterValidSongs(
    List<dynamic> rawTracks, {
    String? requiredArtist,
  }) {
    final List<Map<String, dynamic>> out = [];
    final Set<String> seenIds = {};
    final String? normArtist =
        (requiredArtist != null && requiredArtist.trim().isNotEmpty)
            ? normalizeTr(requiredArtist.trim())
            : null;

    for (final raw in rawTracks) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);

      if (isShortOrTeaserTrack(map)) continue;

      final id = (map['videoId'] ?? map['id'] ?? map['video_id'])?.toString() ?? '';
      if (id.isEmpty || seenIds.contains(id)) continue;

      if (normArtist != null) {
        final nTitle = normalizeTr((map['title'] ?? map['baslik'] ?? '').toString());
        final nChan = normalizeTr((map['channel'] ?? map['kanal'] ?? '').toString());
        if (!nTitle.contains(normArtist) && !nChan.contains(normArtist)) {
          continue;
        }
      }

      seenIds.add(id);
      map['id'] = id;
      map['videoId'] = id;
      out.add(map);
    }

    return out;
  }
}
