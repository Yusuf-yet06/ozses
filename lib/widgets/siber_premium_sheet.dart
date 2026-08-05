import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/subscription_manager.dart';
import '../screens/siber_payment_screen.dart';

class SiberPremiumSheet extends StatefulWidget {
  final Color themeColor;

  const SiberPremiumSheet({super.key, required this.themeColor});

  @override
  State<SiberPremiumSheet> createState() => _SiberPremiumSheetState();
}

class _SiberPremiumSheetState extends State<SiberPremiumSheet> {
  final SubscriptionManager _subManager = SubscriptionManager();

  Widget _buildFeatureRow(String text, bool included, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: included ? Colors.greenAccent : Colors.redAccent.withValues(alpha: 0.5),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: included 
                  ? (highlight ? Colors.amberAccent : Colors.white) 
                  : Colors.white54,
                fontSize: 13,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required SiberTier tier,
    required List<Widget> features,
    required Color accentColor,
    required bool isCurrent,
  }) {
    return SafeArea(
      top: false,
      child: Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrent ? accentColor : accentColor.withValues(alpha: 0.3),
          width: isCurrent ? 2.5 : 1,
        ),
        boxShadow: isCurrent ? [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('MEVCUT PAKETİNİZ', 
                      style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(price, style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.w900)),
                const Divider(color: Colors.white24, height: 30),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: features,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                if (!isCurrent)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor.withValues(alpha: 0.2),
                        side: BorderSide(color: accentColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        if (tier == SiberTier.free) {
                          await _subManager.setTier(tier);
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 $title Paketine Geçiş Başarılı! Uygulama yenileniyor...'),
                                backgroundColor: accentColor,
                              )
                            );
                          }
                        } else {
                          Navigator.pop(context); // Modal kapat
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SiberPaymentScreen(themeColor: widget.themeColor),
                            ),
                          );
                        }
                      },
                      child: Text('SEÇ', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currentTier = _subManager.currentTier;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: widget.themeColor.withValues(alpha: 0.5), width: 2)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium, color: widget.themeColor, size: 32),
                  const SizedBox(width: 10),
                  const Text('SİBER LİGLER', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // FREE TIER
                    _buildPlanCard(
                      title: 'ÇAYLAK',
                      price: 'Ücretsiz',
                      tier: SiberTier.free,
                      accentColor: Colors.blueGrey,
                      isCurrent: currentTier == SiberTier.free,
                      features: [
                        _buildFeatureRow('Sınırsız Dinleme & İndirme', true),
                        _buildFeatureRow('Reklamlar', false),
                        _buildFeatureRow('Standart Karaoke', true),
                        _buildFeatureRow('AI Liste (Günde 1)', true),
                        _buildFeatureRow('İstatistik Raporu (Yılda 3)', true),
                        _buildFeatureRow('Şahsi Keşfet & Otomatik Mix', false),
                        _buildFeatureRow('Sesli Komut', false),
                        _buildFeatureRow('Metamorfoz Modu', false),
                        _buildFeatureRow('Neon Şimmer Efektleri', false),
                      ],
                    ),
                    // STUDENT TIER
                    _buildPlanCard(
                      title: 'AKADEMİK',
                      price: '55 ₺ / Ay',
                      tier: SiberTier.student,
                      accentColor: Colors.cyanAccent,
                      isCurrent: currentTier == SiberTier.student,
                      features: [
                        _buildFeatureRow('Sınırsız Dinleme & İndirme', true),
                        _buildFeatureRow('Reklamsız Deneyim', true, highlight: true),
                        _buildFeatureRow('Neon Karaoke Efektleri', true),
                        _buildFeatureRow('Şahsi Keşfet & Otomatik Mix', true, highlight: true),
                        _buildFeatureRow('AI Liste (Günde 5)', true),
                        _buildFeatureRow('Sesli Komut (Limitli)', true),
                        _buildFeatureRow('İstatistik Raporu (Ayda 1)', true),
                        _buildFeatureRow('Kısıtlı Aura Temaları', true),
                        _buildFeatureRow('Metamorfoz Modu', false),
                      ],
                    ),
                    // PREMIUM TIER
                    _buildPlanCard(
                      title: 'SİBER LORD',
                      price: '90 ₺ / Ay',
                      tier: SiberTier.premium,
                      accentColor: Colors.purpleAccent,
                      isCurrent: currentTier == SiberTier.premium,
                      features: [
                        _buildFeatureRow('Sınırsız Dinleme & İndirme', true),
                        _buildFeatureRow('Sıfır Reklam', true),
                        _buildFeatureRow('Sınırsız AI Müzik Listesi', true, highlight: true),
                        _buildFeatureRow('Limitsiz Sesli Komut', true),
                        _buildFeatureRow('İstatistik Raporu (14 Günde 1)', true),
                        _buildFeatureRow('Limitsiz Aura Renkleri', true),
                        _buildFeatureRow('Siber Metamorfoz Modu', true, highlight: true),
                        _buildFeatureRow('Özel İmparator Rozeti', true, highlight: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
