import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ozses_analytics.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS play_history');
        await _onCreate(db, newVersion);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE play_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        videoId TEXT,
        title TEXT,
        channel TEXT,
        duration INTEGER,
        played_at TEXT
      )
    ''');
  }

  Future<void> logPlay(String videoId, String title, String channel, int durationSeconds) async {
    if (videoId.isEmpty || title.isEmpty) return;
    final db = await database;
    await db.insert(
      'play_history',
      {
        'videoId': videoId,
        'title': title,
        'channel': channel,
        'duration': durationSeconds,
        'played_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('SİBER ANALİTİK: Dinleme kaydedildi -> \$title (\$durationSeconds sn)');
  }

  // --- Analiz Metodları (Wrapped İçin) ---
  
  // Toplam dinleme süresi (saniye)
  Future<int> getTotalListeningTime() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(duration) as total FROM play_history');
    if (result.first['total'] != null) {
      return (result.first['total'] as num).toInt();
    }
    return 0;
  }

  // En çok dinlenen şarkılar (Top 5)
  Future<List<Map<String, dynamic>>> getTopSongs({int limit = 5}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT videoId, title, channel, COUNT(*) as play_count 
      FROM play_history 
      GROUP BY videoId 
      ORDER BY play_count DESC 
      LIMIT ?
    ''', [limit]);
    return result;
  }

  // En çok dinlenen sanatçı/kanal
  Future<String> getTopChannel() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT channel, COUNT(*) as play_count 
      FROM play_history 
      WHERE channel IS NOT NULL AND channel != ''
      GROUP BY channel 
      ORDER BY play_count DESC 
      LIMIT 1
    ''');
    if (result.isNotEmpty) {
      return result.first['channel'] as String;
    }
    return 'Bilinmiyor';
  }

  // Karakter Analizi (Gece Kuşu vs Gün Doğumu vs Öğle)
  Future<String> getListeningPersona() async {
    final db = await database;
    final result = await db.query('play_history', columns: ['played_at']);
    if (result.isEmpty) return 'Keşfetmeye Hazır';

    int night = 0; // 22:00 - 06:00
    int morning = 0; // 06:00 - 14:00
    int evening = 0; // 14:00 - 22:00

    for (var row in result) {
      if (row['played_at'] != null) {
        DateTime time = DateTime.parse(row['played_at'] as String);
        if (time.hour >= 22 || time.hour < 6) {
          night++;
        } else if (time.hour >= 6 && time.hour < 14) {
          morning++;
        } else {
          evening++;
        }
      }
    }

    if (night > morning && night > evening) {
      return 'Gece Kuşu';
    } else if (morning > night && morning > evening) {
      return 'Sabah İnsanı';
    } else {
      return 'Günün Adamı';
    }
  }

  // Wrapped için sahte/örnek veri ekleme (Geliştirme amaçlı)
  Future<void> addMockDataIfEmpty() async {
    final db = await database;
    final countRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM play_history');
    int count = Sqflite.firstIntValue(countRes) ?? 0;
    
    if (count == 0) {
      print('SİBER ANALİTİK: Test verisi ekleniyor...');
      var mockSongs = [
        {'id': 'xyz1', 't': 'Geceler', 'c': 'Ezhel', 'd': 210},
        {'id': 'xyz1', 't': 'Geceler', 'c': 'Ezhel', 'd': 210},
        {'id': 'xyz1', 't': 'Geceler', 'c': 'Ezhel', 'd': 210},
        {'id': 'abc2', 't': 'Ateşten Gömlek', 'c': 'Sagopa Kajmer', 'd': 250},
        {'id': 'abc2', 't': 'Ateşten Gömlek', 'c': 'Sagopa Kajmer', 'd': 250},
        {'id': 'def3', 't': 'Mekanın Sahibi', 'c': 'Norm Ender', 'd': 180},
      ];
      
      for (var s in mockSongs) {
        await logPlay(s['id'] as String, s['t'] as String, s['c'] as String, s['d'] as int);
      }
    }
  }
}
