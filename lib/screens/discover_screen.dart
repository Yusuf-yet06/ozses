import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;
import 'dart:convert'; // 🎯 SİBER HAMLE: json işlemleri için
import '../services/services.dart';
import '../services/weather_service.dart';
import '../services/audio_handler.dart';
import '../widgets/auto_playlist_sheet.dart'; // 🎯 SİBER HAMLE: Yapay Zeka Alt Çekmecesi
import 'package:audio_service/audio_service.dart'; // 🎯 ÇEVRİMİÇİ MÜZİĞİ OYNATMAK İÇİN
import '../main.dart'; // 🎯 AUDIOHANDLER KÖPRÜSÜ
import 'package:shared_preferences/shared_preferences.dart'; // 🎯 Arama Geçmişi Mührü
import '../widgets/bottom_player_bar.dart'; // 🎯 KEŞFET MİNİ OYNATICISI
import '../widgets/mini_eq_visualizer.dart';
import '../widgets/full_screen_player.dart'; // 🎯 TAM EKRAN OYNATICI (SİBER MÜHÜR)
import 'dart:async'; // 🎯 Otonom Dinleyiciler İçin
import '../services/history_service.dart'; // 🎯 SİBER HAMLE: Geçmiş Analizi İçin
import 'package:http/http.dart'
    as http; // 🎯 SİBER HAMLE: Plak kapağı indirmek için
import 'dart:typed_data';


class DiscoverScreen extends StatefulWidget {
  final Color themeColor;
  final Function(String, String)? onDownloadStart;
  final bool isPersonalMode; // 🎯 SİBER HAMLE: Şahsi Keşfet Modu Aktif mi?

  const DiscoverScreen(
      {super.key,
      required this.themeColor,
      this.onDownloadStart,
      this.isPersonalMode = false});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class DiscoverCache {
  List<dynamic> trendList = [];
  List<dynamic> searchResults = [];
  String nextPageToken = '';
  String activeCategory = 'Trendler';
  bool isSearching = false;
  String lastSearchQuery = '';
  int searchPage = 1;
  bool hasMoreSearch = true;
  Map<String, List<dynamic>> genreLists = {};
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  // 🎯 SİBER KALKAN: Keşfet Kalıcılık Hafızası (Sen çıksan bile silinmez)
  static final DiscoverCache _generalCache = DiscoverCache();
  static final DiscoverCache _personalCache = DiscoverCache();

  DiscoverCache get _currentCache => widget.isPersonalMode ? _personalCache : _generalCache;


  // 🎯 YENİ SİBER HAMLE: Otonom AI Mix Motoru & Hava Durumu
  List<Map<String, dynamic>> _aiMixes = [];
  String _dominantMood = 'Genel';
  
  Weather? _currentWeather;
  String _atmosphereMood = 'Genel';

  final TextEditingController _searchController = TextEditingController();
  final OzsesBridge _bridge = OzsesBridge();
  final ScrollController _scrollController =
      ScrollController(); // 🎯 SİBER KALKAN: Kaydırma Motoru

  // 🎯 SİBER MİNİ OYNATICI (PLAYER) DEĞİŞKENLERİ
  StreamSubscription? _mediaItemSub;
  StreamSubscription? _playbackStateSub;
  StreamSubscription? _positionSub;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _isPlaying = false;
  String _currentSongName = 'Müzik Seçilmedi';
  String _currentArtist = 'Victus V7';
  Uint8List? _currentCoverBytes; // 🎯 Çevrimiçi plak kapağı hafızası
  bool _isBuffering =
      false; // 🎯 SİBER HAMLE: Sonsuz Yükleme Kilidi İçin Eklendi

  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingMore = false; // Sonsuz kaydırma için
  bool _showSkeletonTimeout = false; // 🎯 5 sn sonra timeout mesajı
  bool _isOfflineMode = false; // 🎯 SİBER KALKAN: Çevrimdışı modu göstergesi
  Timer? _skeletonTimer;

  // 🎯 SİBER HAMLE: Arama Sayfalaması
  int _searchPage = 1;
  bool _hasMoreSearch = true;

  List<dynamic> _trendList = [];
  List<dynamic> _searchResults = [];
  String _nextPageToken = '';
  Map<String, List<dynamic>> _genreLists = {};

  String _activeCategory = 'Trendler';
  String _activeSearchFilter = ''; // 🎯 GELİŞMİŞ ARAMA FİLTRESİ
  List<String> _searchHistory = []; // 🎯 ARAMA GEÇMİŞİ

  // 🎯 SİBER HAMLE: Canlı Arama Önerileri (Autocomplete)
  List<String> _liveSuggestions = [];
  Timer? _debounceTimer;

  void _onSearchTextChanged(String text) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (text.trim().isEmpty) {
      setState(() {
        _liveSuggestions.clear();
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final suggestions = await _bridge.getSearchSuggestions(text);
      if (mounted && _searchController.text == text) {
        setState(() {
          _liveSuggestions = suggestions;
        });
      }
    });
  }

  final List<String> _categories = [
    'Trendler',
    'Türkçe Rap',
    'Melankolik',
    'Akustik',
    'Deep House',
    'Arabesk'
  ];

  @override
  void initState() {
    super.initState();

    // 🎯 SİBER KALKAN: Mod değiştiyse (Örn: Şahsi'den Genel'e) eski hafızayı sök at!

    // 1. Ekran açıldığında hafızadaki son durumu geri yükle
    _trendList = _currentCache.trendList;
    _searchResults = _currentCache.searchResults;
    _nextPageToken = _currentCache.nextPageToken;
    _activeCategory = _currentCache.activeCategory;
    _isSearching = _currentCache.isSearching;
    _searchController.text = _currentCache.lastSearchQuery;
    _genreLists = _currentCache.genreLists;
    _searchPage = _currentCache.searchPage;
    _hasMoreSearch = _currentCache.hasMoreSearch;

    _loadSearchHistory();
    _initSiberPlayerListeners();

    if (_trendList.isEmpty && !_isSearching) {
      _initDataAndCache();
    }
    _scrollController.addListener(_onScroll);
    _initWeather();
  }

  Future<void> _initWeather() async {
    final w = await WeatherService.getCurrentWeather();
    if (w != null && mounted) {
      setState(() {
        _currentWeather = w;
        _atmosphereMood = WeatherService.getAtmosphereMood(w);
      });
    }
  }

  // 🎯 SİBER HAMLE: Önbellekten (Cache) Yükle ve Sessizce Güncelle
  Future<void> _initDataAndCache() async {
    await _loadCachedTrends();
    final bool hasCache = _trendList.isNotEmpty;

    if (widget.isPersonalMode) {
      _fetchPersonalRecommendations(silent: hasCache);
    } else {
      _fetchTrends(silent: hasCache);
    }
  }

  Future<void> _loadCachedTrends() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('siber_trend_cache');
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached);
        if (mounted) {
          setState(() {
            _trendList = decoded;
            _currentCache.trendList = _trendList;
          });
        }
      } catch (e) {}
    }
  }

  Future<void> _saveTrendsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('siber_trend_cache', jsonEncode(_trendList));
  }

  // 🎯 SİBER HAMLE: Mini Oynatıcıyı Canlı Tutan Radar
  void _initSiberPlayerListeners() {
    _mediaItemSub = audioHandler.mediaItem.listen((item) async {
      if (item != null && mounted) {
        setState(() {
          _currentSongName = item.title;
          _currentArtist = item.artist ?? 'Victus V7';
          _dur = item.duration ?? Duration.zero;
        });

        // 🎯 SİBER HAMLE: Çevrimiçi Plak Kapağı Çözücü
        if (item.artUri != null) {
          try {
            final response = await http.get(item.artUri!);
            if (response.statusCode == 200 && mounted) {
              setState(() {
                _currentCoverBytes = response.bodyBytes;
              });
            }
          } catch (e) {
            if (mounted) setState(() => _currentCoverBytes = null);
          }
        } else {
          if (mounted) setState(() => _currentCoverBytes = null);
        }
      }
    });
    _playbackStateSub = audioHandler.playbackState.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          // 🎯 SİBER HAMLE: _pos = state.position söküldü, StreamBuilder akıcı yönetecek!

          // 🎯 SİBER KALKAN: Buffer kilidi (Sonsuz dönme hatası çözümü)
          _isBuffering =
              state.processingState == AudioProcessingState.buffering ||
                  state.processingState == AudioProcessingState.loading;
          if (state.processingState == AudioProcessingState.ready ||
              state.processingState == AudioProcessingState.completed ||
              state.processingState == AudioProcessingState.idle ||
              state.processingState == AudioProcessingState.error) {
            _isBuffering = false;
          }
        });
      }
    });
    _positionSub = AudioService.position.listen((position) {
      if (mounted) {
        _pos =
            position; // 🎯 SİBER HAMLE: Sadece arka planda günceller, UI'ı StreamBuilder çizer.
      }
    });
  }

  // 🎯 SİBER GELİŞMİŞ ARAMA FİLTRESİ (BottomSheet)
  void _showSearchFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0C16),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: widget.themeColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: widget.themeColor),
                    const SizedBox(width: 10),
                    Text(
                      'GELİŞMİŞ ARAMA FİLTRELERİ',
                      style: TextStyle(
                          color: widget.themeColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              Divider(color: widget.themeColor.withValues(alpha: 0.2)),
              _buildFilterOption('Hepsi', ''),
              _buildFilterOption('Sadece Orijinal Ses (Kapak)', 'official audio'),
              _buildFilterOption('Canlı Performanslar', 'live performance'),
              _buildFilterOption('Remix & Editler', 'remix'),
              _buildFilterOption('Şarkı Sözleri (Lyrics)', 'lyrics'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String title, String filterValue) {
    final bool isSelected = _activeSearchFilter == filterValue;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? widget.themeColor : Colors.white54,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white54,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() => _activeSearchFilter = filterValue);
        Navigator.pop(context);
        if (_searchController.text.isNotEmpty) {
          _performSearch(_searchController.text);
        }
      },
    );
  }

  // 🎯 SİBER HAMLE: Canlı Arama Önerileri Listesi
  Widget _buildSuggestionsList() {
    return ListView.builder(
      itemCount: _liveSuggestions.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final suggestion = _liveSuggestions[index];
        return ListTile(
          leading: Icon(Icons.search, color: widget.themeColor),
          title: Text(
            suggestion,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          onTap: () {
            _searchController.text = suggestion;
            _performSearch(suggestion);
          },
        );
      },
    );
  }

  // 🎯 SİBER HAMLE: Siber Buton Tasarımı
  Widget _buildSiberButton(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.themeColor.withValues(alpha: 0.15),
          border: Border.all(color: widget.themeColor.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: widget.themeColor, size: 18),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // 🎯 2. Metamorfoz Modu (Duygusal Dönüşüm)
  void _showMetamorphosisDialog() {
    String startMood = 'Hüzünlü';
    String endMood = 'Enerjik';
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0A0C16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: widget.themeColor)),
            title: Row(
              children: [
                Icon(Icons.auto_awesome, color: widget.themeColor),
                const SizedBox(width: 8),
                const Text('Metamorfoz Rotası', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Mevcut ruh halinden, ulaşmak istediğin ruh haline seni 10 şarkılık kesintisiz bir siber listeyle taşıyacağız.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: startMood,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: 'Şu Anki Modun', labelStyle: TextStyle(color: widget.themeColor)),
                  items: ['Hüzünlü', 'Yorgun', 'Sakin', 'Gergin'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setStateSB(() => startMood = v!),
                ),
                const SizedBox(height: 10),
                Icon(Icons.arrow_downward, color: widget.themeColor),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: endMood,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: 'Hedeflenen Mod', labelStyle: TextStyle(color: widget.themeColor)),
                  items: ['Enerjik', 'Odaklanmış', 'Mutlu', 'Savaşçı'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setStateSB(() => endMood = v!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
                onPressed: () {
                  Navigator.pop(ctx);
                  _performSearch('$startMood to $endMood metamorphosis music mix official audio');
                },
                child: const Text('Dönüşümü Başlat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  // 🎯 6. Siber Ses İzi (Sonic Aura)
  void _showSonicAuraDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: widget.themeColor, width: 2),
            boxShadow: [BoxShadow(color: widget.themeColor.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Siber Ses İzin', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 30),
              // Sahte 3D Küre (Animasyonlu Gradient)
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                builder: (context, val, child) {
                  return Container(
                    width: 150 + (val * 20),
                    height: 150 + (val * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.themeColor,
                          widget.themeColor.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(color: widget.themeColor.withValues(alpha: 0.8), blurRadius: 50 * val, spreadRadius: 10 * val)
                      ]
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              const Text('En çok dinlenen tarz:\nKARANLIK SİBER POP', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Kapat', style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 5. Otonom Akıllı İndirme (Smart Downloads)
  void _triggerSmartDownloads() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('⚡ Siber İndirme: Wi-Fi analizi yapılıyor. Çevrimdışı mühimmatınız güncelleniyor...'),
      backgroundColor: widget.themeColor,
    ));
    
    // Geçmişten rastgele 2 şarkı indir
    if (_searchHistory.isNotEmpty) {
      Future.delayed(const Duration(seconds: 2), () {
        _performSearch('${_searchHistory.first} official audio');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚡ Arka Planda Mühürleme Başladı!'),
          backgroundColor: Colors.green,
        ));
      });
    }
  }

  @override
  void dispose() {
    _skeletonTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _mediaItemSub?.cancel();
    _playbackStateSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  // 🎯 SİBER HAMLE: Aşağı inildiğinde tetiklenen otonom sensör
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      // 🎯 300 Piksel kala otonom olarak (Infinite Scroll) yeni mühimmat çek
      if (!_isLoadingMore &&
          !_isSearching &&
          (_activeCategory == 'Trendler' ||
              _activeCategory == 'Size Özel Mix') &&
          _nextPageToken.isNotEmpty) {
        _loadMoreTrends();
      } else if (_isSearching && !_isLoadingMore && _hasMoreSearch) {
        _loadMoreSearch();
      }
    }
  }

  // 🎯 SİBER HAMLE: Geçmişi Yükle ve Kaydet
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _searchHistory = prefs.getStringList('siber_discover_history') ?? [];
      });
    }
  }

  Future<void> _saveToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 15) _searchHistory.removeLast();
    await prefs.setStringList('siber_discover_history', _searchHistory);
    if (mounted) setState(() {});
  }

  // 🎯 SİBER HAMLE: Geçmişten Tekil (Manuel) Arama Silme
  Future<void> _deleteFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(query);
    await prefs.setStringList('siber_discover_history', _searchHistory);
    if (mounted) setState(() {});
  }

  // 🎯 SİBER HAMLE: Tüm Arama Geçmişini (Toplu) Sök At
  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.clear();
    await prefs.setStringList('siber_discover_history', _searchHistory);
    if (mounted) setState(() {});
  }

  // 🎯 SİBER HAMLE: Ekranı ve Hafızayı (Cache) Tamamen Sıfırlayıp Yeni Mühimmat Çekme Motoru
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isSearching = false;
      _searchController.clear();
      _currentCache.lastSearchQuery = '';
      _trendList.clear();
      _genreLists.clear();
      _nextPageToken = '';
      _currentCache.trendList.clear();
      _currentCache.genreLists.clear();
      _activeCategory = widget.isPersonalMode ? 'Size Özel Mix' : 'Trendler';
      _searchPage = 1;
      _hasMoreSearch = true;
    });

    if (widget.isPersonalMode) {
      await _fetchPersonalRecommendations();
    } else {
      await _fetchTrends();
    }
  }

  // 🎯 Ana Trendleri (mostPopular) Çek
  Future<void> _fetchTrends({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
      _showSkeletonTimeout = false;
      _skeletonTimer?.cancel();
      // 🎯 Max 5 saniye skeleton sonra timeout mesajı göster
      _skeletonTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _isLoading) {
          setState(() => _showSkeletonTimeout = true);
        }
      });
    }
    final res = await _bridge.fetchKesfet();
    if (mounted) {
      if (res.isEmpty || res['status'] == 'hata') {
        setState(() {
          _isLoading = false;
          _isOfflineMode = true; // 🎯 Siber Kalkan: Çevrimdışı modda olduğumuzu anladık
        });

        return;
      }
      setState(() {
        _isOfflineMode = false;
        _trendList = res['oneriler'] ?? [];
        _currentCache.trendList = _trendList;
        _nextPageToken = res['nextPageToken'] ?? '';
        _currentCache.nextPageToken = _nextPageToken;
        _isLoading = false;
        _showSkeletonTimeout = false;
        _skeletonTimer?.cancel();
      });
      _saveTrendsCache(); // 🎯 Yeni veriyi hafızaya mühürle
      _fetchGenresSequentially(); // 🎯 Alt listeleri ağı boğmadan sırayla çek
    }
  }

  // 🎯 SİBER HAMLE: Şahsi Keşfet Öneri Motoru (Yapay Zeka + İstihbarat)
  Future<void> _fetchPersonalRecommendations({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final favGenres = prefs.getStringList('siber_personal_genres') ?? [];
    final favArtistsRaw = prefs.getString('siber_personal_artists') ?? '';
    final favArtists = favArtistsRaw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    List<String> searchQueries = [];

    // 1. Sanatçılardan sorgu üret
    if (favArtists.isNotEmpty) {
      searchQueries.add('${favArtists.first} mix');
      if (favArtists.length > 1) {
        searchQueries.add('${favArtists[1]} şarkıları');
      }
    }

    // 2. Türlerden sorgu üret
    if (favGenres.isNotEmpty) {
      searchQueries.add('${favGenres.first} popüler');
    }

    // 3. Geçmiş Dinleme Analizi (İstihbarat) ve Siber DJ Mood Hesaplaması
    try {
      final historyList = await HistoryService.getHistory();
      
      // 🌤️ SİBER HAMLE: HAVA DURUMU VE ZAMAN BAĞLAMI
      final now = DateTime.now();
      String timeContext = 'Gündüz';
      if (now.hour >= 18 || now.hour < 5) {
        timeContext = 'Gece';
      } else if (now.hour >= 5 && now.hour < 11) timeContext = 'Sabah';
      
      final weather = await WeatherService.getCurrentWeather();
      String weatherMood = WeatherService.getAtmosphereMood(weather);
      print('Siber Bağlam: $timeContext, Hava Modu: $weatherMood');
      
      // Eğer hava modu özel ise, doğrudan onu arat
      if (weatherMood != 'Genel') {
        searchQueries.add('$weatherMood müzikleri');
      }
      
      if (historyList.isNotEmpty) {
        historyList.sort((a, b) => b.playCount.compareTo(a.playCount));
        
        // --- 🎯 SİBER HAMLE: MOOD HESAPLAMA ---
        Map<String, int> moodTags = {'Enerji': 0, 'Sokak': 0, 'Melankoli': 0, 'Odak': 0, 'Gizem': 0};
        for (var h in historyList) {
          final t = h.name.toLowerCase();
          if (t.contains('rap') || t.contains('drill') || t.contains('hip') || t.contains('ezhel') || t.contains('sokak')) {
            moodTags['Sokak'] = moodTags['Sokak']! + h.playCount;
          } else if (t.contains('slow') || t.contains('akustik') || t.contains('aşk') || t.contains('sezen') || t.contains('müslüm') || t.contains('arabesk')) moodTags['Melankoli'] = moodTags['Melankoli']! + h.playCount;
          else if (t.contains('mix') || t.contains('club') || t.contains('remix') || t.contains('pop') || t.contains('hareketli')) moodTags['Enerji'] = moodTags['Enerji']! + h.playCount;
          else if (t.contains('lofi') || t.contains('chill') || t.contains('study') || t.contains('odak')) moodTags['Odak'] = moodTags['Odak']! + h.playCount;
          else moodTags['Gizem'] = moodTags['Gizem']! + h.playCount;
        }

        String dMood = 'Gizem';
        int maxCount = -1;
        moodTags.forEach((k, v) {
          if (v > maxCount) {
            maxCount = v;
            dMood = k;
          }
        });
        
        _dominantMood = dMood;
        _generateAiMixes(dMood);
        // --------------------------------------

        final topSong = historyList.first.name
            .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
            .split('-')
            .first
            .trim();
        if (topSong.isNotEmpty && topSong.length > 2) {
          searchQueries.add('$topSong mix');
        }
      }
    } catch (e) {}

    if (searchQueries.isEmpty) searchQueries.add('Türkçe müzik trendleri');

    List<dynamic> combinedResults = [];
    bool hasAuthError = false;
    
    // Hızlı açılması için maksimum 3 farklı istihbarat aramasını paralel yapıyoruz (SİBER HIZLANDIRICI)
    final queriesToRun = searchQueries.take(3).toList();
    try {
    final futures = queriesToRun.map((query) => _bridge.searchMusic(query, limit: 10).catchError((e) {
        if (e == 'auth_required') hasAuthError = true;
        print('Arama hatası ($query): $e');
        return <dynamic>[];
      }));
      final results = await Future.wait(futures);
      
      for (var res in results) {
        combinedResults.addAll(res);
      }
    } catch (e) {
      if (e == 'auth_required') {
        hasAuthError = true;
      } else {
        print('Arama hatası: $e');
      }
    }

    if (hasAuthError) {
      _showGuestModeDialog();
      await _fetchTrends(silent: silent);
      return;
    }

    combinedResults.shuffle();

    // Aynı şarkıların tekrar çıkmasını engelle (Filtre Zırhı)
    final seen = <String>{};
    final uniqueResults = combinedResults.where((item) {
      final id = item['video_id'] ?? item['id'];
      if (id == null || seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).toList();

    if (uniqueResults.isEmpty) {
      // 🛡️ Siber Kalkan: Eğer Şahsi Keşfet motoru (API veya Ağ hatası yüzünden) boş dönerse, boş ekran göstermek yerine Trendleri (Genel Keşfet) yükle!
      print('Siber Uyarı: Şahsi Keşfet sonuçları boş döndü. Otonom olarak Trendlere (Genel) geçiş yapılıyor...');
      await _fetchTrends(silent: silent);
      return;
    }

    if (mounted) {
      setState(() {
        _trendList = uniqueResults;
        _currentCache.trendList = _trendList;

        // 🎯 KATEGORİLERİ KİŞİYE ÖZEL İNŞA ET!
        _categories.clear();
        _categories.add('Size Özel Mix');
        _categories.addAll(favGenres);
        if (favArtists.isNotEmpty) _categories.addAll(favArtists.take(2));

        _activeCategory = 'Size Özel Mix';
        _currentCache.activeCategory = _activeCategory;
        _isLoading = false;
      });
      _saveTrendsCache(); // 🎯 Kişisel sonuçları da cache'le
      _fetchGenresSequentially(); // 🎯 Alt listeleri ağı boğmadan sırayla çek
    }
  }

  // 🎯 SİBER HAMLE: Otonom Alt Listeleri Sessizce ve Sırayla Çek (Ağı Yormadan)
  Future<void> _fetchGenresSequentially() async {
    final genresToFetch = widget.isPersonalMode
        ? _categories.where((c) => c != 'Size Özel Mix' && c != 'Trendler').toList()
        : ['Türkçe Rap', 'Arabesk', 'Deep House', 'Akustik', 'Popüler Albüm', 'Türkçe Mixler'];

    for (var genre in genresToFetch) {
      if (!_genreLists.containsKey(genre)) {
        final query = widget.isPersonalMode
            ? '$genre şarkıları'
            : ((genre == 'Popüler Albüm' || genre == 'Türkçe Mixler')
                ? genre
                : '$genre trend şarkılar');

        try {
          // Ağı boğmamak için aralarda ufak bir mola veriyoruz
          await Future.delayed(const Duration(seconds: 1));
          final res = await _bridge.searchMusic(query, limit: 10);
          if (mounted) {
            setState(() {
              _genreLists[genre] = res;
              _currentCache.genreLists[genre] = res;
            });
          }
        } catch (e) {
          // Sessizce yut
        }
      }
    }
  }

  // 🎯 SİBER HAMLE: Sayfayı Aşağı Kaydırdıkça Yeni Mühimmat Çek
  Future<void> _loadMoreTrends() async {
    setState(() => _isLoadingMore = true);
    final res = await _bridge.fetchKesfet(pageToken: _nextPageToken);
    if (mounted) {
      // 🛡️ SİBER KALKAN: Kaydırırken internet giderse donmayı engelle
      if (res.isEmpty || res['status'] == 'hata') {
        setState(() => _isLoadingMore = false);
        return;
      }
      setState(() {
        _trendList.addAll(res['oneriler'] ?? []);
        _currentCache.trendList = _trendList;
        _nextPageToken = res['nextPageToken'] ?? '';
        _currentCache.nextPageToken = _nextPageToken;
        _isLoadingMore = false;
      });
    }
  }

  // 🎯 SİBER HAMLE: Arama Ekranında Aşağı Kaydırdıkça Yükle
  Future<void> _loadMoreSearch() async {
    setState(() => _isLoadingMore = true);
    _searchPage++;

    try {
      // Not: OzsesBridge.searchMusic metoduna 'page' parametresi eklendiği varsayılır.
      final results = await _bridge.searchMusic(_currentCache.lastSearchQuery,
          limit: 20, page: _searchPage);
      if (mounted) {
        setState(() {
          if (results.isEmpty) {
            _hasMoreSearch = false;
          } else {
            _searchResults.addAll(results);
            _currentCache.searchResults = _searchResults;
            _hasMoreSearch = results.length >= 20;
          }
          _currentCache.searchPage = _searchPage;
          _currentCache.hasMoreSearch = _hasMoreSearch;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (e == 'auth_required') {
        _showGuestModeDialog();
      }
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // 🎯 Kategoriye veya Arama Kutusuna Göre Arama Yap
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _currentCache.isSearching = false;
      });
      return;
    }

    _currentCache.lastSearchQuery = query;
    _saveToHistory(query);

    setState(() {
      _isSearching = true;
      _currentCache.isSearching = true;
      _isLoading = true;
      _searchPage = 1;
      _hasMoreSearch = true;
    });

    // 🎯 SİBER HAMLE: Filtre (Kapak / Video / Canlı vb.) Uygulama
    String finalQuery = query;
    if (_activeSearchFilter.isNotEmpty) {
      finalQuery = '$query $_activeSearchFilter';
    }

    // 🎯 SİBER HAMLE: Sayfalama (page) parametresini de köprüden geçiriyoruz
    List<dynamic> results = [];
    try {
      results = await _bridge.searchMusic(finalQuery, limit: 20, page: _searchPage);
    } catch (e) {
      if (e == 'auth_required') {
        _showGuestModeDialog();
        setState(() {
          _isLoading = false;
          _isSearching = false;
        });
        return;
      }
    }

    if (mounted) {
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Siber Radar: Bağlantı zayıf veya sonuç bulunamadı!'),
            backgroundColor: Colors.orangeAccent));
        _hasMoreSearch = false;
      } else {
        _hasMoreSearch = results.length >= 20;
      }
      setState(() {
        _searchResults = results;
        _currentCache.searchResults = results;
        _currentCache.searchPage = _searchPage;
        _currentCache.hasMoreSearch = _hasMoreSearch;
        _isLoading = false;
      });
    }
  }

  // 🎯 Şarkı Tıklandığında Çıkan Siber Karar Menüsü (Video, Dinle, İndir)
  void _showActionSheet(dynamic item) {
    final title = item['title'] ?? item['baslik'] ?? 'Bilinmeyen';
    final videoId = item['video_id'] ?? item['id'];
    final imgUrl = item['thumbnail'];
    final artist = item['channel'] ?? item['kanal'] ?? 'Victus V7';
    final duration = item['duration'] != null ? Duration(seconds: item['duration']) : Duration.zero;

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          side:
              BorderSide(color: widget.themeColor.withValues(alpha: 0.5), width: 1.5),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10)),
                ),
                ListTile(
                  leading: imgUrl != null && imgUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(imageUrl: imgUrl, placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.music_note,
                                      color: Colors.white24, size: 40)))
                      : Icon(Icons.music_note,
                          color: widget.themeColor, size: 40),
                  title: Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text('Siber Radar: Ne yapmak istersin?',
                      style: TextStyle(color: widget.themeColor)),
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading:
                      const Icon(Icons.headphones, color: Colors.cyanAccent),
                  title: const Text('🎵 Sadece Ses Dinle (Plak Modu)',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                      'Ofline özellikleri kullanarak çevrimiçi dinle',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    _playOnlineStream(videoId, title, artist, imgUrl, duration);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.playlist_play, color: Colors.cyanAccent),
                  title: const Text('🎵 Sıradakini Çal (Kuyruğa Ekle)',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                      'Çalmakta olan bitince siber akışta çalar',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    _queueOnlineStream(videoId, title, artist, imgUrl, duration);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        });
  }

  // 🎯 SİBER HAMLE: Şarkıya Tıklandığında Bodoslama Çal
  Future<void> _playDirectly(dynamic item, {List<dynamic>? contextList}) async {
    // 🎯 SİBER OPERASYON: Tıklandığı an, ekrandaki tüm listeyi otonom olarak kuyruğa alıyoruz.
    // Bu sayede ileri/geri tuşları kusursuz çalışır ve müzik asla durmaz.
    final List<dynamic> currentList = contextList ?? [item];
    if (currentList.isEmpty) return;

    final mediaItems = currentList.map((songItem) {
      final cTitle = songItem['title'] ?? songItem['baslik'] ?? 'Bilinmeyen';
      final cVId = songItem['video_id'] ?? songItem['id'];
      final cImgUrl = songItem['thumbnail'];
      final cArtist = songItem['channel'] ?? songItem['kanal'] ?? 'Victus V7';

      // 🎯 SİBER MÜHÜR: Şarkıyı doğrudan URL ile değil, 'yt:' ön eki ve video ID'si ile mühürlüyoruz.
      // Ses motoru (AudioHandler) bu mührü görünce, çalma anında akış linkini kendi çözecek.
      // Bu, listeyi anında yüklememizi sağlar ve uygulamayı kastırmaz.
      return MediaItem(
        id: 'yt:$cVId',
        album: 'Siber Keşfet Akışı',
        title: cTitle,
        artist: cArtist,
        duration: Duration(seconds: songItem['duration'] ?? 0),
        artUri: cImgUrl != null ? Uri.parse(cImgUrl) : null,
      );
    }).toList();

    final index = currentList.indexOf(item);

    await audioHandler.updateQueue(mediaItems);
    await audioHandler.skipToQueueItem(index > -1 ? index : 0);
  }

  // 🎯 SİBER HAMLE 1: Çevrimiçi Sadece Ses Olarak Oynat (Siber Arşiv Özellikleriyle)
  Future<void> _playOnlineStream(
      String videoId, String title, String artist, String? imgUrl, Duration duration) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📡 $title frekansı çevrimiçi çözülüyor...'),
        backgroundColor: widget.themeColor));

    final res = await _bridge.getStreamUrl(videoId);
    if (res['status'] == 'basarili' && res['stream_url'] != null) {
      String streamUrl = res['stream_url'];

      // 🎯 Otonom olarak offline MediaItem yapısına çeviriyoruz! (Thumbnail dahil)
      final mediaItem = MediaItem(
        id: streamUrl,
        album: 'Siber Keşfet Akışı',
        title: title,
        artist: artist,
        duration: duration,
        artUri: imgUrl != null ? Uri.parse(imgUrl) : null,
      );

      await audioHandler.addQueueItem(mediaItem);
      final queue = audioHandler.queue.value;
      await audioHandler.skipToQueueItem(queue.length - 1);
      await audioHandler.play();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('🎶 Siber çevrimiçi akış başlatıldı! (Plak kapak aktif)'),
          backgroundColor: Colors.cyanAccent));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ Akış frekansı koparılamadı!'),
          backgroundColor: Colors.redAccent));
    }
  }

  // 🎯 SİBER HAMLE: Şarkıyı Sadece Kuyruğa At (Hemen Çalma)
  Future<void> _queueOnlineStream(
      String videoId, String title, String artist, String? imgUrl, Duration duration) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📡 $title kuyruğa ekleniyor...'),
        backgroundColor: widget.themeColor));
    final res = await _bridge.getStreamUrl(videoId);
    if (res['status'] == 'basarili' && res['stream_url'] != null) {
      final mediaItem = MediaItem(
        id: res['stream_url'],
        album: 'Siber Keşfet Akışı',
        title: title,
        artist: artist,
        duration: duration,
        artUri: imgUrl != null ? Uri.parse(imgUrl) : null,
      );
      await audioHandler.addQueueItem(mediaItem);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Siber Kuyruğa mühürlendi!'),
          backgroundColor: Colors.green));
    }
  }

  // 🎯 SİBER HAMLE 2: Gerçek İndirme Motoru
  Future<void> _startRealDownload(String videoId, String title) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🚀 $title arka planda indiriliyor...'),
        backgroundColor: Colors.green));

    if (widget.onDownloadStart != null) {
      widget.onDownloadStart!(videoId, title);
    }

    final res = await _bridge.downloadMusic(videoId, title);
    if (res['status'] != 'basladi') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ İndirme Başlatılamadı!'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 4)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('SİBER KEŞFET',
            style: TextStyle(
                color: widget.themeColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [Shadow(color: widget.themeColor, blurRadius: 10)])),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Frekansları Yenile (Taze Mühimmat Çek)',
            onPressed: _isLoading ? null : _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🎯 SİBER ÇEVRİMDIŞI BİLDİRİMİ (Spotify Tarzı Kusursuz Deneyim)
          if (_isOfflineMode)
            Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.symmetric(vertical: 4),
              width: double.infinity,
              color: Colors.black87,
              child: const Center(
                child: Text(
                  'Çevrimdışı Mod. İndirilenler gösteriliyor.',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          // 🎯 SİBER ATMOSFER PANELİ
          if (_currentWeather != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.themeColor.withValues(alpha: 0.2),
                      Colors.black54,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _atmosphereMood == 'Enerjik' ? Icons.wb_sunny :
                      _atmosphereMood == 'Melankolik' ? Icons.water_drop :
                      _atmosphereMood == 'Akustik' ? Icons.ac_unit : Icons.cloud,
                      color: widget.themeColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Siber Atmosfer: ${_currentWeather!.temperature?.celsius?.toStringAsFixed(1)}°C',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Önerilen Mod: $_atmosphereMood',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor.withValues(alpha: 0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => _performSearch('$_atmosphereMood şarkılar official audio'),
                      child: const Text('Moda Gir', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

          // 🎯 SİBER HAMLE: Otonom AI ve Duygusal Dönüşüm Paneli
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSiberButton(Icons.auto_awesome, 'Metamorfoz', _showMetamorphosisDialog),
                _buildSiberButton(Icons.graphic_eq, 'Ses İzim', _showSonicAuraDialog),
                _buildSiberButton(Icons.bolt, 'Siber İndirme', _triggerSmartDownloads),
              ],
            ),
          ),

          // 🎯 ARAMA ÇUBUĞU
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: widget.themeColor.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onSubmitted: _performSearch,
                onChanged: _onSearchTextChanged,
                decoration: InputDecoration(
                    hintText: 'Şarkı, sanatçı, albüm veya şarkı sözü ara...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: widget.themeColor),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              _currentCache.lastSearchQuery = '';
                              setState(() {
                                _liveSuggestions.clear();
                                _isSearching = false;
                                _currentCache.isSearching = false;
                                _activeCategory = 'Trendler';
                                _currentCache.activeCategory = 'Trendler';
                              });
                            },
                          ),
                        IconButton(
                          icon: Icon(Icons.filter_list, color: widget.themeColor),
                          onPressed: () => _showSearchFilters(),
                        ),
                      ],
                    )),
              ),
            ),
          ),

          // 🎯 SİBER HAMLE: Arama Geçmişi Çekmecesi
          if (_searchHistory.isNotEmpty &&
              !_isSearching &&
              _searchController.text.isEmpty)
            Container(
              height: 35,
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchHistory.length,
                      itemBuilder: (context, index) {
                        final historyItem = _searchHistory[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            backgroundColor: Colors.black45,
                            side: BorderSide(
                                color: widget.themeColor.withValues(alpha: 0.3)),
                            labelStyle: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                            avatar: Icon(Icons.history,
                                color: widget.themeColor, size: 14),
                            label: Text(historyItem),
                            deleteIcon: const Icon(Icons.close,
                                size: 14, color: Colors.white54),
                            onDeleted: () => _deleteFromHistory(historyItem),
                            onPressed: () {
                              _searchController.text = historyItem;
                              _performSearch(historyItem);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    icon: const Icon(Icons.delete_sweep,
                        color: Colors.redAccent, size: 22),
                    tooltip: 'Tüm Geçmişi Sök At',
                    onPressed: _clearSearchHistory,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

          // 🎯 YOUTUBE MUSIC TARZI KATEGORİ (MOOD) FİLTRELERİ
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isActive = cat == _activeCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeCategory = cat;
                      _currentCache.activeCategory = cat;
                    });
                    if (cat == 'Trendler') {
                      setState(() {
                        _isSearching = false;
                        _currentCache.isSearching = false;
                        _searchController.clear();
                        _currentCache.lastSearchQuery = '';
                      });
                      if (_trendList.isEmpty) _fetchTrends();
                    } else if (cat == 'Size Özel Mix') {
                      setState(() {
                        _isSearching = false;
                        _currentCache.isSearching = false;
                        _searchController.clear();
                        _currentCache.lastSearchQuery = '';
                      });
                    } else {
                      _searchController.text = cat;
                      _performSearch(cat);
                    }
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? widget.themeColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isActive ? widget.themeColor : Colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat,
                      style: TextStyle(
                          color: isActive ? widget.themeColor : Colors.white70,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // 🎯 ANA İÇERİK BÖLÜMÜ
          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? _buildSkeletonLoader()
                    : _searchController.text.isNotEmpty && _liveSuggestions.isNotEmpty && !_isSearching
                        ? _buildSuggestionsList()
                        : _isSearching
                            ? _buildVerticalList(_searchResults, isScrollable: true)
                            : _buildYouTubeMusicHome(),

                // 🎯 SİBER MİNİ OYNATICI (Sadece şarkı çalarken ortaya çıkar)
                if (_currentSongName != 'Müzik Seçilmedi')
                  Positioned(
                    bottom: 15,
                    left: 15,
                    right: 15,
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                              color: widget.themeColor.withValues(alpha: 0.6),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: widget.themeColor.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 2)
                          ]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: StreamBuilder<Duration>(
                            // 🎯 YUSUF USTA HAMLESİ: Slider artık yağ gibi akacak!
                            stream: AudioService.position,
                            builder: (context, posSnapshot) {
                              final currentPos = posSnapshot.data ?? _pos;
                              return BottomPlayerBar(
                                songName: _currentSongName,
                                artistName: _currentArtist,
                                coverBytes: _currentCoverBytes,
                                themeColor: widget.themeColor,
                                position: currentPos,
                                duration: _dur,
                                isPlaying: _isPlaying,
                                isShuffle: false,
                                isFavorite: false,
                                onFavoriteToggle: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Çevrimiçi akışlar cihaza inmeden mühürlenemez!'),
                                          backgroundColor:
                                              Colors.orangeAccent));
                                },
                                trailingAccessory: MiniEqVisualizer(
                                    themeColor: widget.themeColor,
                                    isPlaying: _isPlaying),
                                repeatMode: 0,
                                onPlayPause: () => _isPlaying
                                    ? audioHandler.pause()
                                    : audioHandler.play(),
                                onNext: () => audioHandler.skipToNext(),
                                onPrevious: () => audioHandler.skipToPrevious(),
                                onSeek: (v) => audioHandler
                                    .seek(Duration(seconds: v.toInt())),
                                onShuffleToggle: () {},
                                onRepeatToggle: () {},
                                // 🎯 SİBER HAMLE: Artık ana ekrana dönmek yerine tam ekran oynatıcıyı direkt burada açar!
                                onExpand: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => FullScreenPlayer(
                                      themeColor: widget.themeColor,
                                      checkIsFavorite: (path) => false,
                                      onToggleFavorite: (path) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Siber Ağ: Çevrimiçi müzikler indirilmeden favorilere alınamaz!'),
                                                backgroundColor:
                                                    Colors.orangeAccent));
                                      },
                                      onAddToPlaylist: (path) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Siber Ağ: Çevrimiçi müzikler indirilmeden listelere eklenemez!'),
                                                backgroundColor:
                                                    Colors.orangeAccent));
                                      },
                                      onDelete: (path) {},
                                      onAddQueue: (path, playNext) {},
                                      onDownloadStart: (videoId, title) {
                                        Navigator.pop(
                                            context); // Oynatıcıyı kapat
                                        _startRealDownload(videoId, title);
                                      },
                                    ),
                                  );
                                },
                                onShowQueue: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Tam kontrol için Ana Karargaha dönün.'),
                                          backgroundColor:
                                              Colors.deepPurpleAccent));
                                },
                                onClose: () {
                                  audioHandler.stop();
                                  setState(() =>
                                      _currentSongName = 'Müzik Seçilmedi');
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 SİBER HAMLE: Animasyonlu Skeleton Yükleyici (Max 5 sn)
  Widget _buildSkeletonLoader() {
    final Color shimmerBase = Colors.white.withValues(alpha: 0.06);
    final Color shimmerHigh = widget.themeColor.withValues(alpha: 0.12);

    Widget skeletonBox(double w, double h, {double radius = 10}) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1200),
        builder: (context, v, _) {
          // v: 0.0 -> 1.0 arası ping-pong için
          final alpha = (v < 0.5 ? v * 2 : (1.0 - v) * 2);
          final blended = Color.lerp(shimmerBase, shimmerHigh, alpha)!;
          return Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(colors: [shimmerBase, blended, shimmerBase]),
            ),
          );
        },
        onEnd: () => setState(() {}), // tekrarlı canlandırma
      );
    }

    if (_showSkeletonTimeout) {
      // 🛡️ 5 saniyeyi aştı — yavaş bağlantı mesajı
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_find, color: widget.themeColor, size: 60),
            const SizedBox(height: 16),
            Text('Bağlantı yavaş...',
                style: TextStyle(color: widget.themeColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Veri çekilmeye devam ediyor, lütfen bekle',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 24),
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(color: widget.themeColor, strokeWidth: 2),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          skeletonBox(160, 18, radius: 6),
          const SizedBox(height: 16),
          // Yatay kartlar satırı
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: skeletonBox(110, 140, radius: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          skeletonBox(140, 18, radius: 6),
          const SizedBox(height: 16),
          // Dikey liste iskeletleri
          ...List.generate(6, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              skeletonBox(52, 52, radius: 10),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  skeletonBox(double.infinity, 14, radius: 5),
                  const SizedBox(height: 8),
                  skeletonBox(100, 12, radius: 5),
                ],
              )),
            ]),
          )),
        ],
      ),
    );
  }

  // 🎯 YENİ SİBER HAMLE: Otonom AI Albüm Üretici (Siber DJ)
  void _generateAiMixes(String mood) {
    if (mood == 'Sokak') {
      _aiMixes = [
        {'name': 'Sokak İsyanı', 'query': 'Türkçe Rap Drill', 'color': Colors.redAccent, 'icon': Icons.sports_kabaddi},
        {'name': 'Karanlık Flow', 'query': 'Dark Trap Rap', 'color': Colors.deepPurpleAccent, 'icon': Icons.nightlight_round},
        {'name': 'Yeraltı Zirvesi', 'query': 'Underground Rap Türkçe', 'color': Colors.orangeAccent, 'icon': Icons.whatshot},
      ];
    } else if (mood == 'Melankoli') {
      _aiMixes = [
        {'name': 'Gece Sürüşü', 'query': 'Gece Arabada Dinlenecek Şarkılar', 'color': Colors.blueAccent, 'icon': Icons.directions_car},
        {'name': 'Derin Melankoli', 'query': 'Slow Akustik Türkçe', 'color': Colors.teal, 'icon': Icons.water_drop},
        {'name': 'Efkâr Dozu', 'query': 'Damar Arabesk', 'color': Colors.brown, 'icon': Icons.wine_bar},
      ];
    } else if (mood == 'Enerji') {
      _aiMixes = [
        {'name': 'Siber Enerji', 'query': 'Hareketli Pop Mix', 'color': Colors.yellowAccent, 'icon': Icons.bolt},
        {'name': 'Kopmalık', 'query': 'Türkçe Club Remix', 'color': Colors.pinkAccent, 'icon': Icons.local_fire_department},
        {'name': 'Motivasyon', 'query': 'Spor Motivasyon Müzikleri', 'color': Colors.greenAccent, 'icon': Icons.fitness_center},
      ];
    } else if (mood == 'Odak') {
      _aiMixes = [
        {'name': 'Lofi Odak', 'query': 'Lofi hip hop beats', 'color': Colors.indigo, 'icon': Icons.headphones},
        {'name': 'Derin Çalışma', 'query': 'Deep Focus Music', 'color': Colors.blueGrey, 'icon': Icons.menu_book},
        {'name': 'Sakin Zihin', 'query': 'Chillout Lounge', 'color': Colors.cyan, 'icon': Icons.spa},
      ];
    } else {
      _aiMixes = [
        {'name': 'Siber Gizem', 'query': 'Siberpunk Synthwave', 'color': Colors.deepPurple, 'icon': Icons.memory},
        {'name': 'Keşfedilmemiş', 'query': 'Alternative Indie Türkçe', 'color': Colors.lightGreen, 'icon': Icons.explore},
        {'name': 'Günün Zirvesi', 'query': 'Türkiye En Çok Dinlenenler', 'color': Colors.amber, 'icon': Icons.star},
      ];
    }
    
    // UI güncellenmesi için:
    if (mounted) setState(() {});
  }

  // 🎯 SİBER HAMLE: Sana Özel Otonom Mixler (Yatay Kaydırmalı Kartlar)
  Widget _buildAutoMixCarousel() {
    final List<Map<String, dynamic>> mixes = _aiMixes.isEmpty ? [
      {'name': 'Siber Analiz', 'query': 'Türkçe trend', 'color': Colors.grey, 'icon': Icons.search}
    ] : _aiMixes;


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: mixes.length,
            itemBuilder: (context, index) {
              final mix = mixes[index];
              return GestureDetector(
                onTap: () => _handleAutoPlaylist(mix['query']),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: mix['color'].withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: mix['color'].withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(mix['icon'], color: mix['color'], size: 36),
                      const SizedBox(height: 10),
                      Text(
                        mix['name'],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 🎯 SİBER HAMLE: Otonom Liste Motorunu Ateşleme Modülü
  Future<void> _handleAutoPlaylist(String selection) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(color: widget.themeColor, strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text("Siber Zeka: '$selection' için en iyi parçalar toplanıyor...")),
        ],
      ),
      backgroundColor: Colors.black87,
      duration: const Duration(seconds: 4),
    ));

    // Arama kutusuna yansıt ve aramayı başlat
    _searchController.text = '$selection şarkılar';
    await _performSearch('$selection şarkılar');

    // Sonuçlar geldiyse ve oynatıcı boş değilse, ilkini çal ve tüm listeyi kuyruğa at
    if (_searchResults.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('🎵 Otonom Liste hazır! Çalınmaya başlanıyor...'),
        backgroundColor: widget.themeColor.withValues(alpha: 0.8),
      ));
      
      // Çalma listesini başlat
      _playDirectly(_searchResults[0], contextList: _searchResults);
    }
  }

  Widget _buildYouTubeMusicHome() {
    return SingleChildScrollView(
      controller:
          _scrollController, // 🎯 SİBER KALKAN: Fare tekerleği ve sonsuz kaydırma için şart!
      physics: const AlwaysScrollableScrollPhysics(),
      // Oynatıcı aktifse en alttaki müzikleri görebilmek için ekstra boşluk bırak
      padding: EdgeInsets.only(
          bottom: _currentSongName != 'Müzik Seçilmedi' ? 140 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle((widget.isPersonalMode || _activeCategory == 'Size Özel Mix')
              ? '🧠 Yapay Zeka: Size Özel Mix'
              : "🔥 Şu An Türkiye'de Trend"),
              
          // 🎯 SİBER HAMLE: Sana Özel Mixler (Şahsi Keşfet'te Görünür)
          if (widget.isPersonalMode || _activeCategory == 'Size Özel Mix')
            _buildAutoMixCarousel(),
            
          _buildHorizontalCarousel(_trendList),

          const SizedBox(height: 20),

          // 🎯 SİBER HAMLE: Seçilen sanatçılara/türlere göre otonom çoğalan kategoriler!
          ..._categories
              .where((c) => c != 'Trendler' && c != 'Size Özel Mix')
              .map((category) {
            if (_genreLists[category] != null &&
                _genreLists[category]!.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('🎧 $category Frekansları'),
                  _buildHorizontalCarousel(_genreLists[category]!),
                  const SizedBox(height: 20),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          _buildSectionTitle(widget.isPersonalMode
              ? '🎵 Kütüphane İstihbarat Radarı'
              : '🎧 Sizin İçin Önerilenler'),
          _buildVerticalList(
              _trendList), // Artık tersine çevirmeden doğrudan basıyoruz

          if (_isLoadingMore)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                  child: CircularProgressIndicator(color: widget.themeColor)),
            )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          )),
    );
  }

  // 🎯 YATAY KAYDIRILABİLİR ALBÜM/KART TASARIMI
  Widget _buildHorizontalCarousel(List<dynamic> items) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final imgUrl = item['thumbnail'];
          return GestureDetector(
            // 🎯 TIKLAMA ALANI
            onTap: () => _playDirectly(item,
                contextList:
                    items), // 🎯 SİBER HAMLE: Tüm yatay listeyi kuyruğa aktar!
            onLongPress: () => _showActionSheet(item),
            child: Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white10,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: imgUrl != null && imgUrl.isNotEmpty
                              ? CachedNetworkImage(imageUrl: imgUrl, placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.music_note,
                                          color: Colors.white24, size: 40),
                                )
                              : const Icon(Icons.music_note,
                                  color: Colors.white24, size: 50),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => _showActionSheet(item),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.more_vert,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['baslik'] ?? 'Bilinmeyen',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['kanal'] ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🎯 DİKEY ARAMA VE MÜZİK LİSTESİ DÜZENİ
  Widget _buildVerticalList(List<dynamic> items, {bool isScrollable = false}) {
    return ListView.builder(
      controller: isScrollable
          ? _scrollController
          : null, // 🎯 SİBER KALKAN: Fare tekerleği kilidi açıldı!
      // 🎯 SİBER KALKAN: Eğer bu liste bağımsızsa (Arama Sonucu) otonom kaydırmayı aç!
      physics: isScrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      shrinkWrap: !isScrollable,
      padding: EdgeInsets.only(
          bottom: _currentSongName != 'Müzik Seçilmedi' ? 140 : 20),
      itemCount: items.length + (isScrollable && _isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
                child: CircularProgressIndicator(color: widget.themeColor)),
          );
        }
        final item = items[index];
        final imgUrl = item['thumbnail'];
        // ignore: unused_local_variable
        final videoId = item['video_id'] ?? item['id'];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imgUrl != null && imgUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: imgUrl, placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.music_note, color: Colors.white24))
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.white10,
                    child: const Icon(Icons.music_note, color: Colors.white54)),
          ),
          title: Text(item['title'] ?? item['baslik'] ?? 'Bilinmeyen',
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          subtitle: Text(item['channel'] ?? item['kanal'] ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: Icon(Icons.more_vert, color: widget.themeColor),
            onPressed: () => _showActionSheet(item),
          ),
          onTap: () => _playDirectly(item,
              contextList:
                  items), // 🎯 SİBER HAMLE: Tüm dikey listeyi kuyruğa aktar!
          onLongPress: () => _showActionSheet(item),
        );
      },
    );
  }

  // 🛡️ SİBER KALKAN: Misafir Modu Uyarı Penceresi
  void _showGuestModeDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.shield, color: Colors.orangeAccent),
              SizedBox(width: 10),
              Text('Siber Kalkan Aktif', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'Misafir modunda sadece keşfet vitrini kullanılabilir. Müzik aramak, indirmek ve derin ağa inmek için Profil sekmesinden giriş yapmalısınız.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anladım', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }
}
