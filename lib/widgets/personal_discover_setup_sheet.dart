import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌌 SİBER ŞAHSİ KEŞFET MİMARİSİ (Akıcı, Neon Cam Tasarım)
/// Genel Keşfet ile 100% uyumlu genişletilmiş türler ve akıllı sanatçı seçimi
class PersonalDiscoverSetupSheet extends StatefulWidget {
  final Color themeColor;
  final bool isInitialSetup;
  final VoidCallback? onCompleted;
  final void Function(List<String> genres, String artists)? onSaved;

  const PersonalDiscoverSetupSheet({
    super.key,
    required this.themeColor,
    this.isInitialSetup = false,
    this.onCompleted,
    this.onSaved,
  });

  /// Statik kolay açıcı metot
  static Future<bool?> show(
    BuildContext context, {
    required Color themeColor,
    bool isInitialSetup = false,
    VoidCallback? onCompleted,
    void Function(List<String> genres, String artists)? onSaved,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => PersonalDiscoverSetupSheet(
        themeColor: themeColor,
        isInitialSetup: isInitialSetup,
        onCompleted: onCompleted,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<PersonalDiscoverSetupSheet> createState() =>
      _PersonalDiscoverSetupSheetState();
}

class _PersonalDiscoverSetupSheetState
    extends State<PersonalDiscoverSetupSheet> {
  final TextEditingController _artistController = TextEditingController();
  final Set<String> _selectedGenres = {};
  bool _isLoading = true;

  /// 🎛️ GENEL KEŞFET İLE BİREBİR UYUMLU GENİŞLETİLMİŞ TÜRLER LİSTESİ
  static const List<Map<String, dynamic>> _availableGenres = [
    {
      'name': 'Trendler',
      'icon': Icons.whatshot_rounded,
      'color': Colors.amberAccent,
    },
    {
      'name': 'Türkçe Rap',
      'icon': Icons.mic_external_on_rounded,
      'color': Color(0xFFFF5252),
    },
    {
      'name': 'Arabesk',
      'icon': Icons.heart_broken_rounded,
      'color': Colors.purpleAccent,
    },
    {
      'name': 'Melankolik',
      'icon': Icons.water_drop_rounded,
      'color': Colors.blueAccent,
    },
    {
      'name': 'Akustik',
      'icon': Icons.music_note_rounded,
      'color': Colors.limeAccent,
    },
    {
      'name': 'Deep House',
      'icon': Icons.speaker_rounded,
      'color': Colors.cyanAccent,
    },
    {
      'name': 'Musiki',
      'icon': Icons.queue_music_rounded,
      'color': Colors.tealAccent,
    },
    {
      'name': 'Marşlar',
      'icon': Icons.military_tech_rounded,
      'color': Colors.redAccent,
    },
    {
      'name': 'Sokak',
      'icon': Icons.local_fire_department_rounded,
      'color': Colors.deepOrangeAccent,
    },
    {
      'name': 'Enerji',
      'icon': Icons.bolt_rounded,
      'color': Colors.yellowAccent,
    },
    {
      'name': 'Odak',
      'icon': Icons.psychology_rounded,
      'color': Colors.greenAccent,
    },
    {
      'name': 'Gizem',
      'icon': Icons.visibility_rounded,
      'color': Colors.indigoAccent,
    },
    {
      'name': 'Pop',
      'icon': Icons.star_rounded,
      'color': Colors.pinkAccent,
    },
    {
      'name': 'Rock',
      'icon': Icons.electric_bolt_rounded,
      'color': Colors.orangeAccent,
    },
    {
      'name': 'Türkü',
      'icon': Icons.library_music_rounded,
      'color': Colors.amber,
    },
    {
      'name': 'R&B',
      'icon': Icons.headphones_rounded,
      'color': Colors.deepPurpleAccent,
    },
    {
      'name': 'Slow',
      'icon': Icons.nights_stay_rounded,
      'color': Colors.lightBlueAccent,
    },
    {
      'name': 'Özgün Müzik',
      'icon': Icons.flare_rounded,
      'color': Colors.teal,
    },
    {
      'name': 'Trap',
      'icon': Icons.equalizer_rounded,
      'color': Colors.deepOrange,
    },
  ];

  /// 🎙️ HIZLI SANATÇI İLHAMLARI
  static const List<String> _quickArtists = [
    'Ceza',
    'Sagopa Kajmer',
    'Velet',
    'GeeFlow',
    'Uzi',
    'Semicenk',
    'Motive',
    'Müslüm Gürses',
    'Sezen Aksu',
    'Duman',
    'Azer Bülbül',
    'Lvbel C5',
    'Emir Can İğrek',
    'Ahmet Kaya',
    'Ezhel',
    'Cakal',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingPreferences();
  }

  @override
  void dispose() {
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGenres = prefs.getStringList('siber_personal_genres') ?? [];
    final savedArtists = prefs.getString('siber_personal_artists') ?? '';

    if (mounted) {
      setState(() {
        _selectedGenres.addAll(savedGenres);
        if (_selectedGenres.isEmpty) {
          // Varsayılan öneri
          _selectedGenres.addAll(['Türkçe Rap', 'Melankolik', 'Akustik']);
        }
        _artistController.text = savedArtists;
        _isLoading = false;
      });
    }
  }

  List<String> _getParsedArtists() {
    return _artistController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _toggleQuickArtist(String artist) {
    final currentList = _getParsedArtists();
    final exists = currentList.any((a) => a.toLowerCase() == artist.toLowerCase());

    if (exists) {
      currentList.removeWhere((a) => a.toLowerCase() == artist.toLowerCase());
    } else {
      currentList.add(artist);
    }

    setState(() {
      _artistController.text = currentList.join(', ');
    });
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        if (_selectedGenres.length >= 6) {
          Fluttertoast.showToast(
            msg: 'Maksimum 6 frekans türü seçebilirsiniz.',
            backgroundColor: Colors.orangeAccent,
            textColor: Colors.black,
          );
          return;
        }
        _selectedGenres.add(genre);
      }
    });
  }

  Future<void> _saveAndProceed() async {
    final artistsList = _getParsedArtists();

    if (_selectedGenres.isEmpty && artistsList.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Yapay zekanın seni tanıması için en az 1 tür veya 1 sanatçı belirlemelisin!',
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('siber_personal_genres', _selectedGenres.toList());
    await prefs.setString('siber_personal_artists', _artistController.text.trim());

    if (widget.onSaved != null) {
      widget.onSaved!(_selectedGenres.toList(), _artistController.text.trim());
    }

    if (mounted) {
      Navigator.pop(context, true);
      Fluttertoast.showToast(
        msg: '⚡ Frekanslar mühürlendi! Şahsi Keşfet hazırlanıyor...',
        backgroundColor: widget.themeColor,
        textColor: Colors.black,
      );
      widget.onCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.themeColor;
    final parsedArtists = _getParsedArtists();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 620,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF13172E).withValues(alpha: 0.96),
                      const Color(0xFF090A14).withValues(alpha: 0.98),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(
                    color: themeColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.22),
                      blurRadius: 32,
                      spreadRadius: 2,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: _isLoading
                      ? SizedBox(
                          height: 300,
                          child: Center(
                            child: CircularProgressIndicator(color: themeColor),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🔹 TUTAMAÇ (DRAG PILL)
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 12, bottom: 6),
                                width: 44,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: Colors.white30,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),

                            // 🔹 BAŞLIK & HEADER
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          themeColor.withValues(alpha: 0.35),
                                          themeColor.withValues(alpha: 0.08),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: themeColor.withValues(alpha: 0.7),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: themeColor.withValues(alpha: 0.35),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.auto_awesome_rounded,
                                      color: themeColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.isInitialSetup
                                              ? 'ŞAHSİ KEŞFET KURULUMU'
                                              : 'ŞAHSİ KEŞFET FREKANSLARI',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Akıllı yapay zeka müzik zevkini kişiselleştirir',
                                          style: TextStyle(
                                            color: themeColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white70,
                                      size: 24,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(
                              color: Colors.white12,
                              height: 1,
                              thickness: 1,
                            ),

                            // 🔹 İÇERİK (KAYDIRILABİLİR ALAN)
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // BİLGİLENDİRME KARTI
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: themeColor.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: themeColor.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.insights_rounded,
                                            color: themeColor,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Seçtiğin tür ve sanatçılarla sana özel 3 sanatçı frekansı, festival kokteyli ve dinamik keşfet akışı üretilir.',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.82),
                                                fontSize: 11.5,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 18),

                                    // 1. ŞARKI TÜRÜ & FREKANS SEÇİMİ BÖLÜMÜ
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.tune_rounded,
                                              size: 16,
                                              color: themeColor,
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'MÜZİK TÜRLERİ & FREKANSLAR',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _selectedGenres.isNotEmpty
                                                ? themeColor.withValues(alpha: 0.2)
                                                : Colors.white10,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: _selectedGenres.isNotEmpty
                                                  ? themeColor.withValues(alpha: 0.6)
                                                  : Colors.white24,
                                            ),
                                          ),
                                          child: Text(
                                            '${_selectedGenres.length} / 6 Seçildi',
                                            style: TextStyle(
                                              color: _selectedGenres.isNotEmpty
                                                  ? themeColor
                                                  : Colors.white60,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Genel keşfetteki tüm tür ve frekans modları entegre edilmiştir (En fazla 6 tür):',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // GENEL KEŞFETLE BİREBİR AYNI ŞIK TÜR ÇİPLERİ
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 9,
                                      children: _availableGenres.map((item) {
                                        final name = item['name'] as String;
                                        final icon = item['icon'] as IconData;
                                        final color = item['color'] as Color;
                                        final isSel = _selectedGenres.contains(name);

                                        return InkWell(
                                          onTap: () => _toggleGenre(name),
                                          borderRadius: BorderRadius.circular(16),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 13,
                                              vertical: 8.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSel
                                                  ? color.withValues(alpha: 0.22)
                                                  : Colors.white.withValues(alpha: 0.04),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSel
                                                    ? color.withValues(alpha: 0.85)
                                                    : Colors.white.withValues(alpha: 0.12),
                                                width: isSel ? 1.5 : 1,
                                              ),
                                              boxShadow: isSel
                                                  ? [
                                                      BoxShadow(
                                                        color: color.withValues(alpha: 0.35),
                                                        blurRadius: 10,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  icon,
                                                  size: 15,
                                                  color: isSel ? color : Colors.white60,
                                                ),
                                                const SizedBox(width: 7),
                                                Text(
                                                  name,
                                                  style: TextStyle(
                                                    color: isSel
                                                        ? Colors.white
                                                        : Colors.white70,
                                                    fontSize: 12,
                                                    fontWeight: isSel
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                  ),
                                                ),
                                                if (isSel) ...[
                                                  const SizedBox(width: 5),
                                                  Icon(
                                                    Icons.check_circle_rounded,
                                                    size: 14,
                                                    color: color,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),

                                    const SizedBox(height: 22),

                                    // 2. FAVORİ SANATÇILAR BÖLÜMÜ
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_pin_rounded,
                                          size: 16,
                                          color: themeColor,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'FAVORİ SANATÇILARIN',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Sanatçı isimlerini virgülle ayırarak yazabilir veya altındaki önerilere dokunabilirsin:',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // SİBER SANATÇI GİRİŞ KUTUSU
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _artistController.text.isNotEmpty
                                              ? themeColor.withValues(alpha: 0.6)
                                              : Colors.white.withValues(alpha: 0.15),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _artistController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                        ),
                                        decoration: InputDecoration(
                                          hintText:
                                              'Örn: Ceza, Sagopa, Velet, Sezen Aksu...',
                                          hintStyle: const TextStyle(
                                            color: Colors.white30,
                                            fontSize: 12.5,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.person_search_rounded,
                                            color: themeColor,
                                            size: 20,
                                          ),
                                          suffixIcon: _artistController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(
                                                    Icons.clear_rounded,
                                                    color: Colors.white54,
                                                    size: 18,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _artistController.clear();
                                                    });
                                                  },
                                                )
                                              : null,
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // HIZLI SANATÇI ÖNERİLERİ
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.flash_on_rounded,
                                          size: 13,
                                          color: themeColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Hızlı Ekle / Çıkar:',
                                          style: TextStyle(
                                            color: themeColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 7,
                                      runSpacing: 7,
                                      children: _quickArtists.map((artist) {
                                        final isArtistSelected = parsedArtists.any(
                                          (a) =>
                                              a.toLowerCase() == artist.toLowerCase(),
                                        );

                                        return InkWell(
                                          onTap: () => _toggleQuickArtist(artist),
                                          borderRadius: BorderRadius.circular(12),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 150),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isArtistSelected
                                                  ? themeColor.withValues(alpha: 0.22)
                                                  : Colors.white.withValues(alpha: 0.04),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isArtistSelected
                                                    ? themeColor.withValues(alpha: 0.8)
                                                    : Colors.white.withValues(alpha: 0.12),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isArtistSelected
                                                      ? Icons.check_rounded
                                                      : Icons.add_rounded,
                                                  size: 12,
                                                  color: isArtistSelected
                                                      ? themeColor
                                                      : Colors.white54,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  artist,
                                                  style: TextStyle(
                                                    color: isArtistSelected
                                                        ? Colors.white
                                                        : Colors.white70,
                                                    fontSize: 11,
                                                    fontWeight: isArtistSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ),

                            // 🔹 ALT BUTON BAR (MÜHÜRLE & BAŞLA)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _saveAndProceed,
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          themeColor,
                                          themeColor.withValues(alpha: 0.85),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: themeColor.withValues(alpha: 0.4),
                                          blurRadius: 18,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.bolt_rounded,
                                          color: Colors.black,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.isInitialSetup
                                              ? 'Mühürle & Şahsi Keşfete Başla'
                                              : 'Frekansları Kaydet & Yenile',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14.5,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
