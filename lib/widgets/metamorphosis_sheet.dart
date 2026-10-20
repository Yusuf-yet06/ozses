import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/metamorphosis_mix_model.dart';
import '../services/siber_theme_service.dart';

/// 🔮 MÜZİK METAMORFOZU (DUYGU & TÜR DÖNÜŞÜMÜ) - ULTRA ŞIK / SADE VE PARLAK TASARIM

/// Kullanıcının hazır şablonlardan tek dokunuşla seçebileceği veya KENDİ İSTEDİĞİ RUH HALİ VE MÜZİK TÜRÜNÜ
/// manuel yazarak (örn: 'Rap Depresif' ➔ 'Enerji Patlaması') fütüristik bir akış oluşturmasını sağlar.
class MetamorphosisSheet extends StatefulWidget {
  final Color themeColor;
  final Function(String query, String title, List<Map<String, dynamic>> customTracks)? onStartMetamorphosis;
  final VoidCallback? onMixSaved;
  final Map<String, dynamic>? initialTrack;
  final List<Map<String, dynamic>>? initialTracks;

  const MetamorphosisSheet({
    super.key,
    required this.themeColor,
    this.onStartMetamorphosis,
    this.onMixSaved,
    this.initialTrack,
    this.initialTracks,
  });

  static Future<void> show(
    BuildContext context, {
    required Color themeColor,
    Function(String query, String title, List<Map<String, dynamic>> customTracks)? onStartMetamorphosis,
    VoidCallback? onMixSaved,
    Map<String, dynamic>? initialTrack,
    List<Map<String, dynamic>>? initialTracks,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MetamorphosisSheet(
        themeColor: themeColor,
        onStartMetamorphosis: onStartMetamorphosis,
        onMixSaved: onMixSaved,
        initialTrack: initialTrack,
        initialTracks: initialTracks,
      ),
    );
  }

  @override
  State<MetamorphosisSheet> createState() => _MetamorphosisSheetState();
}

class _MetamorphosisSheetState extends State<MetamorphosisSheet> {
  final TextEditingController _startMoodCtrl = TextEditingController(text: 'Rap Depresif');
  final TextEditingController _targetMoodCtrl = TextEditingController(text: 'Enerji Patlaması');
  bool _isSaving = false;
  int _selectedIntensity = 1; // 0: Yumuşak, 1: Dengeli, 2: Patlayıcı
  late final List<Map<String, dynamic>> _customTracks;

  @override
  void initState() {
    super.initState();
    _customTracks = [];
    if (widget.initialTracks != null && widget.initialTracks!.isNotEmpty) {
      _customTracks.addAll(widget.initialTracks!.map((t) => Map<String, dynamic>.from(t)));
    } else if (widget.initialTrack != null) {
      _customTracks.add(Map<String, dynamic>.from(widget.initialTrack!));
    }
  }

  // Hazır Popüler Metamorfoz Şablonları (Tek Tıkla Dolum)
  final List<Map<String, String>> _quickPresets = [
    {
      'emoji': '⚡',
      'title': 'Canavar Modu',
      'start': 'Rap Depresif',
      'target': 'Enerji Patlaması',
      'color': 'cyan',
    },
    {
      'emoji': '🏎️',
      'title': 'Gece Sürüşü',
      'start': 'Sakin Akustik',
      'target': 'Drift & Gece Sürüşü',
      'color': 'purple',
    },
    {
      'emoji': '🧠',
      'title': 'Lazer Odak',
      'start': 'Yorgun & Dağınık',
      'target': 'Lazer Odak Deep Work',
      'color': 'blue',
    },
    {
      'emoji': '🌊',
      'title': 'Derin Huzur',
      'start': 'Stresli & Gergin',
      'target': 'Derin Huzur & Chill',
      'color': 'teal',
    },
    {
      'emoji': '🔥',
      'title': 'Phonk Motivasyon',
      'start': 'Karanlık Trap',
      'target': 'Phonk Gym Motivasyon',
      'color': 'amber',
    },
    {
      'emoji': '💥',
      'title': 'Kulüp Kopmalık',
      'start': 'Melankoli',
      'target': 'Club Kopmalık Bas',
      'color': 'magenta',
    },
  ];

  final List<String> _popularStartMoods = [
    'Rap Depresif',
    'Melankoli',
    'Yorgun & Ağır',
    'Damar Arabesk',
    'Stresli & Gergin',
    'Nostalji Akustik',
    'Karanlık Trap',
    'Hissiz & Boş',
  ];

  final List<String> _popularTargetMoods = [
    'Enerji Patlaması',
    'Lazer Odak',
    'Derin Huzur',
    'Spor & Hırs',
    'Pozitif Vibe',
    'Gece Sürüşü',
    'Phonk & Motivasyon',
    'Club Kopmalık',
  ];

  @override
  void dispose() {
    _startMoodCtrl.dispose();
    _targetMoodCtrl.dispose();
    super.dispose();
  }

  void _swapMoods() {
    setState(() {
      final temp = _startMoodCtrl.text;
      _startMoodCtrl.text = _targetMoodCtrl.text;
      _targetMoodCtrl.text = temp;
    });
  }

  String _buildSearchQuery(String start, String target) {
    final combined = '$start $target'.toLowerCase();

    // 🧠 Siber Zeka: Kullanıcının seçtiği ruh hallerini %100 SAF MÜZİK sorgularına dönüştürür.
    // YouTube'un podcast, motivasyon konuşması veya spor vlogları önermesini kesin olarak engeller.
    String musicGenre = '';
    if (combined.contains('phonk') ||
        combined.contains('gym') ||
        combined.contains('fitness') ||
        combined.contains('spor') ||
        combined.contains('antrenman') ||
        combined.contains('hırs') ||
        combined.contains('motivasyon')) {
      musicGenre = 'türkçe rap phonk baslı şarkılar';
    } else if (combined.contains('ders') ||
        combined.contains('odak') ||
        combined.contains('çalışma') ||
        combined.contains('study') ||
        combined.contains('focus') ||
        combined.contains('kütüphane') ||
        combined.contains('lazer') ||
        combined.contains('sınav')) {
      musicGenre = 'lofi hip hop çalışma odaklanma müzik';
    } else if (combined.contains('sürüş') ||
        combined.contains('araba') ||
        combined.contains('drift') ||
        combined.contains('gece')) {
      musicGenre = 'gece sürüşü synthwave phonk şarkıları';
    } else if (combined.contains('uyku') ||
        combined.contains('meditasyon') ||
        combined.contains('huzur') ||
        combined.contains('dinlen') ||
        combined.contains('chill') ||
        combined.contains('akustik') ||
        combined.contains('sakin')) {
      musicGenre = 'akustik dinlendirici chill türkçe şarkılar';
    } else if (combined.contains('kulüp') ||
        combined.contains('parti') ||
        combined.contains('kopmalık') ||
        combined.contains('dans') ||
        combined.contains('club')) {
      musicGenre = 'türkçe club kopmalık remix şarkılar';
    } else if (combined.contains('arabesk') || combined.contains('damar')) {
      musicGenre = 'damar arabesk remix şarkılar';
    } else if (combined.contains('enerji') ||
        combined.contains('canavar') ||
        combined.contains('patlama') ||
        combined.contains('pozitif')) {
      musicGenre = 'türkçe hareketli rap pop enerji şarkıları';
    } else if (combined.contains('depresif') ||
        combined.contains('melankoli') ||
        combined.contains('hissiz') ||
        combined.contains('yorgun')) {
      musicGenre = 'duygusal melankolik türkçe rap şarkılar';
    } else if (combined.contains('rock') || combined.contains('metal')) {
      musicGenre = 'türkçe rock şarkıları';
    } else {
      musicGenre = '$start $target şarkıları müzik';
    }

    String intensityModifier = '';
    if (_selectedIntensity == 0) {
      intensityModifier = 'akustik soft';
    } else if (_selectedIntensity == 2) {
      intensityModifier = 'bass boosted remix';
    }

    final query = '$musicGenre $intensityModifier'.replaceAll(RegExp(r'\s+'), ' ').trim();
    return query;
  }

  void _startMetamorphosis() {
    final start = _startMoodCtrl.text.trim().isEmpty ? 'Depresif' : _startMoodCtrl.text.trim();
    final target = _targetMoodCtrl.text.trim().isEmpty ? 'Enerji' : _targetMoodCtrl.text.trim();
    final query = _buildSearchQuery(start, target);
    final title = '$start ➔ $target';

    Navigator.pop(context);
    widget.onStartMetamorphosis?.call(query, title, _customTracks);
  }

  Future<void> _saveToRegisteredMixes() async {
    final start = _startMoodCtrl.text.trim().isEmpty ? 'Depresif' : _startMoodCtrl.text.trim();
    final target = _targetMoodCtrl.text.trim().isEmpty ? 'Enerji' : _targetMoodCtrl.text.trim();
    final query = _buildSearchQuery(start, target);
    final title = '$start ➔ $target';

    setState(() => _isSaving = true);

    final mix = MetamorphosisMix(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      startMood: start,
      targetMood: target,
      query: query,
      createdAt: DateTime.now(),
      customTracks: _customTracks,
    );

    final ok = await MetamorphosisService.saveMix(mix);
    setState(() => _isSaving = false);

    if (mounted) {
      if (ok) {
        widget.onMixSaved?.call();
        Fluttertoast.showToast(
          msg: '✨ "$title" Keşfet vitrinine mühürlendi!',
          backgroundColor: Colors.deepPurple,
        );
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: 'Miks kaydedilemedi!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.themeColor;
    final startText = _startMoodCtrl.text.trim().isEmpty ? 'Başlangıç' : _startMoodCtrl.text.trim();
    final targetText = _targetMoodCtrl.text.trim().isEmpty ? 'Hedef' : _targetMoodCtrl.text.trim();

    return ValueListenableBuilder<bool>(
      valueListenable: SiberThemeService.instance.isMinimalMode,
      builder: (context, isMinimal, _) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: BoxDecoration(
            color: isMinimal ? const Color(0xFF141416) : const Color(0xFF0C0F1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isMinimal ? Colors.white12 : themeColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: isMinimal
                ? [
                    const BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. ÜST ÇEKMECE ÇİZGİSİ
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. ULTRA ŞIK BAŞLIK BARI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: isMinimal ? const Color(0xFF222226) : null,
                              gradient: isMinimal
                                  ? null
                                  : LinearGradient(
                                      colors: [
                                        themeColor,
                                        Colors.cyanAccent,
                                      ],
                                    ),
                              shape: BoxShape.circle,
                              border: isMinimal ? Border.all(color: Colors.white12) : null,
                              boxShadow: isMinimal
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: themeColor.withValues(alpha: 0.5),
                                        blurRadius: 14,
                                      ),
                                    ],
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: isMinimal ? Colors.white : Colors.black,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MÜZİK METAMORFOZU',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'Duygu & Tür Dönüşüm Stüdyosu',
                                style: TextStyle(
                                  color: isMinimal ? Colors.white60 : themeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 3. CANLI DÖNÜŞÜM REAKTÖRÜ (KÖPRÜ ALANI)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMinimal ? const Color(0xFF1A1A1E) : null,
                      gradient: isMinimal
                          ? null
                          : LinearGradient(
                              colors: [
                                Colors.cyanAccent.withValues(alpha: 0.12),
                                const Color(0xFF14172B),
                                Colors.purpleAccent.withValues(alpha: 0.12),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isMinimal ? Colors.white12 : Colors.white.withValues(alpha: 0.15),
                      ),
                      boxShadow: isMinimal
                          ? null
                          : const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        // Sol: Başlangıç Kapsülü
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.trip_origin_rounded,
                                    color: isMinimal ? Colors.white70 : Colors.cyanAccent,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'ŞU AN',
                                    style: TextStyle(
                                      color: isMinimal ? Colors.white70 : Colors.cyanAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                startText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Merkez: Çift Yönlü Değiştirme Butonu (Swap)
                        InkWell(
                          onTap: _swapMoods,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isMinimal ? const Color(0xFF26262B) : const Color(0xFF1E233D),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isMinimal ? Colors.white24 : themeColor.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                              boxShadow: isMinimal
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: themeColor.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                      ),
                                    ],
                            ),
                            child: Icon(
                              Icons.swap_horiz_rounded,
                              color: isMinimal ? Colors.white : themeColor,
                              size: 20,
                            ),
                          ),
                        ),

                        // Sağ: Hedef Kapsülü
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'HEDEF',
                                    style: TextStyle(
                                      color: isMinimal ? Colors.white70 : Colors.purpleAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.bolt_rounded,
                                    color: isMinimal ? Colors.white70 : Colors.purpleAccent,
                                    size: 14,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                targetText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. HIZLI ŞABLONLAR (TEK DOKUNUŞLA DÖNÜŞÜM)
                  Row(
                    children: const [
                      Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'POPÜLER DÖNÜŞÜM ŞABLONLARI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickPresets.length,
                      itemBuilder: (context, idx) {
                        final item = _quickPresets[idx];
                        final isCurrent = _startMoodCtrl.text == item['start'] &&
                            _targetMoodCtrl.text == item['target'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _startMoodCtrl.text = item['start']!;
                                _targetMoodCtrl.text = item['target']!;
                              });
                            },
                            borderRadius: BorderRadius.circular(19),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? (isMinimal ? Colors.white12 : themeColor.withValues(alpha: 0.25))
                                    : (isMinimal ? const Color(0xFF1A1A1E) : const Color(0xFF141829)),
                                borderRadius: BorderRadius.circular(19),
                                border: Border.all(
                                  color: isCurrent
                                      ? (isMinimal ? Colors.white70 : themeColor)
                                      : (isMinimal ? Colors.white10 : Colors.white.withValues(alpha: 0.12)),
                                  width: isCurrent ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(item['emoji']!, style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 6),
                                  Text(
                                    item['title']!,
                                    style: TextStyle(
                                      color: isCurrent ? Colors.white : Colors.white70,
                                      fontSize: 11.5,
                                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 5. BİRİNCİ POD: BAŞLANGIÇ FREKANSI (MANUEL YAZ VEYA SEÇ)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMinimal ? const Color(0xFF16161A) : const Color(0xFF121524),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isMinimal ? Colors.white12 : Colors.cyanAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.psychology_rounded,
                                  color: isMinimal ? Colors.white70 : Colors.cyanAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '1. NEREDESİN? (Şu Anki Halin / Tarzın)',
                                  style: TextStyle(
                                    color: isMinimal ? Colors.white70 : Colors.cyanAccent,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            if (_startMoodCtrl.text.isNotEmpty)
                              InkWell(
                                onTap: () => setState(() => _startMoodCtrl.clear()),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    'Temizle',
                                    style: TextStyle(color: Colors.white38, fontSize: 10.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Manuel Giriş Çubuğu
                        TextField(
                          controller: _startMoodCtrl,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Kendin yaz: Örn. Rap Depresif, Yorgun, Damar...',
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                            filled: true,
                            fillColor: isMinimal ? const Color(0xFF1E1E24) : Colors.black38,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            prefixIcon: Icon(
                              Icons.edit_rounded,
                              color: isMinimal ? Colors.white60 : Colors.cyanAccent,
                              size: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isMinimal ? Colors.white10 : Colors.transparent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Hızlı Çipler
                        SizedBox(
                          height: 28,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _popularStartMoods.length,
                            itemBuilder: (context, idx) {
                              final mood = _popularStartMoods[idx];
                              final isSel = _startMoodCtrl.text.trim().toLowerCase() == mood.toLowerCase();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: InkWell(
                                  onTap: () => setState(() => _startMoodCtrl.text = mood),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? (isMinimal ? Colors.white24 : Colors.cyanAccent)
                                          : Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSel
                                            ? (isMinimal ? Colors.white60 : Colors.cyanAccent)
                                            : Colors.white12,
                                      ),
                                    ),
                                    child: Text(
                                      mood,
                                      style: TextStyle(
                                        color: isSel
                                            ? (isMinimal ? Colors.white : Colors.black)
                                            : Colors.white70,
                                        fontSize: 10.5,
                                        fontWeight: isSel ? FontWeight.w900 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 6. İKİNCİ POD: HEDEF FREKANS (MANUEL YAZ VEYA SEÇ)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMinimal ? const Color(0xFF16161A) : const Color(0xFF121524),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isMinimal ? Colors.white12 : Colors.purpleAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: isMinimal ? Colors.white70 : Colors.purpleAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '2. NEREYE VARMAK İSTİYORSUN? (Hedef Halin)',
                                  style: TextStyle(
                                    color: isMinimal ? Colors.white70 : Colors.purpleAccent,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            if (_targetMoodCtrl.text.isNotEmpty)
                              InkWell(
                                onTap: () => setState(() => _targetMoodCtrl.clear()),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    'Temizle',
                                    style: TextStyle(color: Colors.white38, fontSize: 10.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Manuel Giriş Çubuğu
                        TextField(
                          controller: _targetMoodCtrl,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Kendin yaz: Örn. Enerji Patlaması, Lazer Odak...',
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                            filled: true,
                            fillColor: isMinimal ? const Color(0xFF1E1E24) : Colors.black38,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            prefixIcon: Icon(
                              Icons.auto_awesome,
                              color: isMinimal ? Colors.white60 : Colors.purpleAccent,
                              size: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isMinimal ? Colors.white10 : Colors.transparent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Hızlı Çipler
                        SizedBox(
                          height: 28,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _popularTargetMoods.length,
                            itemBuilder: (context, idx) {
                              final mood = _popularTargetMoods[idx];
                              final isSel = _targetMoodCtrl.text.trim().toLowerCase() == mood.toLowerCase();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: InkWell(
                                  onTap: () => setState(() => _targetMoodCtrl.text = mood),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? (isMinimal ? Colors.white24 : Colors.purpleAccent)
                                          : Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSel
                                            ? (isMinimal ? Colors.white60 : Colors.purpleAccent)
                                            : Colors.white12,
                                      ),
                                    ),
                                    child: Text(
                                      mood,
                                      style: TextStyle(
                                        color: isSel
                                            ? (isMinimal ? Colors.white : Colors.black)
                                            : Colors.white70,
                                        fontSize: 10.5,
                                        fontWeight: isSel ? FontWeight.w900 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 7. DÖNÜŞÜM DİNAMİĞİ (SEVİYE SEÇİCİ)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DÖNÜŞÜM DİNAMİĞİ',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Row(
                        children: [
                          _buildIntensityPill(0, '🌱 Akıcı & Chill', isMinimal),
                          const SizedBox(width: 6),
                          _buildIntensityPill(1, '⚡ Dengeli Füzyon', isMinimal),
                          const SizedBox(width: 6),
                          _buildIntensityPill(2, '🔥 Ani Patlama', isMinimal),
                        ],
                      ),
                    ],
                  ),

                  // 🎯 MÜHÜRLÜ ÖZEL PARÇALAR (KEŞFET'TEN SEÇİLENLER)
                  if (_customTracks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMinimal ? const Color(0xFF18181C) : Colors.cyanAccent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMinimal ? Colors.white12 : Colors.cyanAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.stars_rounded,
                                    color: isMinimal ? Colors.white70 : Colors.cyanAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'MÜHÜRLENEN PARÇALAR (${_customTracks.length})',
                                    style: TextStyle(
                                      color: isMinimal ? Colors.white : Colors.cyanAccent,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'İlk bunlar çalınacak',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(_customTracks.length, (idx) {
                            final trk = _customTracks[idx];
                            final tTitle = trk['title'] ?? trk['baslik'] ?? 'Parça';
                            final tArtist = trk['channel'] ?? trk['kanal'] ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${idx + 1}.',
                                    style: TextStyle(
                                      color: isMinimal ? Colors.white70 : Colors.cyanAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$tTitle • $tArtist',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() => _customTracks.removeAt(idx));
                                    },
                                    child: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // 8. AKSİYON BUTONLARI (BAŞLAT & MÜHÜRLE)
                  Row(
                    children: [
                      // Ana Başlat Butonu
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isMinimal ? Colors.white : null,
                            gradient: isMinimal
                                ? null
                                : LinearGradient(
                                    colors: [
                                      themeColor,
                                      Colors.cyanAccent,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: isMinimal
                                ? null
                                : [
                                    BoxShadow(
                                      color: themeColor.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _startMetamorphosis,
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                                    SizedBox(width: 6),
                                    Text(
                                      'DÖNÜŞÜMÜ BAŞLAT',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // İkincil Buton: Keşfet'e Kaydet
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isMinimal ? const Color(0xFF1E1E22) : const Color(0xFF161A2B),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isMinimal ? Colors.white12 : Colors.white24,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isSaving ? null : _saveToRegisteredMixes,
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isSaving)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    else
                                      const Icon(Icons.bookmark_add_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isSaving ? 'Kaydediliyor' : 'Kaydet',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntensityPill(int level, String label, [bool isMinimal = false]) {
    final isSel = _selectedIntensity == level;
    return InkWell(
      onTap: () => setState(() => _selectedIntensity = level),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSel
              ? (isMinimal ? Colors.white24 : widget.themeColor.withValues(alpha: 0.2))
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel
                ? (isMinimal ? Colors.white60 : widget.themeColor)
                : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel
                ? (isMinimal ? Colors.white : widget.themeColor)
                : Colors.white54,
            fontSize: 9.5,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
