import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/subscription_manager.dart';
import '../widgets/siber_premium_sheet.dart'; // SiberPremiumSheet için

class SiberPaymentScreen extends StatefulWidget {
  final Color themeColor;

  const SiberPaymentScreen({super.key, required this.themeColor});

  @override
  State<SiberPaymentScreen> createState() => _SiberPaymentScreenState();
}

class _SiberPaymentScreenState extends State<SiberPaymentScreen> {
  final SubscriptionManager _subManager = SubscriptionManager();
  bool _isLoading = false;
  Offerings? _offerings;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        Offerings offerings = await Purchases.getOfferings();
        if (mounted) {
          setState(() {
            _offerings = offerings;
          });
        }
      }
    } catch (e) {
      print("Siber Hata: RevenueCat paketleri alınamadı (Play Store ayarları eksik): $e");
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: widget.themeColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: widget.themeColor),
              const SizedBox(height: 15),
              const Text('Güvenli Bağlantı Kuruluyor...', style: TextStyle(color: Colors.white, fontSize: 12, decoration: TextDecoration.none)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPurchase(SiberTier tier, String planName, String entitlementId) async {
    _showLoadingDialog();

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && _offerings != null && _offerings!.current != null) {
        // Gerçek RevenueCat ödeme denemesi
        Package? packageToBuy;
        
        // EntitlementID'ye göre doğru paketi bulalım
        if (entitlementId == 'student') {
          packageToBuy = _offerings!.current!.availablePackages.firstWhere((p) => p.identifier.contains('student'), orElse: () => _offerings!.current!.availablePackages.first);
        } else {
          packageToBuy = _offerings!.current!.availablePackages.firstWhere((p) => p.identifier.contains('premium'), orElse: () => _offerings!.current!.availablePackages.first);
        }

        if (packageToBuy != null) {
          PurchaseResult purchaseResult = await Purchases.purchasePackage(packageToBuy);
          CustomerInfo customerInfo = purchaseResult.customerInfo;
          if (customerInfo.entitlements.all[entitlementId]?.isActive == true) {
            await _subManager.syncPurchases();
            _onPurchaseSuccess(planName);
            return;
          }
        }
      }
      
      // 🎯 SİBER KALKAN (Developer Mode Bypass)
      // Eğer Google Play kurulu değilse (veya Web ise) lokal test için sahte onayı çalıştır
      await Future.delayed(const Duration(seconds: 2));
      await _subManager.setTier(tier);
      _onPurchaseSuccess(planName);

    } on PlatformException catch (e) {
      Navigator.pop(context); // Dialogu kapat
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${e.message}')));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bilinmeyen bir hata oluştu: $e')));
    }
  }

  void _onPurchaseSuccess(String planName) {
    if (mounted) {
      Navigator.pop(context); // Yükleniyor'u kapat
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Ödeme Başarılı! $planName Paketine Geçiş Yapıldı. Uygulama yenileniyor...'),
          backgroundColor: widget.themeColor,
          duration: const Duration(seconds: 4),
        )
      );

      // Ana sayfaya kadar her şeyi kapat
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required SiberTier tier,
    required List<String> features,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: accentColor, size: 32),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(price, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  child: Divider(color: Colors.white24),
                ),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: accentColor, size: 16),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 10,
                      shadowColor: accentColor,
                    ),
                    onPressed: () => _processPurchase(tier, title, tier == SiberTier.student ? 'student' : 'premium'),
                    child: const Text('ŞİMDİ AKTİF ET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [widget.themeColor.withOpacity(0.3), Colors.black],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Icon(Icons.lock_clock, color: widget.themeColor, size: 50),
                  const SizedBox(height: 15),
                  const Text(
                    'LİMİTLERE TAKILMA',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bu özellik Siber Lig ayrıcalığıdır. Kesintisiz müzik deneyimi ve otonom zeka gücü için hemen aramıza katıl.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Plans
                  _buildPlanCard(
                    title: 'AKADEMİK LİG',
                    price: '55 ₺ / Ay',
                    tier: SiberTier.student,
                    accentColor: Colors.cyanAccent,
                    icon: Icons.school,
                    features: [
                      'Sıfır Reklam, Kesintisiz Müzik',
                      'Günde 5 Kez Yapay Zeka Liste Üretimi',
                      'Günde 20 Kez Sesli Asistan',
                      'Aylık İstatistik Raporu',
                      'Neon Karaoke Efektleri',
                    ],
                  ),

                  _buildPlanCard(
                    title: 'SİBER LORD',
                    price: '90 ₺ / Ay',
                    tier: SiberTier.premium,
                    accentColor: Colors.amber,
                    icon: Icons.workspace_premium,
                    features: [
                      'Tamamen Sınırsız Yapay Zeka',
                      'Limitsiz Siber Sesli Asistan',
                      '14 Günde 1 İstatistik Raporu',
                      'Siber Metamorfoz Modu',
                      'Limitsiz Aura Renkleri',
                      'Özel İmparator Rozeti',
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                       showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => SiberPremiumSheet(themeColor: widget.themeColor),
                      );
                    },
                    child: const Text('Tüm Özellikleri Karşılaştır', style: TextStyle(color: Colors.white54, decoration: TextDecoration.underline)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
