import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:async';
import '../main.dart'; // audioHandler

/// 🎙️ SİBER SESLİ KOMUT MOTORU
/// Türkçe sesli komutları tanır: dur, devam, sonraki, önceki, favori, keşfet vs.
class SiberSesliKomutSheet extends StatefulWidget {
  final Color themeColor;
  final Function(String)? onSearchCommand; // Arama komutu gelince çağrılır

  const SiberSesliKomutSheet({
    super.key,
    required this.themeColor,
    this.onSearchCommand,
  });

  @override
  State<SiberSesliKomutSheet> createState() => _SiberSesliKomutSheetState();
}

class _SiberSesliKomutSheetState extends State<SiberSesliKomutSheet>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  bool _isInitialized = false;
  String _statusText = 'Mikrofon başlatılıyor...';
  String _recognizedText = '';
  String _lastCommand = '';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Komut geçmişi
  final List<String> _commandHistory = [];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _initSpeech();
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _isAvailable = await _speech.initialize(
      onError: (error) {
        if (mounted) {
          setState(() {
            _statusText = 'Mikrofon Hatası: ${error.errorMsg}';
            _isListening = false;
          });
        }
      },
      onStatus: (status) {
        if (mounted) {
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        }
      },
    );

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _statusText = _isAvailable ? 'Hazır — Mikrofona bas ve konuş' : 'Mikrofon kullanılamıyor';
      });
    }
  }

  Future<void> _toggleListening() async {
    if (!_isAvailable) return;

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      if (mounted) {
        setState(() {
          _isListening = true;
          _recognizedText = '';
          _statusText = 'Dinleniyor... Konuşabilirsin!';
        });
      }

      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _recognizedText = result.recognizedWords;
              if (result.finalResult) {
                _processCommand(result.recognizedWords.toLowerCase());
              }
            });
          }
        },
        localeId: 'tr_TR',
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      );
    }
  }

  void _processCommand(String command) {
    if (command.isEmpty) return;

    String action = '❓ Bilinmeyen komut';

    // ⏯️ Oynatma kontrolleri
    if (command.contains('dur') || command.contains('duraklat') || command.contains('pause')) {
      audioHandler.pause();
      action = '⏸ Müzik duraklatıldı';
    } else if (command.contains('devam') || command.contains('çal') || command.contains('oyna') || command.contains('play')) {
      audioHandler.play();
      action = '▶️ Müzik çalıyor';
    } else if (command.contains('sonraki') || command.contains('atla') || command.contains('ileri') || command.contains('next')) {
      audioHandler.skipToNext();
      action = '⏭ Sonraki şarkıya geçildi';
    } else if (command.contains('önceki') || command.contains('geri') || command.contains('previous') || command.contains('back')) {
      audioHandler.skipToPrevious();
      action = '⏮ Önceki şarkıya geçildi';
    } else if (command.contains('durdur') || command.contains('stop')) {
      audioHandler.stop();
      action = '⏹ Müzik durduruldu';
    }
    // 🔀 Karıştır / tekrar
    else if (command.contains('karıştır') || command.contains('shuffle') || command.contains('karışık')) {
      audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
      action = '🔀 Karıştırma modu açıldı';
    } else if (command.contains('tekrarla') || command.contains('döngü') || command.contains('repeat')) {
      audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
      action = '🔂 Tekrar modu açıldı';
    }
    // 🔍 Arama komutu
    else if (command.contains('ara') || command.contains('bul') || command.contains('çal')) {
      // "X'i ara" veya "X çal" → X'i çıkar
      String query = command
          .replaceAll('çal', '')
          .replaceAll('ara', '')
          .replaceAll('bul', '')
          .replaceAll('bana', '')
          .replaceAll('lütfen', '')
          .trim();
      if (query.isNotEmpty && widget.onSearchCommand != null) {
        widget.onSearchCommand!(query);
        action = '🔍 Aranıyor: $query';
        Navigator.pop(context);
      }
    }

    if (mounted) {
      setState(() {
        _lastCommand = action;
        _isListening = false;
        _statusText = action;
        if (action != '❓ Bilinmeyen komut') {
          _commandHistory.insert(0, '${_formatTime(DateTime.now())} → $action');
          if (_commandHistory.length > 10) _commandHistory.removeLast();
        }
      });
    }
  }

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = widget.themeColor;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: const Color(0xFF060812),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.mic_rounded, color: color, size: 22),
                  const SizedBox(width: 10),
                  Text('SİBER SESLİ KOMUT',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Mikrofon butonu
            GestureDetector(
              onTap: _toggleListening,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnim.value : 1.0,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(color: _isListening ? color : Colors.white24, width: 2),
                        boxShadow: _isListening ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)] : [],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? color : Colors.white38,
                        size: 44,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Status
            Text(_statusText,
                style: TextStyle(color: _isListening ? color : Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),

            const SizedBox(height: 8),

            // Tanınan metin
            if (_recognizedText.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text('"$_recognizedText"',
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center),
              ),

            const SizedBox(height: 20),

            // Komut kartları
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildCommandChip('⏸ Dur', color),
                  _buildCommandChip('▶️ Devam', color),
                  _buildCommandChip('⏭ Sonraki', color),
                  _buildCommandChip('⏮ Önceki', color),
                  _buildCommandChip('🔀 Karıştır', color),
                  _buildCommandChip('🔂 Tekrarla', color),
                  _buildCommandChip('🔍 [Şarkı] Çal', color),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Geçmiş
            if (_commandHistory.isNotEmpty) ...[
              Divider(color: color.withValues(alpha: 0.1), indent: 20, endIndent: 20),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: _commandHistory.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(_commandHistory[i],
                        style: TextStyle(color: i == 0 ? color.withValues(alpha: 0.8) : Colors.white38, fontSize: 11)),
                  ),
                ),
              ),
            ] else
              const Spacer(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    );
  }
}
