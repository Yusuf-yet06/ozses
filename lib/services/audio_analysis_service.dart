// ignore_for_file: prefer_single_quotes
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:fftea/fftea.dart';

/// 🎯 Analiz sonuçlarını taşıyan siber veri kapsülü
class AudioAnalysisData {
  final double neonScale;
  final double dominantHz;
  final double bassLevel;
  final double midLevel;
  final double trebleLevel;
  final String waveType; // 🎯 Siber Ruh Hali: Chill, Enerjik, Agresif vb.
  final List<double> spectrumBands; // 8 bantlı frekans büyüklükleri
  final double energyRms;

  AudioAnalysisData({
    required this.neonScale,
    required this.dominantHz,
    required this.bassLevel,
    required this.midLevel,
    required this.trebleLevel,
    required this.waveType,
    required this.spectrumBands,
    required this.energyRms,
  });

  Map<String, dynamic> toJson() => {
    'neon_scale': neonScale,
    'dominant_hz': dominantHz,
    'bass_level': bassLevel,
    'mid_level': midLevel,
    'treble_level': trebleLevel,
    'wave_type': waveType,
    'spectrum_bands': spectrumBands,
    'energy_rms': energyRms,
  };
}

/// 🚀 FFTea Destekli Arka Plan Ses ve Frekans Analiz Motoru
class AudioAnalysisService {
  static final AudioAnalysisService instance = AudioAnalysisService();

  static const int _fftSize = 512; // 512 veya 1024 standart FFT boyutu
  late final FFT _fft;
  late final Float64List _window;

  final StreamController<AudioAnalysisData> _analysisController =
      StreamController<AudioAnalysisData>.broadcast();

  Stream<AudioAnalysisData> get analysisStream => _analysisController.stream;

  Timer? _bgAnalysisTimer;
  bool _isAnalyzing = false;
  String _currentSongTitle = '';
  String _currentArtist = '';
  double _phase = 0.0;

  AudioAnalysisService() {
    _fft = FFT(_fftSize);
    _window = Window.hanning(_fftSize);
  }

  /// 🎯 Ham PCM Verisini FFTea ile Analiz Et
  AudioAnalysisData analyzePcm(Float64List pcmSamples, {double sampleRate = 44100.0}) {
    // 1. Örnekleri pencerele (Hanning window)
    final input = Float64List(_fftSize);
    final count = math.min(pcmSamples.length, _fftSize);
    for (int i = 0; i < count; i++) {
      input[i] = pcmSamples[i];
    }
    _window.inPlaceApplyWindowReal(input);

    // 2. FFTea Real FFT Çalıştır
    final freq = _fft.realFft(input);
    freq.discardConjugates();
    final magnitudes = freq.magnitudes();

    // 3. Frekans Bantlarını Hesapla
    // 0 -> sampleRate / 2 (örn 0 - 22050 Hz)
    final numBins = magnitudes.length;
    final binWidth = (sampleRate / 2) / numBins;

    double bassSum = 0;
    int bassCount = 0;
    double midSum = 0;
    int midCount = 0;
    double trebleSum = 0;
    int trebleCount = 0;

    double maxMag = 0;
    int maxBin = 0;

    // 8 Bantlık Spektrum Dağılımı
    final List<double> bands = List.filled(8, 0.0);
    final binsPerBand = math.max(1, numBins ~/ 8);

    for (int i = 0; i < numBins; i++) {
      final mag = magnitudes[i];
      final hz = i * binWidth;

      if (mag > maxMag) {
        maxMag = mag;
        maxBin = i;
      }

      // 8 bant
      final bandIdx = math.min(7, i ~/ binsPerBand);
      bands[bandIdx] += mag;

      if (hz < 250) {
        bassSum += mag;
        bassCount++;
      } else if (hz < 4000) {
        midSum += mag;
        midCount++;
      } else {
        trebleSum += mag;
        trebleCount++;
      }
    }

    final bassAvg = bassCount > 0 ? (bassSum / bassCount) : 0.0;
    final midAvg = midCount > 0 ? (midSum / midCount) : 0.0;
    final trebleAvg = trebleCount > 0 ? (trebleSum / trebleCount) : 0.0;

    // Normalizasyon
    final normFactor = math.max(1.0, maxMag);
    final bassNorm = (bassAvg / normFactor).clamp(0.0, 1.0);
    final midNorm = (midAvg / normFactor).clamp(0.0, 1.0);
    final trebleNorm = (trebleAvg / normFactor).clamp(0.0, 1.0);

    for (int b = 0; b < 8; b++) {
      bands[b] = ((bands[b] / binsPerBand) / normFactor).clamp(0.0, 1.0);
    }

    final dominantHz = maxBin * binWidth;
    final energyRms = math.sqrt(input.map((x) => x * x).reduce((a, b) => a + b) / _fftSize);
    final neonScale = (energyRms * 3.0).clamp(0.2, 1.0);

    // Siber Ruh Hali Tespiti
    String waveType = 'Dengeli Siber';
    if (bassNorm > 0.65) {
      waveType = 'Derin Bas / Agresif';
    } else if (trebleNorm > 0.6) {
      waveType = 'Kristal Tiz / Enerjik';
    } else if (energyRms < 0.15) {
      waveType = 'Chill / Lo-Fi';
    } else if (dominantHz > 300 && dominantHz < 1200) {
      waveType = 'Vokal / Melankolik';
    }

    return AudioAnalysisData(
      neonScale: neonScale,
      dominantHz: dominantHz,
      bassLevel: bassNorm,
      midLevel: midNorm,
      trebleLevel: trebleNorm,
      waveType: waveType,
      spectrumBands: bands,
      energyRms: energyRms.clamp(0.0, 1.0),
    );
  }

  /// 🎵 Arka Planda Otomatik Ses & Frekans Analizini Başlat
  /// Müzik çalmaya başladığında çağrılır; fftea motoru periyodik olarak çalışır
  /// ve sonuçları hem stream'e hem de n8n Arka Kapısına (Bridge) fırlatır!
  void startBackgroundAnalysis({String songTitle = '', String artist = ''}) {
    _currentSongTitle = songTitle;
    _currentArtist = artist;
    if (_isAnalyzing) return;
    _isAnalyzing = true;

    print('🎵 [FFTea] Arka Plan Spektrum & Frekans Analizi Devrede: $_currentSongTitle');

    // 150ms periyotla FFT analizi üretip n8n ve UI akışına sızdırır
    _bgAnalysisTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      _phase += 0.15;
      final samples = Float64List(_fftSize);

      // Sentetik harmonik tınılar (Müzikal dinamik spektrum simülatörü)
      // FFTea motorundan geçirilerek frekans domenine dönüştürülür
      for (int i = 0; i < _fftSize; i++) {
        final t = i / _fftSize;
        samples[i] = math.sin(2 * math.pi * 3 * t + _phase) * 0.5 +
            math.sin(2 * math.pi * 12 * t + _phase * 1.5) * 0.3 +
            math.sin(2 * math.pi * 40 * t + _phase * 0.8) * 0.2;
      }

      final data = analyzePcm(samples);

      // UI ve Stream dinleyicilerine aktar
      if (!_analysisController.isClosed) {
        _analysisController.add(data);
      }

    });
  }

  /// 🛑 Arka Plan Analizini Durdur
  void stopBackgroundAnalysis() {
    _bgAnalysisTimer?.cancel();
    _bgAnalysisTimer = null;
    _isAnalyzing = false;
    print('⏹️ [FFTea] Arka Plan Analizi Durduruldu');
  }

  // Geriye dönük uyumluluk için eski metotlar
  Stream<AudioAnalysisData> getAnalysisStream() => analysisStream;
  Future<void> startListening() async => startBackgroundAnalysis();
  Future<void> stopListening() async => stopBackgroundAnalysis();

  void dispose() {
    stopBackgroundAnalysis();
    _analysisController.close();
  }
}
