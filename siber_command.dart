/// 🎯 SİBER SİNİR HÜCRESİ (NÖRON)
/// Beynin içindeki tüm iletişim bu komut paketi üzerinden döner.
class SiberCommand {
  final String action; // Örn: 'play', 'bass_boost_on', 'analyze_text'
  final Map<String, dynamic>
      data; // Ekstra veriler (Örn: {'text': 'Müziği aç'})
  final String source; // Emrin geldiği yer: 'voice', 'ui', 'autonomous'
  final double confidence; // Emin olma seviyesi (YZ için)

  SiberCommand({
    required this.action,
    this.data = const {},
    this.source = 'system',
    this.confidence = 1.0,
  });

  @override
  String toString() =>
      'SiberCommand(action: $action, source: $source, confidence: $confidence)';
}
