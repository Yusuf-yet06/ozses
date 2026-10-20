import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_analysis_service.dart';

/// 🚪 SİBER ARKA KAPI: n8n & Dış Entegrasyon Köprüsü
/// Arka planda FFT ses analiz verilerini ve oynatıcı durumunu
/// n8n webhook veya özel otomasyon sistemlerine bağlamak için tasarlanmıştır.
class SiberN8nBridge {
  static final SiberN8nBridge instance = SiberN8nBridge._internal();
  SiberN8nBridge._internal();

  static const String _prefWebhookUrl = 'siber_n8n_webhook_url';
  static const String _prefEnabled = 'siber_n8n_enabled';
  static const String _prefAutoDispatch = 'siber_n8n_auto_dispatch';

  String _webhookUrl = '';
  bool _isEnabled = false;
  bool _autoDispatch = false; // Her analiz karesinde mi yoksa şarkı değişimlerinde mi?

  // 📡 Dışarıya açık canlı veri akışı (Kuzen veya harici servisler abone olabilir)
  final StreamController<Map<String, dynamic>> _backdoorController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get backdoorStream => _backdoorController.stream;

  // 🔌 Özel harici işleyici fonksiyonu (Custom Callback Backdoor)
  Future<void> Function(Map<String, dynamic> data)? _customHandler;

  bool get isEnabled => _isEnabled;
  String get webhookUrl => _webhookUrl;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _webhookUrl = prefs.getString(_prefWebhookUrl) ?? '';
      _isEnabled = prefs.getBool(_prefEnabled) ?? false;
      _autoDispatch = prefs.getBool(_prefAutoDispatch) ?? false;
      print('🚪 [SİBER ARKA KAPI] n8n Köprüsü Hazır (Aktif: $_isEnabled, Hedef: ${_webhookUrl.isEmpty ? "Tanımsız" : _webhookUrl})');
    } catch (e) {
      print('⚠️ [SİBER ARKA KAPI] Başlatma Hatası: $e');
    }
  }

  /// Webhook adresini güncelle (n8n URL'si)
  Future<void> setWebhookUrl(String url) async {
    _webhookUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefWebhookUrl, _webhookUrl);
    print('🚪 [SİBER ARKA KAPI] Webhook adresi mühürlendi: $_webhookUrl');
  }

  /// Köprüyü aktif veya pasif yap
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, enabled);
    print('🚪 [SİBER ARKA KAPI] Köprü Durumu: ${_isEnabled ? "AÇIK" : "KAPALI"}');
  }

  /// Otomatik analiz verisi postalama modunu aç/kapat
  Future<void> setAutoDispatch(bool autoDispatch) async {
    _autoDispatch = autoDispatch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAutoDispatch, autoDispatch);
  }

  /// Kuzenin özel kodla doğrudan araya girmesi için callback arka kapısı
  void registerCustomHandler(Future<void> Function(Map<String, dynamic> data) handler) {
    _customHandler = handler;
    print('🚪 [SİBER ARKA KAPI] Özel kuzen işleyicisi (Custom Handler) bağlandı!');
  }

  /// 🎯 Veriyi Arka Kapıya Fırlat (n8n Webhook + Stream + Custom Handler)
  Future<bool> dispatch({
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now();
    final Map<String, dynamic> fullData = {
      'ozses_event': event,
      'timestamp': now.millisecondsSinceEpoch,
      'iso_time': now.toIso8601String(),
      'platform': kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : (Platform.isWindows ? 'windows' : 'other')),
      'data': payload,
    };

    // 1. Canlı Stream'e bas (Uygulama içi dinleyenler için)
    if (!_backdoorController.isClosed) {
      _backdoorController.add(fullData);
    }

    // 2. Özel callback varsa doğrudan tetikle
    if (_customHandler != null) {
      try {
        await _customHandler!(fullData);
      } catch (err) {
        print('⚠️ [SİBER ARKA KAPI] Custom Handler Hatası: $err');
      }
    }

    // 3. n8n Webhook URL tanımlı ve aktifse HTTP POST ile fırlat
    if (_isEnabled && _webhookUrl.isNotEmpty) {
      return _sendToN8n(fullData);
    }

    return true;
  }

  /// Ses analizi karesini arka kapıya fırlat
  Future<void> dispatchAudioAnalysis(AudioAnalysisData analysis, {String? songTitle, String? artist}) async {
    // Performans için sadece aktifse veya stream dinleniyorsa paket oluştur
    if (!_isEnabled && !_backdoorController.hasListener && _customHandler == null) return;

    final payload = {
      'song_title': songTitle ?? 'Bilinmeyen Parça',
      'artist': artist ?? 'Bilinmeyen Sanatçı',
      'neon_scale': analysis.neonScale,
      'dominant_hz': analysis.dominantHz,
      'bass_level': analysis.bassLevel,
      'mid_level': analysis.midLevel,
      'treble_level': analysis.trebleLevel,
      'wave_type': analysis.waveType,
      'spectrum_bands': analysis.spectrumBands,
      'energy_rms': analysis.energyRms,
    };

    await dispatch(event: 'audio_analysis', payload: payload);
  }

  /// n8n Webhook'una asenkron HTTP POST gönder (Ağ koruması için pasifleştirildi)
  Future<bool> _sendToN8n(Map<String, dynamic> body) async {
    // 🛡️ SİBER KORUMA: Ağ bant daralmasını önlemek için n8n arka plan ağ istekleri tamamen kapatıldı.
    return true;
  }

  /// Manuel test sinyali gönder (Kuzen bağlantıyı denerken kullanır)
  Future<bool> sendPing({String note = 'Manuel Test Sinyali'}) async {
    return await dispatch(
      event: 'backdoor_ping',
      payload: {
        'status': 'aktif',
        'message': note,
        'ozses_version': 'V7_IMPERIUM',
      },
    );
  }

  void dispose() {
    _backdoorController.close();
  }
}
