import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../../main.dart'; // audioHandler
import 'widgets/desktop_sidebar.dart';
import 'widgets/desktop_bottom_player.dart';
import 'views/desktop_discover_view.dart';
import 'widgets/desktop_cinematic_view.dart';
import 'widgets/desktop_right_panel.dart';

class DesktopMainScreen extends StatefulWidget {
  const DesktopMainScreen({super.key});

  @override
  State<DesktopMainScreen> createState() => _DesktopMainScreenState();
}

class _DesktopMainScreenState extends State<DesktopMainScreen> {
  int _selectedIndex = 0; // 0: Anasayfa, 1: Keşfet, 2: Kütüphanem vb.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isCinematicMode = false;
  bool _isRightPanelOpen = false;
  
  // Sürüklenebilir panel state
  bool _isRightPanelDetached = false;
  Offset _rightPanelOffset = const Offset(500, 50); // Başlangıç pozisyonu
  
  StreamSubscription? _mediaItemSubscription;
  bool _hasStartedPlaying = false;

  @override
  void initState() {
    super.initState();
    // İlk defa bir şarkı başladığında Sinematik Modu otomatik aç
    _mediaItemSubscription = audioHandler.mediaItem.listen((item) {
      if (item != null && !_hasStartedPlaying) {
        if (mounted) {
          setState(() {
            _isCinematicMode = true;
            _hasStartedPlaying = true;
          });
        }
      }
    });
  }
  
  @override
  void dispose() {
    _mediaItemSubscription?.cancel();
    super.dispose();
  }

  void _onMenuSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _isCinematicMode = false; // Menüden bir şey seçilince sinematik modu kapat
    });
  }

  void _toggleRightPanel() {
    setState(() {
      _isRightPanelOpen = !_isRightPanelOpen;
    });
  }

  void _toggleDetachPanel() {
    setState(() {
      _isRightPanelDetached = !_isRightPanelDetached;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0D0E15), // Koyu arka plan
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Ana Katman
              Row(
                children: [
                  // Sol Panel (Hesap ve Navigasyon)
                  DesktopSidebar(
                    selectedIndex: _selectedIndex,
                    onMenuSelected: _onMenuSelected,
                  ),
                  
                  // Ferah Odak Alanı
                  Expanded(
                    child: ClipRect( // BackdropFilter taşmasını (buzlucam efekti) engeller
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                // Orta Alan (Keşfet veya Sinematik Mod)
                                Expanded(
                                  child: Stack(
                                    children: [
                                      // Altta Ana İçerik
                                      DesktopDiscoverView(selectedIndex: _selectedIndex),
                                      
                                      // Üstte Sinematik Mod (Eğer açıksa)
                                      if (_isCinematicMode)
                                        StreamBuilder<MediaItem?>(
                                          stream: audioHandler.mediaItem,
                                          builder: (context, snapshot) {
                                            final item = snapshot.data;
                                            if (item == null) return const SizedBox.shrink();
                                            return AnimatedOpacity(
                                              opacity: _isCinematicMode ? 1.0 : 0.0,
                                              duration: const Duration(milliseconds: 300),
                                              child: DesktopCinematicView(
                                                mediaItem: item,
                                                onMinimize: () {
                                                  setState(() {
                                                    _isCinematicMode = false;
                                                  });
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                                
                                // Sağ Panel (Sabit İse)
                                if (!_isRightPanelDetached)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    width: _isRightPanelOpen ? 320 : 0,
                                    child: _isRightPanelOpen
                                        ? DesktopRightPanel(
                                            onClose: () => setState(() => _isRightPanelOpen = false),
                                            isDetached: false,
                                            onToggleDetach: _toggleDetachPanel,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Alt Oynatıcı (Sadece müzik çalarken/seçiliyken)
                          StreamBuilder<MediaItem?>(
                            stream: audioHandler.mediaItem,
                            builder: (context, snapshot) {
                              final isPlaying = snapshot.hasData && snapshot.data != null;
                              return AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: isPlaying
                                    ? DesktopBottomPlayer(
                                        isCinematicMode: _isCinematicMode,
                                        isRightPanelOpen: _isRightPanelOpen,
                                        onToggleCinematicMode: () {
                                          setState(() {
                                            _isCinematicMode = !_isCinematicMode;
                                          });
                                        },
                                        onToggleRightPanel: _toggleRightPanel,
                                      )
                                    : const SizedBox.shrink(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Yüzen Sağ Panel (Ayrılmış ise)
              if (_isRightPanelDetached && _isRightPanelOpen)
                Positioned(
                  left: _rightPanelOffset.dx,
                  top: _rightPanelOffset.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        // Yeni pozisyonu hesapla
                        double newX = _rightPanelOffset.dx + details.delta.dx;
                        double newY = _rightPanelOffset.dy + details.delta.dy;

                        // Sınırlandırmalar: 
                        // Sol menü genişliği genelde 240-280px civarıdır. 300px diyelim ki taşmasın.
                        // Alt panel yüksekliği 110px civarıdır.
                        double minX = 260.0; // Sol panel sınırı
                        double maxX = constraints.maxWidth - 320.0; // Panel genişliği 320
                        
                        double minY = 0.0; // Üst sınır
                        double maxY = constraints.maxHeight - 110.0; // Panel ortalama yüksekliği için alt sınır (eğer alt barda taşma olursa bunu -500 yapabiliriz, pencere çok büyük olabilir)

                        newX = newX.clamp(minX, maxX);
                        newY = newY.clamp(minY, maxY);

                        _rightPanelOffset = Offset(newX, newY);
                      });
                    },
                    child: SizedBox(
                      height: constraints.maxHeight * 0.7, // Ekranın %70'i kadar boy
                      child: DesktopRightPanel(
                        onClose: () => setState(() => _isRightPanelOpen = false),
                        isDetached: true,
                        onToggleDetach: _toggleDetachPanel,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
