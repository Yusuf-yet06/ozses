import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in_dartio/google_sign_in_dartio.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // 🍎 SİBER KALKAN: Apple Giriş Motoru

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
  
  // 🎯 SİBER HAMLE: Web/Masaüstü için özel Web Client ID, iOS/Android için null (otomatik okur)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) 
        ? null 
        : '661550093863-ftcq2gpij6q2hg4bakigt92tqv1fvcu9.apps.googleusercontent.com', 
  );

  /// Otonom Google Giriş Motoru
  Future<User?> signInWithGoogle() async {
    // 🛡️ Masaüstü kayıt tamamlanana kadar bekle
    await _desktopReady.future;
    try {
      // 1. Google ile oturum açma akışını başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Kullanıcı giriş işlemini iptal etti
        return null;
      }

      // 2. Google üzerinden kimlik doğrulama detaylarını al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Firebase kimlik bilgilerini oluştur
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebase Auth ile giriş yap
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 🎯 SİBER KALKAN: Kullanıcı verilerini yerel hafızaya mühürle
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('siber_is_linked', true);
        await prefs.setString('siber_username', user.displayName ?? 'Siber Ajan');
        await prefs.setString('siber_email', user.email ?? '');
        if (user.photoURL != null) {
          await prefs.setString('siber_avatar_url', user.photoURL!);
        }
      }

      return user;
    } catch (e) {
      print('❌ Siber Hata (Google Girişi): $e');
      rethrow; // 🛡️ Hata detayını UI'a gönder
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
        String userName = user.displayName ?? 'Siber Ajan';
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
      print('❌ Siber Hata (Apple Girişi): $e');
      return null;
    }
  }

  /// Otonom E-Posta & Şifre Kayıt Motoru (Siber Beyin Olmadan Tam Entegre)
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
        await user.reload(); // Değişikliklerin anında yansıması için

        // Yerel hafızaya mühürle
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('siber_is_linked', true);
        await prefs.setString('siber_username', username);
        await prefs.setString('siber_email', user.email ?? '');
      }

      return user;
    } catch (e) {
      print('Siber Hata (Kayıt): $e');
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('siber_is_linked', true);
        await prefs.setString('siber_username', user.displayName ?? 'Siber Ajan');
        await prefs.setString('siber_email', user.email ?? '');
      }

      return user;
    } catch (e) {
      print('Siber Hata (Giriş): $e');
      rethrow;
    }
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
