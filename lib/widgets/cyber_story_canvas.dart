import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🎨 SİBER STORY TEMALARI
enum CyberStoryTheme {
  turkuaz,
  magenta,
  altin,
}

/// 📱 SİBER STORY KART TÜRLERİ (ÇEŞİTLİLİK)
enum CyberStoryCardType {
  sanatcilar,       // 📀 01: Plak & Top Sanatçılar
  topluIstatistik,  // 📊 02: Toplu İstatistikler & Metrik Matrisi
  siberAnaliz,      // 🧠 03: Siber Profil & Frekans Analizi
  topSarkilar,      // 🏆 04: Top 5 Şarkı Karnesi
}

class CyberThemeData {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color bgDark;
  final LinearGradient cardGradient;

  const CyberThemeData({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.bgDark,
    required this.cardGradient,
  });

  static const turkuaz = CyberThemeData(
    name: 'SİBER TURKUAZ',
    primary: Color(0xFF00FFE0),
    secondary: Color(0xFF7000FF),
    accent: Color(0xFF00B4D8),
    bgDark: Color(0xFF060912),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x2A00FFE0), Color(0x107000FF)],
    ),
  );

  static const magenta = CyberThemeData(
    name: 'NEON MAGENTA',
    primary: Color(0xFFFF007F),
    secondary: Color(0xFF9D00FF),
    accent: Color(0xFFFF4081),
    bgDark: Color(0xFF120516),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x2AFF007F), Color(0x109D00FF)],
    ),
  );

  static const altin = CyberThemeData(
    name: 'ALTIN VIP',
    primary: Color(0xFFFFD700),
    secondary: Color(0xFFFF8C00),
    accent: Color(0xFFFFB300),
    bgDark: Color(0xFF140E02),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x2AFFD700), Color(0x10FF8C00)],
    ),
  );
}

/// 📱 ÖZSES 9:16 DERGİ KALİTESİNDE HİKAYE KARTI
/// Instagram, TikTok ve WhatsApp durumları için yüksek çözünürlüklü çıktı üreten kanvas.
class CyberStoryCanvas extends StatelessWidget {
  final CyberStoryCardType cardType;
  final CyberStoryTheme theme;
  final String primaryGenre;
  final double primaryGenrePercent;
  final String persona;
  final int totalHours;
  final String nightOwlRatio;
  final int streakDays;
  final List<StoryArtistItem> artists;
  final String topSong;
  final List<StorySongItem>? topSongsList;

  const CyberStoryCanvas({
    super.key,
    this.cardType = CyberStoryCardType.sanatcilar,
    this.theme = CyberStoryTheme.turkuaz,
    required this.primaryGenre,
    required this.primaryGenrePercent,
    required this.persona,
    required this.totalHours,
    this.nightOwlRatio = '%68 Gece',
    this.streakDays = 34,
    required this.artists,
    this.topSong = 'Azer Bülbül - Çoğu Gitti Azı Kaldı',
    this.topSongsList,
  });

  CyberThemeData get _t {
    switch (theme) {
      case CyberStoryTheme.magenta:
        return CyberThemeData.magenta;
      case CyberStoryTheme.altin:
        return CyberThemeData.altin;
      case CyberStoryTheme.turkuaz:
      default:
        return CyberThemeData.turkuaz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          color: _t.bgDark,
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.4),
            radius: 1.2,
            colors: [
              _t.primary.withValues(alpha: 0.16),
              _t.secondary.withValues(alpha: 0.08),
              _t.bgDark,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          border: Border.all(color: _t.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Stack(
          children: [
            // 🌐 Arka plan siber ızgara dokusu
            Positioned.fill(
              child: CustomPaint(
                painter: _StoryGridPainter(color: _t.primary),
              ),
            ),

            // İçerik Akışı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Üst Bar: ÖZSES Logosu & V7 Mührü
                  _buildHeader(),
                  const SizedBox(height: 12),

                  // 2. Dinamik Gövde (Seçilen Kart Modeline Göre Değişir)
                  Expanded(
                    child: _buildCardBody(),
                  ),

                  const SizedBox(height: 10),
                  // 3. Alt Bilgi: QR / Barkod ve ÖZSES Markası
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Üst Başlık Barı ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _t.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _t.primary, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.blur_on_rounded, size: 14, color: _t.primary),
              const SizedBox(width: 4),
              Text(
                'ÖZSES',
                style: TextStyle(
                  color: _t.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            '2026 SİBER RAPOR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // --- Alt Barkod ve İmza ---
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ÖZSES MÜZİK // V7',
              style: TextStyle(
                color: _t.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'ozses.app • Siber Özet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
              ),
            ),
          ],
        ),
        CustomPaint(
          size: const Size(60, 22),
          painter: _CyberBarcodePainter(color: _t.primary),
        ),
      ],
    );
  }

  // --- Ana Kart Gövdesi ---
  Widget _buildCardBody() {
    switch (cardType) {
      case CyberStoryCardType.topluIstatistik:
        return _buildTopluIstatistikCard();
      case CyberStoryCardType.siberAnaliz:
        return _buildSiberAnalizCard();
      case CyberStoryCardType.topSarkilar:
        return _buildTopSarkilarCard();
      case CyberStoryCardType.sanatcilar:
      default:
        return _buildSanatcilarCard();
    }
  }

  // ==========================================
  // 📀 KART 1: PLAK & SANATÇILAR
  // ==========================================
  Widget _buildSanatcilarCard() {
    return Column(
      children: [
        // Persona Kapsülü
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _t.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _t.primary.withValues(alpha: 0.4)),
          ),
          child: Text(
            'AURA: $persona',
            style: TextStyle(
              color: _t.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Kahraman Plak
        SizedBox(
          height: 120,
          width: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _t.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(114, 114),
                painter: _HoloVinylPainter(themeColor: _t.primary),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _t.bgDark,
                  border: Border.all(color: _t.primary, width: 2),
                ),
                child: Icon(Icons.graphic_eq_rounded, color: _t.primary, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Tür & Yüzde
        Text(
          'BENİM DÖNEMİM',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          '$primaryGenre %${primaryGenrePercent.round()}',
          style: GoogleFonts.bungee(
            fontSize: 22,
            color: _t.primary,
            shadows: [
              Shadow(color: _t.primary.withValues(alpha: 0.8), blurRadius: 16),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3 Metrik Kutusu
        Row(
          children: [
            _buildMetricTile(
              icon: Icons.headphones_rounded,
              label: 'TOPLAM',
              value: '$totalHours SAAT',
              color: _t.primary,
            ),
            const SizedBox(width: 8),
            _buildMetricTile(
              icon: Icons.nightlight_round,
              label: 'BİYORİTİM',
              value: nightOwlRatio,
              color: _t.secondary,
            ),
            const SizedBox(width: 8),
            _buildMetricTile(
              icon: Icons.local_fire_department_rounded,
              label: 'SERİ',
              value: '$streakDays GÜN',
              color: _t.accent,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Top Sanatçılar Başlığı
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'TOP SANATÇILAR // 2026',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 6),

        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(artists.length, 4),
            separatorBuilder: (_, __) => const SizedBox(height: 5),
            itemBuilder: (context, idx) {
              final artist = artists[idx];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Text(
                      '0${idx + 1}',
                      style: TextStyle(
                        color: _t.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        artist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${artist.hours} SAAT',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 📊 KART 2: TOPLU İSTATİSTİKLER (METRİK MATRİSİ)
  // ==========================================
  Widget _buildTopluIstatistikCard() {
    final int estimatedTracks = (totalHours * 16.5).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Başlık Rozeti
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _t.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _t.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_rounded, size: 14, color: _t.primary),
              const SizedBox(width: 6),
              Text(
                'TOPLU İSTATİSTİK MATRİSİ // 2026',
                style: TextStyle(
                  color: _t.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4'lü Büyük Neon İstatistik Blokları
        Row(
          children: [
            _buildStatCard(
              icon: Icons.headset_rounded,
              title: '$totalHours',
              unit: 'SAAT',
              subtitle: 'Toplam Dinleme',
              color: _t.primary,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              icon: Icons.music_note_rounded,
              title: '$estimatedTracks',
              unit: 'ŞARKI',
              subtitle: 'Oynatılan Parça',
              color: _t.accent,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatCard(
              icon: Icons.nightlight_round,
              title: nightOwlRatio,
              unit: '',
              subtitle: 'Gece Biyoritmi',
              color: _t.secondary,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              icon: Icons.local_fire_department_rounded,
              title: '$streakDays',
              unit: 'GÜN',
              subtitle: 'Kesintisiz Seri',
              color: const Color(0xFFFF9100),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tür Dağılımı Çubukları
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'MÜZİKAL TÜR MATRİSİ // DAĞILIM',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),

        _buildGenreBar('Arabesk & Damar', primaryGenrePercent / 100, _t.primary),
        const SizedBox(height: 6),
        _buildGenreBar('Rap & Hip-Hop', 0.42, _t.accent),
        const SizedBox(height: 6),
        _buildGenreBar('Özgün & Anadolu Rock', 0.30, _t.secondary),
        const SizedBox(height: 6),
        _buildGenreBar('Pop & Elektronik', 0.28, const Color(0xFFFF007F)),

        const Spacer(),

        // Alt Bilgi Kartı: Zirve Saati & Skor
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _t.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EN AKTİF SAAT DİLİMİ',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '01:00 - 04:00 (Gece Zirvesi)',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _t.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _t.primary),
                ),
                child: Text(
                  'SKOR: 98.4',
                  style: TextStyle(color: _t.primary, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String unit,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  title,
                  style: GoogleFonts.bungee(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreBar(String genre, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              genre,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Text(
              '%${(ratio * 100).round()}',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 🧠 KART 3: SİBER ANALİZ (PROFİL ANALİZİ & SES İZİ)
  // ==========================================
  Widget _buildSiberAnalizCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Rütbe Rozeti
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _t.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _t.primary, width: 1.2),
          ),
          child: Text(
            'SİBER KİMLİK: $persona',
            style: TextStyle(
              color: _t.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 🎛️ Ses İzi & Frekans Spektrumu (Custom Paint)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _t.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SES İZİ & FREKANS SPEKTRUMU',
                    style: TextStyle(
                      color: _t.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _t.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '432 Hz DERİNLİK',
                      style: TextStyle(color: _t.primary, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Spektrum Çizimi
              SizedBox(
                height: 70,
                width: double.infinity,
                child: CustomPaint(
                  painter: _FrequencySpectrumPainter(color: _t.primary, accentColor: _t.secondary),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildEqLabel('SUB-BAS', '92%'),
                  _buildEqLabel('BAS', '88%'),
                  _buildEqLabel('ORTA', '65%'),
                  _buildEqLabel('TİZ', '74%'),
                  _buildEqLabel('AURA', '95%'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 🩺 Siber Teşhis Kutusu
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _t.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _t.secondary.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_rounded, color: _t.secondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'SİBER TEŞHİS RAPORU',
                    style: TextStyle(
                      color: _t.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildDiagnosisLine('Müzikal Teşhis', 'Melankolik Gece Dalgalanması & Derin Dinleyici'),
              const SizedBox(height: 6),
              _buildDiagnosisLine('Müzikal Biyom', 'Gece Kuşu Siber Sürüş • Yüksek Rezonans'),
              const SizedBox(height: 6),
              _buildDiagnosisLine('Gizli Kayıt', 'Parçaların %68\'i 23:00 sonrasında dinlendi.'),
            ],
          ),
        ),

        const Spacer(),

        // Onay Mührü
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_rounded, color: _t.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'BİYOMETRİK FREKANS DOĞRULANDI • IMPERIUM V7',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEqLabel(String name, String val) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(color: _t.primary, fontSize: 10, fontWeight: FontWeight.w900),
        ),
        Text(
          name,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDiagnosisLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• $label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 🏆 KART 4: TOP 5 ŞARKI KARNESİ
  // ==========================================
  Widget _buildTopSarkilarCard() {
    final List<StorySongItem> songs = topSongsList ?? [
      StorySongItem(rank: 1, title: topSong, plays: 142, tag: 'ŞAMPİYON'),
      const StorySongItem(rank: 2, title: 'Müslüm Gürses - Affet', plays: 120, tag: 'KLASİK'),
      const StorySongItem(rank: 3, title: 'Ahmet Kaya - Kum Gibi', plays: 86, tag: 'ÖZGÜN'),
      const StorySongItem(rank: 4, title: 'Ezhel - Geceler', plays: 54, tag: 'RAP'),
      const StorySongItem(rank: 5, title: 'Sagopa Kajmer - Galiba', plays: 31, tag: 'NOSTALJİ'),
    ];

    return Column(
      children: [
        // Başlık Rozeti
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _t.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _t.primary),
          ),
          child: Text(
            '🏆 2026 ŞAMPİYONLAR // TOP ŞARKILAR',
            style: TextStyle(
              color: _t.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 👑 1 Numara Şampiyon Vitrini
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: _t.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _t.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _t.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '1. ŞAMPİYON PARÇA',
                        style: TextStyle(
                          color: _t.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD700)),
                    ),
                    child: const Text(
                      'ZİRVE',
                      style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                songs.first.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${songs.first.plays} DEFA ÇALINDI',
                    style: TextStyle(
                      color: _t.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• %96 Tamamlama',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Diğer Parçalar Listesi (2, 3, 4, 5)
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(songs.length - 1, 4),
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
              final song = songs[idx + 1];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Text(
                      '0${song.rank}',
                      style: TextStyle(
                        color: _t.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${song.plays}x',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryArtistItem {
  final String name;
  final int hours;
  final int percent;

  const StoryArtistItem({
    required this.name,
    required this.hours,
    required this.percent,
  });
}

class StorySongItem {
  final int rank;
  final String title;
  final int plays;
  final String tag;

  const StorySongItem({
    required this.rank,
    required this.title,
    required this.plays,
    required this.tag,
  });
}

/// 💿 HOLOGRAM PLAK ÇİZİCİ
class _HoloVinylPainter extends CustomPainter {
  final Color themeColor;

  _HoloVinylPainter({required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final basePaint = Paint()
      ..color = const Color(0xFF10121A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, basePaint);

    final groovePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double r = radius * 0.45; r < radius * 0.95; r += 6.0) {
      canvas.drawCircle(center, r, groovePaint);
    }

    final neonPaint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 1, neonPaint);

    final shinePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          themeColor.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shinePaint);
  }

  @override
  bool shouldRepaint(covariant _HoloVinylPainter oldDelegate) =>
      oldDelegate.themeColor != themeColor;
}

/// 🌐 ARKAPLAN HAFİF SİBER ÇİZGİLERİ
class _StoryGridPainter extends CustomPainter {
  final Color color;

  _StoryGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..strokeWidth = 0.8;

    const double step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StoryGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 🔲 FÜTÜRİSTİK SİBER BARKOD
class _CyberBarcodePainter extends CustomPainter {
  final Color color;

  _CyberBarcodePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;

    final widths = [2.0, 1.0, 3.0, 1.0, 4.0, 2.0, 1.0, 3.0, 2.0, 1.0, 4.0, 2.0];
    double currentX = 0;

    for (var w in widths) {
      paint.strokeWidth = w;
      canvas.drawLine(Offset(currentX, 0), Offset(currentX, size.height), paint);
      currentX += w + 2.5;
      if (currentX > size.width) break;
    }
  }

  @override
  bool shouldRepaint(covariant _CyberBarcodePainter oldDelegate) => false;
}

/// 🎛️ SİBER FREKANS SPEKTRUM ÇİZİCİSİ
class _FrequencySpectrumPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  _FrequencySpectrumPainter({required this.color, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    const int barCount = 28;
    final double barWidth = (size.width - (barCount - 1) * 3) / barCount;

    final heights = [
      0.65, 0.82, 0.95, 0.78, 0.88, 0.60, 0.75, 0.90,
      0.98, 0.85, 0.70, 0.55, 0.68, 0.80, 0.92, 0.75,
      0.60, 0.85, 0.90, 0.70, 0.50, 0.65, 0.78, 0.60,
      0.45, 0.55, 0.40, 0.35,
    ];

    for (int i = 0; i < barCount; i++) {
      final double h = size.height * heights[i % heights.length];
      final double x = i * (barWidth + 3);
      final double y = size.height - h;

      paint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color.withValues(alpha: 0.2), i > 14 ? accentColor : color],
      ).createShader(Rect.fromLTWH(x, y, barWidth, h));

      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barWidth, h), const Radius.circular(2)),
        paint,
      );

      // Üst parlama noktası
      final peakPaint = Paint()..color = (i > 14 ? accentColor : color).withValues(alpha: 0.9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y - 2, barWidth, 2), const Radius.circular(1)),
        peakPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FrequencySpectrumPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accentColor != accentColor;
}
