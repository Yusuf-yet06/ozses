/// 🎯 ÖZSES V7 - Akıllı Türkçe ve Global Arama Motoru Yardımcısı
/// Bu sınıf; büyük/küçük harf, Türkçe karakterler (i-ı, u-ü, o-ö, s-ş, c-ç, g-ğ)
/// ve kelime sırası bağımsız toleranslı arama mantığını sağlar.
class SearchUtils {
  /// Türkçe karakterleri koruyarak doğru küçük harfe dönüştürür.
  /// Standart Dart .toLowerCase() 'I' harfini 'i' yaptığı için
  /// Türkçede 'IŞIK' -> 'işik' gibi hatalar oluşur. Bu fonksiyon bunu önler.
  static String toTurkishLower(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ç', 'ç')
        .replaceAll('Ğ', 'ğ')
        .toLowerCase();
  }

  /// Karakter toleranslı normalizasyon:
  /// (i-ı, u-ü, o-ö, s-ş, c-ç, g-ğ) ve tüm aksanları standart latin harfine eşitler.
  /// Hem büyük harf hem küçük harf hem de farklı klavye tiplerini %100 tolere eder.
  static String normalizeForSearch(String text) {
    if (text.isEmpty) return '';
    String s = text;

    // 1. Türkçe ve aksanlı karakterleri standart kök harflere eşitle
    s = s
        // i - ı eşitlemesi
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('î', 'i')
        .replaceAll('Î', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('í', 'i')
        // u - ü eşitlemesi
        .replaceAll('Ü', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('Û', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ú', 'u')
        // o - ö eşitlemesi
        .replaceAll('Ö', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('Ô', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ó', 'o')
        // s - ş eşitlemesi
        .replaceAll('Ş', 's')
        .replaceAll('ş', 's')
        // c - ç eşitlemesi
        .replaceAll('Ç', 'c')
        .replaceAll('ç', 'c')
        // g - ğ eşitlemesi
        .replaceAll('Ğ', 'g')
        .replaceAll('ğ', 'g')
        // a - â eşitlemesi
        .replaceAll('Â', 'a')
        .replaceAll('â', 'a')
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        // e - ê eşitlemesi
        .replaceAll('Ê', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e');

    // 2. Kalan karakterleri küçük harfe çevir
    s = s.toLowerCase();

    // 3. Noktalama işaretlerini ve özel karakterleri boşluğa çevir
    s = s.replaceAll(RegExp(r'[()\[\]{}\-_,.\?!"\x27:;/\\]'), ' ');

    // 4. Fazla boşlukları temizle
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  /// Bir şarkının başlık, sanatçı, isim veya dosya yolunda
  /// aranan sorgunun toleranslı olarak eşleşip eşleşmediğini kontrol eder.
  static bool matchesSong({
    required String query,
    String? title,
    String? artist,
    String? name,
    String? path,
  }) {
    final cleanQ = normalizeForSearch(query);
    if (cleanQ.isEmpty) return true;

    // Hedef alanları bir araya getir
    final fileName = (path != null && path.isNotEmpty)
        ? path.split('/').last.split('\\').last
        : '';
    final combinedTargets = [
      title ?? '',
      artist ?? '',
      name ?? '',
      fileName,
    ].join(' ');

    final cleanTarget = normalizeForSearch(combinedTargets);

    // 1. Doğrudan alt dize eşleşmesi
    if (cleanTarget.contains(cleanQ)) return true;

    // 2. Boşluksuz kompakt eşleşme (Örn: "Gülpembe" <-> "Gül pembe")
    final compactTarget = cleanTarget.replaceAll(' ', '');
    final compactQuery = cleanQ.replaceAll(' ', '');
    if (compactTarget.contains(compactQuery)) return true;

    // 3. Kelime bazlı bağımsız sıra eşleşmesi
    // Kullanıcı "sezen vazgectim" veya "vazgectim sezen" yazsa da bulur
    final qWords = cleanQ.split(' ').where((w) => w.isNotEmpty).toList();
    if (qWords.isNotEmpty && qWords.every((word) => cleanTarget.contains(word))) {
      return true;
    }

    // 4. Kısmi kelime / Ön ek eşleşmesi (Örn: "musl gurs" -> "Müslüm Gürses")
    if (qWords.length > 1) {
      final targetWords = cleanTarget.split(' ').where((w) => w.isNotEmpty).toList();
      final allWordsMatch = qWords.every((qw) {
        return targetWords.any((tw) => tw.startsWith(qw) || tw.contains(qw));
      });
      if (allWordsMatch) return true;
    }

    return false;
  }

  /// Genel metin eşleştirici (Çalma listeleri, kategoriler vb.)
  static bool matchesText(String target, String query) {
    final cleanQ = normalizeForSearch(query);
    if (cleanQ.isEmpty) return true;

    final cleanT = normalizeForSearch(target);
    if (cleanT.contains(cleanQ)) return true;

    final compactT = cleanT.replaceAll(' ', '');
    final compactQ = cleanQ.replaceAll(' ', '');
    if (compactT.contains(compactQ)) return true;

    final qWords = cleanQ.split(' ').where((w) => w.isNotEmpty).toList();
    if (qWords.isNotEmpty && qWords.every((w) => cleanT.contains(w))) {
      return true;
    }

    return false;
  }

  /// Online arama (Keşfet / Spotify / YouTube) için
  /// toleranslı sorgu varyasyonları üretir.
  static List<String> prepareSearchVariants(String rawQuery) {
    if (rawQuery.trim().isEmpty) return [];

    final variants = <String>[];
    final trimmed = rawQuery.trim();
    variants.add(trimmed);

    // 1. Düzgün Türkçe küçük harfli hali (I -> ı, İ -> i)
    final trLower = toTurkishLower(trimmed);
    if (!variants.contains(trLower) && trLower.isNotEmpty) {
      variants.add(trLower);
    }

    // 2. Tamamen Latinize / normalize edilmiş hali (isik, manco, gul vb.)
    final normalized = normalizeForSearch(trimmed);
    if (!variants.contains(normalized) && normalized.isNotEmpty) {
      variants.add(normalized);
    }

    return variants;
  }
}
