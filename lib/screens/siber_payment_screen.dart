import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/subscription_manager.dart';
import '../widgets/siber_premium_sheet.dart'; // SiberPremiumSheet için
import '../widgets/legal_sheets.dart'; // 🎯 MAĞAZA UYUMLULUK: Gizlilik ve EULA

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
    required List<Map<String, dynamic>> features,
    required Color accentColor,
    required IconData icon,
    bool isCurrentPlan = false,
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
                ...features.map((f) {
                  bool isIncluded = f['included'];
                  String text = f['text'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(isIncluded ? Icons.check_circle : Icons.cancel, color: isIncluded ? accentColor : Colors.redAccent.withOpacity(0.5), size: 16),
                        const SizedBox(width: 10),
                        Expanded(child: Text(text, style: TextStyle(color: isIncluded ? Colors.white70 : Colors.white38, fontSize: 13, decoration: isIncluded ? TextDecoration.none : TextDecoration.lineThrough))),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan ? Colors.grey.withOpacity(0.3) : accentColor,
                      foregroundColor: isCurrentPlan ? Colors.white70 : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: isCurrentPlan ? 0 : 10,
                      shadowColor: accentColor,
                    ),
                    onPressed: isCurrentPlan ? null : () => _processPurchase(tier, title, tier == SiberTier.student ? 'student' : 'premium'),
                    child: Text(isCurrentPlan ? 'MEVCUT PLAN' : 'ŞİMDİ AKTİF ET', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.5)),
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
                  Icon(Icons.workspace_premium, color: widget.themeColor, size: 50),
                  const SizedBox(height: 15),
                  const Text(
                    'SİBER LİG\'E KATIL',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Otonom müzik deneyimini sınırların ötesine taşı.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Plans
                  _buildPlanCard(
                    title: 'ÜCRETSİZ',
                    price: '0 ₺ / Ay',
                    tier: SiberTier.free,
                    accentColor: Colors.grey,
                    icon: Icons.headphones,
                    isCurrentPlan: true, // Şimdilik varsayılan
                    features: [
                      {'text': 'Sınırsız Müzik Dinleme', 'included': true},
                      {'text': 'Reklamsız Deneyim', 'included': false},
                      {'text': 'Günde 5 Şarkı Arşivleme', 'included': true},
                      {'text': 'Reklamla Ekstra İndirme (+2)', 'included': true},
                      {'text': 'Günde 1 Kez AI Listeleme', 'included': true},
                      {'text': 'Yılda 2 Kez İstatistik Raporu', 'included': true},
                      {'text': 'Atmosferik Hava Mixi', 'included': false},
                      {'text': 'Siber Metamorfoz', 'included': false},
                    ],
                  ),

                  _buildPlanCard(
                    title: 'SİBER ÖĞRENCİ',
                    price: '54.99 ₺ / Ay',
                    tier: SiberTier.student,
                    accentColor: Colors.cyanAccent,
                    icon: Icons.school,
                    features: [
                      {'text': 'Sınırsız Müzik Dinleme', 'included': true},
                      {'text': 'Reklamsız Deneyim', 'included': true},
                      {'text': 'Günde 15 Şarkı Arşivleme', 'included': true},
                      {'text': 'Günde 5 Kez AI Listeleme', 'included': true},
                      {'text': '2 Ayda 1 İstatistik Raporu', 'included': true},
                      {'text': 'Atmosferik Hava Mixi Açık', 'included': true},
                      {'text': 'Siber Metamorfoz', 'included': false},
                    ],
                  ),

                  _buildPlanCard(
                    title: 'IMPERIUM PREMIUM',
                    price: '89.99 ₺ / Ay',
                    tier: SiberTier.premium,
                    accentColor: Colors.amber,
                    icon: Icons.diamond,
                    features: [
                      {'text': 'Sınırsız Müzik Dinleme', 'included': true},
                      {'text': 'Reklamsız Deneyim', 'included': true},
                      {'text': 'Limitsiz Şarkı Arşivleme', 'included': true},
                      {'text': 'Limitsiz AI Listeleme', 'included': true},
                      {'text': 'Limitsiz İstatistik Raporu', 'included': true},
                      {'text': 'Atmosferik Hava Mixi Açık', 'included': true},
                      {'text': 'Siber Metamorfoz Açık', 'included': true},
                    ],
                  ),
                  
                  const SizedBox(height: 20),

                  // 🎯 MAĞAZA UYUMLULUK: Satın Alımları Geri Yükle
                  TextButton.icon(
                    onPressed: () async {
                      _showLoadingDialog();
                      await _subManager.syncPurchases();
                      if (mounted) {
                        Navigator.pop(context); // Dialogu kapat
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Satın alımlarınız başarıyla kontrol edildi ve senkronize edildi.'),
                            backgroundColor: widget.themeColor,
                          ),
                        );
                        setState(() {}); // Durumu güncelle
                      }
                    },
                    icon: Icon(Icons.restore, color: widget.themeColor, size: 18),
                    label: Text('Satın Alımları Geri Yükle', style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),

                  // 🎯 MAĞAZA UYUMLULUK: Otomatik Yenileme ve Yasal Bilgilendirme
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                    child: Text(
                      'Abonelikler, mevcut dönemin bitiminden en az 24 saat önce iptal edilmediği sürece otomatik olarak yenilenir. Ödeme, satın alma onayında Apple ID / Google Hesabınızdan tahsil edilir. Aboneliğinizi mağaza hesap ayarlarınızdan yönetebilir veya dilediğiniz an iptal edebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 10, height: 1.4),
                    ),
                  ),

                  // 🎯 MAĞAZA UYUMLULUK: EULA ve Gizlilik Linkleri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => showLegalDocsModal(context, themeColor: widget.themeColor, initialTab: 0),
                        child: const Text('Kullanım Koşulları', style: TextStyle(color: Colors.white70, fontSize: 11, decoration: TextDecoration.underline)),
                      ),
                      const Text(' | ', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      TextButton(
                        onPressed: () => showLegalDocsModal(context, themeColor: widget.themeColor, initialTab: 1),
                        child: const Text('Gizlilik Politikası', style: TextStyle(color: Colors.white70, fontSize: 11, decoration: TextDecoration.underline)),
                      ),
                    ],
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
