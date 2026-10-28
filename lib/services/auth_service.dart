import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in_dartio/google_sign_in_dartio.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // 🍎 SİBER KALKAN: Apple Giriş Motoru
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloud_library_service.dart'; // Bulut veritabanı

import 'dart:async';

class AuthService {
  // 🎯 SİBER HAMLE: Singleton pattern ile her yerden tekil erişim
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  // 🛡️ SİBER KALKAN: Masaüstü kayıt tamamlanana kadar kilitli kapı
  final Completer<void> _desktopReady = Completer<void>();

  AuthService._internal() {
    _initDesktop();
  }

  void _initDesktop() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      // 🎯 SİBER HAMLE: Masaüstü (Windows) Google Giriş Motoru
      try {
        await GoogleSignInDart.register(
          clientId: '533526268311-lg797g77dbmgjjhhdvpjruhvscfqfoob.apps.googleusercontent.com',
        );
        print('✅ Windows Google Giriş Motoru hazır.');
      } catch (e) {
        print('⚠️ Windows Google Kayıt Hatası: $e');
      }
    }
    if (!_desktopReady.isCompleted) _desktopReady.complete();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 🎯 SİBER HAMLE: Web/Masaüstü için özel Web Client ID, Android/iOS için serverClientId
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '533526268311-lg797g77dbmgjjhhdvpjruhvscfqfoob.apps.googleusercontent.com',
    clientId: (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) 
        ? null 
        : '533526268311-lg797g77dbmgjjhhdvpjruhvscfqfoob.apps.googleusercontent.com', 
  );

  /// Otonom Google Giriş Motoru (Gerçek Firebase Auth & Cloud Firestore Entegrasyonu)
  Future<bool> signInWithGoogle() async {
    // 🛡️ Masaüstü kayıt tamamlanana kadar bekle
    await _desktopReady.future;
    try {
      // 🛡️ Önbellekteki eski oturumu sıfırla ki hesap seçici temiz açılsın
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // 1. Google ile oturum açma akışını başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Kullanıcı giriş işlemini iptal etti
        return false;
      }

      // 2. Google kimlik belirteçlerini (token) al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. GERÇEK Firebase Kimlik Doğrulaması (Asla sahte/test moduna düşürülmez)
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Firebase oturumu başlatılamadı.');
      }

      final String name = user.displayName ?? googleUser.displayName ?? 'Müziksever';
      final String email = user.email ?? googleUser.email;
      final String? photoUrl = user.photoURL ?? googleUser.photoUrl;

      // 4. Firestore Kullanıcı Profilini Mühürle
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'displayName': name,
        'photoUrl': photoUrl ?? '',
        'provider': 'google.com',
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 5. Yerel Kimlik Hafızasını Güncelle
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('siber_is_linked', true);
      await prefs.setString('siber_username', name);
      await prefs.setString('siber_email', email);
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await prefs.setString('siber_avatar_url', photoUrl);
      }
      await prefs.setString('siber_uid', user.uid);

      // 6. ⚡ Gerçek Mail & Bulut Hafızasını Otomatik Eşitle (Kütüphane, Listeler, Kanallar)
      try {
        await CloudLibraryService().fullSync();
      } catch (e) {
        print('⚠️ İlk bulut senkronizasyon uyarısı: $e');
      }

      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Siber Hata (FirebaseAuthException): ${e.code} - ${e.message}');
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('Bu e-posta adresiyle ilişkili farklı bir oturum yöntemi mevcut.');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Google kimlik belirteci geçersiz veya süresi dolmuş.');
      } else if (e.code == 'user-disabled') {
        throw Exception('Bu kullanıcı hesabı askıya alınmış.');
      } else if (e.code == 'network-request-failed') {
        throw Exception('Ağ Hatası: Firebase sunucularına ulaşılamadı. İnternet bağlantınızı kontrol edin.');
      }
      throw Exception('Firebase Kimlik Hatası: [${e.code}] ${e.message ?? 'Giriş yapılamadı.'}');
    } catch (e) {
      print('❌ Siber Hata (Google Girişi): $e');
      final err = e.toString();
      if (err.contains('10') || err.contains('DEVELOPER_ERROR')) {
        throw Exception(
          'Google Güvenlik Reddi (SHA-1 / SHA-256 Uyuşmazlığı): Uygulamanın imza parmak izi Firebase Konsolu ile eşleşmedi. Firebase Konsoluna SHA-1 / SHA-256 anahtarlarının eklenmesi gerekir.',
        );
      } else if (err.contains('12500')) {
        throw Exception(
          'Google Yapılandırma Hatası (12500): Google Cloud Console üzerinde OAuth Onay Ekranı veya Destek E-postası eksik yapılandırılmış.',
        );
      } else if (err.contains('access_denied') || err.contains('403')) {
        throw Exception(
          'Erişim Engellendi (403): Google OAuth projesi "Test" modunda. Bu e-postanın Google Cloud Test Kullanıcıları listesine eklenmesi veya uygulamanın yayına alınması gerekir.',
        );
      } else if (err.contains('network_error') || err.contains('7')) {
        throw Exception(
          'Ağ Bağlantı Hatası: Google sunucularına ulaşılamadı. İnternet bağlantınızı kontrol edin.',
        );
      }
      rethrow;
    }
  }

  /// 🍎 Otonom Apple Giriş Motoru (iOS Cihazlar İçin Zorunlu Mühür)
  Future<User?> signInWithApple() async {
    try {
      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // 🛡️ SİBER KALKAN: Apple kimliklerini Firebase OAuth'a çevir
      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final AuthCredential credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('siber_is_linked', true);
        
        // 🎯 Apple gizliliği gereği isim sadece İLK kayıtta verilir!
        String userName = user.displayName ?? 'Müziksever';
        if (appleCredential.givenName != null) {
          userName = '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim();
        }
        
        await prefs.setString('siber_username', userName);
        await prefs.setString('siber_email', user.email ?? '');
        if (user.photoURL != null) {
          await prefs.setString('siber_avatar_url', user.photoURL!);
        }
      }

      return user;
    } catch (e) {
      print('❌ Hata (Apple Girişi): $e');
      return null;
    }
  }

  /// Otonom E-Posta & Şifre Kayıt Motoru (Tam Entegre)
  Future<User?> registerWithEmailAndPassword(String username, String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // Kullanıcı adını Firebase profiline kaydet
        await user.updateDisplayName(username);
        
        // E-posta doğrulama linki gönder
        if (!user.emailVerified) {
          await user.sendEmailVerification();
        }

        await user.reload(); // Değişikliklerin anında yansıması için
        
        // Güvenlik: E-posta doğrulanana kadar oturumu kapat
        await _auth.signOut();
      }

      return user;
    } catch (e) {
      print('Hata (Kayıt): $e');
      rethrow;
    }
  }

  /// Otonom E-Posta & Şifre Giriş Motoru
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;

      if (user != null) {
        if (!user.emailVerified) {
          await _auth.signOut();
          throw Exception('email_not_verified');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('siber_is_linked', true);
        await prefs.setString('siber_username', user.displayName ?? 'Müziksever');
        await prefs.setString('siber_email', user.email ?? '');
      }

      return user;
    } catch (e) {
      print('Siber Hata (Giriş): $e');
      rethrow;
    }
  }

  /// Otonom Hesap Silme Motoru (Mağaza Uyumluluk)
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      try {
        // 1. Kullanıcının Bulut Arşivini Sil
        final libDocs = await firestore.collection('users').doc(uid).collection('library').get();
        final batch = firestore.batch();
        for (var doc in libDocs.docs) {
          batch.delete(doc.reference);
        }

        // 2. Kullanıcının Oynatma Listelerini Sil
        final plDocs = await firestore.collection('users').doc(uid).collection('playlists').get();
        for (var doc in plDocs.docs) {
          batch.delete(doc.reference);
        }

        // 3. Kullanıcı Ana Dokümanını Sil
        batch.delete(firestore.collection('users').doc(uid));

        await batch.commit();
        print('✅ Siber Veriler Buluttan Temizlendi.');
      } catch (e) {
        print('⚠️ Bulut Veri Silme Hatası: $e');
      }

      // 4. Firebase Auth Hesabını Sil
      try {
        await user.delete();
        print('✅ Siber Firebase Hesabı Silindi.');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw Exception('requires-recent-login');
        } else {
          rethrow;
        }
      }
    }

    // 5. Yerel Kimlikleri Temizle
    await _googleSignIn.signOut();
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('siber_is_linked', false);
    await prefs.remove('siber_username');
    await prefs.remove('siber_email');
    await prefs.remove('siber_avatar_url');
    await prefs.remove('siber_instagram');
    await prefs.remove('siber_twitter');
  }

  /// Otonom Çıkış Motoru (Güvenli Koparma)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      // Yerel mühürleri temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('siber_is_linked', false);
      await prefs.remove('siber_username');
      await prefs.remove('siber_email');
      // avatarı bilerek silmiyoruz, default robohash'a düşmesi için profile_screen'de yöneteceğiz
    } catch (e) {
      print('❌ Siber Hata (Çıkış): $e');
    }
  }

  /// O anki aktif kullanıcıyı getirir
  User? get currentUser => _auth.currentUser;
}
