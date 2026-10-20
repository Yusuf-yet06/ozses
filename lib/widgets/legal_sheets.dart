import 'package:flutter/material.dart';

void showLegalDocsModal(BuildContext context, {Color? themeColor, int initialTab = 0}) {
  final accentColor = themeColor ?? Colors.cyanAccent;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DefaultTabController(
        length: 2,
        initialIndex: initialTab,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 15),
              TabBar(
                indicatorColor: accentColor,
                labelColor: accentColor,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'Kullanım Koşulları (EULA)'),
                  Tab(text: 'Gizlilik Politikası'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTermsOfService(accentColor),
                    _buildPrivacyPolicy(accentColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildTermsOfService(Color accentColor) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ÖZSES - KULLANIM KOŞULLARI (EULA)', style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _paragraph('Uygulamayı kullanarak aşağıdaki şartları kabul etmiş sayılırsınız:'),
        _subtitle('1. Hizmetin Kapsamı', accentColor),
        _paragraph('ÖZSES, herkese açık ses ve video platformlarındaki içerikleri otonom olarak arayan ve oynatan bir istemcidir. Uygulama, sunucularında herhangi bir müzik veya medya dosyası barındırmaz. Telif hakları tamamen ilgili eser sahiplerine aittir.'),
        _subtitle('2. Kullanıcı Yükümlülükleri', accentColor),
        _paragraph('Kullanıcılar, uygulamayı yasadışı amaçlarla kullanamaz. Çevrimdışı önbelleğe alınan (cache) içerikler tamamen kullanıcının cihazında geçici olarak tutulur ve ticari bir amaçla paylaşılamaz.'),
        _subtitle('3. Otomatik Yenilenen Abonelikler (Premium Planlar)', accentColor),
        _paragraph('Uygulama içi satın alımlar (Öğrenci, Premium vb.) aracılığıyla abonelik başlatabilirsiniz. Abonelikler, mevcut dönemin bitiminden en az 24 saat önce iptal edilmediği sürece otomatik olarak yenilenir. Yenileme ücreti, mevcut dönemin bitiminden önceki 24 saat içinde Apple ID veya Google Hesabınızdan tahsil edilir. Aboneliğinizi cihazınızın mağaza ayarlarından istediğiniz zaman iptal edebilir veya yönetebilirsiniz.'),
        _subtitle('4. Sorumluluk Reddi', accentColor),
        _paragraph('Geliştirici, uygulamanın kesintisiz veya tamamen hatasız çalışacağını garanti etmez. Üçüncü taraf açık kaynak sunucuların hizmet vermeyi durdurmasından veya yapısal değişikliklerinden kaynaklı kesintilerden sorumlu tutulamaz.'),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'ÖZSES İstemci Mimarisi — Sürüm v7.0.0 (Imperium)',
            style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}

Widget _buildPrivacyPolicy(Color accentColor) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ÖZSES - GİZLİLİK POLİTİKASI', style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _paragraph('ÖZSES olarak gizliliğinize büyük önem veriyoruz. Hangi verileri nasıl işlediğimize dair detaylar aşağıdadır:'),
        _subtitle('1. Toplanan Veriler', accentColor),
        _paragraph('Hesap oluşturduğunuzda (Google, Apple veya E-posta) adınız, e-posta adresiniz ve profil fotoğrafınız uygulamanın veritabanına kaydedilir. Müzik deneyiminizi kişiselleştirmek için dinleme geçmişiniz ve özel çalma listeleriniz bulutta yedeklenir. Cihazınızın kaba konum verisi (sadece "Uygulamayı Kullanırken" izni verilirse), hava durumu ve Ses Aurası özelliklerini yansıtmak amacıyla anlık kullanılır ve sunucularımızda saklanmaz.'),
        _subtitle('2. Verilerin Kullanımı', accentColor),
        _paragraph('Toplanan profil ve dinleme verileri tamamen dinleme geçmişinizi ve "ÖZSES Wrapped" deneyiminizi oluşturmak, hesap senkronizasyonunu sağlamak ve yapay zeka müzik önerileri sunmak içindir.'),
        _subtitle('3. Üçüncü Taraf Paylaşımı', accentColor),
        _paragraph('Verileriniz Firebase (veritabanı & kimlik doğrulama), RevenueCat (abonelik yönetimi) ve AdMob (reklam gösterimi) gibi güvenli hizmet sağlayıcılar dışında hiçbir üçüncü şahıs kurum veya kuruluşla satılmaz ve paylaşılmaz.'),
        _subtitle('4. Hesabı ve Verileri Silme Hakkı', accentColor),
        _paragraph('Kullanıcılar diledikleri an "Profil > Hesap Bağını Kopar > Hesabımı ve Verilerimi Sil" yolunu izleyerek bulut arşivini, çalma listelerini, profilini ve oturum kimliklerini tamamen ve geri döndürülemez bir şekilde silebilir.'),
        _subtitle('5. İletişim', accentColor),
        _paragraph('Gizlilik politikamız ile ilgili her türlü soru için destek ekibimize ulaşabilirsiniz.'),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'ÖZSES İstemci Mimarisi — Sürüm v7.0.0 (Imperium)',
            style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}

Widget _subtitle(String text, Color color) {
  return Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 5),
    child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
  );
}

Widget _paragraph(String text) {
  return Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5));
}
