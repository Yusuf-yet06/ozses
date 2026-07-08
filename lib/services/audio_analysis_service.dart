// ignore_for_file: prefer_single_quotes

import 'dart:async';
import 'package:record/record.dart'; // 🎯 SİBER HAMLE: Yeni Nesil Mikrofon Motoru
import 'dart:typed_data';
import 'package:fftea/fftea.dart'; // 🎯 SİBER HAMLE: FFT Matematik Motoru
import 'dart:math' as math;

// Analiz sonuçlarını taşıyacak siber veri kapsülü
class AudioAnalysisData {
  final double neonScale;
  final double dominantHz;
  final double bassLevel;
  final double midLevel;
  final double trebleLevel;
  final String waveType; // 🎯 Siber Ruh Hali: Chill, Enerjik, Agresif vb.

  AudioAnalysisData({
    required this.neonScale,
    required this.dominantHz,
    required this.bassLevel,
    required this.midLevel,
    required this.trebleLevel,
    required this.waveType,
  });
}

class AudioAnalysisService {
  static final AudioAnalysisService instance = AudioAnalysisService();
  Stream<AudioAnalysisData>? _analysisStream;
  StreamSubscription<Uint8List>? _micSubscription;
  final AudioRecorder _audioRecorder = AudioRecorder(); // 🎯 SİBER KULAK
  bool _isListening = false;

  // Analiz motorunu başlatan ve veri akışını döndüren ana fonksiyon
  Stream<AudioAnalysisData> getAnalysisStream() {
    if (_analysisStream == null) {
      final controller = StreamController<AudioAnalysisData>.broadcast();

      // Asenkron başlatmayı tetikliyoruz usta
      _startListening(controller);

      controller.onCancel = () {
        _stopListening();
        _analysisStream = null;
      };

      _analysisStream = controller.stream;
    }
    return _analysisStream!;
  }

  void _startListening(StreamController<AudioAnalysisData> controller) async {
    if (_isListening) return;

    _isListening = true; // Dinleme niyetini baştan mühürle usta

    try {
      // 1. Önce mikrofonun izinlerini mühürleyip yayın akışını (Stream) güvenle çekiyoruz
      if (!(await _audioRecorder.hasPermission())) {
        controller.addError("Mikrofon izni reddedildi usta!");
        _isListening = false;
        return;
      }

      final Stream<Uint8List> micStream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );

      // 2. Yayını şimdi gıcır gıcır dinlemeye (listen) alıyoruz usta
      _micSubscription = micStream.listen(
        (data) {
          if (!_isListening) return;

          final samples = Int16List.view(data.buffer);
          if (samples.isEmpty) return;

          // --- 1. Siber Hacim (Volume) / Neon Ölçeği (neonScale) Hesabı ---
          double sumOfSquares = 0.0;
          for (var sample in samples) {
            final normalizedSample = sample / 32768.0;
            sumOfSquares += normalizedSample * normalizedSample;
          }
          final rms = sumOfSquares > 0 ? (sumOfSquares / samples.length) : 0.0;
          final volume = rms * 6.0; // Hassasiyet çarpanı
          final neonScale =
              1.0 + (volume.clamp(0.0, 1.0) * 0.5); // 1.0 ile 1.5 arası esneme

          // --- 2. SİBER YAPAY ZEKA: FFT İLE FREKANS VE RUH HALİ ANALİZİ ---
          // FFT (Fast Fourier Transform) 2'nin üsleri şeklinde çalışır. Biz 1024 parça alıyoruz.
          int fftSize = 1024;
          if (samples.length >= fftSize) {
            final floatSamples = Float64List(fftSize);
            for (int i = 0; i < fftSize; i++) {
              floatSamples[i] = samples[i] / 32768.0; // Sesi normalize et
            }

            // FFT Motorunu ateşle
            final fft = FFT(fftSize);
            final freqData = fft.realFft(floatSamples);
            final Float64List flatFreqData = freqData.buffer
                .asFloat64List(); // 🎯 SİBER BALYOZ: Karmaşık Float64x2 yapısını ezip saf double listesine çeviriyoruz!

            // Büyüklükleri (Magnitudes) hesapla
            List<double> magnitudes = [];
            for (int i = 0; i < fftSize ~/ 2; i++) {
              double real = flatFreqData[2 * i];
              double imag = flatFreqData[2 * i + 1];
              magnitudes.add(math.sqrt(real * real + imag * imag));
            }

            // 🎯 Frekans Bantlarını Ayırma (44100 Hz Sample Rate baz alınarak)
            double bass = 0.0; // 0 - 250 Hz
            double mid = 0.0; // 250 - 2000 Hz
            double treble = 0.0; // 2000+ Hz
            double maxMag = 0.0;
            double dominantHz = 0.0;

            for (int i = 0; i < magnitudes.length; i++) {
              double hz = i * (44100.0 / fftSize);
              if (magnitudes[i] > maxMag) {
                maxMag = magnitudes[i];
                dominantHz = hz;
              }
              if (hz < 250)
                bass += magnitudes[i];
              else if (hz < 2000)
                mid += magnitudes[i];
              else
                treble += magnitudes[i];
            }

            // 🎯 Ruh Hali Karar Mekanizması (Şahsi Keşfet'in Beyni)
            String waveType = "Dengeli / Chill";
            if (bass > mid * 1.5 && bass > treble)
              waveType = "Agresif / Sub-Bass";
            else if (mid > bass && mid > treble)
              waveType = "Vokal / Akustik";
            else if (treble > bass * 1.5 && treble > mid)
              waveType = "Enerjik / Tiz";

            // Yüzdelik oranlara (0.0 - 1.0) çek
            double total = bass + mid + treble;
            if (total == 0) total = 1.0;

            controller.add(AudioAnalysisData(
              neonScale: neonScale,
              dominantHz: dominantHz,
              bassLevel: bass / total,
              midLevel: mid / total,
              trebleLevel: treble / total,
              waveType: waveType,
            ));
          }
        },
        onError: (error) => controller.addError(error),
        onDone: () => _isListening = false,
      );
    } catch (e) {
      controller.addError("Siber motor başlatılırken hata çıktı: $e");
      _isListening = false;
    }
  }

  void _stopListening() async {
    _micSubscription?.cancel();
    _micSubscription = null;
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }
    _isListening = false;
  }

  void dispose() => _stopListening();
}
