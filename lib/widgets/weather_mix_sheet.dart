import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/weather_service.dart';
import '../utils/song_media_utils.dart';
import '../main.dart';

/// 🌤️ SİBER HAVA DURUMU & KİŞİSEL MÜZİK ZEVKİ MİXİ
/// Kullanıcının konumundaki hava durumu ile dinleme geçmişini harmanlayarak
/// anında başlatılabilir akıllı mix sunar.
class WeatherMixSheet extends StatefulWidget {
  final Weather? currentWeather;
  final String? atmosphereMood;
  final Color themeColor;
  final Function(String videoId, String title)? onDownloadStart;

  const WeatherMixSheet({
    super.key,
    this.currentWeather,
    this.atmosphereMood,
    required this.themeColor,
    this.onDownloadStart,
  });

  @override
  State<WeatherMixSheet> createState() => _WeatherMixSheetState();
}

class _WeatherMixSheetState extends State<WeatherMixSheet> {
  bool _isLoading = true;
  WeatherMixBundle? _bundle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMix();
  }

  Future<void> _loadMix({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bundle = await WeatherService.generateWeatherMix(
        weather: widget.currentWeather,
        currentMood: widget.atmosphereMood,
      );

      if (mounted) {
        setState(() {
          _bundle = bundle;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Atmosfer mixi hazırlanırken bir sorun oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playAll() async {
    if (_bundle == null || _bundle!.tracks.isEmpty) return;

    final List<MediaItem> mediaItems = [];
    for (var t in _bundle!.tracks) {
      final vid = (t['videoId'] ?? t['id'] ?? t['video_id'])?.toString();
      if (vid != null && vid.isNotEmpty) {
        mediaItems.add(MediaItem(
          id: 'yt:$vid',
          album: _bundle!.title,
          title: t['title'] ?? 'Bilinmeyen',
          artist: t['channel'] ?? t['artist'] ?? 'Atmosfer Miksi',
          artUri: safeParseUri(t['thumbnail']),
        ));
      }
    }

    if (mediaItems.isNotEmpty) {
      await audioHandler.updateQueue(mediaItems);
      await audioHandler.skipToQueueItem(0);
      if (mounted) {
        Navigator.pop(context);
        Fluttertoast.showToast(
          msg: '🎧 ${_bundle!.title} başlatıldı!',
          backgroundColor: _bundle!.themeColor,
          textColor: Colors.black,
        );
      }
    }
  }

  Future<void> _playSingleTrack(int index) async {
    if (_bundle == null || _bundle!.tracks.isEmpty) return;

    final List<MediaItem> mediaItems = [];
    for (var t in _bundle!.tracks) {
      final vid = (t['videoId'] ?? t['id'] ?? t['video_id'])?.toString();
      if (vid != null && vid.isNotEmpty) {
        mediaItems.add(MediaItem(
          id: 'yt:$vid',
          album: _bundle!.title,
          title: t['title'] ?? 'Bilinmeyen',
          artist: t['channel'] ?? t['artist'] ?? 'Atmosfer Miksi',
          artUri: safeParseUri(t['thumbnail']),
        ));
      }
    }

    if (mediaItems.isNotEmpty && index < mediaItems.length) {
      await audioHandler.updateQueue(mediaItems);
      await audioHandler.skipToQueueItem(index);
      if (mounted) {
        Navigator.pop(context);
        Fluttertoast.showToast(
          msg: '🎵 ${mediaItems[index].title} çalınıyor',
          backgroundColor: _bundle!.themeColor,
          textColor: Colors.black,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _bundle?.themeColor ?? widget.themeColor;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF090A14),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: activeColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sürükleme Tutamacı (Pill)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header (Hava Durumu + Başlık)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: activeColor.withValues(alpha: 0.4)),
                    ),
                    child: Icon(
                      _bundle?.icon ?? Icons.wb_sunny_rounded,
                      color: activeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: activeColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: activeColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                _bundle?.mood.toUpperCase() ?? 'ATMOSFER',
                                style: TextStyle(
                                  color: activeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            if (_bundle?.temp != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${_bundle!.temp!.toStringAsFixed(0)}°C',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _bundle?.title ?? 'Atmosfer Miksi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    tooltip: 'Mixi Yenile',
                    onPressed: _isLoading ? null : () => _loadMix(forceRefresh: true),
                  ),
                ],
              ),
            ),

            if (_bundle != null && _bundle!.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _bundle!.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ),

            // Kullanıcı zevki etiketleri (Örn: 🎧 Ceza, Uzi)
            if (_bundle != null && _bundle!.userTaste.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 6.0, bottom: 10.0),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'Zevkine Göre:',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _bundle!.userTaste.map((taste) {
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                taste,
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Ana "Mixi Başlat" Neon Butonu
            if (!_isLoading && _bundle != null && _bundle!.tracks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: InkWell(
                  onTap: _playAll,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          activeColor,
                          activeColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'MİXİ BAŞLAT (TÜMÜNÜ ÇAL)',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const Divider(color: Colors.white12, height: 16),

            // Şarkı Listesi veya Yükleme
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: activeColor),
                          const SizedBox(height: 16),
                          Text(
                            '🌤️ Hava durumu ve müzik zevkin harmanlanıyor...',
                            style: TextStyle(color: activeColor, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_off_rounded, color: Colors.orangeAccent, size: 44),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _loadMix(forceRefresh: true),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Tekrar Dene'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: activeColor,
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _bundle == null || _bundle!.tracks.isEmpty
                          ? const Center(
                              child: Text(
                                'Bu mod için şu an parça bulunamadı.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              itemCount: _bundle!.tracks.length,
                              itemBuilder: (context, index) {
                                final track = _bundle!.tracks[index];
                                final title = track['title'] ?? 'Bilinmeyen Şarkı';
                                final channel = track['channel'] ?? track['artist'] ?? 'Victus V7';
                                final thumbnail = track['thumbnail'] as String?;
                                final videoId = (track['videoId'] ?? track['id'] ?? track['video_id'])?.toString();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: thumbnail != null && thumbnail.isNotEmpty
                                          ? Image.network(
                                              thumbnail,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 50,
                                                height: 50,
                                                color: Colors.white12,
                                                child: Icon(Icons.music_note, color: activeColor),
                                              ),
                                            )
                                          : Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.white12,
                                              child: Icon(Icons.music_note, color: activeColor),
                                            ),
                                    ),
                                    title: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      channel,
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (widget.onDownloadStart != null && videoId != null)
                                          IconButton(
                                            icon: const Icon(Icons.download_rounded, color: Colors.white60, size: 20),
                                            tooltip: 'İndir',
                                            onPressed: () {
                                              widget.onDownloadStart!(videoId, title);
                                              Fluttertoast.showToast(msg: '📥 İndirme başlatıldı: $title');
                                            },
                                          ),
                                        IconButton(
                                          icon: Icon(Icons.play_circle_fill_rounded, color: activeColor, size: 28),
                                          tooltip: 'Çal',
                                          onPressed: () => _playSingleTrack(index),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _playSingleTrack(index),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
