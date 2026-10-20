import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/history_service.dart';
import '../../../services/siber_theme_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/rank_manager.dart';
import '../../../services/subscription_manager.dart';
import '../../siber_wrapped_screen.dart';
import '../../../widgets/siber_premium_sheet.dart';
import '../../../widgets/legal_sheets.dart'; // 🎯 MAĞAZA UYUMLULUK

class CompactDesktopProfile extends StatefulWidget {
  final VoidCallback onClose;

  const CompactDesktopProfile({super.key, required this.onClose});

  @override
  State<CompactDesktopProfile> createState() => _CompactDesktopProfileState();
}

class _CompactDesktopProfileState extends State<CompactDesktopProfile> {
  String _username = 'Müziksever';
  String _rank = 'Yeni Dinleyici';
  String _avatarUrl = 'https://robohash.org/siber_ajan.png?set=set3';
  int _totalListenHours = 0;
  double _rankProgress = 0.0;
  bool _isLoading = true;
  Color _auraColor = Colors.cyanAccent;
  bool _isAccountLinked = false; // 🎯 MAĞAZA UYUMLULUK

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('siber_username') ?? 'Müziksever';
    final avatar = prefs.getString('siber_avatar_url');
    final isLinked = prefs.getBool('siber_is_linked') ?? false; // 🎯 MAĞAZA UYUMLULUK
    
    final historyList = await HistoryService.getHistory();
    int totalSeconds = 0;
    for (var item in historyList) {
      totalSeconds += item.totalListenSeconds;
    }
    int totalHours = totalSeconds ~/ 3600;

    String rank = 'Yeni Dinleyici';
    double rankProgress = 0.0;
    
    final tiers = RankManager.allTiers;
    for (int i = 0; i < tiers.length; i++) {
      if (totalHours >= tiers[i].hours) {
        rank = tiers[i].name;
        if (i < tiers.length - 1) {
          int currentTierHours = tiers[i].hours;
          int nextTierHours = tiers[i + 1].hours;
          int hoursInCurrentTier = totalHours - currentTierHours;
          int tierSpan = nextTierHours - currentTierHours;
          rankProgress = (hoursInCurrentTier / tierSpan).clamp(0.0, 1.0);
        } else {
          rankProgress = 1.0;
        }
      }
    }

    if (mounted) {
      setState(() {
        _username = name;
        _rank = rank;
        _totalListenHours = totalHours;
        _rankProgress = rankProgress;
        if (avatar != null && avatar.isNotEmpty) {
          _avatarUrl = avatar;
        } else {
          _avatarUrl = "https://robohash.org/${name.replaceAll(' ', '_')}?set=set3";
        }
        _isLoading = false;
        _isAccountLinked = isLinked;
      });
    }
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {bool isPassword = false, Color? customColor}) {
    final color = customColor ?? _auraColor;
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: color),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color),
        ),
        filled: true,
        fillColor: Colors.black45,
      ),
    );
  }

  void _unlinkAccount() async {
    await AuthService().signOut();
    _loadProfileData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Hesap siber ağdan koparıldı.'),
        backgroundColor: Colors.orangeAccent,
      ));
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.redAccent),
              SizedBox(width: 8),
              Expanded(child: Text('Hesabımı Sil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          content: const Text(
            'Bu işlem geri alınamaz. Bulut arşivinizdeki tüm şarkılar, oynatma listeleriniz, dinleme geçmişiniz ve profil verileriniz kalıcı olarak silinecektir.\n\nEmin misiniz?',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await AuthService().deleteAccount();
                  _loadProfileData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hesabınız ve verileriniz başarıyla silindi.'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (e.toString().contains('requires-recent-login')) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Güvenlik nedeniyle hesabı silmeden önce tekrar giriş yapmalısınız.'), backgroundColor: Colors.orangeAccent),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hesap silme başarısız: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                }
              },
              child: const Text('Kalıcı Olarak Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showLinkAccountDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final usernameController = TextEditingController();
    bool isLoginMode = true; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => setDialogState(() => isLoginMode = true),
                    child: Text('GİRİŞ YAP',
                        style: TextStyle(
                            color: isLoginMode ? _auraColor : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                  const Text('|',
                      style: TextStyle(color: Colors.white24, fontSize: 18)),
                  GestureDetector(
                    onTap: () => setDialogState(() => isLoginMode = false),
                    child: Text('KAYIT OL',
                        style: TextStyle(
                            color: !isLoginMode ? _auraColor : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Siber buluta bağlanmak için kimliğini doğrula.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (!isLoginMode) ...[
                      _buildTextField(
                          usernameController, 'Kullanıcı Adı', Icons.person),
                      const SizedBox(height: 10),
                    ],
                    _buildTextField(emailController, 'E-Posta', Icons.email),
                    const SizedBox(height: 10),
                    _buildTextField(
                        passwordController, 'Siber Şifre', Icons.lock,
                        isPassword: true),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _auraColor.withValues(alpha: 0.8),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (emailController.text.isNotEmpty &&
                              passwordController.text.isNotEmpty &&
                              (isLoginMode ||
                                  usernameController.text.isNotEmpty)) {
                            final email = emailController.text.trim();
                            final pass = passwordController.text;
                            final username = usernameController.text.trim();

                            try {
                              if (isLoginMode) {
                                await AuthService().signInWithEmailAndPassword(email, pass);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _loadProfileData(); 
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: const Text('Siber Ağa Başarıyla Bağlanıldı!'),
                                    backgroundColor: _auraColor,
                                  ));
                                }
                              } else {
                                await AuthService().registerWithEmailAndPassword(username, email, pass);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: const Text('Kayıt tamam! E-postana bir doğrulama linki gönderdik. Onayladıktan sonra giriş yapabilirsin!'),
                                    backgroundColor: _auraColor,
                                    duration: const Duration(seconds: 4),
                                  ));
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Siber Hata Oluştu. E-posta veya şifre hatalı olabilir.'),
                                  backgroundColor: Colors.redAccent,
                                ));
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Lütfen siber mühür için tüm alanları doldur!'),
                              backgroundColor: Colors.redAccent,
                            ));
                          }
                        },
                        child: Text(
                            isLoginMode ? 'GİRİŞ YAP' : 'KAYIT OL & MÜHÜRLE',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('VEYA', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Google Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
                        label: const Text('Google ile Bağlan', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          try {
                            final success = await AuthService().signInWithGoogle();
                            if (success) {
                              _loadProfileData();
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Siber ağa başarıyla bağlanıldı (Google).'), backgroundColor: Colors.green));
                              }
                            }
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Bağlantı hatası: Google Play Hizmetleri.'), backgroundColor: Colors.red));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRankDetailsDialog() {
    final rankIcons = {
      SiberRank.yeniDinleyici: Icons.headphones_rounded,
      SiberRank.cirakTaktisyen: Icons.military_tech_rounded,
      SiberRank.muziksever: Icons.radar_rounded,
      SiberRank.ritimTutkunu: Icons.graphic_eq_rounded,
      SiberRank.melodiUstasi: Icons.auto_awesome_rounded,
      SiberRank.sesGurmesi: Icons.workspace_premium_rounded,
      SiberRank.ozsesEfsanesi: Icons.diamond_rounded,
    };

    final rankColors = {
      SiberRank.yeniDinleyici: Colors.white54,
      SiberRank.cirakTaktisyen: Colors.greenAccent,
      SiberRank.muziksever: Colors.blueAccent,
      SiberRank.ritimTutkunu: Colors.purpleAccent,
      SiberRank.melodiUstasi: Colors.orangeAccent,
      SiberRank.sesGurmesi: Colors.redAccent,
      SiberRank.ozsesEfsanesi: Colors.amber,
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 600,
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                    color: const Color(0xFF0F0F1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(
                        color: SiberThemeService.instance.currentThemeColor.value.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.military_tech_rounded, color: Colors.amber, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'RÜTBE VE ÖDÜL SİSTEMİ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Dinledikçe rütbe atla; geçici reklamsız dinleme süreleri, ek indirme ve AI liste haklarını hesabına ücretsiz kat!',
                        style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Colors.cyanAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Şu anki dinleme süren: $_totalListenHours Saat | Rütben: $_rank',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: RankManager.allTiers.length,
                        itemBuilder: (context, index) {
                          final tier = RankManager.allTiers[index];
                          bool isAchieved = _totalListenHours >= tier.hours;
                          bool isCurrent = _rank == tier.name;
                          Color activeColor = rankColors[tier.rank] ?? Colors.white54;
                          IconData iconData = rankIcons[tier.rank] ?? Icons.headphones_rounded;

                          return Opacity(
                            opacity: isAchieved ? 1.0 : 0.45,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? activeColor.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isCurrent
                                      ? activeColor.withValues(alpha: 0.6)
                                      : (isAchieved ? Colors.white24 : Colors.white10),
                                  width: isCurrent ? 2.0 : 1.0,
                                ),
                                boxShadow: isCurrent
                                    ? [
                                        BoxShadow(
                                            color: activeColor.withValues(alpha: 0.25),
                                            blurRadius: 10)
                                      ]
                                : [],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isAchieved
                                          ? activeColor.withValues(alpha: 0.2)
                                          : Colors.black38,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isAchieved ? activeColor.withValues(alpha: 0.5) : Colors.white12,
                                      ),
                                    ),
                                    child: Icon(
                                      isAchieved ? iconData : Icons.lock_outline_rounded,
                                      color: isAchieved ? activeColor : Colors.white38,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              tier.name,
                                              style: TextStyle(
                                                color: isAchieved
                                                    ? Colors.white
                                                    : Colors.white54,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (isCurrent) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: activeColor.withValues(alpha: 0.25),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: activeColor, width: 1),
                                                ),
                                                child: Text(
                                                  'MEVCUT RÜTBEN',
                                                  style: TextStyle(color: activeColor, fontSize: 9, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tier.hours == 0
                                              ? "Gereksinim: Başlangıç Seviyesi"
                                              : "Gereksinim: ${tier.hours} Saat Dinleme",
                                          style: TextStyle(
                                            color: isAchieved
                                                ? Colors.white70
                                                : Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline_rounded,
                                              size: 15,
                                              color: isAchieved ? activeColor : Colors.white38,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                tier.perk,
                                                style: TextStyle(
                                                  color: isAchieved ? activeColor : Colors.white60,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (tier.bonus.isNotEmpty) ...[
                                          const SizedBox(height: 5),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.stars_rounded,
                                                size: 14,
                                                color: isAchieved ? Colors.amberAccent : Colors.white30,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  tier.bonus,
                                                  style: TextStyle(
                                                    color: isAchieved
                                                        ? Colors.amberAccent.withValues(alpha: 0.9)
                                                        : Colors.white38,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        // 🎯 GEÇİCİ REKLAMSIZ DİNLEME AKTİVASYON BUTONU
                                        if (tier.adFreeMinutes > 0) ...[
                                          const SizedBox(height: 8),
                                          FutureBuilder<bool>(
                                            future: SubscriptionManager().isRankAdFreeClaimed(tier.rank),
                                            builder: (context, snapshot) {
                                              final isClaimed = snapshot.data ?? false;
                                              final isCurrentlyAdFree = SubscriptionManager().isAdFree;
                                              final remainingText = SubscriptionManager().remainingAdFreeFormatted;

                                              if (SubscriptionManager().currentTier != SiberTier.free) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 13),
                                                      SizedBox(width: 4),
                                                      Text('Abonelikle Sınırsız Reklamsız', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                );
                                              }

                                              if (isClaimed) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isCurrentlyAdFree ? Colors.green.withValues(alpha: 0.15) : Colors.white10,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: isCurrentlyAdFree ? Colors.greenAccent : Colors.white24),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(isCurrentlyAdFree ? Icons.timer_outlined : Icons.check_circle_outline, color: isCurrentlyAdFree ? Colors.greenAccent : Colors.white54, size: 13),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isCurrentlyAdFree ? 'REKLAMSIZ MOD AKTİF ($remainingText)' : 'BU HEDİYE KULLANILDI',
                                                        style: TextStyle(color: isCurrentlyAdFree ? Colors.greenAccent : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }

                                              if (isAchieved) {
                                                return InkWell(
                                                  onTap: () async {
                                                    final success = await SubscriptionManager().claimAdFreePass(tier.rank);
                                                    if (success && context.mounted) {
                                                      setDialogState(() {});
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('🎉 ${tier.name} hediyesi: ${tier.adFreeMinutes} Dakika Reklamsız Dinleme Başlatıldı!'),
                                                          backgroundColor: Colors.green,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.indigoAccent]),
                                                      borderRadius: BorderRadius.circular(8),
                                                      boxShadow: [
                                                        BoxShadow(color: Colors.deepPurpleAccent.withValues(alpha: 0.4), blurRadius: 6),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.flash_on_rounded, color: Colors.amberAccent, size: 14),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'REKLAMSIZ MODU BAŞLAT (+${tier.adFreeMinutes} Dk)',
                                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }

                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                        color: isAchieved
                                            ? Colors.green.withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isAchieved
                                              ? Colors.green.withValues(alpha: 0.5)
                                              : Colors.grey.withValues(alpha: 0.3),
                                        )),
                                    child: Text(
                                      isAchieved ? 'AÇIK' : 'KİLİTLİ',
                                      style: TextStyle(
                                        color: isAchieved ? Colors.greenAccent : Colors.grey,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('KAPAT', style: TextStyle(color: Colors.white54)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProfileEditDialog() {
    final List<String> availableGenres = [
      'Lo-Fi', 'Rap', 'Rock', 'Elektronik', 'Klasik', 'Jazz', 'Pop', 'Ambient', 'Hip-Hop', 'Akustik', 'R&B', 'Metal'
    ];
    final List<String> availableArtists = [
      'Victus V7', 'The Weeknd', 'Daft Punk', 'Eminem', 'Arctic Monkeys', 'Hans Zimmer', 'Kendrick Lamar', 'Tame Impala', 'Drake', 'J. Cole'
    ];
    
    List<String> selectedGenres = [];
    List<String> selectedArtists = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 500,
                height: 600,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: SiberThemeService.instance.currentThemeColor.value.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'ŞAHSİ KEŞFET PROFİLİ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Text(
                      'Otonom AI sisteminin sana daha iyi listeler yapabilmesi için\nmüzik türü ve sanatçı tercihlerini seç.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const Text('Favori Müzik Türleri', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableGenres.map((genre) {
                              final isSelected = selectedGenres.contains(genre);
                              return InkWell(
                                onTap: () {
                                  setStateDialog(() {
                                    if (isSelected) {
                                      selectedGenres.remove(genre);
                                    } else {
                                      selectedGenres.add(genre);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? SiberThemeService.instance.currentThemeColor.value.withValues(alpha: 0.2) : Colors.white10,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? SiberThemeService.instance.currentThemeColor.value : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(genre, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 13)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 30),
                          const Text('Favori Sanatçılar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableArtists.map((artist) {
                              final isSelected = selectedArtists.contains(artist);
                              return InkWell(
                                onTap: () {
                                  setStateDialog(() {
                                    if (isSelected) {
                                      selectedArtists.remove(artist);
                                    } else {
                                      selectedArtists.add(artist);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? SiberThemeService.instance.currentThemeColor.value.withValues(alpha: 0.2) : Colors.white10,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? SiberThemeService.instance.currentThemeColor.value : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(artist, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 13)),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İPTAL', style: TextStyle(color: Colors.white54)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SiberThemeService.instance.currentThemeColor.value,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setStringList('favorite_genres', selectedGenres);
                              await prefs.setStringList('favorite_artists', selectedArtists);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tercihler kaydedildi! AI Modülü güncellendi.'), backgroundColor: Colors.green),
                              );
                            },
                            child: const Text('MÜHÜRLE', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPlaceholderDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: SiberThemeService.instance.currentThemeColor.value.withValues(alpha: 0.5), width: 1.5),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(content, style: const TextStyle(color: Colors.white70)),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              onPressed: () => Navigator.pop(context),
              child: Text('KAPAT', style: TextStyle(color: SiberThemeService.instance.currentThemeColor.value, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: SiberThemeService.instance.currentThemeColor,
      builder: (context, themeColor, child) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Container(
          width: 250,
          color: const Color(0xFF0F111A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              // Üst Kısım: Geri Butonu ve Başlık
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                      onPressed: widget.onClose,
                    ),
                    const Text(
                      'Profil',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Avatar ve İsim
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: themeColor, width: 2),
                        image: DecorationImage(
                          image: NetworkImage(_avatarUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _username,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _rank,
                      style: TextStyle(color: themeColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // İstatistik Kartı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dinleme İstatistiği',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_totalListenHours Saat',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.access_time_rounded, color: themeColor, size: 24),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _rankProgress,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Özses Özetim ve Hesap
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildMenuButton(
                      icon: Icons.edit_note_rounded,
                      title: 'Profili Düzenle',
                      color: Colors.white,
                      onTap: () {
                        _showProfileEditDialog();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      icon: Icons.military_tech_rounded,
                      title: 'Rütbe ve Ödüller',
                      color: Colors.amberAccent,
                      onTap: () {
                        _showRankDetailsDialog();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      icon: Icons.query_stats_rounded,
                      title: 'Şahsi Müzik Analizi',
                      color: Colors.pinkAccent,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SiberWrappedScreen()));
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      icon: Icons.share_rounded,
                      title: 'Özetimi Paylaş',
                      color: Colors.lightGreenAccent,
                      onTap: () {
                        _showPlaceholderDialog('Özetimi Paylaş', 'Müzik istihbarat karneni ve rütbeni sosyal medyada veya doğrudan bağlantı olarak paylaş.');
                      },
                    ),
                    const SizedBox(height: 12),
                    if (!_isAccountLinked)
                      _buildMenuButton(
                        icon: Icons.link_rounded,
                        title: 'Hesap Bağla',
                        color: Colors.cyanAccent,
                        onTap: _showLinkAccountDialog,
                      )
                    else ...[
                      _buildMenuButton(
                        icon: Icons.link_off_rounded,
                        title: 'Hesabın Bağını Kopar',
                        color: Colors.orangeAccent,
                        onTap: _unlinkAccount,
                      ),
                      const SizedBox(height: 12),
                      _buildMenuButton(
                        icon: Icons.delete_forever_rounded,
                        title: 'Hesabımı ve Verilerimi Sil',
                        color: Colors.redAccent,
                        onTap: _deleteAccount,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      icon: Icons.policy_rounded,
                      title: 'Gizlilik ve Kullanım Koşulları',
                      color: Colors.blueAccent,
                      onTap: () => showLegalDocsModal(context, themeColor: themeColor),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Özses Premium',
                      color: Colors.orangeAccent,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SiberPremiumSheet(themeColor: themeColor),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuButton({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
