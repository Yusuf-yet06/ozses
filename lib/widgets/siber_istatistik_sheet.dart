import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../services/history_service.dart';

/// 📊 SİBER İSTATİSTİK RADARI
/// Günlük/haftalık dinleme süresini çubuk grafik olarak gösterir
class SiberIstatistikSheet extends StatefulWidget {
  final Color themeColor;
  const SiberIstatistikSheet({super.key, required this.themeColor});

  @override
  State<SiberIstatistikSheet> createState() => _SiberIstatistikSheetState();
}

class _SiberIstatistikSheetState extends State<SiberIstatistikSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  bool _isLoading = true;
  bool _showWeekly = true;

  List<_DayData> _weeklyData = [];
  List<_HourData> _hourlyData = [];

  int _totalListenMinutes = 0;
  int _totalPlayCount = 0;
  String _topSongName = '—';
  String _topArtistName = '—';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _loadStats();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final history = await HistoryService.getHistory();
    final now = DateTime.now();

    List<_DayData> weekly = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _DayData(label: _dayLabel(day.weekday), minutes: 0, count: 0);
    });

    List<_HourData> hourly = List.generate(6, (i) {
      return _HourData(label: '${(i * 4).toString().padLeft(2, '0')}:00', minutes: 0);
    });

    int totalSec = 0;
    int totalPlays = 0;
    Map<String, int> songCounts = {};
    Map<String, int> artistCounts = {};

    for (var rec in history) {
      final lastPlayed =
          DateTime.fromMillisecondsSinceEpoch(rec.lastPlayedTimestamp);
      final diffDays = now.difference(lastPlayed).inDays;
      final diffHours = now.difference(lastPlayed).inHours;

      if (diffDays < 7) {
        int idx = 6 - diffDays;
        if (idx >= 0 && idx < 7) {
          weekly[idx].minutes += rec.totalListenSeconds ~/ 60;
          weekly[idx].count += rec.playCount;
        }
      }

      if (diffHours < 24) {
        int blockIdx = ((24 - diffHours - 1) ~/ 4).clamp(0, 5);
        hourly[blockIdx].minutes += rec.totalListenSeconds ~/ 60;
      }

      totalSec += rec.totalListenSeconds;
      totalPlays += rec.playCount;
      songCounts[rec.name] = (songCounts[rec.name] ?? 0) + rec.playCount;
      if (rec.name.contains('-')) {
        final artist = rec.name.split('-').first.trim();
        artistCounts[artist] = (artistCounts[artist] ?? 0) + rec.playCount;
      }
    }

    String topSong = '—';
    if (songCounts.isNotEmpty) {
      topSong = songCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key
          .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
          .trim();
      if (topSong.length > 30) topSong = '${topSong.substring(0, 28)}...';
    }

    String topArtist = '—';
    if (artistCounts.isNotEmpty) {
      topArtist = artistCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    if (mounted) {
      setState(() {
        _weeklyData = weekly;
        _hourlyData = hourly;
        _totalListenMinutes = totalSec ~/ 60;
        _totalPlayCount = totalPlays;
        _topSongName = topSong;
        _topArtistName = topArtist;
        _isLoading = false;
      });
      _animCtrl.forward();
    }
  }

  String _dayLabel(int weekday) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[(weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: widget.themeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: widget.themeColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: widget.themeColor, size: 22),
                    const SizedBox(width: 10),
                    Text('SİBER İSTATİSTİK RADARI',
                        style: TextStyle(
                            color: widget.themeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() => _showWeekly = !_showWeekly);
                        _animCtrl.reset();
                        _animCtrl.forward();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: widget.themeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: widget.themeColor.withValues(alpha: 0.4))),
                        child: Text(_showWeekly ? '7 Gün' : '24 Saat',
                            style: TextStyle(
                                color: widget.themeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(color: widget.themeColor, strokeWidth: 2)),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildStatCard(icon: Icons.access_time, label: 'Toplam',
                          value: _totalListenMinutes >= 60
                              ? '${_totalListenMinutes ~/ 60}s ${_totalListenMinutes % 60}dk'
                              : '${_totalListenMinutes}dk'),
                      const SizedBox(width: 10),
                      _buildStatCard(icon: Icons.play_arrow_rounded, label: 'Çalma', value: '$_totalPlayCount kez'),
                      const SizedBox(width: 10),
                      _buildStatCard(icon: Icons.person, label: 'Top Sanatçı', value: _topArtistName, compact: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(double.infinity, 160),
                        painter: _showWeekly
                            ? _WeeklyBarPainter(data: _weeklyData, progress: _anim.value, color: widget.themeColor)
                            : _HourlyBarPainter(data: _hourlyData, progress: _anim.value, color: widget.themeColor),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (_topSongName != '—')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: widget.themeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.themeColor.withValues(alpha: 0.2))),
                      child: Row(
                        children: [
                          Icon(Icons.stars_rounded, color: widget.themeColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('En Çok Dinlenen',
                                    style: TextStyle(color: widget.themeColor.withValues(alpha: 0.7), fontSize: 10)),
                                Text(_topSongName,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, bool compact = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
            color: widget.themeColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.themeColor.withValues(alpha: 0.2), width: 1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: widget.themeColor, size: 16),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class _DayData { String label; int minutes; int count; _DayData({required this.label, required this.minutes, required this.count}); }
class _HourData { String label; int minutes; _HourData({required this.label, required this.minutes}); }

class _WeeklyBarPainter extends CustomPainter {
  final List<_DayData> data;
  final double progress;
  final Color color;
  _WeeklyBarPainter({required this.data, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.map((d) => d.minutes).reduce(math.max).toDouble();
    if (maxVal == 0) {
      final tp = TextPainter(text: const TextSpan(text: 'Henüz dinleme verisi yok', style: TextStyle(color: Colors.white38, fontSize: 12)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2)); return;
    }
    final spacing = size.width / data.length;
    final barWidth = spacing * 0.5;
    const bottomPad = 28.0; const topPad = 10.0;
    final chartH = size.height - bottomPad - topPad;

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final barH = (chartH * (maxVal > 0 ? d.minutes / maxVal : 0) * progress).clamp(0.0, chartH);
      final x = spacing * i + spacing / 2;
      final isToday = (i == data.length - 1);

      if (isToday && barH > 0) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - barWidth / 2 - 4, topPad + chartH - barH - 4, barWidth + 8, barH + 4), const Radius.circular(8)),
            Paint()..color = color.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      }

      if (barH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x - barWidth / 2, topPad + chartH - barH, barWidth, barH), const Radius.circular(5)),
          Paint()..shader = ui.Gradient.linear(Offset(x, topPad + chartH - barH), Offset(x, topPad + chartH),
              [isToday ? color : color.withValues(alpha: 0.6), isToday ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.1)]),
        );
      }

      (TextPainter(text: TextSpan(text: d.label, style: TextStyle(color: isToday ? color : Colors.white38, fontSize: 10, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)), textDirection: TextDirection.ltr)..layout())
          .paint(canvas, Offset(x - 12, size.height - 18));

      if (d.minutes > 0 && barH > 20) {
        final minText = d.minutes >= 60 ? '${d.minutes ~/ 60}s' : '${d.minutes}dk';
        (TextPainter(text: TextSpan(text: minText, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9)), textDirection: TextDirection.ltr)..layout())
            .paint(canvas, Offset(x - 10, topPad + chartH - barH - 14));
      }
    }
    canvas.drawLine(Offset(0, topPad + chartH), Offset(size.width, topPad + chartH), Paint()..color = color.withValues(alpha: 0.15)..strokeWidth = 1);
  }
  @override bool shouldRepaint(covariant _WeeklyBarPainter old) => old.progress != progress;
}

class _HourlyBarPainter extends CustomPainter {
  final List<_HourData> data;
  final double progress;
  final Color color;
  _HourlyBarPainter({required this.data, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.map((d) => d.minutes).reduce(math.max).toDouble();
    if (maxVal == 0) {
      final tp = TextPainter(text: const TextSpan(text: 'Son 24 saatte dinleme yok', style: TextStyle(color: Colors.white38, fontSize: 12)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2)); return;
    }
    final spacing = size.width / data.length;
    final barWidth = spacing * 0.55;
    const bottomPad = 28.0; const topPad = 10.0;
    final chartH = size.height - bottomPad - topPad;

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final barH = (chartH * (maxVal > 0 ? d.minutes / maxVal : 0) * progress).clamp(0.0, chartH);
      final x = spacing * i + spacing / 2;
      if (barH > 0) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - barWidth / 2, topPad + chartH - barH, barWidth, barH), const Radius.circular(5)),
            Paint()..shader = ui.Gradient.linear(Offset(x, topPad + chartH - barH), Offset(x, topPad + chartH), [color, color.withValues(alpha: 0.2)]));
      }
      (TextPainter(text: TextSpan(text: d.label, style: const TextStyle(color: Colors.white38, fontSize: 9)), textDirection: TextDirection.ltr)..layout())
          .paint(canvas, Offset(x - 14, size.height - 18));
    }
    canvas.drawLine(Offset(0, topPad + chartH), Offset(size.width, topPad + chartH), Paint()..color = color.withValues(alpha: 0.15)..strokeWidth = 1);
  }
  @override bool shouldRepaint(covariant _HourlyBarPainter old) => old.progress != progress;
}
