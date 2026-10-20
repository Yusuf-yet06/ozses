import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/subscription_manager.dart';
import 'legal_sheets.dart';

class SiberPremiumSheet extends StatefulWidget {
  final Color themeColor;

  const SiberPremiumSheet({super.key, required this.themeColor});

  @override
  State<SiberPremiumSheet> createState() => _SiberPremiumSheetState();
}

class _SiberPremiumSheetState extends State<SiberPremiumSheet> {
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
      debugPrint("Siber Hata: RevenueCat paketleri alınamadı: $e");
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
              const Text('Güvenli Bağlantı Kuruluyor...',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      decoration: TextDecoration.none)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPurchase(SiberTier tier, String planName, String entitlementId) async {
    _showLoadingDialog();

    try {
      if (!kIsWeb &&
          (Platform.isAndroid || Platform.isIOS) &&
          _offerings != null &&
          _offerings!.current != null) {
        Package? packageToBuy;

        if (entitlementId == 'student') {
          packageToBuy = _offerings!.current!.availablePackages.firstWhere(
              (p) => p.identifier.contains('student'),
              orElse: () => _offerings!.current!.availablePackages.first);
        } else {
          packageToBuy = _offerings!.current!.availablePackages.firstWhere(
              (p) => p.identifier.contains('premium'),
              orElse: () => _offerings!.current!.availablePackages.first);
        }

        if (packageToBuy != null) {
          PurchaseResult purchaseResult =
              await Purchases.purchasePackage(packageToBuy);
          CustomerInfo customerInfo = purchaseResult.customerInfo;
          if (customerInfo.entitlements.all[entitlementId]?.isActive == true) {
            await _subManager.syncPurchases();
            _onPurchaseSuccess(planName);
            return;
          }
        }
      }

      // Geliştirici / Test simülasyonu
      await Future.delayed(const Duration(seconds: 1));
      await _subManager.setTier(tier);
      _onPurchaseSuccess(planName);
    } on PlatformException catch (e) {
      if (mounted) Navigator.pop(context); // Loading dialog
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Hata: ${e.message}')));
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
      }
    }
  }

  void _onPurchaseSuccess(String planName) {
    if (mounted) {
      Navigator.pop(context); // Loading dialog
      Navigator.pop(context); // Sheet'i kapat

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🎉 $planName Paketine Geçiş Yapıldı! Uygulama yenileniyor...'),
        backgroundColor: widget.themeColor,
        duration: const Duration(seconds: 3),
      ));
    }
  }

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
                                content: Text('🎉 $title Paketine Geçiş Başarılı!'),
                                backgroundColor: accentColor,
                              )
                            );
                            Navigator.pop(context);
                          }
                        } else {
                          // Doğrudan bu pencerede satın alma işlemi başlat
                          await _processPurchase(
                            tier,
                            title,
                            tier == SiberTier.student ? 'student' : 'premium',
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
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 2)),
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
                  Icon(Icons.workspace_premium, color: Theme.of(context).colorScheme.primary, size: 32),
                  const SizedBox(width: 10),
                  const Text('ÖZSES PLANLARI', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
                      title: 'ÜCRETSİZ',
                      price: '0 ₺ / Ay',
                      tier: SiberTier.free,
                      accentColor: Colors.blueGrey,
                      isCurrent: currentTier == SiberTier.free,
                      features: [
                        _buildFeatureRow('Sınırsız Dinleme', true),
                        _buildFeatureRow('Reklamsız Deneyim', false),
                        _buildFeatureRow('Arşive Ekleme (5/Gün)', true),
                        _buildFeatureRow('Reklamla Ekstra Hak (+2)', true),
                        _buildFeatureRow('AI Listeleme (1/Gün)', true),
                        _buildFeatureRow('İstatistik (Yılda 2)', true),
                        _buildFeatureRow('Atmosferik Hava Mixi', false),
                        _buildFeatureRow('Metamorfoz Stüdyosu', false),
                      ],
                    ),
                    // STUDENT TIER
                    _buildPlanCard(
                      title: 'ÖĞRENCİ PLANI',
                      price: '54.99 ₺ / Ay',
                      tier: SiberTier.student,
                      accentColor: Colors.cyanAccent,
                      isCurrent: currentTier == SiberTier.student,
                      features: [
                        _buildFeatureRow('Sınırsız Dinleme', true),
                        _buildFeatureRow('Reklamsız Deneyim', true, highlight: true),
                        _buildFeatureRow('Arşive Ekleme (15/Gün)', true, highlight: true),
                        _buildFeatureRow('AI Listeleme (5/Gün)', true),
                        _buildFeatureRow('İstatistik (2 Ayda 1)', true),
                        _buildFeatureRow('Atmosferik Hava Mixi Açık', true, highlight: true),
                        _buildFeatureRow('Metamorfoz Stüdyosu', false),
                      ],
                    ),
                    // PREMIUM TIER
                    _buildPlanCard(
                      title: 'IMPERIUM PREMIUM',
                      price: '89.99 ₺ / Ay',
                      tier: SiberTier.premium,
                      accentColor: Colors.amber,
                      isCurrent: currentTier == SiberTier.premium,
                      features: [
                        _buildFeatureRow('Sınırsız Dinleme', true),
                        _buildFeatureRow('Sıfır Reklam', true),
                        _buildFeatureRow('Limitsiz Şarkı Arşivleme', true, highlight: true),
                        _buildFeatureRow('Limitsiz AI Listeleme', true, highlight: true),
                        _buildFeatureRow('Limitsiz İstatistik Raporu', true),
                        _buildFeatureRow('Atmosferik Hava Mixi Açık', true, highlight: true),
                        _buildFeatureRow('Metamorfoz Stüdyosu Açık', true, highlight: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Satın Alımları Geri Yükle
              TextButton.icon(
                onPressed: () async {
                  _showLoadingDialog();
                  await _subManager.syncPurchases();
                  if (!context.mounted) return;
                  Navigator.pop(context); // Dialogu kapat
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Satın alımlarınız kontrol edildi ve senkronize edildi.'),
                      backgroundColor: widget.themeColor,
                    ),
                  );
                  if (mounted) setState(() {});
                },
                icon: Icon(Icons.restore, color: widget.themeColor, size: 16),
                label: Text('Satın Alımları Geri Yükle',
                    style: TextStyle(
                        color: widget.themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              // Yasal Bilgilendirme & EULA Linkleri
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => showLegalDocsModal(context,
                          themeColor: widget.themeColor, initialTab: 0),
                      child: const Text('Kullanım Koşulları',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              decoration: TextDecoration.underline)),
                    ),
                    const Text(' • ',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                    TextButton(
                      onPressed: () => showLegalDocsModal(context,
                          themeColor: widget.themeColor, initialTab: 1),
                      child: const Text('Gizlilik Politikası',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
