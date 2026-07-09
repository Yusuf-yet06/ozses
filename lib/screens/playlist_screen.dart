import 'package:flutter/material.dart';

class OzsesPlaylistScreen extends StatelessWidget {
  const OzsesPlaylistScreen({super.key});

  // Örnek veri (Python'dan gelecek olan liste)
  final List<Map<String, String>> recordings = const [
    {
      'title': 'Ahmet_Bey_Egzersiz_1',
      'date': '23.04.2026',
      'duration': '02:15',
    },
    {'title': 'Otonom_Kayit_Sefik', 'date': '22.04.2026', 'duration': '01:45'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // SİBER TEMA: Arka plan karanlık
      appBar: AppBar(
        title: const Text(
          'ÖZSES - Siber Klinik Arşiv',
          style: TextStyle(color: Colors.cyanAccent, fontSize: 18),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: recordings.length,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.grey[900], // SİBER TEMA: Koyu gri kartlar
            elevation: 4,
            shadowColor: Colors.cyanAccent.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Colors.cyanAccent.withValues(alpha: 0.5),
                width: 1,
              ), // Neon çerçeve
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.cyanAccent,
                child: Icon(
                  Icons.mic,
                  color: Colors.black,
                ), // Hatalı black8ort kodu düzeltildi
              ),
              title: Text(
                recordings[index]['title']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                recordings[index]['date']!,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.cyanAccent,
                  size: 35,
                ),
                onPressed: () {
                  // Python'daki playlist_engine.play_file() fonksiyonunu tetikleyecek
                  print(
                    "${recordings[index]['title']} mühürlendi ve oynatılıyor...",
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
