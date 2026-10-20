import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/platform/siber_platform.dart';
import 'history_service.dart';

class Temperature {
  final double? celsius;
  Temperature(this.celsius);
}

class Weather {
  final String? weatherMain;
  final Temperature? temperature;
  
  Weather({this.weatherMain, this.temperature});
}

// 🎯 SİBER HAMLE: Otonom Meteoroloji ve Konum Motoru (Açık Kaynak - API Key İstemez)
class WeatherService {
  static Future<Weather?> getCurrentWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null; // Konum kapalıysa zorlama
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low); // Pili korumak için düşük hassasiyet

      // Open-Meteo API (Ücretsiz, limitsiz, anahtarsız)
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_weather'];
        if (current != null) {
          double temp = (current['temperature'] as num).toDouble();
          int code = current['weathercode'] as int;
          
          String mainCond = 'Clear';
          if (code >= 1 && code <= 3) {
            mainCond = 'Clouds';
          } else if (code >= 45 && code <= 48) mainCond = 'Fog';
          else if (code >= 51 && code <= 55) mainCond = 'Drizzle';
          else if (code >= 61 && code <= 67) mainCond = 'Rain';
          else if (code >= 71 && code <= 77) mainCond = 'Snow';
          else if (code >= 80 && code <= 82) mainCond = 'Rain';
          else if (code >= 95 && code <= 99) mainCond = 'Thunderstorm';

          return Weather(
            weatherMain: mainCond,
            temperature: Temperature(temp)
          );
        }
      }
      return null;
    } catch (e) {
      print('🛑 Siber Hava Durumu Hatası: $e');
      return null;
    }
  }

  // Ruh hali önerilerini havaya göre şekillendiren otonom analiz
  static String getAtmosphereMood(Weather? w) {
    if (w == null) return 'Genel'; // Varsayılan
    
    final condition = w.weatherMain?.toLowerCase() ?? '';
    
    if (condition.contains('rain') || condition.contains('drizzle') || condition.contains('thunderstorm')) {
      return 'Melankolik'; // Yağmurlu
    } else if (condition.contains('snow')) {
      return 'Akustik'; // Karlı
    } else if (condition.contains('clear')) {
      return 'Enerjik'; // Güneşli
    } else if (condition.contains('clouds')) {
      return 'Odaklanma'; // Bulutlu/Kapalı
    }
    
    return 'Genel';
  }

  // 🎯 SİBER ATMOSFER & KİŞİSEL MÜZİK ZEVKİ FÜZYONU (Hava Durumu Mix Motoru)
  static Future<WeatherMixBundle> generateWeatherMix({Weather? weather, String? currentMood}) async {
    weather ??= await getCurrentWeather();
    String mood = currentMood ?? getAtmosphereMood(weather);

    final hour = DateTime.now().hour;
    final isNight = hour >= 22 || hour <= 5;
    if (isNight && mood == 'Genel') {
      mood = 'Gece';
    }

    // 🎧 Dinleme geçmişinden en çok dinlenen sanatçıları süz
    List<String> userTaste = [];
    try {
      final history = await HistoryService.getHistory();
      if (history.isNotEmpty) {
        history.sort((a, b) => b.totalListenSeconds.compareTo(a.totalListenSeconds));
        for (var rec in history.take(8)) {
          String clean = rec.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').trim();
          String artist = '';
          if (clean.contains('-')) {
            artist = clean.split('-').first.trim();
          } else if (clean.contains('–')) {
            artist = clean.split('–').first.trim();
          } else if (clean.contains(':')) {
            artist = clean.split(':').first.trim();
          }
          if (artist.isNotEmpty && artist.length <= 25 && !userTaste.contains(artist)) {
            userTaste.add(artist);
          }
        }
      }
    } catch (e) {
      print('Siber Hava Durumu: Dinleme geçmişi okunamadı: $e');
    }

    // Şahsi Keşfet tercihlerine de bak
    if (userTaste.length < 2) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawArtists = prefs.getString('siber_personal_artists') ?? '';
        if (rawArtists.isNotEmpty) {
          for (var a in rawArtists.split(',')) {
            final tr = a.trim();
            if (tr.isNotEmpty && !userTaste.contains(tr)) {
              userTaste.add(tr);
            }
          }
        }
      } catch (e) {
        print('Siber Hava Durumu: Şahsi tercihler okunamadı: $e');
      }
    }

    final double? temp = weather?.temperature?.celsius;
    final String tempStr = temp != null ? '${temp.toStringAsFixed(0)}°C ' : '';

    String title;
    String description;
    IconData icon;
    Color color;
    List<String> queries = [];

    switch (mood) {
      case 'Melankolik':
        title = '🌧️ Yağmurlu Gün & Melankoli Mixi';
        description = '${tempStr}Yağmurlu havanın ritmine ve müzik zevkine özel duygusal parçalar.';
        icon = Icons.water_drop_rounded;
        color = Colors.blueAccent;
        if (userTaste.isNotEmpty) {
          queries.add('${userTaste.first} slow akustik');
          if (userTaste.length > 1) queries.add('${userTaste[1]} duygusal');
        }
        queries.add('yağmurlu hava şarkıları');
        queries.add('türkçe lofi yağmur');
        break;

      case 'Akustik':
        title = '❄️ Karlı Hava & Sıcak Akustik Mix';
        description = '${tempStr}Soğuk havada içini ısıtacak akustik ve sakin tınılar.';
        icon = Icons.ac_unit_rounded;
        color = Colors.tealAccent;
        if (userTaste.isNotEmpty) {
          queries.add('${userTaste.first} akustik gitar');
          if (userTaste.length > 1) queries.add('${userTaste[1]} akustik');
        }
        queries.add('karlı hava akustik şarkılar');
        queries.add('türkçe sakin akustik');
        break;

      case 'Enerjik':
        title = '☀️ Güneşli Gün & Enerji Patlaması';
        description = '${tempStr}Güneşin altında enerjini zirveye taşıyacak hareketli parçalar.';
        icon = Icons.wb_sunny_rounded;
        color = Colors.amberAccent;
        if (userTaste.isNotEmpty) {
          queries.add('${userTaste.first} hareketli remix');
          if (userTaste.length > 1) queries.add('${userTaste[1]} hit');
        }
        queries.add('türkçe enerjik pop');
        queries.add('yaz şarkıları hareketli');
        break;

      case 'Odaklanma':
        title = '☁️ Bulutlu Hava & Derin Odak Mixi';
        description = '${tempStr}Gri bulutların altında derinleşen beatler ve ritimler.';
        icon = Icons.cloud_rounded;
        color = Colors.lightBlueAccent;
        if (userTaste.isNotEmpty) {
          queries.add('${userTaste.first} beat');
        }
        queries.add('türkçe lofi beat');
        queries.add('deep house chill mix');
        break;

      case 'Gece':
      default:
        if (isNight) {
          title = '🌙 Gece Sürüşü & Neon Yıldızlar';
          description = 'Gecenin sessizliğinde müzik zevkine eşlik eden derin akış.';
          icon = Icons.nightlight_round;
          color = Colors.deepPurpleAccent;
          if (userTaste.isNotEmpty) {
            queries.add('${userTaste.first} slowed reverb');
          }
          queries.add('gece sürüşü şarkıları');
          queries.add('synthwave chill night');
        } else {
          title = '🌤️ Atmosfer Miksi';
          description = '${tempStr}Günün akışına ve dinleme alışkanlıklarına özel akıllı seçki.';
          icon = Icons.album_rounded;
          color = Colors.cyanAccent;
          if (userTaste.isNotEmpty) {
            queries.add('${userTaste.first} en çok dinlenen');
          }
          queries.add('trend türkçe müzikler');
        }
        break;
    }

    final List<Map<String, dynamic>> tracks = [];
    final Set<String> seenIds = {};

    for (var q in queries.take(3)) {
      try {
        final res = await SiberPlatform.instance.searchMusic(q, limit: 8);
        for (var item in res) {
          if (item is Map) {
            final id = (item['videoId'] ?? item['id'] ?? item['video_id'])?.toString();
            if (id != null && id.isNotEmpty && !seenIds.contains(id)) {
              seenIds.add(id);
              tracks.add(Map<String, dynamic>.from(item));
            }
          }
        }
      } catch (e) {
        print('Siber Hava Mix Arama Hatası ($q): $e');
      }
    }

    return WeatherMixBundle(
      title: title,
      description: description,
      mood: mood,
      icon: icon,
      themeColor: color,
      temp: temp,
      userTaste: userTaste,
      tracks: tracks,
    );
  }
}

// 🎯 SİBER PAKET: Hava Durumu Mix Paketi
class WeatherMixBundle {
  final String title;
  final String description;
  final String mood;
  final IconData icon;
  final Color themeColor;
  final double? temp;
  final List<String> userTaste;
  final List<Map<String, dynamic>> tracks;

  WeatherMixBundle({
    required this.title,
    required this.description,
    required this.mood,
    required this.icon,
    required this.themeColor,
    this.temp,
    required this.userTaste,
    required this.tracks,
  });
}
