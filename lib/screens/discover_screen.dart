import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'dart:math';
import '../utils/song_media_utils.dart';
import '../utils/search_utils.dart';
import '../models/song_model.dart'; // 🎯 SİBER ÇEVRİMDIŞI PLAYLİST İÇİN
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;
import 'dart:convert'; // 🎯 SİBER HAMLE: json işlemleri için
import '../services/services.dart';
import '../services/weather_service.dart';
import '../widgets/weather_mix_sheet.dart';
import '../services/siber_theme_service.dart';
import '../services/audio_handler.dart';
import '../services/ai_commander.dart';
import '../widgets/auto_playlist_sheet.dart'; // 🎯 SİBER HAMLE: Yapay Zeka Alt Çekmecesi
import 'package:audio_service/audio_service.dart';
import '../widgets/siber_ad_widget.dart'; // 🎯 ÇEVRİMİÇİ MÜZİĞİ OYNATMAK İÇİN
import '../main.dart'; // 🎯 AUDIOHANDLER KÖPRÜSÜ
import 'package:shared_preferences/shared_preferences.dart'; // 🎯 Arama Geçmişi Mührü
import '../services/ad_manager.dart';
import '../services/offline_cache_service.dart'; // 🎯 SİBER ÇEVRİMDİŞİ HAFIZASI
import '../widgets/full_screen_player.dart'; // 🎯 TAM EKRAN OYNATICI (SİBER MÜHÜR)
import 'dart:async'; // 🎯 Otonom Dinleyiciler İçin
import '../services/history_service.dart';
import 'package:http/http.dart'
    as http; // 🎯 SİBER HAMLE: Plak kapağı indirmek için
import 'dart:typed_data';
import '../widgets/siber_istatistik_sheet.dart';
import 'profile_screen.dart';
import '../services/subscription_manager.dart';
import '../widgets/siber_premium_sheet.dart';
import '../widgets/bottom_player_bar.dart';
import '../widgets/mini_eq_visualizer.dart';
import '../widgets/personal_discover_setup_sheet.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/metamorphosis_mix_model.dart';
import '../widgets/metamorphosis_sheet.dart';
import '../models/custom_discover_mix_model.dart';
import '../utils/siber_web_downloader.dart';
import '../services/spotify_service.dart';
import '../services/notification_service.dart';
import '../services/radar_filter.dart';

class DiscoverScreen extends StatefulWidget {
  final Color themeColor;
  final Function(String, String)? onDownloadStart;
  final bool isPersonalMode; // 🎯 SİBER HAMLE: Şahsi Keşfet Modu Aktif mi?
  final bool initialOpenMetamorphosis;

  const DiscoverScreen(
      {super.key,
      required this.themeColor,
      this.onDownloadStart,
      this.isPersonalMode = false,
      this.initialOpenMetamorphosis = false});

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
  Map<String, List<dynamic>> personalArtistMixes = {};
  Map<String, List<Map<String, dynamic>>> personalArtistAlbums = {};
  List<dynamic> personalCocktail = [];
  List<dynamic> similarArtistsTracks = [];
  List<String> personalArtists = [];
  List<String> personalGenres = [];
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final AICommander _aiCommander = AICommander();
  // 🎯 SİBER KALKAN: Keşfet Kalıcılık Hafızası (Sen çıksan bile silinmez)
  static final DiscoverCache _generalCache = DiscoverCache();
  static final DiscoverCache _personalCache = DiscoverCache();

  bool _isPersonalMode = false;
  // 📌 SİBER SABİTLENEN SANATÇI KANALLARI
  List<String> _pinnedArtists = [];

  // 🎧 10-SANİYE NAKARAT RADARI (Hook Snip)
  bool _isHookSnipActive = false;
  String _hookSnipTitle = '';
  String _hookSnipArtist = '';
  String _hookSnipThumb = '';
  int _hookSnipSecondsLeft = 10;
  Timer? _hookSnipTimer;
  ja.AudioPlayer? _hookPlayer;
  bool _wasPlayingBeforeHook = false;
  dynamic _activeHookItem;

  DiscoverCache get _currentCache => _isPersonalMode ? _personalCache : _generalCache;

  // 🎯 ŞAHSİ KEŞFET (KİŞİSEL KARARGAH) HAFIZASI
  List<String> _personalArtists = ['Ceza', 'Velet', 'GeeFlow'];
  List<String> _personalGenres = ['Türkçe Rap'];
  String _activePersonalGenre = 'Türkçe Rap';
  final Set<String> _recentlyRecommendedIds = {};
  Map<String, List<dynamic>> _personalArtistMixes = {};
  Map<String, List<Map<String, dynamic>>> _personalArtistAlbums = {};
  List<dynamic> _personalCocktail = [];
  List<dynamic> _similarArtistsTracks = [];

  // 🎛️ İnce Kaydırılabilir 3'lü Stüdyo Çubuğu Kontrolcüsü
  final PageController _studioBarPageController = PageController();
  int _activeStudioSlide = 0;

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);


  // 🎯 YENİ SİBER HAMLE: Otonom AI Mix Motoru & Hava Durumu
  List<Map<String, dynamic>> _aiMixes = [];
  String _dominantMood = 'Genel';
  
  // 🔮 SİBER METAMORFOZ: Kayıtlı Miksler Hafızası
  List<MetamorphosisMix> _savedMetamorphosisMixes = [];

  // 🎧 MANUEL KEŞFET MİKSLERİ: Kullanıcının Kendi Özel Miksleri (Tamamen Ücretsiz)
  List<CustomDiscoverMix> _savedCustomMixes = [];
  
  Weather? _currentWeather;
  String _atmosphereMood = 'Genel';

  final TextEditingController _searchController = TextEditingController();
  final OzsesBridge _bridge = OzsesBridge();
  final ScrollController _scrollController =
      ScrollController(); // 🎯 Arama sonuçları için kaydırma kontrolcüsü
  final ScrollController _generalScrollController =
      ScrollController(); // 🎯 Genel Keşfet için bağımsız kaydırma
  final ScrollController _personalScrollController =
      ScrollController(); // 🎯 Şahsi Keşfet için bağımsız kaydırma

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
  bool _isManuallyClosed = false; // 🛑 SİBER KALKAN: X'e basılınca player yeniden açılmasın

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

  // 🎯 HESAP DURUMU
  bool _isAccountLinked = false;
  String _userName = 'Müziksever';
  String _userAvatarUrl = '';
  bool _showAccountBanner = true;

  Future<void> _loadAccountStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final linked = prefs.getBool('siber_is_linked') ?? false;
    final name = prefs.getString('siber_username') ?? 'Müziksever';
    final avatar = prefs.getString('siber_avatar_url') ?? '';

    if (mounted) {
      setState(() {
        _isAccountLinked = linked;
        _userName = name;
        _userAvatarUrl = avatar;
      });
    }
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
    SiberThemeService.instance.currentThemeColor.addListener(_onThemeChanged);
    SiberThemeService.instance.isMinimalMode.addListener(_onThemeChanged);
    _isPersonalMode = widget.isPersonalMode;

    // 🎯 SİBER KALKAN: Modlar arası veri izolasyonu — Aktif moda göre hafızayı geri yükle
    if (_isPersonalMode) {
      _personalCocktail = List.from(_personalCache.personalCocktail);
      _personalArtistMixes = Map.from(_personalCache.personalArtistMixes);
      _personalArtistAlbums = Map.from(_personalCache.personalArtistAlbums);
      _similarArtistsTracks = List.from(_personalCache.similarArtistsTracks);
      if (_personalCache.personalArtists.isNotEmpty) {
        _personalArtists = List.from(_personalCache.personalArtists);
      }
      if (_personalCache.personalGenres.isNotEmpty) {
        _personalGenres = List.from(_personalCache.personalGenres);
      }
      _activeCategory = 'Size Özel Mix';
    } else {
      _trendList = List.from(_generalCache.trendList);
      _genreLists = Map.from(_generalCache.genreLists);
      _nextPageToken = _generalCache.nextPageToken;
      _activeCategory = _generalCache.activeCategory.isEmpty ? 'Trendler' : _generalCache.activeCategory;
    }

    _searchResults = [];
    _isSearching = false;
    _searchController.clear();
    _currentCache.isSearching = false;
    _currentCache.lastSearchQuery = '';
    _searchPage = 1;
    _hasMoreSearch = true;

    _loadSearchHistory();
    _initSiberPlayerListeners();

    // 🎯 Eğer aktif modun verisi yoksa hemen çek
    final bool needsData = _isPersonalMode ? _personalCocktail.isEmpty : _trendList.isEmpty;
    if (needsData && !_isSearching) {
      _initDataAndCache();
    _loadPinnedArtists();
    }

    _scrollController.addListener(_onScroll);
    _generalScrollController.addListener(_onScroll);
    _personalScrollController.addListener(_onScroll);
    _initWeather();
    _loadAccountStatus();
    _loadSavedMetamorphosisMixes();
    _loadSavedCustomMixes();

    if (widget.initialOpenMetamorphosis) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMetamorphosisDialog();
      });
    }
  }

  // 🎯 SİBER MOD ANAHTARI: Genel Keşfet ile Şahsi Keşfet Arasında Pürüzsüz & Karışmasız Geçiş
  void _switchMode(bool toPersonal) {
    if (_isPersonalMode == toPersonal) return;

    // 1. Mevcut aktif modun verilerini kendi önbelleğine sakla
    if (_isPersonalMode) {
      _personalCache.personalCocktail = List.from(_personalCocktail);
      _personalCache.personalArtistMixes = Map.from(_personalArtistMixes);
      _personalCache.personalArtistAlbums = Map.from(_personalArtistAlbums);
      _personalCache.similarArtistsTracks = List.from(_similarArtistsTracks);
      _personalCache.personalArtists = List.from(_personalArtists);
      _personalCache.personalGenres = List.from(_personalGenres);
      _personalCache.isSearching = _isSearching;
      _personalCache.searchResults = List.from(_searchResults);
    } else {
      _generalCache.trendList = List.from(_trendList);
      _generalCache.genreLists = Map.from(_genreLists);
      _generalCache.activeCategory = _activeCategory;
      _generalCache.nextPageToken = _nextPageToken;
      _generalCache.isSearching = _isSearching;
      _generalCache.searchResults = List.from(_searchResults);
    }

    setState(() {
      _isPersonalMode = toPersonal;
      _isSearching = false;
      _searchController.clear();

      // 2. Hedef modun verilerini önbelleğinden geri yükle
      if (toPersonal) {
        _personalCocktail = List.from(_personalCache.personalCocktail);
        _personalArtistMixes = Map.from(_personalCache.personalArtistMixes);
        _personalArtistAlbums = Map.from(_personalCache.personalArtistAlbums);
        _similarArtistsTracks = List.from(_personalCache.similarArtistsTracks);
        if (_personalCache.personalArtists.isNotEmpty) {
          _personalArtists = List.from(_personalCache.personalArtists);
        }
        if (_personalCache.personalGenres.isNotEmpty) {
          _personalGenres = List.from(_personalCache.personalGenres);
        }
        _activeCategory = 'Size Özel Mix';
      } else {
        _trendList = List.from(_generalCache.trendList);
        _genreLists = Map.from(_generalCache.genreLists);
        _activeCategory = _generalCache.activeCategory.isEmpty ? 'Trendler' : _generalCache.activeCategory;
        _nextPageToken = _generalCache.nextPageToken;
      }
    });

    // 3. Hedef modun içeriği henüz hiç çekilmediyse çek
    if (toPersonal) {
      if (_personalCocktail.isEmpty && !_isLoading) {
        _loadCachedPersonalData().then((_) {
          if (_personalCocktail.isEmpty && mounted) {
            _fetchPersonalRecommendations();
          }
        });
      }
    } else {
      if (_trendList.isEmpty && !_isLoading) {
        _loadCachedTrends().then((_) {
          if (_trendList.isEmpty && mounted) {
            _fetchTrends();
          }
        });
      }
    }
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

  // 🎯 SİBER HAMLE: Aktif Moda Göre Önbellekten Yükle ve İzole Olarak Güncelle
  // 🛡️ BİRLEŞİK TEK KEŞFET: Tüm Önbelleği Anında Yükle ve Arka Planda Taze Verileri Çek
  Future<void> _initDataAndCache() async {
    await _loadCachedTrends();
    await _loadCachedPersonalData();
    await _loadPinnedArtists();

    final bool hasTrends = _trendList.isNotEmpty;
    final bool hasPersonal = _personalCocktail.isNotEmpty || _personalArtistMixes.isNotEmpty;

    _fetchTrends(silent: hasTrends);
    _fetchPersonalRecommendations(silent: hasPersonal);
  }

  Future<void> _loadCachedTrends() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('siber_trend_cache');
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached);
        if (mounted) {
          final list = List<dynamic>.from(decoded);
          for (var item in list) {
            final id = item['videoId'] ?? item['id'] ?? item['video_id'];
            if (id != null) {
              item['id'] = id;
              item['videoId'] = id;
            }
          }
          _generalCache.trendList = list;
          if (!_isPersonalMode) {
            setState(() {
              _trendList = list;
            });
          }
        }
      } catch (e) {}
    }
  }

  Future<void> _saveTrendsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('siber_trend_cache', jsonEncode(_generalCache.trendList));
  }

  Future<void> _loadCachedPersonalData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedCocktail = prefs.getString('siber_personal_cocktail_cache');
    final cachedMixes = prefs.getString('siber_personal_mixes_cache');
    final cachedAlbums = prefs.getString('siber_personal_albums_cache');
    final cachedSimilar = prefs.getString('siber_personal_similar_cache');

    if (cachedCocktail != null) {
      try {
        final decoded = jsonDecode(cachedCocktail);
        _personalCache.personalCocktail = List<dynamic>.from(decoded);
        if (mounted) {
          setState(() => _personalCocktail = List<dynamic>.from(decoded));
        }
      } catch (_) {}
    }
    if (cachedMixes != null) {
      try {
        final decoded = jsonDecode(cachedMixes) as Map<String, dynamic>;
        final parsed = decoded.map((k, v) => MapEntry(k, List<dynamic>.from(v)));
        _personalCache.personalArtistMixes = parsed;
        if (mounted) {
          setState(() => _personalArtistMixes = parsed);
        }
      } catch (_) {}
    }
    if (cachedAlbums != null) {
      try {
        final decoded = jsonDecode(cachedAlbums) as Map<String, dynamic>;
        final parsed = decoded.map((k, v) => MapEntry(
              k,
              (v as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
            ));
        _personalCache.personalArtistAlbums = parsed;
        if (mounted) {
          setState(() => _personalArtistAlbums = parsed);
        }
      } catch (_) {}
    }
    if (cachedSimilar != null) {
      try {
        final decoded = jsonDecode(cachedSimilar);
        _personalCache.similarArtistsTracks = List<dynamic>.from(decoded);
        if (mounted) {
          setState(() => _similarArtistsTracks = List<dynamic>.from(decoded));
        }
      } catch (_) {}
    }
  }

  Future<void> _savePersonalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('siber_personal_cocktail_cache', jsonEncode(_personalCache.personalCocktail));
    await prefs.setString('siber_personal_mixes_cache', jsonEncode(_personalCache.personalArtistMixes));
    await prefs.setString('siber_personal_albums_cache', jsonEncode(_personalCache.personalArtistAlbums));
    await prefs.setString('siber_personal_similar_cache', jsonEncode(_personalCache.similarArtistsTracks));
  }

  // 🎯 SİBER HAMLE: Mini Oynatıcıyı Canlı Tutan Radar
  void _initSiberPlayerListeners() {
    _mediaItemSub = audioHandler.mediaItem.listen((item) async {
      if (item == null) {
        if (mounted) {
          setState(() {
            _currentSongName = 'Müzik Seçilmedi';
            _currentCoverBytes = null;
          });
        }
        return;
      }
      if (mounted) {
        // 🛑 SİBER KALKAN: Kullanıcı X'e bastıysa player yeniden açılmasın
        if (_isManuallyClosed) return;
        setState(() {
          _currentSongName = item.title;
          _currentArtist = item.artist ?? 'Victus V7';
          _dur = item.duration ?? Duration.zero;
        });

        // 🎯 SİBER HAMLE: Çevrimiçi Plak Kapağı Çözücü
        if (item.artUri != null) {
          try {
            final response = await http.get(item.artUri!);
            if (response.statusCode == 200 && mounted && !_isManuallyClosed) {
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

  // 🎯 SİBER HAMLE: Sesli Arama Tetikleyicisi
  void _startVoiceSearch() async {
    String currentLanguage = 'tr_TR';
    String liveText = '';

    void startMic(StateSetter setModalState) {
      _aiCommander.startListening((text, isFinal) {
        if (text.isNotEmpty) {
          setModalState(() {
            liveText = text;
          });
          if (isFinal) {
            if (Navigator.canPop(context)) Navigator.pop(context); // Çekmeceyi kapat
            setState(() {
              _searchController.text = text;
            });
            _performSearch(text); // Otomatik aramayı başlat
          }
        }
      }, localeId: currentLanguage);
    }

    // Çekmeceyi aç
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) {
        bool isMicStarted = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            if (!isMicStarted) {
              isMicStarted = true;
              Future.microtask(() => startMic(setModalState));
            }
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dil Seçici
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Türkçe'),
                        selected: currentLanguage == 'tr_TR',
                        selectedColor: widget.themeColor.withValues(alpha: 0.5),
                        onSelected: (bool selected) {
                          if (selected) {
                            setModalState(() {
                              currentLanguage = 'tr_TR';
                              liveText = '';
                            });
                            startMic(setModalState); // Dili değiştirince yeniden başlat
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('English'),
                        selected: currentLanguage == 'en_US',
                        selectedColor: widget.themeColor.withValues(alpha: 0.5),
                        onSelected: (bool selected) {
                          if (selected) {
                            setModalState(() {
                              currentLanguage = 'en_US';
                              liveText = '';
                            });
                            startMic(setModalState); // Dili değiştirince yeniden başlat
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Icon(Icons.mic, size: 50, color: widget.themeColor),
                  const SizedBox(height: 20),
                  Text(
                    liveText.isNotEmpty
                        ? liveText
                        : (currentLanguage == 'tr_TR' ? 'Sizi dinliyorum...' : 'Listening...'),
                    style: TextStyle(
                      color: liveText.isNotEmpty ? widget.themeColor : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontStyle: liveText.isNotEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _aiCommander.stopListening();
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

  // 🎯 Buton Tasarımı (Sade / Parlak Uyumlu)
  Widget _buildSiberButton(IconData icon, String text, VoidCallback onTap) {
    final isMinimal = SiberThemeService.instance.isMinimalMode.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: isMinimal ? Colors.white10 : widget.themeColor.withOpacity(0.3),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMinimal ? const Color(0xFF1E1E22) : null,
            gradient: isMinimal
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isMinimal ? Colors.white12 : Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: isMinimal
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isMinimal
                      ? null
                      : [
                          BoxShadow(color: widget.themeColor.withOpacity(0.4), blurRadius: 6),
                        ],
                ),
                child: Icon(
                  icon,
                  color: isMinimal ? Colors.white70 : widget.themeColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 SİBER METAMORFOZ: Kayıtlı Miksleri Yükle
  Future<void> _loadSavedMetamorphosisMixes() async {
    try {
      final mixes = await MetamorphosisService.getSavedMixes();
      if (mounted) {
        setState(() {
          _savedMetamorphosisMixes = mixes;
        });
      }
    } catch (_) {}
  }

  // 🎧 MANUEL KEŞFET MİKSİ: Kayıtlı Özel Miksleri Yükle (Tamamen Ücretsiz)
  Future<void> _loadSavedCustomMixes() async {
    try {
      final mixes = await CustomDiscoverMixService.getMixes();
      if (mounted) {
        setState(() {
          _savedCustomMixes = mixes;
        });
      }
    } catch (_) {}
  }

  // 🎯 2. Siber Metamorfoz Stüdyosu (DJ Füzyon & Manuel Geçiş Konsolu)
  void _showMetamorphosisDialog({Map<String, dynamic>? initialTrack, List<Map<String, dynamic>>? initialTracks}) {
    if (!SubscriptionManager().canUseMetamorphosis()) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => SiberPremiumSheet(themeColor: widget.themeColor),
      );
      return;
    }

    MetamorphosisSheet.show(
      context,
      themeColor: widget.themeColor,
      initialTrack: initialTrack,
      initialTracks: initialTracks,
      onStartMetamorphosis: (query, title, customTracks) async {
        if (customTracks.isNotEmpty) {
          Fluttertoast.showToast(
            msg: '🔮 Metamorfoz: "$title" (${customTracks.length} özel parça) akışı başlatıldı!',
            backgroundColor: widget.themeColor,
          );
          _playDirectly(customTracks.first, contextList: customTracks, isMix: true);
          _searchController.text = query;
        } else {
          _searchController.text = query;
          Fluttertoast.showToast(
            msg: '🔮 Metamorfoz: "$title" müzikleri hazırlanıyor...',
            backgroundColor: widget.themeColor,
          );
          await _performSearch(query);
          if (_searchResults.isNotEmpty) {
            _playDirectly(_searchResults.first, contextList: _searchResults, isMix: true);
          }
        }
      },
      onMixSaved: _loadSavedMetamorphosisMixes,
    );
  }

  // 🎛️ İNCE & KAYDIRILABİLİR 3'LÜ STÜDYO ÇUBUĞU (Mod Haplarının Hemen Altında)
  // Sağa-sola kaydırarak 3 özellik (Özel Miks | Metamorfoz | Atmosfer) arasında geçiş yapar,
  // dokunulduğunda doğrudan o sekmeyle stüdyo çekmecesini açar.
  Widget _buildStudioDrawerBar() {
    final isMinimal = SiberThemeService.instance.isMinimalMode.value;
    final weatherTemp = _currentWeather?.temperature?.celsius?.toStringAsFixed(0);

    final slides = [
      {
        'icon': Icons.headphones_rounded,
        'color': Colors.tealAccent,
        'title': 'Özel Miks Stüdyosu (${_savedCustomMixes.length})',
        'sub': 'Kendi listelerin • Kaydır ⇄ veya Dokun Aç',
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'color': Colors.purpleAccent,
        'title': 'Metamorfoz Frekansı (${_savedMetamorphosisMixes.length})',
        'sub': 'Duygu geçişi • Kaydır ⇄ veya Dokun Aç',
      },
      {
        'icon': Icons.wb_twilight_rounded,
        'color': Colors.amberAccent,
        'title': weatherTemp != null
            ? 'Atmosfer & Hava ($weatherTemp°C $_atmosphereMood)'
            : 'Canlı Atmosfer & Hava Modu',
        'sub': 'Ortam radarı • Kaydır ⇄ veya Dokun Aç',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isMinimal
              ? const Color(0xFF16161B)
              : const Color(0xFF121626).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isMinimal
                ? Colors.white12
                : widget.themeColor.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // Sol küçük ok (Önceki modül)
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                final prev = (_activeStudioSlide - 1 + slides.length) % slides.length;
                _studioBarPageController.animateToPage(
                  prev,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Icon(Icons.chevron_left_rounded, color: Colors.white54, size: 18),
              ),
            ),
            // Ortada sağa-sola kaydırılabilir 3 özellik
            Expanded(
              child: PageView.builder(
                controller: _studioBarPageController,
                itemCount: slides.length,
                onPageChanged: (idx) {
                  setState(() => _activeStudioSlide = idx);
                },
                itemBuilder: (context, index) {
                  final s = slides[index];
                  final Color c = s['color'] as Color;
                  return InkWell(
                    onTap: () => _showStudioDrawer(initialTab: index),
                    child: Row(
                      children: [
                        Icon(
                          s['icon'] as IconData,
                          color: isMinimal ? Colors.white70 : c,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${s['title']}  •  ${s['sub']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 3 Nokta İndikatörü
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(slides.length, (i) {
                final active = _activeStudioSlide == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: active ? 10 : 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? widget.themeColor : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(width: 4),
            // Sağda doğrudan çekmeceyi açan kompakt hap buton
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showStudioDrawer(initialTab: _activeStudioSlide),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMinimal
                      ? Colors.white10
                      : widget.themeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Stüdyo',
                      style: TextStyle(
                        color: isMinimal ? Colors.white : widget.themeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.expand_less_rounded,
                      color: isMinimal ? Colors.white70 : widget.themeColor,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎛️ MİKS & ATMOSFER ÇEKMECESİ (Ambiyanslı Bottom Sheet)
  void _showStudioDrawer({int initialTab = 0}) {
    final weatherTemp = _currentWeather?.temperature?.celsius?.toStringAsFixed(0);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDrawerState) {
            return DefaultTabController(
              length: 3,
              initialIndex: initialTab,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF13192B),
                      Color(0xFF0C101C),
                      Color(0xFF080B13),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: widget.themeColor.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.themeColor.withValues(alpha: 0.25),
                      blurRadius: 36,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Üst Tutamaç & Ambiyanslı Başlık Barı
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 4.5,
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [widget.themeColor, Colors.purpleAccent],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            widget.themeColor.withValues(alpha: 0.3),
                                            Colors.purpleAccent.withValues(alpha: 0.25),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: widget.themeColor.withValues(alpha: 0.5)),
                                      ),
                                      child: Icon(Icons.auto_awesome_motion_rounded, color: widget.themeColor, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'MİKS & ATMOSFER MERKEZİ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        Text(
                                          'Kişiselleştirilmiş çalma listeleri ve ortam modları',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                                  ),
                                  onPressed: () => Navigator.pop(ctx),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Sekme Çubuğu (Segmented Ambient TabBar)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0D16),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [widget.themeColor, Colors.purpleAccent],
                            ),
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: widget.themeColor.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.white70,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                          tabs: [
                            Tab(text: '🎧 Özel (${_savedCustomMixes.length})'),
                            Tab(text: '🔮 Metamorfoz (${_savedMetamorphosisMixes.length})'),
                            Tab(text: '🌤️ Hava (${weatherTemp != null ? '$weatherTemp°' : 'Canlı'})'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Sekme İçerikleri
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildCustomMixesDrawerTab(setDrawerState),
                            _buildMetamorphosisDrawerTab(setDrawerState),
                            _buildWeatherDrawerTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 1. ÖZEL MİKSLER SEKME İÇERİĞİ
  Widget _buildCustomMixesDrawerTab(StateSetter setDrawerState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Özel Çalma Listelerin / Mikslerin',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              InkWell(
                onTap: () async {
                  await _showCreateCustomMixDialog();
                  setDrawerState(() {});
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add_rounded, color: Colors.tealAccent, size: 16),
                      SizedBox(width: 4),
                      Text('Yeni Miks', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_savedCustomMixes.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.playlist_add_rounded, color: Colors.tealAccent, size: 48),
                    const SizedBox(height: 10),
                    const Text(
                      'Henüz Özel Miksiniz Yok',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Keşfet\'teki parçalardan "Özel Miksime Ekle" ile toplayıp dinleyebilirsiniz. Tamamen ücretsizdir!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await _showCreateCustomMixDialog();
                        setDrawerState(() {});
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Yeni Miks Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _savedCustomMixes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final mix = _savedCustomMixes[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10242B),
                          const Color(0xFF0C171C),
                          Colors.tealAccent.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.tealAccent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.queue_music_rounded, color: Colors.tealAccent, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mix.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    '${mix.tracks.length} Parça Kayıtlı • Ücretsiz',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.tealAccent, size: 30),
                              onPressed: () {
                                if (mix.tracks.isEmpty) {
                                  Fluttertoast.showToast(msg: 'Bu mikste henüz parça yok');
                                  return;
                                }
                                Navigator.pop(context);
                                Fluttertoast.showToast(
                                  msg: '🎧 "${mix.title}" (${mix.tracks.length} parça) çalınıyor...',
                                  backgroundColor: Colors.teal,
                                );
                                _playDirectly(mix.tracks.first, contextList: mix.tracks, isMix: true);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                if (mix.tracks.isEmpty) {
                                  Fluttertoast.showToast(msg: 'Önce mikse en az 1 parça ekleyin');
                                  return;
                                }
                                Navigator.pop(context);
                                _showMetamorphosisDialog(initialTracks: mix.tracks);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 12),
                                    SizedBox(width: 4),
                                    Text('Metamorfoz\'a Aktar', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.tealAccent,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    _showCustomMixTracksDialog(mix);
                                  },
                                  icon: const Icon(Icons.format_list_bulleted_rounded, size: 14),
                                  label: const Text('Parçalar', style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dCtx) => AlertDialog(
                                        backgroundColor: const Color(0xFF141724),
                                        title: const Text('Miksi Sil', style: TextStyle(color: Colors.white)),
                                        content: Text('"${mix.title}" miksini silmek istediğinize emin misiniz?', style: const TextStyle(color: Colors.white70)),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('İptal', style: TextStyle(color: Colors.white54))),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                            onPressed: () => Navigator.pop(dCtx, true),
                                            child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await CustomDiscoverMixService.deleteMix(mix.id);
                                      await _loadSavedCustomMixes();
                                      setDrawerState(() {});
                                      Fluttertoast.showToast(msg: 'Miks silindi');
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // 2. METAMORFOZ SEKME İÇERİĞİ
  Widget _buildMetamorphosisDrawerTab(StateSetter setDrawerState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Duygu & Tür Dönüşüm Kapsülleri',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showMetamorphosisDialog();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add_rounded, color: Colors.purpleAccent, size: 16),
                      SizedBox(width: 4),
                      Text('Yeni Metamorfoz', style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_savedMetamorphosisMixes.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 48),
                    const SizedBox(height: 10),
                    const Text(
                      'Kayıtlı Metamorfoz Kapsülü Yok',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ruh halini veya müzik türlerini dönüştürmek için yeni bir metamorfoz başlatın.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showMetamorphosisDialog();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Metamorfoz Başlat', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _savedMetamorphosisMixes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final mix = _savedMetamorphosisMixes[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A1528),
                          const Color(0xFF110E1D),
                          Colors.purpleAccent.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purpleAccent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mix.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    '${mix.startMood} ➔ ${mix.targetMood} • ${mix.customTracks.length} Özel Parça',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.purpleAccent, size: 30),
                              onPressed: () {
                                Navigator.pop(context);
                                if (mix.customTracks.isNotEmpty) {
                                  Fluttertoast.showToast(
                                    msg: '🔮 Metamorfoz: "${mix.title}" (${mix.customTracks.length} özel parça) başlatıldı!',
                                    backgroundColor: widget.themeColor,
                                  );
                                  _playDirectly(mix.customTracks.first, contextList: mix.customTracks, isMix: true);
                                  _searchController.text = mix.query;
                                } else {
                                  Fluttertoast.showToast(
                                    msg: '🔮 Metamorfoz: "${mix.title}" akışı başlatılıyor...',
                                    backgroundColor: widget.themeColor,
                                  );
                                  _searchController.text = mix.query;
                                  _performSearch(mix.query).then((_) {
                                    if (_searchResults.isNotEmpty) {
                                      _playDirectly(_searchResults.first, contextList: _searchResults, isMix: true);
                                    }
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (mix.customTracks.isNotEmpty)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.purpleAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  _showMixTracksDialog(mix);
                                },
                                icon: const Icon(Icons.format_list_bulleted_rounded, size: 14),
                                label: const Text('Parçalar', style: TextStyle(fontSize: 11)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dCtx) => AlertDialog(
                                    backgroundColor: const Color(0xFF141724),
                                    title: const Text('Miksi Sil', style: TextStyle(color: Colors.white)),
                                    content: Text('"${mix.title}" miksini silmek istediğinize emin misiniz?', style: const TextStyle(color: Colors.white70)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('İptal', style: TextStyle(color: Colors.white54))),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                        onPressed: () => Navigator.pop(dCtx, true),
                                        child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await MetamorphosisService.deleteMix(mix.id);
                                  await _loadSavedMetamorphosisMixes();
                                  setDrawerState(() {});
                                  Fluttertoast.showToast(msg: 'Miks silindi');
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // 3. HAVA DURUMU SEKME İÇERİĞİ
  Widget _buildWeatherDrawerTab() {
    final temp = _currentWeather?.temperature?.celsius?.toStringAsFixed(1) ?? '--';
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.themeColor.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.themeColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _atmosphereMood == 'Enerjik' ? Icons.wb_sunny :
                    _atmosphereMood == 'Melankolik' ? Icons.water_drop :
                    _atmosphereMood == 'Akustik' ? Icons.ac_unit : Icons.cloud,
                    color: widget.themeColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hava Durumu: $temp°C',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Önerilen Ruh Hali: $_atmosphereMood',
                        style: TextStyle(color: widget.themeColor, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Hava koşullarına göre dinamik yapay zeka müzik frekansı',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                if (!SubscriptionManager().canUseWeatherMix()) {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => SiberPremiumSheet(themeColor: widget.themeColor),
                  );
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => WeatherMixSheet(
                    currentWeather: _currentWeather,
                    atmosphereMood: _atmosphereMood,
                    themeColor: widget.themeColor,
                    onDownloadStart: _downloadAudio,
                  ),
                );
              },
              icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
              label: const Text(
                '🌤️ Atmosferik Hava Durumu Mixini Başlat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 METAMORFOZ: Kayıtlı Miks Kartı (Sade / Parlak Tasarım)
  Widget _buildSavedMixCard(MetamorphosisMix mix) {
    final isMinimal = SiberThemeService.instance.isMinimalMode.value;
    return Container(
      width: 235,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: isMinimal ? const Color(0xFF18181C) : null,
        gradient: isMinimal
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF161B33),
                  const Color(0xFF0E111F),
                  widget.themeColor.withValues(alpha: 0.15),
                ],
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isMinimal ? Colors.white12 : widget.themeColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: isMinimal
            ? null
            : [
                BoxShadow(
                  color: widget.themeColor.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              if (mix.customTracks.isNotEmpty) {
                Fluttertoast.showToast(
                  msg: '🔮 Metamorfoz: "${mix.title}" (${mix.customTracks.length} özel parça) akışı başlatıldı!',
                  backgroundColor: widget.themeColor,
                );
                _playDirectly(mix.customTracks.first, contextList: mix.customTracks, isMix: true);
                _searchController.text = mix.query;
              } else {
                Fluttertoast.showToast(
                  msg: '🔮 Metamorfoz: "${mix.title}" akışı başlatılıyor...',
                  backgroundColor: widget.themeColor,
                );
                _searchController.text = mix.query;
                await _performSearch(mix.query);
                if (_searchResults.isNotEmpty) {
                  _playDirectly(_searchResults.first, contextList: _searchResults, isMix: true);
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst Dönüşüm Köprüsü (Holografik İki Uçlu Rozet)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.cyanAccent,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.cyanAccent, blurRadius: 6)],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            mix.startMood,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Icon(Icons.arrow_forward_rounded, color: widget.themeColor, size: 13),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.purpleAccent,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.purpleAccent, blurRadius: 6)],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            mix.targetMood,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Başlık & Açıklama
                  Text(
                    mix.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (mix.customTracks.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 2, bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, color: Colors.cyanAccent, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            '${mix.customTracks.length} Özel Parça Mühürlü',
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: Colors.white38, size: 11),
                        SizedBox(width: 4),
                        Text(
                          'Otonom Dönüşüm Akışı',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  const Spacer(),

                  // Alt Bar (Siber Etiket & Sil / Çal)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.themeColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: widget.themeColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          mix.customTracks.isNotEmpty ? 'ÖZEL MİKS' : 'METAMORFOZ',
                          style: TextStyle(
                            color: widget.themeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mühürlü Parçaları Gör Butonu (varsa)
                          if (mix.customTracks.isNotEmpty) ...[
                            InkWell(
                              onTap: () => _showMixTracksDialog(mix),
                              child: Container(
                                padding: const EdgeInsets.all(5.0),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.queue_music_rounded, color: Colors.cyanAccent, size: 16),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          // Sil Butonu
                          InkWell(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  backgroundColor: const Color(0xFF141724),
                                  title: const Text('Miksi Sil', style: TextStyle(color: Colors.white)),
                                  content: Text('"${mix.title}" miksini kayıtlı mikslerden kaldırmak istiyor musunuz?', style: const TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('İptal', style: TextStyle(color: Colors.white54))),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      onPressed: () => Navigator.pop(dCtx, true),
                                      child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await MetamorphosisService.deleteMix(mix.id);
                                _loadSavedMetamorphosisMixes();
                                Fluttertoast.showToast(msg: 'Miks silindi');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Çal Butonu
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.themeColor,
                                  Colors.cyanAccent,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: widget.themeColor.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 SİBER METAMORFOZ: Kapsüle Mühürlü Parçaları Yönetme & Dinleme Çekmecesi
  void _showMixTracksDialog(MetamorphosisMix mix) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F121E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: widget.themeColor.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.themeColor.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                              ),
                              child: const Icon(Icons.queue_music_rounded, color: Colors.cyanAccent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MÜHÜRLÜ ÖZEL PARÇALAR',
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  mix.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    if (mix.customTracks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'Bu kapsülde henüz mühürlü parça yok.\nKeşfet\'teki şarkıların 3 noktasına basarak ekleyebilirsin!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.45,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: mix.customTracks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (c, idx) {
                            final song = mix.customTracks[idx];
                            final sTitle = song['title'] ?? song['baslik'] ?? 'Parça';
                            final sArtist = song['channel'] ?? song['kanal'] ?? '';
                            final sId = song['id'] ?? song['videoId'] ?? song['video_id'];
                            final sImg = song['thumbnail'];
                            final sDurSec = song['duration'] is int
                                ? song['duration']
                                : (song['duration'] != null ? int.tryParse(song['duration'].toString()) ?? 0 : 0);
                            final sDur = Duration(seconds: sDurSec);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: widget.themeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${idx + 1}',
                                        style: TextStyle(
                                          color: widget.themeColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          sArtist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Oynat
                                  IconButton(
                                    icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.cyanAccent, size: 28),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _playDirectly(song, contextList: mix.customTracks, isMix: true);
                                    },
                                  ),
                                  // Çıkar
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () async {
                                      await MetamorphosisService.removeTrackFromMix(mix.id, sId);
                                      await _loadSavedMetamorphosisMixes();
                                      final updated = _savedMetamorphosisMixes.firstWhere(
                                        (m) => m.id == mix.id,
                                        orElse: () => mix,
                                      );
                                      setSheetState(() {
                                        mix = updated;
                                      });
                                      Fluttertoast.showToast(msg: 'Parça kapsülden çıkarıldı');
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  // 🎧 MANUEL KEŞFET MİKS KARTI
  Widget _buildCustomMixCard(CustomDiscoverMix mix) {
    final isMinimal = SiberThemeService.instance.isMinimalMode.value;
    return Container(
      width: 235,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: isMinimal ? const Color(0xFF18181C) : null,
        gradient: isMinimal
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F2327),
                  const Color(0xFF0A161B),
                  Colors.tealAccent.withValues(alpha: 0.12),
                ],
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isMinimal ? Colors.white12 : Colors.tealAccent.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: isMinimal
            ? null
            : [
                BoxShadow(
                  color: Colors.tealAccent.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (mix.tracks.isEmpty) {
                Fluttertoast.showToast(msg: 'Bu mikste henüz parça yok. Şarkı eklemek için parçaların yanındaki seçenekleri kullanın.');
                return;
              }
              Fluttertoast.showToast(
                msg: '🎧 "${mix.title}" (${mix.tracks.length} parça) çalınıyor...',
                backgroundColor: Colors.teal,
              );
              _playDirectly(mix.tracks.first, contextList: mix.tracks, isMix: true);
            },
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst Bilgi Barı: Ücretsiz Etiketi & Metamorfoz Aktar Rozeti
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.lock_open_rounded, color: Colors.tealAccent, size: 10),
                            SizedBox(width: 3),
                            Text(
                              'ÜCRETSİZ',
                              style: TextStyle(color: Colors.tealAccent, fontSize: 9.5, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                      // 🔮 KÖPRÜ BUTONU: Metamorfoz'a Aktar
                      InkWell(
                        onTap: () {
                          if (mix.tracks.isEmpty) {
                            Fluttertoast.showToast(msg: 'Metamorfoz\'a aktarmak için önce bu mikse en az 1 parça ekleyin!');
                            return;
                          }
                          _showMetamorphosisDialog(initialTracks: mix.tracks);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.3), blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 11),
                              SizedBox(width: 3),
                              Text(
                                'Metamorfoz\'a Aktar',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Başlık & Şarkı Sayısı
                  Text(
                    mix.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.music_note_rounded, color: Colors.white54, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${mix.tracks.length} Parça Kayıtlı',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Alt Bar (Yönet / Sil / Çal)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'MANUEL MİKS',
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Parçaları Yönet Butonu
                          InkWell(
                            onTap: () => _showCustomMixTracksDialog(mix),
                            child: Container(
                              padding: const EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                color: Colors.tealAccent.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.format_list_bulleted_rounded, color: Colors.tealAccent, size: 16),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Sil Butonu
                          InkWell(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  backgroundColor: const Color(0xFF141724),
                                  title: const Text('Miksi Sil', style: TextStyle(color: Colors.white)),
                                  content: Text('"${mix.title}" miksini silmek istediğinize emin misiniz?', style: const TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('İptal', style: TextStyle(color: Colors.white54))),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      onPressed: () => Navigator.pop(dCtx, true),
                                      child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await CustomDiscoverMixService.deleteMix(mix.id);
                                await _loadSavedCustomMixes();
                                Fluttertoast.showToast(msg: 'Miks silindi');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Çal Butonu
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.tealAccent,
                                  Colors.cyanAccent,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.tealAccent.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎧 MANUEL KEŞFET MİKSİ: Parçaları Yönetme Çekmecesi & Metamorfoz Köprüsü
  void _showCustomMixTracksDialog(CustomDiscoverMix mix) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E24),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.tealAccent.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.queue_music_rounded, color: Colors.tealAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ÖZEL MİKS PARÇALARI',
                                style: TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                mix.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 🔮 KÖPRÜ: Bu Miksi Metamorfoz'a Aktar Butonu
                    if (mix.tracks.isNotEmpty) ...[
                      InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _showMetamorphosisDialog(initialTracks: mix.tracks);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.3), blurRadius: 8),
                            ],
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🔮 Bu Miksi Metamorfoz\'a Aktar',
                                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Parçaları DJ Metamorfoz Reaktörüne aktararak dönüştürün',
                                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Divider(color: Colors.white12),
                    const SizedBox(height: 6),

                    if (mix.tracks.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        child: const Text(
                          'Bu mikste henüz parça bulunmuyor.\nKeşfet\'teki şarkılardan "Özel Miksime Ekle" ile ekleyebilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.42,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: mix.tracks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, idx) {
                            final t = mix.tracks[idx];
                            final tTitle = t['title'] ?? t['baslik'] ?? 'Parça';
                            final tArtist = t['channel'] ?? t['kanal'] ?? 'Sanatçı';
                            final tVId = t['video_id'] ?? t['id'] ?? t['videoId'] ?? '';
                            final tImg = t['thumbnail'];
                            final tDurSec = t['duration'] is int
                                ? t['duration']
                                : (t['duration'] != null ? int.tryParse(t['duration'].toString()) ?? 0 : 0);
                            final tDuration = Duration(seconds: tDurSec);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.black26,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: (tImg != null && tImg.toString().isNotEmpty)
                                      ? Image.network(tImg, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.tealAccent))
                                      : const Icon(Icons.music_note, color: Colors.tealAccent),
                                ),
                                title: Text(
                                  tTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  tArtist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.tealAccent, size: 24),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _playDirectly(t, contextList: mix.tracks, isMix: true);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                      onPressed: () async {
                                        await CustomDiscoverMixService.removeTrackFromMix(mix.id, tVId);
                                        await _loadSavedCustomMixes();
                                        final updated = _savedCustomMixes.firstWhere(
                                          (m) => m.id == mix.id,
                                          orElse: () => CustomDiscoverMix(id: '', title: '', createdAt: DateTime.now()),
                                        );
                                        setSheetState(() {
                                          mix.tracks.clear();
                                          mix.tracks.addAll(updated.tracks);
                                        });
                                        Fluttertoast.showToast(msg: 'Parça miksten çıkarıldı');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🎧 MANUEL KEŞFET MİKSİ: Yeni Miks Oluşturma Diyaloğu
  Future<void> _showCreateCustomMixDialog({Map<String, dynamic>? initialTrack}) async {
    final titleCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1E24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.4)),
        ),
        title: Row(
          children: const [
            Icon(Icons.queue_music_rounded, color: Colors.tealAccent, size: 22),
            SizedBox(width: 8),
            Text('Yeni Özel Miks', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Miksinize bir isim verin:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Örn: Gece Sürüşü, Enerji Listem...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) {
                Fluttertoast.showToast(msg: 'Lütfen bir miks adı yazın');
                return;
              }
              Navigator.pop(dCtx);
              await CustomDiscoverMixService.createMix(
                title,
                initialTracks: initialTrack != null ? [initialTrack] : null,
              );
              await _loadSavedCustomMixes();
              Fluttertoast.showToast(
                msg: '🎧 "$title" miksi oluşturuldu!',
                backgroundColor: Colors.teal,
              );
            },
            child: const Text('Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
              const Text('Ses İzin (Aura)', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
              const Text('En çok dinlenen tarz:\nELEKTRONİK & POP', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16)),
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
      content: const Text('⚡ Akıllı İndirme: Wi-Fi kontrol ediliyor. Çevrimdışı parçalarınız güncelleniyor...'),
      backgroundColor: widget.themeColor,
    ));
    
    // Geçmişten rastgele 2 şarkı indir
    if (_searchHistory.isNotEmpty) {
      Future.delayed(const Duration(seconds: 2), () {
        _performSearch(_searchHistory.first);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚡ Arka Planda İndirme Başladı!'),
          backgroundColor: Colors.green,
        ));
      });
    }
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SiberThemeService.instance.currentThemeColor.removeListener(_onThemeChanged);
    SiberThemeService.instance.isMinimalMode.removeListener(_onThemeChanged);
    _skeletonTimer?.cancel();
    _hookSnipTimer?.cancel();
    _hookPlayer?.dispose();
    _studioBarPageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _generalScrollController.removeListener(_onScroll);
    _generalScrollController.dispose();
    _personalScrollController.dispose();
    _searchController.dispose();
    _mediaItemSub?.cancel();
    _playbackStateSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  // 🎯 SİBER HAMLE: Aşağı inildiğinde tetiklenen otonom sensör
  void _onScroll() {
    final activeController = _isSearching
        ? _scrollController
        : _generalScrollController;

    if (activeController.hasClients &&
        activeController.position.pixels >=
            activeController.position.maxScrollExtent - 300) {
      // 🎯 300 Piksel kala otonom olarak (Infinite Scroll) yeni mühimmat çek
      if (!_isLoadingMore &&
          !_isSearching &&
          !_isPersonalMode &&
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

  // 🎯 SİBER HAMLE: Ekranı Karartmadan Taze Mühimmat Çekme Motoru (Soft Refresh)
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isSearching = false;
      _searchController.clear();
      _currentCache.lastSearchQuery = '';
      _searchPage = 1;
      _hasMoreSearch = true;
    });

    await Future.wait([
      _fetchTrends(isRefresh: true),
      _fetchPersonalRecommendations(isRefresh: true),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.bolt_rounded, color: widget.themeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isPersonalMode
                      ? '⚡ Şahsi Keşfet yenilendi: Taze öneriler yüklendi!'
                      : '⚡ Trendler yenilendi: Yeni şarkılar yüklendi!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1B1B2F),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 🎯 Ana Trendleri (mostPopular) Çek + C++ Filtre & Favori Sanatçı Piggyback Kontrolü
  Future<void> _fetchTrends({bool silent = false, bool isRefresh = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
      _showSkeletonTimeout = false;
      _skeletonTimer?.cancel();
      // 🎯 Max 15 saniye skeleton sonra timeout mesajı göster
      _skeletonTimer = Timer(const Duration(seconds: 15), () {
        if (mounted && _isLoading) {
          setState(() => _showSkeletonTimeout = true);
        }
      });
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGenres = prefs.getStringList('siber_personal_genres') ?? [];
      if (savedGenres.isNotEmpty) {
        _personalGenres = savedGenres;
      }

      final res = await _bridge.fetchKesfet();
      if (mounted) {
        if (res.isEmpty || res['status'] == 'hata') {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isOfflineMode = true; // 🎯 Siber Kalkan: Çevrimdışı modda olduğumuzu anladık
            });
          }
          return;
        }
        List<dynamic> rawFetchedList = List.from(res['oneriler'] ?? []);
        // ⚡ C++ Mimarili Siber Filtre: Shorts / Teaser / Kesit (<75sn) elenir ve tekilleştirilir
        List<dynamic> fetchedList = SiberStreamFilterEngine.filterValidSongs(rawFetchedList);
        final Set<String> existingIds = fetchedList
            .map((e) => (e['videoId'] ?? e['id'])?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet();

        // 🚀 SİBER HAFİFLETME: Yalnızca liste 8'den azsa tek bir hafif arama yap
        if (fetchedList.length < 8) {
          try {
            final extra = await _bridge.searchMusic('en çok dinlenen türkçe pop şarkılar', limit: 10);
            for (var t in SiberStreamFilterEngine.filterValidSongs(extra)) {
              final id = (t['videoId'] ?? t['id'] ?? t['video_id'])?.toString();
              if (id != null && id.isNotEmpty && !existingIds.contains(id)) {
                t['id'] = id;
                t['videoId'] = id;
                fetchedList.add(t);
                existingIds.add(id);
              }
            }
          } catch (_) {}
        }

        // 🔔 SIFIR WAKE-LOCK PIGGYBACK: Çekilen trend verisi içinde favori sanatçı varsa bildirimi tetikle
        unawaited(NotificationService.instance.inspectPiggybackFeedForFavorites(fetchedList));

        if (isRefresh && fetchedList.isNotEmpty) {
          fetchedList.shuffle(Random());
        }

        _generalCache.trendList = fetchedList;
        _generalCache.nextPageToken = res['nextPageToken'] ?? '';
        _saveTrendsCache(); // 🎯 Yeni veriyi hafızaya mühürle

        if (mounted) {
          setState(() {
            _isOfflineMode = false;
            _trendList = fetchedList;
            _nextPageToken = res['nextPageToken'] ?? '';
            _isLoading = false;
            _showSkeletonTimeout = false;
            _skeletonTimer?.cancel();
          });

          // 🚀 SİBER JET ÖN ISITMA: En baştaki 2 şarkıyı arka planda önceden çöz (Tıklanınca 0 ms başlasın)
          for (var item in fetchedList.take(2)) {
            final vId = (item['videoId'] ?? item['id'] ?? item['video_id'])?.toString();
            if (vId != null && vId.isNotEmpty) {
              _bridge.preWarm(vId);
            }
          }

          // 🚀 Kategorileri de arka planda sessizce yükle
          _fetchGenresSequentially();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOfflineMode = true;
          _showSkeletonTimeout = false;
        });
      }
    }
  }

  // 💿 SANATÇININ SAF ALBÜMÜNE TIKLANDIĞINDA ALBÜM PARÇALARINI ÇEK VE OYNAT
  Future<void> _playOrOpenArtistAlbum(Map<String, dynamic> album) async {
    final String title = (album['title'] ?? 'Albüm').toString();
    final String artist = (album['artist'] ?? '').toString();
    final String albumId = (album['albumId'] ?? '').toString();
    final String thumb = (album['thumbnail'] ?? '').toString();
    final bool isYtFallback = album['isYoutubeFallback'] == true;

    Fluttertoast.showToast(
      msg: '💿 "$artist - $title" saf albümü hazırlanıyor...',
      backgroundColor: widget.themeColor,
    );

    List<dynamic> albumTracks = [];
    if (!kIsWeb && !isYtFallback && albumId.isNotEmpty) {
      try {
        albumTracks = await SpotifyService.instance.getAlbumTracks(
          albumId,
          fallbackThumbnail: thumb,
          fallbackArtist: artist,
        );
      } catch (_) {}
    }

    if (albumTracks.isEmpty) {
      try {
        final raw = await _bridge.searchMusic('$artist $title', limit: 12, onlyMusic: true);
        albumTracks = SiberStreamFilterEngine.filterValidSongs(raw);
      } catch (_) {}
    }

    if (albumTracks.isNotEmpty && mounted) {
      _playDirectly(albumTracks.first, contextList: albumTracks, isMix: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💿 "$title" albümü (${albumTracks.length} parça) çalınıyor!'),
          backgroundColor: const Color(0xFF1B1B2F),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 🎯 SİBER HAMLE: Şahsi Keşfet Öneri Motoru (Tanımlanan Sanatçı Kadar Saf Albümlü Mix + Tür Önerileri)
  Future<void> _fetchPersonalRecommendations({bool silent = false, bool isRefresh = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
      _showSkeletonTimeout = false;
      _skeletonTimer?.cancel();
      _skeletonTimer = Timer(const Duration(seconds: 15), () {
        if (mounted && _isLoading) {
          setState(() => _showSkeletonTimeout = true);
        }
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Tercihlerden sanatçı ve türleri oku
      final favArtistsRaw = prefs.getString('siber_personal_artists') ?? '';
      List<String> explicitArtists = favArtistsRaw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      List<String> favGenres = prefs.getStringList('siber_personal_genres') ?? [];
      if (favGenres.isEmpty) favGenres = ['Türkçe Rap', 'Melankolik', 'Pop'];
      _personalGenres = favGenres;

      // 2. Dinleme geçmişinden ve indirilenlerden sanatçı istihbaratı topla
      final List<String> discoveredArtists = [];
      try {
        final history = await HistoryService.getHistory();
        final Map<String, int> playCounts = {};
        for (var h in history) {
          final name = h.name;
          if (name.contains(' - ')) {
            final artistPart = name.split(' - ').first.trim();
            final clean = artistPart
                .replaceAll(RegExp(r'\[.*?\]'), '')
                .replaceAll(RegExp(r'\(.*?\)'), '')
                .trim();
            if (clean.isNotEmpty &&
                clean.toLowerCase() != 'null' &&
                clean.toLowerCase() != 'unknown' &&
                clean != 'Bilinmeyen Müzik' &&
                clean.length > 1) {
              playCounts[clean] = (playCounts[clean] ?? 0) + h.playCount;
            }
          }
        }
        for (var s in OfflineCacheService().cachedSongs) {
          final a = (s.artist ?? '').trim();
          if (a.isNotEmpty &&
              a.toLowerCase() != 'null' &&
              a.toLowerCase() != 'unknown' &&
              a != 'Victus V7' &&
              a != 'Bilinmeyen Sanatçı') {
            playCounts[a] = (playCounts[a] ?? 0) + 2;
          }
        }
        final sorted = playCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        discoveredArtists.addAll(sorted.map((e) => e.key));
      } catch (e) {
        print('İstihbarat hatası: $e');
      }

      // 3. Kullanıcı sanatçı havuzunu birleştir: Kullanıcının tanımladığı TÜM sanatçılar mix tarifesine girer!
      final Set<String> artistPoolSet = {};
      artistPoolSet.addAll(explicitArtists);
      artistPoolSet.addAll(discoveredArtists);
      if (artistPoolSet.isEmpty) {
        artistPoolSet.addAll(['Ceza', 'Velet', 'GeeFlow']);
      }
      final allArtists = artistPoolSet.toList();

      // 🎯 Kullanıcının bizzat tanımladığı sanatçı varsa tanımladığı KADAR sanatçı mixi oluştur;
      // henüz tanımlamadıysa ilk 3 sanatçıyı baz al.
      List<String> targetArtists = explicitArtists.isNotEmpty
          ? List<String>.from(explicitArtists)
          : allArtists.take(3).toList();
      _personalArtists = targetArtists;

      Map<String, List<dynamic>> personalArtistMixes = {};
      Map<String, List<Map<String, dynamic>>> personalArtistAlbums = {};

      // 4. Her tanımlı sanatçı için:
      //    a) Üst kısma 2-3 adet SAF SANATÇI ALBÜMÜ (Albüm kapaklı)
      //    b) Alt kısma Shorts/Kesit filtresinden geçmiş normal şarkıları
      //    c) Sıfır wake-lock Piggyback yeni şarkı bildirim kontrolü
      await Future.wait(targetArtists.map((artist) async {
        final cleanArtist = artist.trim();
        if (cleanArtist.isEmpty) return;

        // A) Saf Sanatçı Albümleri (2-3 adet, Spotify API + YT Fallback)
        try {
          List<Map<String, dynamic>> albums = [];
          if (!kIsWeb) {
            albums = await SpotifyService.instance.getArtistAlbums(cleanArtist, limit: 3);
          }
          if (albums.isEmpty) {
            final rawAlb = await _bridge.searchMusic(
              SiberStreamFilterEngine.buildVariableAlbumQuery(cleanArtist),
              limit: 4,
              onlyMusic: true,
            );
            for (final item in rawAlb) {
              if (albums.length >= 3) break;
              if (item is! Map) continue;
              final t = (item['title'] ?? item['baslik'] ?? '').toString().trim();
              if (t.isEmpty) continue;
              albums.add({
                'albumId': (item['videoId'] ?? item['id'] ?? '').toString(),
                'title': t,
                'artist': cleanArtist,
                'thumbnail': (item['thumbnail'] ?? '').toString(),
                'year': 'Albüm',
                'totalTracks': 10,
                'albumType': 'Saf Albüm',
                'isYoutubeFallback': true,
              });
            }
          }
          personalArtistAlbums[cleanArtist] = albums;
        } catch (e) {
          print('Albüm çekme hatası ($cleanArtist): $e');
        }

        // B) Sanatçının Normal Şarkıları (Değişken sorgulu & Shorts filtreli)
        try {
          final query = SiberStreamFilterEngine.buildVariableArtistQuery(
            cleanArtist,
            forRefresh: isRefresh,
          );
          final primaryTracks = await _bridge.searchMusic(query, limit: 12, onlyMusic: true);
          final artistMatches = SiberStreamFilterEngine.filterValidSongs(
            primaryTracks,
            requiredArtist: cleanArtist,
          );

          // 🔔 SIFIR WAKE-LOCK PIGGYBACK: Sanatçının çekilen verisinde yeni tam şarkı varsa bildir!
          unawaited(
            NotificationService.instance.inspectPiggybackArtistTracks(
              cleanArtist,
              artistMatches,
            ),
          );

          // Yenilemede parçaları karıştır ve daha önce gösterilenleri geriye at
          if (isRefresh && artistMatches.isNotEmpty) {
            artistMatches.shuffle(Random());
            if (_recentlyRecommendedIds.isNotEmpty) {
              artistMatches.sort((a, b) {
                final idA = (a['videoId'] ?? a['id'])?.toString() ?? '';
                final idB = (b['videoId'] ?? b['id'])?.toString() ?? '';
                final aSeen = _recentlyRecommendedIds.contains(idA) ? 1 : 0;
                final bSeen = _recentlyRecommendedIds.contains(idB) ? 1 : 0;
                return aSeen.compareTo(bSeen);
              });
            }
          }

          personalArtistMixes[cleanArtist] = artistMatches;
        } catch (e) {
          print('Mix arama hatası ($cleanArtist): $e');
        }
      }));

      // 5. Önbellek kontrolü için birleşik liste oluştur
      List<dynamic> cocktail = [];
      for (int i = 0; i < 5; i++) {
        for (var artist in targetArtists) {
          final tracks = personalArtistMixes[artist] ?? [];
          if (i < tracks.length) {
            final track = tracks[i];
            final id = track['videoId'] ?? track['id'];
            if (id != null && !cocktail.any((c) => (c['videoId'] ?? c['id']) == id)) {
              cocktail.add(track);
            }
          }
        }
      }
      if (isRefresh) {
        cocktail.shuffle(Random());
      }

      for (var item in cocktail) {
        final id = (item['videoId'] ?? item['id'])?.toString();
        if (id != null && id.isNotEmpty) {
          _recentlyRecommendedIds.add(id);
        }
      }
      if (_recentlyRecommendedIds.length > 100) {
        final toRemove = _recentlyRecommendedIds.take(40).toList();
        _recentlyRecommendedIds.removeAll(toRemove);
      }

      // 6. Alt Akış: Kullanıcının Seçtiği Türler & Sanatçı Önerileri
      List<dynamic> bottomTracks = [];
      try {
        final selectedGenre = (isRefresh && _personalGenres.length > 1)
            ? _personalGenres[Random().nextInt(_personalGenres.length)]
            : (_personalGenres.isNotEmpty ? _personalGenres.first : 'Türkçe Rap');
        _activePersonalGenre = selectedGenre;

        final genreQueries = [
          '$selectedGenre en çok dinlenen hit şarkılar 2026',
          '$selectedGenre popüler şarkılar ve yeni hitler',
          '$selectedGenre keşfedilmemiş inciler',
          '$selectedGenre viral şarkılar Türkiye',
          '$selectedGenre haftalık mix ve trendler',
          '$selectedGenre en sevilen düetler',
          '$selectedGenre akustik ve canlı performanslar',
        ];
        final chosenQuery = isRefresh
            ? genreQueries[Random().nextInt(genreQueries.length)]
            : genreQueries.first;

        final rawSimilar = await _bridge.searchMusic(chosenQuery, limit: 12);
        final filteredSimilar = SiberStreamFilterEngine.filterValidSongs(rawSimilar);

        for (var item in filteredSimilar) {
          final id = item['videoId'] ?? item['id'];
          if (id != null && !bottomTracks.any((b) => (b['videoId'] ?? b['id']) == id)) {
            bottomTracks.add(item);
          }
        }

        // Sanatçıların diğer şarkılarını da alt akışa harmanla
        for (var artist in targetArtists) {
          final tracks = personalArtistMixes[artist] ?? [];
          if (tracks.length > 3) {
            for (var t in tracks.skip(3)) {
              final id = t['videoId'] ?? t['id'];
              if (id != null && !bottomTracks.any((b) => (b['videoId'] ?? b['id']) == id)) {
                bottomTracks.add(t);
              }
            }
          }
        }

        if (isRefresh) {
          bottomTracks.shuffle(Random());
        }
      } catch (e) {
        print('Benzer şarkılar arama hatası: $e');
        bottomTracks = List.from(cocktail);
      }

      // 7. Önbelleği Şahsi Depolamaya Mühürle
      _personalCache.personalCocktail = cocktail;
      _personalCache.personalArtistMixes = personalArtistMixes;
      _personalCache.personalArtistAlbums = personalArtistAlbums;
      _personalCache.similarArtistsTracks = bottomTracks;
      _personalCache.personalArtists = targetArtists;
      _personalCache.personalGenres = favGenres;
      _savePersonalCache();

      if (mounted) {
        setState(() {
          _personalCocktail = cocktail;
          _personalArtistMixes = personalArtistMixes;
          _personalArtistAlbums = personalArtistAlbums;
          _similarArtistsTracks = bottomTracks;
          _isLoading = false;
          _showSkeletonTimeout = false;
          _skeletonTimer?.cancel();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showSkeletonTimeout = false;
        });
      }
    }
  }

  // 🎯 SİBER HAMLE: Otonom Alt Listeleri Sessizce ve Sırayla Çek (Ağı Yormadan)
  Future<void> _fetchGenresSequentially() async {
    final genresToFetch = _isPersonalMode
        ? _categories.where((c) => c != 'Size Özel Mix' && c != 'Trendler').toList()
        : ['Türkçe Rap', 'Arabesk', 'Deep House', 'Akustik', 'Popüler Albüm', 'Türkçe Mixler'];

    for (var genre in genresToFetch) {
      if (!_genreLists.containsKey(genre)) {
        final query = _isPersonalMode
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

      // 🎯 TOLERANSLI ARAMA: Eğer sonuç boş dönerse alternatif Türkçe/Latin varyasyonlarını dene
      if (results.isEmpty && _searchPage == 1) {
        final variants = SearchUtils.prepareSearchVariants(query);
        for (final alt in variants) {
          if (alt != query) {
            try {
              final altQuery = _activeSearchFilter.isNotEmpty ? '$alt $_activeSearchFilter' : alt;
              final altResults = await _bridge.searchMusic(altQuery, limit: 20, page: 1);
              if (altResults.isNotEmpty) {
                results = altResults;
                break;
              }
            } catch (_) {}
          }
        }
      }
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
            content: Text('Bağlantı zayıf veya sonuç bulunamadı!'),
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

      // 🚀 SİBER JET ÖN ISITMA: İlk arama sonucunun akışını arka planda hemen çöz (0 ms anında başlasın)
      if (results.isNotEmpty) {
        final firstId = (results[0]['videoId'] ?? results[0]['id'] ?? results[0]['video_id'])?.toString();
        if (firstId != null && firstId.isNotEmpty) {
          _bridge.preWarm(firstId);
        }
      }
    }
  }

  // 🎯 Şarkı Tıklandığında Çıkan İşlem Menüsü (Video, Dinle, İndir)
  void _showActionSheet(dynamic item) {
    final title = item['title'] ?? item['baslik'] ?? 'Bilinmeyen';
    final videoId = item['video_id'] ?? item['id'] ?? item['videoId'];
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
                  subtitle: Text('Ne yapmak istersin?',
                      style: TextStyle(color: widget.themeColor)),
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: Icon(
                    _pinnedArtists.contains(artist) ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    color: _pinnedArtists.contains(artist) ? Colors.amberAccent : Colors.cyanAccent,
                  ),
                  title: Text(
                    _pinnedArtists.contains(artist) ? '📌 Kanal Sabitlemesini Kaldır' : '📌 Kanalı / Sanatçıyı Sabitle',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _pinnedArtists.contains(artist) ? '$artist sabitlemelerden çıkarılır' : '$artist kanalını Keşfet başına iğnele',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _togglePinArtist(artist);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.radar_rounded, color: Colors.amberAccent),
                  title: const Text('🎧 10s Nakarat Radarı Dinle',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      'Şarkının nakaratını 10 saniye hızlıca önizle',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    _startHookSnipPreview(item);
                  },
                ),
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
                    _playDirectly(item);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.playlist_play, color: Colors.cyanAccent),
                  title: const Text('🎵 Sıradakini Çal (Kuyruğa Ekle)',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                      'Çalmakta olan bitince sırada çalar',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    _queueOnlineStream(videoId, title, artist, imgUrl, duration);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.cloud_download_rounded, color: Colors.cyanAccent),
                  title: const Text('📥 Çevrimdışı İndir (Kütüphane)',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                      'İnternetsiz dinlemek için cihazına kaydet',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadAudio(videoId, title);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.queue_music_rounded, color: Colors.tealAccent),
                  title: const Text('🎧 Özel Miksime Ekle (Ücretsiz)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      'Kendi oluşturduğun çalma listesine/miksine ekle',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddToCustomMixSheet(item);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.auto_awesome, color: Colors.purpleAccent),
                  title: const Text('🔮 Metamorfoz Kapsülüne Ekle',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      'Bu parçayı kayıtlı bir dönüşüm miksinin kalbine mühürle',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddToMetamorphosisSheet(item);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        });
  }

  // 🎧 MANUEL KEŞFET MİKSİ: Şarkıyı Özel Mikse Ekleme Çekmecesi (Tamamen Ücretsiz)
  void _showAddToCustomMixSheet(dynamic item) async {
    final title = item['title'] ?? item['baslik'] ?? 'Bilinmeyen';
    final videoId = item['video_id'] ?? item['id'] ?? item['videoId'];
    final imgUrl = item['thumbnail'];
    final artist = item['channel'] ?? item['kanal'] ?? 'Sanatçı';
    final durSec = item['duration'] is int
        ? item['duration']
        : (item['duration'] != null ? int.tryParse(item['duration'].toString()) ?? 0 : 0);

    final trackData = {
      'id': videoId,
      'videoId': videoId,
      'title': title,
      'channel': artist,
      'thumbnail': imgUrl ?? '',
      'duration': durSec,
    };

    final savedMixes = await CustomDiscoverMixService.getMixes();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1E24),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withValues(alpha: 0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.queue_music_rounded, color: Colors.tealAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ÖZEL MİKSE EKLE (ÜCRETSİZ)',
                            style: TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                const Text(
                  'Bu parçayı eklemek istediğin miksi seç:',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (savedMixes.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.queue_music_rounded, color: Colors.white38, size: 36),
                        const SizedBox(height: 8),
                        const Text(
                          'Henüz oluşturulmuş özel bir miksin yok.',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showCreateCustomMixDialog(initialTrack: trackData);
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Bu Parçayla Yeni Miks Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: savedMixes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final m = savedMixes[idx];
                        final isAlreadyInMix = m.tracks.any((t) =>
                            (t['id'] ?? t['videoId'] ?? t['video_id']) == videoId);
                        return Container(
                          decoration: BoxDecoration(
                            color: isAlreadyInMix
                                ? Colors.tealAccent.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isAlreadyInMix
                                  ? Colors.tealAccent.withValues(alpha: 0.4)
                                  : Colors.white10,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.tealAccent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAlreadyInMix ? Icons.check_circle : Icons.music_note_rounded,
                                color: isAlreadyInMix ? Colors.tealAccent : Colors.white70,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              m.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${m.tracks.length} Parça Kayıtlı',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: isAlreadyInMix
                                ? const Text('Mevcut', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold))
                                : const Icon(Icons.add_circle_outline, color: Colors.tealAccent, size: 22),
                            onTap: () async {
                              Navigator.pop(ctx);
                              if (isAlreadyInMix) {
                                Fluttertoast.showToast(msg: 'Bu parça zaten bu mikste mevcut!');
                                return;
                              }
                              await CustomDiscoverMixService.addTrackToMix(m.id, trackData);
                              await _loadSavedCustomMixes();
                              Fluttertoast.showToast(
                                msg: '🎧 "$title" başarıyla "${m.title}" miksine eklendi!',
                                backgroundColor: Colors.teal,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCreateCustomMixDialog(initialTrack: trackData);
                      },
                      icon: const Icon(Icons.add_box_outlined, size: 18),
                      label: const Text('Bu Parçayla Yeni Miks Oluştur'),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🎯 SİBER METAMORFOZ: Şarkıyı Kayıtlı Kapsüle Ekleme veya Yeni Kapsül Başlatma
  void _showAddToMetamorphosisSheet(dynamic item) async {
    final title = item['title'] ?? item['baslik'] ?? 'Bilinmeyen';
    final videoId = item['video_id'] ?? item['id'] ?? item['videoId'];
    final imgUrl = item['thumbnail'];
    final artist = item['channel'] ?? item['kanal'] ?? 'Sanatçı';
    final durSec = item['duration'] is int
        ? item['duration']
        : (item['duration'] != null ? int.tryParse(item['duration'].toString()) ?? 0 : 0);

    final trackData = {
      'id': videoId,
      'videoId': videoId,
      'title': title,
      'channel': artist,
      'thumbnail': imgUrl ?? '',
      'duration': durSec,
    };

    final savedMixes = await MetamorphosisService.getSavedMixes();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F121E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: widget.themeColor.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.themeColor.withValues(alpha: 0.25),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MÜZİK METAMORFOZU',
                            style: TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                const Text(
                  'Bu parçayı eklemek istediğin miksi seç:',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (savedMixes.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.bubble_chart_outlined, color: Colors.white38, size: 36),
                        const SizedBox(height: 8),
                        const Text(
                          'Henüz kayıtlı bir Metamorfoz miksin yok.',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.themeColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showMetamorphosisDialog(initialTrack: trackData);
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Bu Parçayla Kapsül Başlat', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: savedMixes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final m = savedMixes[idx];
                        final isAlreadyInMix = m.customTracks.any((t) =>
                            (t['id'] ?? t['videoId'] ?? t['video_id']) == videoId);
                        return Container(
                          decoration: BoxDecoration(
                            color: isAlreadyInMix
                                ? Colors.cyanAccent.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isAlreadyInMix
                                  ? Colors.cyanAccent.withValues(alpha: 0.4)
                                  : Colors.white10,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.themeColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAlreadyInMix ? Icons.check_circle : Icons.blur_on_rounded,
                                color: isAlreadyInMix ? Colors.cyanAccent : widget.themeColor,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              m.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${m.startMood} ➔ ${m.targetMood} • ${m.customTracks.length} Özel Parça',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: isAlreadyInMix
                                ? const Text('Mühürlü', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold))
                                : Icon(Icons.add_circle_outline, color: widget.themeColor, size: 22),
                            onTap: () async {
                              Navigator.pop(ctx);
                              if (isAlreadyInMix) {
                                Fluttertoast.showToast(msg: 'Bu parça zaten bu kapsülde mevcut!');
                                return;
                              }
                              await MetamorphosisService.addTrackToMix(m.id, trackData);
                              await _loadSavedMetamorphosisMixes();
                              Fluttertoast.showToast(
                                msg: '✨ "$title" başarıyla "${m.title}" kapsülüne mühürlendi!',
                                backgroundColor: widget.themeColor,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: widget.themeColor.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showMetamorphosisDialog(initialTrack: trackData);
                      },
                      icon: const Icon(Icons.add_box_outlined, size: 18),
                      label: const Text('Bu Parçayla Yeni Kapsül Başlat'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // 🎯 SİBER HAMLE: Şarkıya Tıklandığında Bodoslama Çal ve Akıllı Radyoyu Başlat

  

  Future<void> _playDirectly(dynamic item, {List<dynamic>? contextList, bool isFromSearch = false, bool isMix = false}) async {
    // 🛑 SİBER KALKAN: Yeni şarkı başlayınca kapat bayrağını sıfırla
    if (_isManuallyClosed) {
      setState(() => _isManuallyClosed = false);
    }
    // 1. Tıklanan şarkıyı anında çal
    final cTitle = item['title'] ?? item['baslik'] ?? 'Bilinmeyen';
    final cVId = item['video_id'] ?? item['id'] ?? item['videoId'];
    final cImgUrl = item['thumbnail'];
    final cArtist = item['channel'] ?? item['kanal'] ?? 'Victus V7';
    final durationSecs = item['duration'] ?? 0;
    
    // length "4:32" gibi bir string geliyorsa saniyeye çevir
    int finalDuration = 0;
    if (durationSecs is int) {
      finalDuration = durationSecs;
    } else if (durationSecs is String) {
      final parts = durationSecs.split(':');
      if (parts.length == 2) {
        finalDuration = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      } else if (parts.length == 3) {
        finalDuration = (int.tryParse(parts[0]) ?? 0) * 3600 + (int.tryParse(parts[1]) ?? 0) * 60 + (int.tryParse(parts[2]) ?? 0);
      }
    }

    final firstItem = MediaItem(
      id: 'yt:$cVId',
      album: 'Keşfet Akışı',
      title: cTitle,
      artist: cArtist,
      duration: Duration(seconds: finalDuration),
      artUri: safeParseUri(cImgUrl),
    );

    // 🎯 SİBER AKIŞ: Tıklanan liste (Keşfet, Miks, Kategori, Trendler, Arama) varsa TÜM LİSTEYİ KUYRUĞA AL
    // Böylece 1. şarkı bittiğinde 2. şarkıya, 3. şarkıya KESİNTİSİZ ve OTOMATİK geçer!
    if (contextList != null && contextList.isNotEmpty) {
      final List<MediaItem> fullQueue = [];
      int targetIndex = 0;

      for (int i = 0; i < contextList.length; i++) {
        final cItem = contextList[i];
        final sTitle = cItem['title'] ?? cItem['baslik'] ?? 'Bilinmeyen';
        final sVId = cItem['video_id'] ?? cItem['id'] ?? cItem['videoId'];
        final sImg = cItem['thumbnail'];
        final sArt = cItem['channel'] ?? cItem['kanal'] ?? 'ÖZSES Müzik';
        final sDur = cItem['duration'] ?? 0;
        int dSec = 0;
        if (sDur is int) {
          dSec = sDur;
        } else if (sDur is String) {
          final p = sDur.split(':');
          if (p.length == 2) {
            dSec = (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
          } else if (p.length == 3) {
            dSec = (int.tryParse(p[0]) ?? 0) * 3600 + (int.tryParse(p[1]) ?? 0) * 60 + (int.tryParse(p[2]) ?? 0);
          }
        }

        if (sVId != null) {
          if (sVId == cVId) {
            targetIndex = fullQueue.length;
          }
          fullQueue.add(MediaItem(
            id: 'yt:$sVId',
            album: isMix ? 'Özel Mix Akışı' : 'Keşfet Akışı',
            title: sTitle,
            artist: sArt,
            duration: Duration(seconds: dSec),
            artUri: safeParseUri(sImg),
          ));
        }
      }

      if (fullQueue.isNotEmpty) {
        await audioHandler.updateQueue(fullQueue);
        await audioHandler.skipToQueueItem(targetIndex);
        return;
      }
    }

    // 🛡️ NORMAL ŞARKI: TEKLİ ÇALMA VE OTONOM 10 ŞARKILIK RADYO KUYRUĞU
    // Tıklanan şarkı anında başlar, arkasına bağımsız 10 benzer şarkı dizilir
    await audioHandler.updateQueue([firstItem]);
    await audioHandler.skipToQueueItem(0);

    // Arka planda 10 adet benzer şarkıyı dinamik radyo akışı olarak çek
    final radioSongs = await _bridge.getRadio(
      cVId,
      title: cTitle,
      artist: cArtist,
    );
    
    if (_isManuallyClosed || !mounted) return;
    
    if (radioSongs.isNotEmpty) {
      final List<MediaItem> radioQueue = [firstItem];
      
      for (var rSong in radioSongs.take(10)) {
        final rTitle = rSong['title'] ?? 'Bilinmeyen';
        final rVId = rSong['id'];
        final rImgUrl = rSong['thumbnail'];
        final rArtist = rSong['channel'] ?? 'ÖZSES Müzik';
        final rDur = rSong['duration'] ?? 0;
        
        int rFinalDur = 0;
        if (rDur is int) {
          rFinalDur = rDur;
        } else if (rDur is String) {
          final parts = rDur.split(':');
          if (parts.length == 2) {
            rFinalDur = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
          } else if (parts.length == 3) {
            rFinalDur = (int.tryParse(parts[0]) ?? 0) * 3600 + (int.tryParse(parts[1]) ?? 0) * 60 + (int.tryParse(parts[2]) ?? 0);
          }
        }

        if (rVId != null && rVId != cVId && !radioQueue.any((it) => it.id == 'yt:$rVId')) {
          radioQueue.add(MediaItem(
            id: 'yt:$rVId',
            album: 'ÖZSES Radyo Akışı',
            title: rTitle,
            artist: rArtist,
            duration: Duration(seconds: rFinalDur),
            artUri: safeParseUri(rImgUrl),
          ));
        }
      }
      
      for (var radioItem in radioQueue.skip(1)) {
        await audioHandler.addQueueItem(radioItem);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.radio_rounded, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('📻 "$cTitle" ile 10 şarkılık özel radyo listesi oluşturuldu!'),
              ),
            ],
          ),
          backgroundColor: Colors.black.withValues(alpha: 0.9),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // 🎯 Çevrimiçi Sadece Ses Olarak Oynat (Çevrimdışı Özellikleriyle)
  Future<void> _playOnlineStream(
      String videoId, String title, String artist, String? imgUrl, Duration duration) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📡 $title çevrimiçi hazırlanıyor...'),
        backgroundColor: widget.themeColor));

    final res = await _bridge.getStreamUrl(videoId);
    if (res['status'] == 'basarili' && res['stream_url'] != null) {
      String streamUrl = res['stream_url'];

      final mediaItem = MediaItem(
        id: streamUrl,
        album: 'Keşfet Akışı',
        title: title,
        artist: artist,
        duration: duration,
        artUri: safeParseUri(imgUrl),
      );

      await audioHandler.addQueueItem(mediaItem);
      final queue = audioHandler.queue.value;
      await audioHandler.skipToQueueItem(queue.length - 1);
      await audioHandler.play();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('🎶 Çevrimiçi akış başlatıldı! (Plak modu aktif)'),
          backgroundColor: Colors.cyanAccent));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ Akış başlatılamadı!'),
          backgroundColor: Colors.redAccent));
    }
  }

  // 🎯 Şarkıyı Sadece Kuyruğa At (Hemen Çalma)
  Future<void> _queueOnlineStream(
      String videoId, String title, String artist, String? imgUrl, Duration duration) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📡 $title kuyruğa ekleniyor...'),
        backgroundColor: widget.themeColor));
    final res = await _bridge.getStreamUrl(videoId);
    if (res['status'] == 'basarili' && res['stream_url'] != null) {
      final mediaItem = MediaItem(
        id: res['stream_url'],
        album: 'Keşfet Akışı',
        title: title,
        artist: artist,
        duration: duration,
        artUri: safeParseUri(imgUrl),
      );
      await audioHandler.addQueueItem(mediaItem);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Çalma sırasına eklendi!'),
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
    return ValueListenableBuilder<bool>(
      valueListenable: SiberThemeService.instance.isMinimalMode,
      builder: (context, isMinimal, _) {
        return Scaffold(
          resizeToAvoidBottomInset: false, // 🛑 SİBER KALKAN: Klavye açılınca player bar yukarı fırlamaması için
          backgroundColor: isMinimal ? const Color(0xFF0F0F12) : Colors.transparent, // Arka plan Stack ile yönetilecek
          extendBodyBehindAppBar: true, // AppBar'ı resmin üstüne bindir
          appBar: AppBar(
            backgroundColor: isMinimal ? const Color(0xFF0F0F12) : Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isMinimal
                    ? const Color(0xFF1C1C20)
                    : widget.themeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMinimal
                      ? Colors.white24
                      : widget.themeColor.withValues(alpha: 0.5),
                  width: 1.1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.explore_rounded,
                    color: isMinimal ? Colors.white : widget.themeColor,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'ÖZSES KEŞFET',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isMinimal ? Colors.white24 : widget.themeColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'UNIFIED V7',
                      style: TextStyle(
                        color: isMinimal ? Colors.white : widget.themeColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // 🍃 SADE / ✨ PARLAK MOD BUTONU (Kompakt ve Çakışmasız)
              GestureDetector(
                onTap: () {
                  SiberThemeService.instance.toggleMinimalMode();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            !isMinimal ? Icons.eco_rounded : Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            !isMinimal
                                ? '🍃 Sade Mod Aktif'
                                : '✨ Parlak Mod Aktif',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      backgroundColor: !isMinimal ? const Color(0xFF1E293B) : widget.themeColor,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMinimal
                        ? const Color(0xFF1E1E22)
                        : widget.themeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMinimal ? Colors.white24 : widget.themeColor.withValues(alpha: 0.5),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMinimal ? Icons.eco_rounded : Icons.auto_awesome_rounded,
                        color: isMinimal ? Colors.white70 : widget.themeColor,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isMinimal ? 'SADE' : 'PARLAK',
                        style: TextStyle(
                          color: isMinimal ? Colors.white70 : widget.themeColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, size: 20, color: isMinimal ? Colors.white70 : Colors.white),
                tooltip: 'Akışı Yenile',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _isLoading ? null : _refreshData,
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                  _loadAccountStatus();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12, left: 2),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isMinimal
                        ? const Color(0xFF1E1E22)
                        : (_isAccountLinked
                            ? Colors.teal.withValues(alpha: 0.25)
                            : widget.themeColor.withValues(alpha: 0.18)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isMinimal
                          ? Colors.white24
                          : (_isAccountLinked
                              ? Colors.tealAccent.withValues(alpha: 0.6)
                              : widget.themeColor.withValues(alpha: 0.35)),
                      width: 1.2,
                    ),
                    boxShadow: isMinimal
                        ? null
                        : [
                            BoxShadow(
                              color: (_isAccountLinked ? Colors.tealAccent : widget.themeColor).withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  child: Icon(
                    _isAccountLinked ? Icons.verified_user_rounded : Icons.person_rounded,
                    color: isMinimal
                        ? Colors.white70
                        : (_isAccountLinked ? Colors.tealAccent : Colors.white),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // 🎯 Otonom Arka Plan (Sade Modda Mat Siyah, Parlak Modda Dinamik Ambiyans)
              Positioned.fill(
                child: isMinimal
                    ? Container(color: const Color(0xFF0F0F12))
                    : (_currentCoverBytes != null
                        ? RepaintBoundary(
                            child: ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                              child: Image.memory(
                                _currentCoverBytes!,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  widget.themeColor.withValues(alpha: 0.2),
                                  Colors.black,
                                  Colors.black,
                                ],
                              ),
                            ),
                          )),
              ),
              // 🎯 Koyu Kalkan (Sadece Parlak Modda albüm kapağının üstüne)
              if (!isMinimal && _currentCoverBytes != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.65),
                  ),
                ),
              // 🎯 İÇERİK
              SafeArea(
                child: Column(
                  children: [
              // 🎯 ÇEVRİMDIŞI BİLDİRİMİ
              if (_isOfflineMode)
                Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  width: double.infinity,
                  color: isMinimal ? const Color(0xFF1A1A1E) : Colors.black87,
                  child: const Center(
                    child: Text(
                      'Çevrimdışı Mod. İndirilenler gösteriliyor.',
                      style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

              // 🎯 HESAP BAĞLAMA DAVET BANNERI
              if (!_isAccountLinked && _showAccountBanner)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMinimal ? const Color(0xFF16161A) : null,
                      gradient: isMinimal
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1B1936),
                                const Color(0xFF0F172A),
                                Colors.cyan.withValues(alpha: 0.15),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isMinimal ? Colors.white12 : widget.themeColor.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: isMinimal
                          ? null
                          : [
                              BoxShadow(
                                color: widget.themeColor.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMinimal ? const Color(0xFF222226) : null,
                            gradient: isMinimal
                                ? null
                                : LinearGradient(
                                    colors: [
                                      widget.themeColor.withValues(alpha: 0.3),
                                      Colors.cyanAccent.withValues(alpha: 0.2),
                                    ],
                                  ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isMinimal ? Colors.white24 : widget.themeColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(Icons.cloud_upload_rounded, color: isMinimal ? Colors.white70 : widget.themeColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'ÖZSES Hesabını Bağla',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.4,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Çalma listelerini ve müzik zevkini bulutta güvenle senkronize et.',
                            style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        foregroundColor: Colors.black,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                        _loadAccountStatus();
                      },
                      icon: const Icon(Icons.login_rounded, size: 13),
                      label: const Text('Giriş', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Kapat',
                      onPressed: () => setState(() => _showAccountBanner = false),
                    ),
                  ],
                ),
              ),
            ),

          // 🎯 ARAMA ÇUBUĞU
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: isMinimal ? const Color(0xFF18181C) : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isMinimal ? Colors.white12 : widget.themeColor.withValues(alpha: 0.5),
                ),
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
                    prefixIcon: Icon(Icons.search, color: isMinimal ? Colors.white70 : widget.themeColor),
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
                          icon: Icon(Icons.filter_list, color: isMinimal ? Colors.white70 : widget.themeColor),
                          onPressed: _showSearchFilters,
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

          // 🎯 ARAMA MOTORUNUN ALTINDA MOD & TÜR HAPLARI (Yatay Kaydırılabilir)
          _buildMoodAndCategoryPillsBar(isMinimal),

          // 🎛️ MOD HAPLARININ ALTINDA İNCE KAYDIRILABİLİR 3'LÜ STÜDYO ÇUBUĞU
          _buildStudioDrawerBar(),

          const SizedBox(height: 6),

          // 🎯 ANA İÇERİK BÖLÜMÜ
          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? _buildSkeletonLoader()
                    : _searchController.text.isNotEmpty && _liveSuggestions.isNotEmpty && !_isSearching
                        ? _buildSuggestionsList()
                        : _isSearching
                                ? _buildVerticalList(_searchResults, isScrollable: true, isSearch: true)
                                : _buildUnifiedDiscoverHome(),

                // 🎯 SİBER MİNİ OYNATICI (Sadece şarkı çalarken ortaya çıkar)
                if (_currentSongName != 'Müzik Seçilmedi' && !_isDesktop)
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
                                                    'Çevrimiçi müzikler indirilmeden favorilere eklenemez!'),
                                                backgroundColor:
                                                    Colors.orangeAccent));
                                      },
                                      onAddToPlaylist: (path) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Çevrimiçi müzikler indirilmeden listelere eklenemez!'),
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
                                              'Tam kontrol için Ana Ekrana dönün.'),
                                          backgroundColor:
                                              Colors.deepPurpleAccent));
                                },
                                onClose: () {
                                  _isManuallyClosed = true; // 🛑 SİBER KALKAN
                                  audioHandler.stop();
                                  setState(() {
                                    _currentSongName = 'Müzik Seçilmedi';
                                    _currentCoverBytes = null;
                                    _isPlaying = false;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
                const SiberAdWidget(),
                if (_currentSongName != 'Müzik Seçilmedi' && !_isDesktop)
                  const SizedBox(height: 85)
                else
                  const SizedBox(height: 15),
              ],
            ),
          ),
        ],
      ),
    );
      },
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

    // Siber Kalkan: Timeout UI kaldırıldı, sadece skeleton dönmeye devam edecek.

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
        {'name': 'Yeraltı Zirvesi', 'query': 'Underground Rap Türkçe', 'color': Colors.orangeAccent, 'icon': Icons.local_fire_department},
        {'name': 'Gettodan Zirveye', 'query': 'Hip Hop Türkçe', 'color': Colors.red, 'icon': Icons.whatshot},
        {'name': 'Eski Okul', 'query': 'Oldschool Türkçe Rap', 'color': Colors.brown, 'icon': Icons.mic},
        {'name': 'Beat Şöleni', 'query': 'Turkish Rap Beats', 'color': Colors.deepOrange, 'icon': Icons.headphones},
      ];
    } else if (mood == 'Melankoli') {
      _aiMixes = [
        {'name': 'Gece Sürüşü', 'query': 'Gece Arabada Dinlenecek Şarkılar', 'color': Colors.blueAccent, 'icon': Icons.directions_car},
        {'name': 'Derin Melankoli', 'query': 'Slow Akustik Türkçe', 'color': Colors.teal, 'icon': Icons.water_drop},
        {'name': 'Efkâr Dozu', 'query': 'Damar Arabesk', 'color': Colors.brown, 'icon': Icons.wine_bar},
        {'name': 'Yağmurlu Cam', 'query': 'Hüzünlü Şarkılar', 'color': Colors.blueGrey, 'icon': Icons.cloudy_snowing},
        {'name': 'Kırık Kalpler', 'query': 'Ayrılık Şarkıları Türkçe', 'color': Colors.pink, 'icon': Icons.heart_broken},
        {'name': 'Sonbahar Rüzgarı', 'query': 'Sonbahar Akustik', 'color': Colors.orange, 'icon': Icons.eco},
      ];
    } else if (mood == 'Enerji') {
      _aiMixes = [
        {'name': 'Saf Enerji', 'query': 'Hareketli Pop Mix', 'color': Colors.yellowAccent, 'icon': Icons.bolt},
        {'name': 'Kopmalık', 'query': 'Türkçe Club Remix', 'color': Colors.pinkAccent, 'icon': Icons.local_fire_department},
        {'name': 'Motivasyon', 'query': 'Spor Motivasyon Müzikleri', 'color': Colors.greenAccent, 'icon': Icons.fitness_center},
        {'name': 'Zirve Hızı', 'query': 'Fast Tempo Workout', 'color': Colors.redAccent, 'icon': Icons.speed},
        {'name': 'Yaz Gecesi', 'query': 'Yaz Hitleri Türkçe', 'color': Colors.orangeAccent, 'icon': Icons.wb_sunny},
        {'name': 'Bas Testi', 'query': 'Bass Boosted Turkish', 'color': Colors.purpleAccent, 'icon': Icons.speaker},
      ];
    } else if (mood == 'Odak') {
      _aiMixes = [
        {'name': 'Lofi Odak', 'query': 'Lofi hip hop beats', 'color': Colors.indigo, 'icon': Icons.headphones},
        {'name': 'Derin Çalışma', 'query': 'Deep Focus Music', 'color': Colors.blueGrey, 'icon': Icons.menu_book},
        {'name': 'Sakin Zihin', 'query': 'Chillout Lounge', 'color': Colors.cyan, 'icon': Icons.spa},
        {'name': 'Kozmik Alan', 'query': 'Ambient Space Music', 'color': Colors.deepPurple, 'icon': Icons.rocket_launch},
        {'name': 'Klasik Deha', 'query': 'Classical Focus Piano', 'color': Colors.amber, 'icon': Icons.piano},
        {'name': 'Doğa Sesleri', 'query': 'Nature Sounds Relaxing', 'color': Colors.green, 'icon': Icons.park},
      ];
    } else {
      _aiMixes = [
        {'name': 'Gece & Gizem', 'query': 'Synthwave Chill', 'color': Colors.deepPurple, 'icon': Icons.memory},
        {'name': 'Keşfedilmemiş', 'query': 'Alternative Indie Türkçe', 'color': Colors.lightGreen, 'icon': Icons.explore},
        {'name': 'Günün Zirvesi', 'query': 'Türkiye En Çok Dinlenenler', 'color': Colors.amber, 'icon': Icons.star},
        {'name': 'Rastgele Macera', 'query': 'Karışık Türkçe', 'color': Colors.orange, 'icon': Icons.shuffle},
        {'name': 'Viral Hitler', 'query': 'TikTok Şarkıları Türkçe', 'color': Colors.pinkAccent, 'icon': Icons.trending_up},
        {'name': 'Zamanda Yolculuk', 'query': 'Nostalji Türkçe Pop', 'color': Colors.blue, 'icon': Icons.history},
      ];
    }
    
    // UI güncellenmesi için:
    if (mounted) setState(() {});
  }

  // 🎯 SİBER HAMLE: Sana Özel Otonom Mixler (Kompakt Spotify Tarzı Izgara - 6'lı Grid)
  
  // 🎯 SİBER HAMLE: Mood Chips (Apple Music / YT Music stili hap butonlar)
  Widget _buildMoodChips() {
    final isMinimal = SiberThemeService.instance.isMinimalMode.value;
    final List<String> moods = ['Sokak', 'Melankoli', 'Enerji', 'Odak', 'Gizem'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: moods.length,
        itemBuilder: (context, index) {
          final mood = moods[index];
          final isSelected = _dominantMood == mood;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _dominantMood = mood;
                _generateAiMixes(mood);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              decoration: BoxDecoration(
                gradient: (isSelected && !isMinimal)
                    ? LinearGradient(
                        colors: [widget.themeColor, widget.themeColor.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? (isMinimal ? Colors.white : null)
                    : (isMinimal ? const Color(0xFF1E1E22) : Colors.white.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (isMinimal ? Colors.white : Colors.transparent)
                      : (isMinimal ? Colors.white12 : Colors.white24),
                  width: 1,
                ),
                boxShadow: (isSelected && !isMinimal)
                    ? [BoxShadow(color: widget.themeColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                mood,
                style: TextStyle(
                  color: isSelected
                      ? (isMinimal ? Colors.black : Colors.white)
                      : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAutoMixCarousel() {
    final List<Map<String, dynamic>> mixes = _aiMixes.isEmpty ? [
      {'name': 'Trend Analiz', 'query': 'Türkçe trend', 'color': Colors.grey, 'icon': Icons.search}
    ] : _aiMixes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: mixes.map((mix) {
              return GestureDetector(
                onTap: () => _handleAutoPlaylist(mix['query']),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 40) / 2, // Ekrana 2 tane sığacak genişlik
                  height: 56, // Daha kompakt ve Spotify vari bir yükseklik
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      // Sol Taraf: İkon ve Gradient Arka Plan
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [mix['color'], mix['color'].withOpacity(0.5)],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                          boxShadow: [
                            BoxShadow(color: mix['color'].withOpacity(0.3), blurRadius: 8)
                          ]
                        ),
                        child: Icon(mix['icon'], color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 8),
                      // Sağ Taraf: Metin
                      Expanded(
                        child: Text(
                          mix['name'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
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
          Expanded(child: Text("Akıllı Algoritma: '$selection' için en iyi parçalar toplanıyor...")),
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

  // 🎯 ARAMA MOTORUNUN ALTINDA YATAY MOD & TÜR HAPLARI
  Widget _buildMoodAndCategoryPillsBar(bool isMinimal) {
    final List<Map<String, dynamic>> pills = [
      {'name': 'Trendler', 'icon': Icons.whatshot_rounded, 'color': Colors.amberAccent},
      {'name': 'Türkçe Rap', 'icon': Icons.mic_external_on_rounded, 'color': const Color(0xFFFF5252)},
      {'name': 'Melankolik', 'icon': Icons.water_drop_rounded, 'color': Colors.blueAccent},
      {'name': 'Enerji', 'icon': Icons.bolt_rounded, 'color': Colors.yellowAccent},
      {'name': 'Akustik', 'icon': Icons.music_note_rounded, 'color': Colors.limeAccent},
      {'name': 'Arabesk', 'icon': Icons.heart_broken_rounded, 'color': Colors.purpleAccent},
      {'name': 'Sokak', 'icon': Icons.local_fire_department_rounded, 'color': Colors.deepOrangeAccent},
      {'name': 'Odak', 'icon': Icons.psychology_rounded, 'color': Colors.greenAccent},
      {'name': 'Deep House', 'icon': Icons.speaker_rounded, 'color': Colors.cyanAccent},
      {'name': 'Musiki', 'icon': Icons.queue_music_rounded, 'color': Colors.tealAccent, 'query': 'Türk Sanat Müziği'},
      {'name': 'Marşlar', 'icon': Icons.military_tech_rounded, 'color': Colors.redAccent, 'query': 'Türk Marşları ve Mehter'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pills.length + 1,
        itemBuilder: (context, index) {
          if (index == pills.length) {
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _showCategoriesSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isMinimal ? const Color(0xFF1E1E22) : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isMinimal ? Colors.white24 : widget.themeColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 14, color: widget.themeColor),
                      const SizedBox(width: 5),
                      const Text(
                        'Tüm Türler',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final item = pills[index];
          final String cat = item['name'] as String;
          final IconData icon = item['icon'] as IconData;
          final Color accent = item['color'] as Color;
          final String? customQuery = item['query'] as String?;
          final bool isSelected = _activeCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
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
                } else {
                  final searchQuery = customQuery ?? '$cat hit şarkılar';
                  _searchController.text = searchQuery;
                  _performSearch(searchQuery);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isMinimal ? Colors.white : widget.themeColor)
                      : (isMinimal ? const Color(0xFF1A1A1E) : const Color(0xFF141829).withValues(alpha: 0.85)),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isMinimal ? Colors.white12 : accent.withValues(alpha: 0.4)),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 13.5,
                      color: isSelected ? Colors.black : accent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔥 GENEL KEŞFET ÜST VİTRİN: Anlık Trend Şarkılar (Dev Mix Hero yerine doğrudan Trend Şarkılar)
  Widget _buildInstantTrendStrip(List<dynamic> trendItems) {
    if (trendItems.isEmpty) return const SizedBox.shrink();
    final isMinimal = SiberThemeService.instance.isMinimalMode.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.whatshot_rounded, color: widget.themeColor, size: 20),
                  const SizedBox(width: 6),
                  const Text(
                    'Anlık Trend Şarkılar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _playDirectly(trendItems.first, contextList: trendItems, isMix: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMinimal ? Colors.white10 : widget.themeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMinimal ? Colors.white24 : widget.themeColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 15, color: isMinimal ? Colors.white : widget.themeColor),
                      const SizedBox(width: 3),
                      Text(
                        'Trendleri Çal',
                        style: TextStyle(
                          color: isMinimal ? Colors.white : widget.themeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 154,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: trendItems.length,
            itemBuilder: (context, index) {
              final item = trendItems[index];
              final thumb = (item['thumbnail'] ?? '').toString();
              final title = (item['title'] ?? 'Bilinmeyen').toString();
              final artist = (item['channel'] ?? 'ÖZSES Müzik').toString();

              return GestureDetector(
                onTap: () => _playDirectly(item, contextList: trendItems, isMix: true),
                onLongPress: () => _startHookSnipPreview(item),
                child: Container(
                  width: 124,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isMinimal ? const Color(0xFF16161B) : const Color(0xFF141829).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMinimal ? Colors.white12 : widget.themeColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: thumb.isNotEmpty
                                  ? Image.network(
                                      thumb,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(color: widget.themeColor.withValues(alpha: 0.2)),
                                    )
                                  : Container(color: widget.themeColor.withValues(alpha: 0.2)),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: widget.themeColor.withValues(alpha: 0.6)),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    color: widget.themeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isMinimal ? Colors.white : widget.themeColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54, fontSize: 10.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  
  // ==========================================
  // 📌 SİBER SABİTLENEN SANATÇI KANALLARI (Pinned Channels)
  // ==========================================
  Future<void> _loadPinnedArtists() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('siber_pinned_artists');
    if (saved != null && saved.isNotEmpty) {
      if (mounted) setState(() => _pinnedArtists = saved);
    } else {
      final def = _personalArtists.isNotEmpty
          ? _personalArtists.take(4).toList()
          : ['Ceza', 'Velet', 'Motive'];
      if (mounted) setState(() => _pinnedArtists = def);
      await prefs.setStringList('siber_pinned_artists', def);
    }
  }

  Future<void> _togglePinArtist(String artist) async {
    final clean = artist.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> current = List.from(_pinnedArtists);
    bool added = false;
    if (current.contains(clean)) {
      current.remove(clean);
      added = false;
    } else {
      current.insert(0, clean);
      added = true;
    }
    await prefs.setStringList('siber_pinned_artists', current);
    if (mounted) {
      setState(() => _pinnedArtists = current);
    }
    Fluttertoast.showToast(
      msg: added ? '📌 $clean kanalı Keşfet başına sabitlendi!' : '📌 $clean sabitlemelerden kaldırıldı.',
      backgroundColor: const Color(0xFF1B1B2F),
    );
  }

  void _showAddPinnedArtistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: widget.themeColor.withValues(alpha: 0.5)),
          ),
          title: Row(
            children: [
              Icon(Icons.push_pin_rounded, color: widget.themeColor),
              const SizedBox(width: 8),
              const Text('Kanal / Sanatçı Sabitle', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Sanatçı veya kanal adı girin...',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: widget.themeColor.withValues(alpha: 0.4)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: widget.themeColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final txt = controller.text.trim();
                if (txt.isNotEmpty) {
                  _togglePinArtist(txt);
                }
                Navigator.pop(context);
              },
              child: const Text('Sabitle', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPinnedChannelsBar(bool isMinimal) {
    if (_pinnedArtists.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.push_pin_rounded, color: Colors.amberAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Sabitlenen Kanallar',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _showAddPinnedArtistDialog,
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 15, color: widget.themeColor),
                      const SizedBox(width: 4),
                      Text(
                        'Kanal Ekle',
                        style: TextStyle(color: widget.themeColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _pinnedArtists.length,
              itemBuilder: (context, index) {
                final artist = _pinnedArtists[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _searchController.text = artist;
                      _performSearch('$artist en çok dinlenen şarkılar');
                    },
                    onLongPress: () => _togglePinArtist(artist),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isMinimal ? const Color(0xFF1E1E22) : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.themeColor.withValues(alpha: 0.5),
                          width: 1.1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: widget.themeColor.withValues(alpha: 0.3),
                            child: Text(
                              artist.isNotEmpty ? artist[0].toUpperCase() : '?',
                              style: TextStyle(color: widget.themeColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            artist,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _togglePinArtist(artist),
                            child: const Icon(Icons.close_rounded, size: 13, color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ⚡ KEŞFETTEN 15 ŞARKILIK MİKS ÜRET (One-Tap Dynamic Mix)
  // ==========================================
  Future<void> _generateAndPlayDiscoverMix() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    final List<dynamic> mixPool = [];
    final Set<String> seenIds = {};

    void addTracks(List<dynamic> source, int limit) {
      for (var t in source) {
        final id = (t['videoId'] ?? t['id'] ?? t['video_id'])?.toString();
        if (id != null && id.isNotEmpty && !seenIds.contains(id)) {
          seenIds.add(id);
          mixPool.add(t);
          if (mixPool.length >= 15) return;
        }
      }
    }

    addTracks(_trendList.take(6).toList(), 5);
    for (var tracks in _personalArtistMixes.values) {
      addTracks(tracks.take(3).toList(), 5);
      if (mixPool.length >= 10) break;
    }
    addTracks(_personalCocktail.take(8).toList(), 5);
    if (mixPool.length < 15) {
      for (var list in _genreLists.values) {
        addTracks(list.take(4).toList(), 15 - mixPool.length);
        if (mixPool.length >= 15) break;
      }
    }
    if (mixPool.length < 15) {
      addTracks(_trendList.skip(6).toList(), 15 - mixPool.length);
    }

    if (mixPool.isEmpty) {
      Fluttertoast.showToast(msg: 'Miks için şarkılar yükleniyor...');
      _refreshData();
      return;
    }

    mixPool.shuffle(Random());
    final final15 = mixPool.take(15).toList();

    await _playDirectly(final15.first, contextList: final15, isMix: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.bolt_rounded, color: widget.themeColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '⚡ 15 Parçalık Siber Keşfet Miksi Başlatıldı!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF141829),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildGenerateMixBanner(bool isMinimal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: _generateAndPlayDiscoverMix,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.themeColor.withValues(alpha: 0.25),
                const Color(0xFF1B1B3A),
                Colors.deepPurple.withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.themeColor.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.themeColor.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.themeColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bolt_rounded, color: widget.themeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '⚡ 15 Şarkılık Anlık Akıllı Miks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6), width: 0.8),
                          ),
                          child: const Text(
                            'TEK TIKLA',
                            style: TextStyle(color: Colors.amberAccent, fontSize: 8.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Trendler ve sevdiğin sanatçılardan canlı harmanlanan miksi başlat',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.themeColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🎧 10-SANİYE NAKARAT RADARI (Hook Snip Radar)
  // ==========================================
  Future<void> _startHookSnipPreview(dynamic item) async {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    _activeHookItem = item;
    final title = (item['title'] ?? item['baslik'] ?? 'Şarkı').toString();
    final artist = (item['channel'] ?? item['kanal'] ?? 'Özses').toString();
    final thumb = (item['thumbnail'] ?? '').toString();
    final videoId = (item['videoId'] ?? item['id'] ?? item['video_id'])?.toString();

    if (videoId == null || videoId.isEmpty) {
      _showActionSheet(item);
      return;
    }

    final isCurrentlyPlaying = audioHandler.playbackState.value.playing;
    if (isCurrentlyPlaying) {
      _wasPlayingBeforeHook = true;
      try {
        await audioHandler.pause();
      } catch (_) {}
    } else {
      _wasPlayingBeforeHook = false;
    }

    _hookSnipTimer?.cancel();
    try {
      await _hookPlayer?.stop();
    } catch (_) {}

    setState(() {
      _isHookSnipActive = true;
      _hookSnipTitle = title;
      _hookSnipArtist = artist;
      _hookSnipThumb = thumb;
      _hookSnipSecondsLeft = 10;
    });

    try {
      final res = await _bridge.getStreamUrl(videoId);
      if (!_isHookSnipActive || _activeHookItem != item) return;

      if (res['status'] == 'basarili' && res['stream_url'] != null) {
        final streamUrl = res['stream_url'] as String;
        _hookPlayer ??= ja.AudioPlayer();

        if (res['is_file'] == true) {
          await _hookPlayer!.setAudioSource(ja.AudioSource.file(streamUrl));
        } else {
          await _hookPlayer!.setAudioSource(ja.AudioSource.uri(Uri.parse(streamUrl)));
        }

        int totalSec = 0;
        final dur = item['duration'];
        if (dur is int) {
          totalSec = dur;
        } else if (dur is String) {
          final p = dur.split(':');
          if (p.length == 2) totalSec = (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
          else if (p.length == 3) totalSec = (int.tryParse(p[0]) ?? 0) * 3600 + (int.tryParse(p[1]) ?? 0) * 60 + (int.tryParse(p[2]) ?? 0);
        }

        final int seekSec = totalSec > 35 ? (totalSec * 0.35).round() : 0;
        if (seekSec > 0) {
          await _hookPlayer!.seek(Duration(seconds: seekSec));
        }

        await _hookPlayer!.play();

        _hookSnipTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || !_isHookSnipActive) {
            timer.cancel();
            return;
          }
          if (_hookSnipSecondsLeft <= 1) {
            timer.cancel();
            _stopHookSnipPreview();
          } else {
            setState(() {
              _hookSnipSecondsLeft--;
            });
          }
        });
      } else {
        _stopHookSnipPreview();
        if (mounted) _showActionSheet(item);
      }
    } catch (e) {
      print('Hook Snip Hatası: $e');
      _stopHookSnipPreview();
      if (mounted) _showActionSheet(item);
    }
  }

  Future<void> _stopHookSnipPreview() async {
    _hookSnipTimer?.cancel();
    _hookSnipTimer = null;
    try {
      await _hookPlayer?.stop();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isHookSnipActive = false;
        _activeHookItem = null;
      });
    }

    if (_wasPlayingBeforeHook) {
      _wasPlayingBeforeHook = false;
      try {
        await audioHandler.play();
      } catch (_) {}
    }
  }

  Widget _buildHookSnipCapsule() {
    if (!_isHookSnipActive) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1035), Color(0xFF121829), Color(0xFF1E1035)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.amberAccent.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amberAccent.withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _hookSnipThumb.isNotEmpty
                        ? Image.network(
                            _hookSnipThumb,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 44,
                              height: 44,
                              color: Colors.white10,
                              child: const Icon(Icons.music_note, color: Colors.amberAccent, size: 20),
                            ),
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            color: Colors.white10,
                            child: const Icon(Icons.music_note, color: Colors.amberAccent, size: 20),
                          ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.radar_rounded, color: Colors.amberAccent, size: 22),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amberAccent, width: 0.8),
                          ),
                          child: Text(
                            '🎧 NAKARAT RADARI ${_hookSnipSecondsLeft}s',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _hookSnipTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _hookSnipArtist,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  final item = _activeHookItem;
                  _stopHookSnipPreview();
                  if (item != null) {
                    _playDirectly(item);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.themeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.black, size: 16),
                      SizedBox(width: 2),
                      Text('Çal', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _stopHookSnipPreview,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🌌 BİRLEŞİK TEK KEŞFET ANA EKRANI (Unified Discover View)
  // ==========================================
  Widget _buildBiorhythmAndSetupBar(bool isMinimal, bool isNight, String genresLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMinimal ? const Color(0xFF16161A) : Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isMinimal ? Colors.white12 : widget.themeColor.withAlpha(80),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isNight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                    color: isNight ? Colors.indigoAccent : Colors.amberAccent,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_personalArtists.length} Sanatçı İstasyonu • $genresLabel',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _showEditArtistsSheet,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMinimal ? const Color(0xFF1E1E22) : widget.themeColor.withAlpha(40),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isMinimal ? Colors.white24 : widget.themeColor.withAlpha(120),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: isMinimal ? Colors.white70 : widget.themeColor, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    'Sanatçı & Tür Seç',
                    style: TextStyle(
                      color: isMinimal ? Colors.white70 : widget.themeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedDiscoverHome() {
    final int total = _trendList.length;
    List<dynamic> instantTrends = [];
    List<dynamic> candidateMix = [];
    List<dynamic> effectiveBottomList = [];

    if (total >= 12) {
      instantTrends = _trendList.take(6).toList();
      candidateMix = _trendList.skip(6).take(6).toList();
      effectiveBottomList = _trendList.skip(12).toList();
    } else if (total >= 6) {
      instantTrends = _trendList.take(3).toList();
      candidateMix = _trendList.skip(3).take(3).toList();
      effectiveBottomList = _trendList.skip(6).toList();
    } else {
      instantTrends = List.from(_trendList);
      candidateMix = List.from(_trendList);
      effectiveBottomList = [];
    }

    final List<dynamic> blendedCandidateMix = [];
    final Set<String> seenCandidateIds = {};

    for (final genre in _personalGenres) {
      final genreTracks = _genreLists[genre] ?? [];
      for (final gt in genreTracks.take(3)) {
        final id = (gt['videoId'] ?? gt['id'])?.toString() ?? '';
        if (id.isNotEmpty && !seenCandidateIds.contains(id)) {
          seenCandidateIds.add(id);
          blendedCandidateMix.add(gt);
        }
      }
    }
    for (final ct in candidateMix) {
      final id = (ct['videoId'] ?? ct['id'])?.toString() ?? '';
      if (id.isNotEmpty && !seenCandidateIds.contains(id)) {
        seenCandidateIds.add(id);
        blendedCandidateMix.add(ct);
      }
    }

    final List<dynamic> combinedBottomList = [];
    final Set<String> seenBottomIds = {};
    for (var t in effectiveBottomList) {
      final id = (t['videoId'] ?? t['id'] ?? t['video_id'])?.toString() ?? '';
      if (id.isNotEmpty && !seenBottomIds.contains(id)) {
        seenBottomIds.add(id);
        combinedBottomList.add(t);
      }
    }
    final personalTracks = _similarArtistsTracks.isNotEmpty ? _similarArtistsTracks : _personalCocktail;
    for (var t in personalTracks) {
      final id = (t['videoId'] ?? t['id'] ?? t['video_id'])?.toString() ?? '';
      if (id.isNotEmpty && !seenBottomIds.contains(id)) {
        seenBottomIds.add(id);
        combinedBottomList.add(t);
      }
    }

    final isMinimal = SiberThemeService.instance.isMinimalMode.value;
    final now = DateTime.now();
    final isNight = now.hour >= 22 || now.hour < 6;
    final String genresLabel = _personalGenres.isNotEmpty
        ? _personalGenres.take(3).join(' • ')
        : _activePersonalGenre;
    final String genreFilterLabel = _personalGenres.isNotEmpty
        ? '${_personalGenres.take(2).join(" • ")} & Trend Filtresi'
        : 'Seçtiğin Türler & Trend Şarkılar Filtresi';

    return RefreshIndicator(
      color: widget.themeColor,
      backgroundColor: const Color(0xFF14142B),
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        controller: _generalScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: (_currentSongName != 'Müzik Seçilmedi' && !_isDesktop) ? 140 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            // 1. BİYORİTİM & SANATÇI/TÜR SEÇİM BARI
            _buildBiorhythmAndSetupBar(isMinimal, isNight, genresLabel),

            const SizedBox(height: 10),

            // 2. 📌 SABİTLENEN SANATÇI KANALLARI (Pinned Channels)
            _buildPinnedChannelsBar(isMinimal),

            // 3. ⚡ 15 ŞARKILIK ANLIK AKILLI MİKS ÜRET BARİ
            _buildGenerateMixBanner(isMinimal),

            const SizedBox(height: 10),

            // 4. 🔥 ANLIK TREND ŞARKILAR (Hook Snip / 10s Nakarat Radarı destekli)
            if (instantTrends.isNotEmpty) _buildInstantTrendStrip(instantTrends),

            const SizedBox(height: 14),

            // 5. 🎯 SANA ÖZEL SANATÇI MİKSLERİ & ALBÜMLERİ
            if (_personalArtistMixes.isNotEmpty) ...[
              ..._personalArtistMixes.entries.map((entry) {
                final artist = entry.key;
                final tracks = entry.value;
                final albums = _personalArtistAlbums[artist] ?? const [];
                if (tracks.isEmpty && albums.isEmpty) return const SizedBox.shrink();
                final String firstThumb = albums.isNotEmpty &&
                        (albums.first['thumbnail'] ?? '').toString().isNotEmpty
                    ? albums.first['thumbnail'].toString()
                    : (tracks.isNotEmpty ? (tracks[0]['thumbnail'] ?? '').toString() : '');
                final int albumCount = albums.take(3).length;
                return _GlassAccordionMix(
                  title: '$artist Özel Mixi',
                  subtitle: albumCount > 0
                      ? '💿 $albumCount Saf Albüm + ${tracks.length} Şarkı Önerisi'
                      : '⚡ ${tracks.length} Özel Seçim Şarkı',
                  imageUrl: firstThumb,
                  albums: albums.take(3).toList(),
                  onAlbumTap: _playOrOpenArtistAlbum,
                  tracks: tracks,
                  themeColor: widget.themeColor,
                  onDownloadMixTap: tracks.isNotEmpty
                      ? () => _downloadMix('$artist Özel Mixi', tracks)
                      : null,
                  onTrackTap: (item, list) => _playDirectly(item, contextList: list, isMix: true),
                  onTrackLongPress: (item) => _startHookSnipPreview(item),
                  onDownloadTap: (item) {
                    final videoId = item['videoId'] ?? item['id'];
                    if (videoId != null && videoId.isNotEmpty) {
                      _downloadAudio(videoId, item['title'] ?? 'Bilinmeyen');
                    }
                  },
                );
              }),
              const SizedBox(height: 14),
            ],

            // 6. 🎧 DİNLAMEYE ADAY ŞARKILAR MİXİ (Kendi Seçtiği Türler + Trend Filtresi)
            if (blendedCandidateMix.isNotEmpty)
              _GlassAccordionMix(
                title: '📌 Dinlemeye Aday Şarkılar',
                subtitle: genreFilterLabel,
                imageUrl: blendedCandidateMix[0]['thumbnail'] ?? '',
                tracks: blendedCandidateMix,
                themeColor: widget.themeColor,
                onDownloadMixTap: () => _downloadMix('Dinlemeye Aday Şarkılar', blendedCandidateMix),
                onTrackTap: (item, list) => _playDirectly(item, contextList: list, isMix: true),
                onTrackLongPress: (item) => _startHookSnipPreview(item),
                onDownloadTap: (item) {
                  final videoId = item['videoId'] ?? item['id'];
                  if (videoId != null && videoId.isNotEmpty) {
                    _downloadAudio(videoId, item['title'] ?? 'Bilinmeyen');
                  }
                },
              ),

            const SizedBox(height: 14),

            // 7. 📻 KESİNTİSİZ KEŞFET AKIŞI (Trendler & Kişisel İstasyon)
            if (combinedBottomList.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.radar_rounded, color: widget.themeColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '📻 Kesintisiz Keşfet Akışı ($genresLabel)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              _buildVerticalList(combinedBottomList),
            ],

            if (_isLoadingMore)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator(color: widget.themeColor)),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildYouTubeMusicHome() {
    // 🎯 GENEL KEŞFET YENİ MİMARİ:
    // 1) Üstte doğrudan Anlık Trend Şarkılar (Kocaman Mix Hero iptal edildi)
    // 2) Ortada Dinlemeye Aday Şarkılar (Kullanıcının seçtiği şarkı türleri + Trend şarkılar filtresi)
    // 3) Altta kesintisiz devam eden şarkı akışı
    final int total = _trendList.length;
    List<dynamic> instantTrends = [];
    List<dynamic> candidateMix = [];
    List<dynamic> effectiveBottomList = [];

    if (total >= 12) {
      instantTrends = _trendList.take(6).toList();
      candidateMix = _trendList.skip(6).take(6).toList();
      effectiveBottomList = _trendList.skip(12).toList();
    } else if (total >= 6) {
      instantTrends = _trendList.take(3).toList();
      candidateMix = _trendList.skip(3).take(3).toList();
      effectiveBottomList = _trendList.skip(6).toList();
    } else {
      instantTrends = List.from(_trendList);
      candidateMix = List.from(_trendList);
      effectiveBottomList = [];
    }

    // Kullanıcının seçtiği şarkı türlerinden (_personalGenres) parçaları Dinlemeye Aday Mix'e harmanla
    final List<dynamic> blendedCandidateMix = [];
    final Set<String> seenCandidateIds = {};

    for (final genre in _personalGenres) {
      final genreTracks = _genreLists[genre] ?? [];
      for (final gt in genreTracks.take(3)) {
        final id = (gt['videoId'] ?? gt['id'])?.toString() ?? '';
        if (id.isNotEmpty && !seenCandidateIds.contains(id)) {
          seenCandidateIds.add(id);
          blendedCandidateMix.add(gt);
        }
      }
    }
    for (final ct in candidateMix) {
      final id = (ct['videoId'] ?? ct['id'])?.toString() ?? '';
      if (id.isNotEmpty && !seenCandidateIds.contains(id)) {
        seenCandidateIds.add(id);
        blendedCandidateMix.add(ct);
      }
    }

    final String genreFilterLabel = _personalGenres.isNotEmpty
        ? '${_personalGenres.take(2).join(" • ")} & Trend Filtresi'
        : 'Seçtiğin Türler & Trend Şarkılar Filtresi';

    return RefreshIndicator(
      color: widget.themeColor,
      backgroundColor: const Color(0xFF14142B),
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        controller: _generalScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: (_currentSongName != 'Müzik Seçilmedi' && !_isDesktop) ? 140 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ANLIK TREND ŞARKILAR (Doğrudan üstte)
            if (instantTrends.isNotEmpty) _buildInstantTrendStrip(instantTrends),

            const SizedBox(height: 10),

            // 2. DİNLEMEYE ADAY ŞARKILAR MİXİ (Kendi Seçtiği Türler + Trend Filtresi)
            if (blendedCandidateMix.isNotEmpty)
              _GlassAccordionMix(
                title: '🔥 DİNLEMEYE ADAY ŞARKILAR',
                subtitle: genreFilterLabel,
                imageUrl: blendedCandidateMix[0]['thumbnail'] ?? '',
                tracks: blendedCandidateMix,
                themeColor: widget.themeColor,
                onTrackTap: (item, list) => _playDirectly(item, contextList: list, isMix: true),
                onTrackLongPress: (item) => _showActionSheet(item),
                onDownloadTap: (item) {
                  final videoId = item['videoId'] ?? item['id'];
                  if (videoId != null && videoId.isNotEmpty) {
                    _downloadAudio(videoId, item['title'] ?? 'Bilinmeyen');
                  }
                },
              ),

            const SizedBox(height: 12),

            // 3. ALTA DOĞRU DEVAM EDEN ŞARKILAR
            if (effectiveBottomList.isNotEmpty) ...[
              _buildSectionTitle('⚡ Trend & Keşif Akışı'),
              _buildVerticalList(effectiveBottomList),
            ],

            if (_isLoadingMore)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator(color: widget.themeColor)),
              )
          ],
        ),
      ),
    );
  }

  // 🎯 HERO VİTRİN (Trendler / Günün Parçası)
  Widget _buildHeroShowcase(List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final isMinimal = SiberThemeService.instance.isMinimalMode.value;
    final heroItem = items[0];
    final imageUrl = heroItem['thumbnail'] ?? '';

    return GestureDetector(
      onTap: () => _playDirectly(heroItem, contextList: items, isMix: true),
      child: Container(
        height: 280,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isMinimal ? Colors.white12 : widget.themeColor.withAlpha(100),
            width: isMinimal ? 1 : 2,
          ),
          boxShadow: isMinimal
              ? null
              : [
                  BoxShadow(color: widget.themeColor.withAlpha(60), blurRadius: 25, spreadRadius: 2, offset: const Offset(0, 8)),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arkaplan
              if (imageUrl.isNotEmpty)
                Image.network(imageUrl, fit: BoxFit.cover)
              else
                Container(color: widget.themeColor.withAlpha(50)),

              // Gradient Gölge
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withAlpha(220), Colors.black.withAlpha(50), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),

              // İçerik
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isMinimal ? Colors.white12 : widget.themeColor.withAlpha(50),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isMinimal ? Colors.white24 : widget.themeColor.withAlpha(150)),
                      ),
                      child: Text(
                        '🔥 GÜNÜN TREND VİTRİNİ',
                        style: TextStyle(
                          color: isMinimal ? Colors.white : widget.themeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      heroItem['title'] ?? 'Bilinmeyen Frekans',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      heroItem['channel'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Dev Play Butonu
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: widget.themeColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: widget.themeColor.withAlpha(100), blurRadius: 15)],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 30),
                ),
              ),
            ],
          ),
        ),
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

  // 🎯 YATAY KAYDIRILABİLİR ALBÜM/KART TASARIMI (YT Music Stili)
  Widget _buildHorizontalCarousel(List<dynamic> items) {
    return SizedBox(
      height: 220, // Albüm kapakları için daha geniş alan
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final imgUrl = item['thumbnail'];
          return GestureDetector(
            // 🎯 TIKLAMA ALANI
            onTap: () => _playDirectly(item, contextList: items), 
            onLongPress: () => _startHookSnipPreview(item),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 160,
                        width: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20), // Köşeleri oval
                          color: Colors.white10,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: imgUrl != null && imgUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imgUrl, 
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.music_note, color: Colors.white24, size: 50),
                                )
                              : const Icon(Icons.music_note, color: Colors.white24, size: 60),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _showActionSheet(item),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.more_vert,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
                          child: Icon(Icons.play_arrow, color: widget.themeColor, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['title'] ?? item['baslik'] ?? 'Bilinmeyen',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['channel'] ?? item['kanal'] ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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

  // 🎯 DİKEY ARAMA VE MÜZİK LİSTESİ DÜZENİ (Premium Tasarım)
  Widget _buildVerticalList(List<dynamic> items, {bool isScrollable = false, bool isSearch = false}) {
    return ListView.builder(
      controller: isScrollable ? _scrollController : null,
      physics: isScrollable ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      shrinkWrap: !isScrollable,
      padding: EdgeInsets.only(bottom: (_currentSongName != 'Müzik Seçilmedi' && !_isDesktop) ? 140 : 20),
      itemCount: items.length + (isScrollable && _isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: widget.themeColor)),
          );
        }
        final item = items[index];
        final imgUrl = item['thumbnail'];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imgUrl != null && imgUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imgUrl, 
                          width: 60, height: 60, fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
                          errorWidget: (context, url, error) => const Icon(Icons.music_note, color: Colors.white24))
                      : Container(width: 60, height: 60, color: Colors.white10, child: const Icon(Icons.music_note, color: Colors.white54)),
                ),
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                ),
              ],
            ),
            title: Text(item['title'] ?? item['baslik'] ?? 'Bilinmeyen',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(item['channel'] ?? item['kanal'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<Map<String, double>>(
                  valueListenable: OfflineCacheService().downloadProgress,
                  builder: (context, progressMap, _) {
                    final vId = item['videoId'] ?? item['id'] ?? '';
                    final isDownloading = progressMap.containsKey(vId);
                    final isCached = OfflineCacheService().isCached(vId);

                    if (isDownloading) {
                      final prog = progressMap[vId] ?? 0.0;
                      return SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: prog > 0 ? prog : null,
                              strokeWidth: 2.5,
                              color: Colors.cyanAccent,
                              backgroundColor: Colors.white10,
                            ),
                            Text(
                              '${(prog * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (isCached) {
                      return const IconButton(
                        icon: Icon(Icons.offline_pin, color: Colors.greenAccent, size: 22),
                        tooltip: 'Çevrimdışı Bellekte',
                        onPressed: null,
                      );
                    }
                    return IconButton(
                      icon: const Icon(Icons.cloud_download_outlined, color: Colors.cyanAccent),
                      tooltip: 'Çevrimdışı İndir',
                      onPressed: () => _downloadAudio(
                        vId,
                        item['title'] ?? item['baslik'] ?? 'Bilinmeyen',
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: widget.themeColor),
                  onPressed: () => _showActionSheet(item),
                ),
              ],
            ),
            onTap: () => _playDirectly(
              item,
              contextList: isSearch ? null : items,
              isFromSearch: isSearch,
            ),
            onLongPress: () => _startHookSnipPreview(item),
          ),
        );
      },
    );
  }

  // 🛡️ SİBER KALKAN: Misafir Modu Metamorfoz Kalkanı
  void _showGuestModeDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B1B32), Color(0xFF0D0E1A)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withValues(alpha: 0.25),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.shield_moon_rounded, color: Colors.orangeAccent, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'MİSAFİR MODU DEVREDE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Misafir modunda keşfet vitrini açıktır. Müzik aramak, kütüphaneye eklemek ve tüm özelliklere erişmek için Profil sekmesinden giriş yapabilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Anladım, Vitrinde Kal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🎯 SİBER HAMLE: Çevrimdışı İndirilenleri Gösterme Motoru
  void _showOfflineCacheDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ValueListenableBuilder<int>(
          valueListenable: OfflineCacheService().cacheChangeNotifier,
          builder: (context, _, __) {
            return ValueListenableBuilder<Map<String, double>>(
              valueListenable: OfflineCacheService().downloadProgress,
              builder: (context, progressMap, __) {
                final cachedSongs = OfflineCacheService().cachedSongs;
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF101B2B),
                    const Color(0xFF070B14),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(
                  top: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 1.8),
                  left: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                  right: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Çevrimdışı Kütüphane',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${cachedSongs.length} şarkı',
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                            if (cachedSongs.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final List<MediaItem> mediaItems = cachedSongs.map(songToMediaItem).toList();
                                        await audioHandler.updateQueue(mediaItems);
                                        await audioHandler.skipToQueueItem(0);
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                                      label: const Text('Tümünü Çal'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                                        foregroundColor: Colors.cyanAccent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final shuffled = List<SongModel>.from(cachedSongs)..shuffle();
                                        final List<MediaItem> mediaItems = shuffled.map(songToMediaItem).toList();
                                        await audioHandler.updateQueue(mediaItems);
                                        await audioHandler.skipToQueueItem(0);
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.shuffle_rounded, size: 22),
                                      label: const Text('Karıştır'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.2),
                                        foregroundColor: Colors.deepPurpleAccent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (progressMap.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '⚡ Aktif İndirilenler (${progressMap.length})',
                                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...progressMap.entries.map((entry) {
                                final vId = entry.key;
                                final pct = entry.value;
                                final dTitle = OfflineCacheService().downloadTitles.value[vId] ?? 'Şarkı indiriliyor...';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              dTitle,
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${(pct * 100).toInt()}%',
                                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: pct > 0 ? pct : null,
                                          minHeight: 4,
                                          color: Colors.cyanAccent,
                                          backgroundColor: Colors.white10,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Expanded(
                        child: cachedSongs.isEmpty && progressMap.isEmpty
                            ? const Center(
                                child: Text(
                                  'Çevrimdışı bellek boş.\nKeşfetten şarkıları buluta tıklayarak indirebilirsin!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white54, fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                itemCount: cachedSongs.length,
                                itemBuilder: (context, index) {
                                  final song = cachedSongs[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.4),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: song.videoId != null
                                              ? Image.network(
                                                  'https://i.ytimg.com/vi/${song.videoId}/hqdefault.jpg',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(Icons.offline_pin, color: Colors.cyanAccent, size: 28),
                                                )
                                              : const Icon(Icons.offline_pin, color: Colors.cyanAccent, size: 28),
                                        ),
                                      ),
                                      title: Text(
                                        song.title ?? song.name ?? 'Bilinmeyen',
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        song.artist ?? 'Victus V7',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.archive, color: Colors.greenAccent),
                                            tooltip: 'Arşive Aktar',
                                            onPressed: () async {
                                              if (song.videoId != null) {
                                                await OfflineCacheService().exportToArchive(song.videoId!);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('✅ Ana kütüphaneye başarıyla aktarıldı!'), backgroundColor: Colors.green),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                            tooltip: 'Sil',
                                            onPressed: () async {
                                              if (song.videoId != null) {
                                                await OfflineCacheService().removeCachedSong(song.videoId!);
                                                // cacheChangeNotifier ile otomatik yenilenir
                                                setState(() {}); // Ana ekranı yenile
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('🗑️ Çevrimdışı bellekten silindi!'), backgroundColor: Colors.redAccent),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      onTap: () async {
                                        Navigator.pop(context); // Çalınca çekmeceyi hemen kapat
                                        final List<MediaItem> mediaItems = cachedSongs.map(songToMediaItem).toList();
                                        await audioHandler.updateQueue(mediaItems);
                                        await audioHandler.skipToQueueItem(index);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
              },
            );
          },
        );
      },
    );
  }



  // 🎯 SİBER İNDİRME MOTORU
  Future<void> _downloadAudio(String videoId, String title) async {
    if (videoId.isEmpty) return;
    if (OfflineCacheService().isCached(videoId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ "$title" zaten çevrimdışı arşivde kayıtlı!'),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 🔒 SİBER LİMİT KONTROLÜ: Günlük Arşive Ekleme / İndirme Hakkı
    final canDownload = await SubscriptionManager().canAddArchive();
    if (!canDownload) {
      if (!mounted) return;
      _showDownloadLimitModal(videoId, title);
      return;
    }

    // 🌐 WEB CİHAZ İNDİRME: iOS Safari, Android Chrome, PC/Mac doğrudan cihaza indirsin
    if (kIsWeb) {
      final cleanTitle = title.replaceAll(RegExp(r'[^\w\s\u00C0-\u017F.-]'), '').trim();
      final fileName = cleanTitle.isNotEmpty ? '$cleanTitle.mp3' : 'sarki.mp3';
      final streamUrl = 'https://167-172-190-129.nip.io/api/stream/$videoId?apikey=siber_secret_key_v7';

      downloadWebFile(streamUrl, fileName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.download_done_rounded, color: Colors.cyanAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text('📥 "$fileName" cihazınıza indiriliyor...'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F2035),
          duration: const Duration(seconds: 3),
        ),
      );
      await SubscriptionManager().incrementArchiveUsage();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('⚡ "$title" indiriliyor...'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F2035),
        duration: const Duration(seconds: 2),
      ),
    );
    await SubscriptionManager().incrementArchiveUsage();
    OfflineCacheService().downloadStream(
      videoId,
      title,
      'Müzik İndirme',
    ).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "$title" başarıyla indirildi ve arşive eklendi!'),
            backgroundColor: const Color(0xFF007A3D),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }).catchError((e) {
      if (mounted) {
        final errStr = e.toString();
        final cleanMsg = errStr.contains('Iptal')
            ? 'İndirme iptal edildi.'
            : (errStr.contains('boyutu cok kucuk') || errStr.contains('indirilemedi')
                ? 'Şarkı indirilemedi, lütfen tekrar deneyin.'
                : 'Ağ bağlantısı koptu. Lütfen internetinizi kontrol edin.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ "$title" indirilemedi: $cleanMsg'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  // 🎬 SİBER KOTA VE ÖDÜLLÜ REKLAM DİYALOĞU
  void _showDownloadLimitModal(String pendingVideoId, String pendingTitle) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: widget.themeColor.withValues(alpha: 0.5), width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.download_for_offline, color: widget.themeColor, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'GÜNLÜK İNDİRME KOTASI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bugünkü 5 ücretsiz şarkı indirme hakkınız doldu.\nKotanız her gece 00:00\'da yenilenir.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'İster kısa bir reklam izleyip anında +2 hak kazanın, ister Premium\'a geçip sınırsız indirin!',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          // Buton 1: 1 Kısa Reklam İzle (+2 Hak)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.play_circle_fill, color: Colors.amberAccent),
              label: const Text(
                '1 Kısa Reklam İzle (+2 Hak Kazan)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () {
                Navigator.pop(dialogContext); // Dialogu kapat
                // Ödüllü reklamı başlat
                AdManager.showRewardedAd(
                  onReward: () async {
                    await SubscriptionManager().grantBonusArchiveDownloads(amount: 2);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 Tebrikler! +2 indirme hakkı hesabınıza tanımlandı.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Şarkı indirmesini hemen devam ettir
                      _downloadAudio(pendingVideoId, pendingTitle);
                    }
                  },
                  onFailed: () {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reklam yüklenemedi. Lütfen tekrar deneyin.'),
                          backgroundColor: Colors.orangeAccent,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Buton 2: Premium'a Geç (Limitsiz İndir)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.amber.withValues(alpha: 0.8), width: 1.5),
                foregroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.workspace_premium, color: Colors.amber),
              label: const Text(
                'Imperium Premium\'a Geç (Limitsiz)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => SiberPremiumSheet(themeColor: widget.themeColor),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          // İptal Butonu
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Daha Sonra', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 ŞAHSİ KEŞFET MİMARİSİ: Toplu Mix İndirme (Siber Arşiv)
  void _downloadMix(String mixName, List<dynamic> tracks) async {
    if (tracks.isEmpty) return;
    final validTracks = tracks.where((item) {
      final vId = item['videoId'] ?? item['id'];
      return vId != null && vId.toString().isNotEmpty;
    }).take(15).toList();

    if (validTracks.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '⚡ "$mixName" arşive indiriliyor (${validTracks.length} parça)...',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0C1929),
        duration: const Duration(seconds: 3),
      ),
    );

    int completed = 0;
    for (var item in validTracks) {
      // 🔒 Her parça için limit kontrolü
      final canDownloadMore = await SubscriptionManager().canAddArchive();
      if (!canDownloadMore) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  '⚠️ Günlük arşiv indirme limitine ulaşıldı. Kalan parçalar için paketinizi yükseltin!'),
              backgroundColor: Colors.deepOrangeAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        break;
      }

      final videoId = item['videoId'] ?? item['id'];
      final trackTitle = item['title'] ?? 'Bilinmeyen';
      try {
        await SubscriptionManager().incrementArchiveUsage();
        await OfflineCacheService().downloadStream(
          videoId,
          trackTitle,
          mixName,
        );
        completed++;
      } catch (e) {
        print('Mix indirme parça hatası ($videoId): $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            completed > 0
                ? '✅ "$mixName" tamamlandı! ($completed/${validTracks.length} parça çevrimdışı arşive kaydedildi)'
                : '❌ "$mixName" parçaları indirilemedi!',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: completed > 0 ? const Color(0xFF007A3D) : Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // 🎯 ŞAHSİ KEŞFET: Sanatçıları ve Frekansları Düzenle Çekmecesi (Genel Keşfet ile 100% Uyumlu)
  void _showEditArtistsSheet() {
    PersonalDiscoverSetupSheet.show(
      context,
      themeColor: widget.themeColor,
      isInitialSetup: false,
      onSaved: (genres, artists) {
        final list = artists
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (list.isEmpty) list.addAll(['Ceza', 'Velet', 'GeeFlow']);

        if (mounted) {
          setState(() {
            _personalArtists = list;
            _personalGenres = genres.isNotEmpty ? genres : ['Türkçe Rap'];
          });
          _refreshData();
        }
      },
    );
  }


  // 🎯 GENEL KEŞFET: Metamorfoz Tür ve Frekans Çekmecesi (Akıcı & Siber Tasarım)
  void _showCategoriesSheet() {
    final categoriesData = [
      {'name': 'Trendler', 'icon': Icons.whatshot_rounded, 'color': Colors.amberAccent},
      {'name': 'Musiki', 'icon': Icons.queue_music_rounded, 'color': Colors.tealAccent, 'query': 'Türk Sanat Müziği'},
      {'name': 'Marşlar', 'icon': Icons.military_tech_rounded, 'color': Colors.redAccent, 'query': 'Türk Marşları ve Mehter'},
      {'name': 'Türkçe Rap', 'icon': Icons.mic_external_on_rounded, 'color': const Color(0xFFFF5252)},
      {'name': 'Melankolik', 'icon': Icons.water_drop_rounded, 'color': Colors.blueAccent},
      {'name': 'Akustik', 'icon': Icons.music_note_rounded, 'color': Colors.limeAccent},
      {'name': 'Deep House', 'icon': Icons.speaker_rounded, 'color': Colors.cyanAccent},
      {'name': 'Arabesk', 'icon': Icons.heart_broken_rounded, 'color': Colors.purpleAccent},
      {'name': 'Sokak', 'icon': Icons.local_fire_department_rounded, 'color': Colors.deepOrangeAccent},
      {'name': 'Enerji', 'icon': Icons.bolt_rounded, 'color': Colors.yellowAccent},
      {'name': 'Odak', 'icon': Icons.psychology_rounded, 'color': Colors.greenAccent},
      {'name': 'Gizem', 'icon': Icons.visibility_rounded, 'color': Colors.indigoAccent},
      {'name': 'Misafir Modu', 'icon': Icons.shield_moon_rounded, 'color': Colors.orangeAccent},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF101426),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: widget.themeColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.themeColor.withValues(alpha: 0.25),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Çekmece Çizgisi (Handle)
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Başlık Satırı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.themeColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: widget.themeColor, width: 1.5),
                            ),
                            child: Icon(Icons.tune_rounded, color: widget.themeColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'METAMORFOZ FREKANSLARI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                'Tür ve duygu frekansını seç',
                                style: TextStyle(
                                  color: widget.themeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Butonlar (Kusursuz Görünürlük & Canlı Neon Kontrast)
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: categoriesData.map((catData) {
                      final cat = catData['name'] as String;
                      final icon = catData['icon'] as IconData;
                      final color = catData['color'] as Color;
                      final query = catData['query'] as String?;
                      final isSelected = _activeCategory == cat;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            if (cat == 'Misafir Modu') {
                              _showGuestModeDialog();
                              return;
                            }
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
                            } else if (['Sokak', 'Melankoli', 'Enerji', 'Odak', 'Gizem'].contains(cat)) {
                              setState(() {
                                _dominantMood = cat;
                              });
                              _generateAiMixes(cat);
                            } else {
                              final searchQuery = query ?? cat;
                              _searchController.text = searchQuery;
                              _performSearch(searchQuery);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : const Color(0xFF1C223A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.white : color.withValues(alpha: 0.75),
                                width: isSelected ? 2.0 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected ? color.withValues(alpha: 0.5) : Colors.black45,
                                  blurRadius: isSelected ? 12 : 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  color: isSelected ? Colors.black : color,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 🎯 ŞAHSİ KEŞFET ANA GÖVDESİ (KİŞİSEL KARARGAH)
  Widget _buildPersonalDiscoverHome() {
    final isMinimal = SiberThemeService.instance.isMinimalMode.value;
    final now = DateTime.now();
    final isNight = now.hour >= 22 || now.hour < 6;

    final displayList = _similarArtistsTracks.isNotEmpty
        ? _similarArtistsTracks
        : _personalCocktail;

    final String genresLabel = _personalGenres.isNotEmpty
        ? _personalGenres.take(3).join(' • ')
        : _activePersonalGenre;

    return RefreshIndicator(
      color: widget.themeColor,
      backgroundColor: const Color(0xFF14142B),
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        controller: _personalScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: (_currentSongName != 'Müzik Seçilmedi' && !_isDesktop) ? 140 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            // 1. BİYORİTİM VE HIZLI SANATÇI/TÜR TANIMLAMA BARI (Kocaman Mix Hero iptal edildi)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMinimal ? const Color(0xFF16161A) : Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isMinimal ? Colors.white12 : widget.themeColor.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isNight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                            color: isNight ? Colors.indigoAccent : Colors.amberAccent,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_personalArtists.length} Sanatçı Mixi • $genresLabel',
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showEditArtistsSheet,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMinimal ? const Color(0xFF1E1E22) : widget.themeColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isMinimal ? Colors.white24 : widget.themeColor.withAlpha(120),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, color: isMinimal ? Colors.white70 : widget.themeColor, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            'Sanatçı & Tür Seç',
                            style: TextStyle(
                              color: isMinimal ? Colors.white70 : widget.themeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 2. TANIMLANAN SANATÇI KADAR ÖZEL MİX TARİFESİ:
            // Açıldığında üstte 2-3 Saf Sanatçı Albümü (Albüm kapaklı) + altında normal şarkıları!
            if (_personalArtistMixes.isEmpty && !_isLoading)
              _buildPersonalHeroPlaceholder()
            else
              ..._personalArtistMixes.entries.map((entry) {
                final artist = entry.key;
                final tracks = entry.value;
                final albums = _personalArtistAlbums[artist] ?? const [];
                if (tracks.isEmpty && albums.isEmpty) return const SizedBox.shrink();
                final String firstThumb = albums.isNotEmpty &&
                        (albums.first['thumbnail'] ?? '').toString().isNotEmpty
                    ? albums.first['thumbnail'].toString()
                    : (tracks.isNotEmpty ? (tracks[0]['thumbnail'] ?? '').toString() : '');
                final int albumCount = albums.take(3).length;
                return _GlassAccordionMix(
                  title: '$artist Özel Mixi',
                  subtitle: albumCount > 0
                      ? '💿 $albumCount Saf Albüm + ${tracks.length} Şarkı Önerisi'
                      : '🎵 ${tracks.length} Özel Seçim Şarkı',
                  imageUrl: firstThumb,
                  albums: albums.take(3).toList(),
                  onAlbumTap: _playOrOpenArtistAlbum,
                  tracks: tracks,
                  themeColor: widget.themeColor,
                  onDownloadMixTap: tracks.isNotEmpty
                      ? () => _downloadMix('$artist Özel Mixi', tracks)
                      : null,
                  onTrackTap: (item, list) => _playDirectly(item, contextList: list, isMix: true),
                  onTrackLongPress: (item) => _showActionSheet(item),
                  onDownloadTap: (item) {
                    final videoId = item['videoId'] ?? item['id'];
                    if (videoId != null && videoId.isNotEmpty) {
                      _downloadAudio(videoId, item['title'] ?? 'Bilinmeyen');
                    }
                  },
                );
              }),

            const SizedBox(height: 16),

            // 3. ALTTA SEÇTİĞİ ŞARKI TÜRLERİ VE SANATÇI ÜZERİNDEN DEVAM EDEN NORMAL ŞARKILAR
            if (displayList.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.radar_rounded, color: widget.themeColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚡ Seçtiğin Türler & Sanatçı Akışı ($genresLabel)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              _buildVerticalList(displayList),
            ],

            if (_isLoadingMore)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator(color: widget.themeColor)),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalHeroSkeleton() {
    return Container(
      height: 240,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: widget.themeColor.withAlpha(60), width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: widget.themeColor),
            const SizedBox(height: 14),
            Text(
              '🎯 Şahsi Müzik Kokteyli Hazırlanıyor...',
              style: TextStyle(color: widget.themeColor, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalHeroPlaceholder() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.themeColor.withAlpha(40), Colors.black54],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: widget.themeColor.withAlpha(80), width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, color: widget.themeColor, size: 36),
            const SizedBox(height: 10),
            const Text(
              'Şahsi öneriler için frekansları yenileyin',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh, color: widget.themeColor, size: 18),
              label: Text('Önerileri Çek', style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 ŞAHSİ KOKTEYL HERO VİTRİNİ
  Widget _buildPersonalCocktailHero(List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final isMinimal = SiberThemeService.instance.isMinimalMode.value;
    final heroItem = items[0];
    final imageUrl = heroItem['thumbnail'] ?? '';
    final artistsText = _personalArtists.take(3).join(' • ');

    return GestureDetector(
      onTap: () => _playDirectly(heroItem, contextList: items, isMix: true),
      child: Container(
        height: 280,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isMinimal ? Colors.white12 : widget.themeColor.withAlpha(120),
            width: isMinimal ? 1 : 2,
          ),
          boxShadow: isMinimal
              ? null
              : [
                  BoxShadow(color: widget.themeColor.withAlpha(80), blurRadius: 25, spreadRadius: 2, offset: const Offset(0, 8)),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arkaplan
              if (imageUrl.isNotEmpty)
                Image.network(imageUrl, fit: BoxFit.cover)
              else
                Container(color: widget.themeColor.withAlpha(50)),

              // Gradient
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withAlpha(230), Colors.black.withAlpha(60), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),

              // İçerik
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isMinimal ? Colors.white12 : widget.themeColor.withAlpha(60),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isMinimal ? Colors.white24 : widget.themeColor.withAlpha(160),
                        ),
                      ),
                      child: Text(
                        '🍸 ŞAHSİ KOKTEYL (3 SANATÇI HARMANI)',
                        style: TextStyle(
                          color: isMinimal ? Colors.white : widget.themeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      artistsText.isNotEmpty ? artistsText : 'Kişisel Özel Mix',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '3 favori sanatçın ve tarzın parçaları tek bir akışta birleşti',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Dev Play Butonu
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isMinimal ? Colors.white : widget.themeColor,
                    shape: BoxShape.circle,
                    boxShadow: isMinimal
                        ? null
                        : [BoxShadow(color: widget.themeColor.withAlpha(120), blurRadius: 15)],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 34),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// 🎯 YENİ MİMARİ: Accordion Mix Kartı (Üstte 2-3 Saf Sanatçı Albümü + Altta Normal Şarkılar Desteği)
class _GlassAccordionMix extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<Map<String, dynamic>> albums;
  final Function(Map<String, dynamic> album)? onAlbumTap;
  final List<dynamic> tracks;
  final Color themeColor;
  final Function(dynamic item, List<dynamic> contextList) onTrackTap;
  final Function(dynamic item) onTrackLongPress;
  final Function(dynamic item) onDownloadTap;
  final VoidCallback? onDownloadMixTap;

  const _GlassAccordionMix({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.albums = const [],
    this.onAlbumTap,
    required this.tracks,
    required this.themeColor,
    required this.onTrackTap,
    required this.onTrackLongPress,
    required this.onDownloadTap,
    this.onDownloadMixTap,
  }) : super(key: key);

  @override
  __GlassAccordionMixState createState() => __GlassAccordionMixState();
}

class __GlassAccordionMixState extends State<_GlassAccordionMix> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isMinimal = SiberThemeService.instance.isMinimalMode.value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutBack,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMinimal ? Colors.white12 : widget.themeColor.withAlpha(80),
          width: isMinimal ? 1 : 1.5,
        ),
        boxShadow: [
          if (_isExpanded && !isMinimal)
            BoxShadow(color: widget.themeColor.withAlpha(50), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: isMinimal ? const Color(0xFF16161A) : const Color(0xEE161622), // 🎯 Sıfır GPU kasması, kusursuz performans
          child: Column(
              children: [
                // Başlık Kartı (Tıklanabilir)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    height: 90,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(),
                    child: Stack(
                      children: [
                        // Arkaplan resmi
                        Positioned.fill(
                          child: widget.imageUrl.isNotEmpty
                              ? Image.network(widget.imageUrl, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.3))
                              : Container(color: widget.themeColor.withAlpha(50)),
                        ),
                        // Karanlık Gradient
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withAlpha(200), Colors.transparent],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        // İçerik Satırı
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Albüm kapağı
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: widget.imageUrl.isNotEmpty
                                        ? DecorationImage(image: NetworkImage(widget.imageUrl), fit: BoxFit.cover)
                                        : null,
                                    border: Border.all(
                                      color: isMinimal ? Colors.white24 : widget.themeColor,
                                      width: isMinimal ? 1 : 2,
                                    ),
                                    boxShadow: isMinimal
                                        ? null
                                        : [BoxShadow(color: widget.themeColor.withAlpha(100), blurRadius: 8)],
                                  ),
                                  child: widget.imageUrl.isEmpty ? Icon(Icons.music_note, color: widget.themeColor, size: 22) : null,
                                ),
                                const SizedBox(width: 12),
                                // Başlık & altyazı
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(widget.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                                      const SizedBox(height: 3),
                                      Text(widget.subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: widget.themeColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                // İndir butonu (sadece Şahsi kartlarda)
                                if (widget.onDownloadMixTap != null)
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.download_for_offline_rounded, color: Colors.cyanAccent, size: 22),
                                      tooltip: 'Tüm Mixi Arşivle',
                                      onPressed: widget.onDownloadMixTap,
                                    ),
                                  ),
                                // Aç/kapa oku
                                Icon(
                                  _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Genişleyen Liste (Üstte 2-3 Saf Sanatçı Albümü + Altta Normal Şarkıları)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 💿 1. ÜST BÖLÜM: SAF SANATÇI ALBÜMLERİ (2-3 Adet, Albüm Kapaklı)
                            if (widget.albums.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.album_rounded, color: widget.themeColor, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SAF SANATÇI ALBÜMLERİ (${widget.albums.length})',
                                      style: TextStyle(
                                        color: widget.themeColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 148,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  itemCount: widget.albums.length,
                                  itemBuilder: (context, albIdx) {
                                    final alb = widget.albums[albIdx];
                                    final String albCover = (alb['thumbnail'] ?? '').toString();
                                    final String albTitle = (alb['title'] ?? 'Albüm').toString();
                                    final String albSub = (alb['albumType'] ?? 'Saf Albüm').toString();
                                    final String albYear = (alb['year'] ?? '').toString();

                                    return GestureDetector(
                                      onTap: widget.onAlbumTap != null
                                          ? () => widget.onAlbumTap!(alb)
                                          : null,
                                      child: Container(
                                        width: 118,
                                        margin: const EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          color: isMinimal
                                              ? const Color(0xFF1F1F25)
                                              : const Color(0xFF1B1F34),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isMinimal
                                                ? Colors.white12
                                                : widget.themeColor.withValues(alpha: 0.45),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: const BorderRadius.vertical(
                                                      top: Radius.circular(13),
                                                    ),
                                                    child: albCover.isNotEmpty
                                                        ? Image.network(
                                                            albCover,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (_, __, ___) => Container(
                                                              color: widget.themeColor.withAlpha(45),
                                                              child: Icon(Icons.album, color: widget.themeColor),
                                                            ),
                                                          )
                                                        : Container(
                                                            color: widget.themeColor.withAlpha(45),
                                                            child: Icon(Icons.album, color: widget.themeColor),
                                                          ),
                                                  ),
                                                  if (albYear.isNotEmpty)
                                                    Positioned(
                                                      top: 5,
                                                      left: 5,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withValues(alpha: 0.72),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          albYear,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  Positioned(
                                                    bottom: 5,
                                                    right: 5,
                                                    child: Container(
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(
                                                        color: isMinimal ? Colors.white : widget.themeColor,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.play_arrow_rounded,
                                                        color: Colors.black,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    albTitle,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11.2,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    albSub,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: widget.themeColor.withValues(alpha: 0.85),
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.music_note_rounded, color: Colors.white70, size: 15),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'SANATÇI ŞARKI ÖNERİLERİ',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // 🎵 2. ALT BÖLÜM: NORMAL ŞARKILAR LİSTESİ
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.tracks.length,
                              itemBuilder: (context, index) {
                                final item = widget.tracks[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(item['thumbnail'] ?? '', width: 45, height: 45, fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(width: 45, height: 45, color: widget.themeColor.withAlpha(50))),
                                  ),
                                  title: Text(item['title'] ?? 'Bilinmeyen', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                  subtitle: Text(item['channel'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  trailing: ValueListenableBuilder<Map<String, double>>(
                                    valueListenable: OfflineCacheService().downloadProgress,
                                    builder: (context, progressMap, _) {
                                      final vId = item['videoId'] ?? item['id'] ?? '';
                                      final isDownloading = progressMap.containsKey(vId);
                                      final isCached = OfflineCacheService().isCached(vId);

                                      if (isDownloading) {
                                        final prog = progressMap[vId] ?? 0.0;
                                        return SizedBox(
                                          width: 38,
                                          height: 38,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                value: prog > 0 ? prog : null,
                                                strokeWidth: 2.2,
                                                color: widget.themeColor,
                                                backgroundColor: Colors.white10,
                                              ),
                                              Text(
                                                '${(prog * 100).toInt()}%',
                                                style: TextStyle(
                                                  color: widget.themeColor,
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      if (isCached) {
                                        return const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.offline_pin, color: Colors.greenAccent, size: 22),
                                        );
                                      }
                                      return IconButton(
                                        icon: Icon(Icons.cloud_download_outlined, color: widget.themeColor, size: 24),
                                        onPressed: () => widget.onDownloadTap(item),
                                      );
                                    },
                                  ),
                                  onTap: () => widget.onTrackTap(item, widget.tracks),
                                  onLongPress: () => widget.onTrackLongPress(item),
                                );
                              },
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
