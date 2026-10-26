import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// 🔔 Profil > Bildirimler: küçük, kompakt alt çekmece (ekranı kaplamaz).
Future<void> showNotificationSettingsSheet(BuildContext context, {required Color themeColor}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    builder: (_) => Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: NotificationSettingsSheet(themeColor: themeColor),
      ),
    ),
  );
}

class NotificationSettingsSheet extends StatefulWidget {
  final Color themeColor;
  const NotificationSettingsSheet({super.key, required this.themeColor});

  @override
  State<NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  final _svc = NotificationService.instance;
  bool _fav = true;
  bool _ann = true;
  bool _dl = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final f = await _svc.isEnabled(NotificationService.prefFavArtists);
    final a = await _svc.isEnabled(NotificationService.prefAnnouncements);
    final d = await _svc.isEnabled(NotificationService.prefDownloads);
    if (!mounted) return;
    setState(() {
      _fav = f;
      _ann = a;
      _dl = d;
      _loaded = true;
    });
  }

  Future<void> _toggle(String key, bool v, void Function(bool) apply) async {
    setState(() => apply(v));
    await _svc.setEnabled(key, v);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.themeColor;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        decoration: BoxDecoration(
          color: const Color(0xF2121216),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.withValues(alpha: 0.35)),
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.12), blurRadius: 18)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.notifications_active, color: c, size: 18),
                const SizedBox(width: 8),
                const Text('BİLDİRİMLER',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 4),
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.all(18),
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              _row(Icons.person_pin, 'Favori sanatçı şarkıları',
                  'Yeni tam şarkılar (Shorts hariç)', _fav,
                  (v) => _toggle(NotificationService.prefFavArtists, v, (x) => _fav = x)),
              _row(Icons.campaign, 'Duyurular', 'Yönetici ve genel duyurular', _ann,
                  (v) => _toggle(NotificationService.prefAnnouncements, v, (x) => _ann = x)),
              _row(Icons.download_for_offline, 'İndirme bildirimleri',
                  'Yüzde ve tamamlanma durumu', _dl,
                  (v) => _toggle(NotificationService.prefDownloads, v, (x) => _dl = x)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String title, String sub, bool value, ValueChanged<bool> onChanged) {
    final c = widget.themeColor;
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(vertical: -2),
      activeThumbColor: c,
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: value ? c : Colors.white38, size: 22),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(sub,
          style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
    );
  }
}
