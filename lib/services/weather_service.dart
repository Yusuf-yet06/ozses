import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      final url = "https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_weather'];
        if (current != null) {
          double temp = (current['temperature'] as num).toDouble();
          int code = current['weathercode'] as int;
          
          String mainCond = "Clear";
          if (code >= 1 && code <= 3) mainCond = "Clouds";
          else if (code >= 45 && code <= 48) mainCond = "Fog";
          else if (code >= 51 && code <= 55) mainCond = "Drizzle";
          else if (code >= 61 && code <= 67) mainCond = "Rain";
          else if (code >= 71 && code <= 77) mainCond = "Snow";
          else if (code >= 80 && code <= 82) mainCond = "Rain";
          else if (code >= 95 && code <= 99) mainCond = "Thunderstorm";

          return Weather(
            weatherMain: mainCond,
            temperature: Temperature(temp)
          );
        }
      }
      return null;
    } catch (e) {
      print("🛑 Siber Hava Durumu Hatası: $e");
      return null;
    }
  }

  // Ruh hali önerilerini havaya göre şekillendiren otonom analiz
  static String getAtmosphereMood(Weather? w) {
    if (w == null) return "Genel"; // Varsayılan
    
    final condition = w.weatherMain?.toLowerCase() ?? "";
    
    if (condition.contains("rain") || condition.contains("drizzle") || condition.contains("thunderstorm")) {
      return "Melankolik"; // Yağmurlu
    } else if (condition.contains("snow")) {
      return "Akustik"; // Karlı
    } else if (condition.contains("clear")) {
      return "Enerjik"; // Güneşli
    } else if (condition.contains("clouds")) {
      return "Odaklanma"; // Bulutlu/Kapalı
    }
    
    return "Genel";
  }
}
