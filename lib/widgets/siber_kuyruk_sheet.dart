import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import '../main.dart';

/// 🎵 SİBER ŞARKI KUYRUĞU
/// Çalma sırasındaki şarkıları gösterir, sürükle-bırak ile yeniden sırala
class SiberKuyrukSheet extends StatefulWidget {
  final Color themeColor;
  const SiberKuyrukSheet({super.key, required this.themeColor});

  @override
  State<SiberKuyrukSheet> createState() => _SiberKuyrukSheetState();
}

class _SiberKuyrukSheetState extends State<SiberKuyrukSheet> {
  List<MediaItem> _queue = [];
  int _currentIndex = 0;
  StreamSubscription? _queueSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    // Mevcut kuyruğu yükle
    _queue = List.from(audioHandler.queue.value);
    _currentIndex = audioHandler.playbackState.value.queueIndex ?? 0;

    _queueSub = audioHandler.queue.listen((q) {
      if (mounted) setState(() => _queue = List.from(q));
    });
    _stateSub = audioHandler.playbackState.listen((state) {
      if (mounted) setState(() => _currentIndex = state.queueIndex ?? 0);
    });
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.themeColor;

    return SafeArea(
      top: false,
      child: Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: BoxDecoration(
        color: const Color(0xFF080810),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          // Handle + Header
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.queue_music_rounded, color: color, size: 22),
                const SizedBox(width: 10),
                Text('ÇALMA KUYRUĞU', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
                  child: Text('${_queue.length} şarkı', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          Divider(color: color.withValues(alpha: 0.1), height: 16),

          if (_queue.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.queue_music_rounded, color: Colors.white12, size: 60),
                    SizedBox(height: 12),
                    Text('Kuyruk boş', style: TextStyle(color: Colors.white38, fontSize: 14)),
                    Text('Bir şarkı çal ve buraya gelir', style: TextStyle(color: Colors.white24, fontSize: 11)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: _queue.length,
                onReorder: (oldIdx, newIdx) async {
                  if (newIdx > oldIdx) newIdx--;
                  final newQueue = List<MediaItem>.from(_queue);
                  final item = newQueue.removeAt(oldIdx);
                  newQueue.insert(newIdx, item);
                  await audioHandler.updateQueue(newQueue);
                },
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 8,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: child,
                  );
                },
                itemBuilder: (context, idx) {
                  final item = _queue[idx];
                  final isCurrent = idx == _currentIndex;

                  return Dismissible(
                    key: Key('queue_${item.id}_$idx'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    ),
                    onDismissed: (_) async {
                      final newQueue = List<MediaItem>.from(_queue)..removeAt(idx);
                      await audioHandler.updateQueue(newQueue);
                    },
                    child: GestureDetector(
                      onTap: () async {
                        await audioHandler.skipToQueueItem(idx);
                        await audioHandler.play();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCurrent ? color.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent ? color.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
                            width: isCurrent ? 1 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Numara ya da aktif göstergesi
                            SizedBox(
                              width: 28,
                              child: isCurrent
                                  ? _PlayingIndicator(color: color)
                                  : Text('${idx + 1}',
                                      style: const TextStyle(color: Colors.white24, fontSize: 12),
                                      textAlign: TextAlign.center),
                            ),
                            const SizedBox(width: 10),
                            // Şarkı bilgisi
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      color: isCurrent ? Colors.white : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item.artist ?? 'Bilinmeyen',
                                    style: TextStyle(color: isCurrent ? color.withValues(alpha: 0.8) : Colors.white38, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Sürükle tutacağı
                            ReorderableDragStartListener(
                              index: idx,
                              child: Icon(Icons.drag_handle_rounded,
                                  color: isCurrent ? color.withValues(alpha: 0.6) : Colors.white12, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    ));
  }
}

/// Aktif çalma göstergesi (3 barlı animasyonlu)
class _PlayingIndicator extends StatefulWidget {
  final Color color;
  const _PlayingIndicator({required this.color});

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            final h = 4.0 + (i.isEven ? _ctrl.value : (1 - _ctrl.value)) * 10;
            return Container(
              width: 3, height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
