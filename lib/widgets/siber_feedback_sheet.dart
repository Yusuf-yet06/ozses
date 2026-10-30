import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ÖZSES V7 IMPERIUM - Merkezi Geri Bildirim & Hata Bildirim Çekmecesi
/// Hem Ana Ekran (Sol Menü) hem de Profil Ekranı üzerinden çağrılabilir.
/// Gönderilen bildirimleri 3 katmanlı olarak:
///  1) Firebase Firestore (`feedbacks` koleksiyonu)
///  2) VPS n8n Otomasyon Köprüsü (`/webhook/OZSES_V7-IMPERIUM` -> Telegram + Veritabanı)
///  3) VPS Doğrudan SQLite & JSON API (`/api/feedback?apikey=siber_secret_key_v7`)
/// üzerine kaydeder.
void showSiberFeedbackSheet(BuildContext context, {required Color themeColor}) {
  final TextEditingController feedbackCtrl = TextEditingController();
  bool isSending = false;
  String selectedCategory = '🐞 Hata Bildirimi';

  final List<String> categories = [
    '🐞 Hata Bildirimi',
    '💡 Özellik Önerisi',
    '🎵 Şarkı / Sanatçı İsteği',
    '💬 Genel Görüş',
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0D14).withValues(alpha: 0.97),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: themeColor.withValues(alpha: 0.65),
                    width: 2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.22),
                    blurRadius: 28,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeColor.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Icon(
                          Icons.support_agent_rounded,
                          color: themeColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GERİ BİLDİRİM & DESTEK',
                              style: TextStyle(
                                color: themeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Hata, öneri veya şarkı isteğini doğrudan ekibimize ilet',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Kategori Seçim Hapları
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, idx) {
                        final cat = categories[idx];
                        final isSelected = cat == selectedCategory;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? themeColor.withValues(alpha: 0.22)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? themeColor
                                    : Colors.white.withValues(alpha: 0.12),
                                width: isSelected ? 1.3 : 1.0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: feedbackCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                          'Karşılaştığın hatayı, önerini veya isteğini buraya yaz...',
                      hintStyle: const TextStyle(
                        color: Colors.white30,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: themeColor.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: themeColor.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: themeColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSending ? Colors.grey[800] : themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                      ),
                      onPressed: isSending
                          ? null
                          : () async {
                              final text = feedbackCtrl.text.trim();
                              if (text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Lütfen bir mesaj yazın.'),
                                    backgroundColor: Colors.orangeAccent,
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => isSending = true);

                              final nowStr = DateTime.now()
                                  .toString()
                                  .substring(0, 16);
                              String userIdentity = 'Misafir';
                              String uid = '';
                              try {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final savedName =
                                    prefs.getString('siber_username') ?? '';
                                final savedEmail =
                                    prefs.getString('siber_email') ?? '';
                                final authUser =
                                    FirebaseAuth.instance.currentUser;
                                uid = authUser?.uid ?? '';
                                final email = authUser?.email ??
                                    (savedEmail != 'Bağlı hesap yok'
                                        ? savedEmail
                                        : '');
                                if (savedName.isNotEmpty &&
                                    email.isNotEmpty) {
                                  userIdentity = '$savedName ($email)';
                                } else if (email.isNotEmpty) {
                                  userIdentity = email;
                                } else if (savedName.isNotEmpty) {
                                  userIdentity = savedName;
                                }
                              } catch (_) {}

                              final payloadMap = {
                                'tarih': nowStr,
                                'kategori': selectedCategory,
                                'kullanici': userIdentity,
                                'email': userIdentity,
                                'mesaj': text,
                                'cihaz': 'Android OZSES Imperium',
                                'surum': '1.0.21+24',
                                'uid': uid,
                              };
                              final payloadJson = jsonEncode(payloadMap);
                              final headers = {
                                'Content-Type':
                                    'application/json; charset=utf-8',
                              };

                              bool delivered = false;

                              // 1. Katman: Doğrudan VPS SQLite & JSON API
                              try {
                                final vpsRes = await http
                                    .post(
                                      Uri.parse(
                                        'https://167-172-190-129.nip.io/api/feedback?apikey=siber_secret_key_v7',
                                      ),
                                      headers: headers,
                                      body: payloadJson,
                                    )
                                    .timeout(const Duration(seconds: 5));
                                if (vpsRes.statusCode >= 200 &&
                                    vpsRes.statusCode < 300) {
                                  delivered = true;
                                }
                              } catch (e) {
                                debugPrint('⚠️ [VPS Feedback API Hatası]: $e');
                              }

                              // 2. Katman: n8n Webhook (Telegram Bildirimi + Otomasyon)
                              try {
                                final n8nRes = await http
                                    .post(
                                      Uri.parse(
                                        'https://167-172-190-129.nip.io/webhook/OZSES_V7-IMPERIUM',
                                      ),
                                      headers: headers,
                                      body: payloadJson,
                                    )
                                    .timeout(const Duration(seconds: 5));
                                if (n8nRes.statusCode >= 200 &&
                                    n8nRes.statusCode < 300) {
                                  delivered = true;
                                }
                              } catch (e) {
                                debugPrint('⚠️ [n8n Feedback Hatası]: $e');
                              }

                              // 3. Katman: Firebase Firestore
                              try {
                                await FirebaseFirestore.instance
                                    .collection('feedbacks')
                                    .add({
                                  ...payloadMap,
                                  'timestamp': FieldValue.serverTimestamp(),
                                }).timeout(const Duration(seconds: 4));
                                delivered = true;
                              } catch (fbErr) {
                                debugPrint(
                                    '⚠️ [Firebase Feedback Hatası]: $fbErr');
                              }

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          delivered
                                              ? Icons.check_circle_rounded
                                              : Icons.info_outline_rounded,
                                          color: themeColor,
                                        ),
                                        const SizedBox(width: 10),
                                        const Expanded(
                                          child: Text(
                                            'Geri bildiriminiz ekibimize iletildi. Teşekkürler!',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.92),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      child: isSending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'GERİ BİLDİRİMİ GÖNDER',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
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
