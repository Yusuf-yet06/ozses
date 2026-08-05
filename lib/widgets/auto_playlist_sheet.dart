import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AutoPlaylistBottomSheet extends StatefulWidget {
  final Color themeColor;

  const AutoPlaylistBottomSheet({super.key, required this.themeColor});

  static Future<Map<String, String>?> show(BuildContext context, Color themeColor) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AutoPlaylistBottomSheet(themeColor: themeColor),
    );
  }

  @override
  State<AutoPlaylistBottomSheet> createState() => _AutoPlaylistBottomSheetState();
}

class _AutoPlaylistBottomSheetState extends State<AutoPlaylistBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? selectedType;
  String? selectedSelection;

  final List<Map<String, dynamic>> moods = [
    {'name': 'Enerjik / Spor', 'icon': Icons.directions_run, 'color': Colors.orangeAccent},
    {'name': 'Melankolik', 'icon': Icons.water_drop, 'color': Colors.blueAccent},
    {'name': 'Sakin / Odak', 'icon': Icons.self_improvement, 'color': Colors.tealAccent},
    {'name': 'Parti / Eğlence', 'icon': Icons.celebration, 'color': Colors.purpleAccent},
    {'name': 'İsyankar / Sert', 'icon': Icons.local_fire_department, 'color': Colors.redAccent},
    {'name': 'Nostaljik', 'icon': Icons.album, 'color': Colors.amberAccent},
  ];

  final List<Map<String, dynamic>> genres = [
    {'name': 'Pop / Türkçe Pop', 'icon': Icons.mic, 'color': Colors.pinkAccent},
    {'name': 'Arabesk', 'icon': Icons.nightlife, 'color': Colors.indigoAccent},
    {'name': 'Rap / Hip-Hop', 'icon': Icons.graphic_eq, 'color': Colors.greenAccent},
    {'name': 'Rock / Metal', 'icon': Icons.electric_bolt, 'color': Colors.deepOrangeAccent},
    {'name': 'Elektronik / EDM', 'icon': Icons.headphones, 'color': Colors.cyanAccent},
    {'name': 'Türkü / Özgün', 'icon': Icons.landscape, 'color': Colors.brown},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(String type, String selection) {
    setState(() {
      selectedType = type;
      selectedSelection = selection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
          top: BorderSide(color: widget.themeColor.withValues(alpha: 0.6), width: 2),
          left: BorderSide(color: widget.themeColor.withValues(alpha: 0.3), width: 1),
          right: BorderSide(color: widget.themeColor.withValues(alpha: 0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(color: widget.themeColor.withValues(alpha: 0.15), blurRadius: 25, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Column(
            children: [
              // Üst Kulp (Handle)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              // Başlık
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: widget.themeColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Otonom Çalma Listesi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Yapay zeka sizin için en uygun şarkıları seçsin',
                            style: TextStyle(
                              color: widget.themeColor.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sekmeler (Tabs)
              TabBar(
                controller: _tabController,
                indicatorColor: widget.themeColor,
                indicatorWeight: 3,
                labelColor: widget.themeColor,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                tabs: const [
                  Tab(icon: Icon(Icons.mood), text: 'Ruh Hali'),
                  Tab(icon: Icon(Icons.library_music), text: 'Müzik Türü'),
                ],
              ),
              
              // Sekme İçerikleri
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGrid(moods, 'Mood'),
                    _buildGrid(genres, 'Genre'),
                  ],
                ),
              ),
              
              // 🎯 SİBER HAMLE: BAŞLAT BUTONU (Her zaman görünür, seçime göre aktif/pasif olur)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedSelection != null 
                        ? widget.themeColor.withValues(alpha: 0.8)
                        : Colors.grey.withValues(alpha: 0.2),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    shadowColor: selectedSelection != null ? widget.themeColor : Colors.transparent,
                    elevation: selectedSelection != null ? 10 : 0,
                  ),
                  onPressed: selectedSelection != null
                      ? () {
                          Navigator.pop(context, {'type': selectedType!, 'selection': selectedSelection!});
                        }
                      : null, // 🎯 SİBER KALKAN: Seçim yoksa butona basılamaz
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selectedSelection != null ? Icons.rocket_launch : Icons.touch_app, 
                        color: selectedSelection != null ? Colors.white : Colors.white54
                      ),
                      const SizedBox(width: 12),
                      Text(
                        selectedSelection != null ? 'SİBER ZEKAYI BAŞLAT' : 'BİR KATEGORİ SEÇİN',
                        style: TextStyle(
                          color: selectedSelection != null ? Colors.white : Colors.white54, 
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 2.0
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
      ),
    ))));
  }

  Widget _buildGrid(List<Map<String, dynamic>> items, String type) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedSelection == item['name'];
        return _buildNeonCard(
          title: item['name'],
          icon: item['icon'],
          color: item['color'],
          isSelected: isSelected,
          onTap: () => _onItemTapped(type, item['name']),
        );
      },
    );
  }

  Widget _buildNeonCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.4), width: isSelected ? 2.5 : 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.3 : 0.1),
              blurRadius: isSelected ? 25 : 15,
              spreadRadius: isSelected ? 5 : 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
