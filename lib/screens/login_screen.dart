import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  Future<void> _siberGiris() async {
    final email = _emailController.text.trim();
    final password = _passController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Siber mühür için tüm alanları doldurun!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().signInWithEmailAndPassword(email, password);
      if (mounted) {
        // Geri dönüşü engellemek için doğrudan ana karargaha gönder
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erişim Reddedildi: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _siberGoogleGiris() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Bağlantı Hatası: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _siberAppleGiris() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithApple();
      if (user != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple Bağlantı Hatası: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apple Girişi sadece Apple ekosisteminde (iOS, macOS) geçerli
    final bool showAppleSignIn = !kIsWeb && 
      (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'SİBER KARARGAHA GİRİŞ',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Colors.cyanAccent.withValues(alpha: 0.15), Colors.black],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🎯 Siber Logo (Güvenlik Kalkanı)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                      border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.8),
                          width: 2),
                    ),
                    child: const Icon(Icons.security, size: 60, color: Colors.cyanAccent),
                  ),
                  const SizedBox(height: 40),

                  // 🎯 SİBER FORM (Glassmorphism Mührü)
                  _buildGlassCard(
                    child: Column(
                      children: [
                        _buildSiberTextField(
                          hint: 'E-Posta Adresi',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _buildSiberTextField(
                          hint: 'Siber Şifre',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _passController,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 🎯 GİRİŞ YAP BUTONU (Neon Efektli)
                  InkWell(
                    onTap: _isLoading ? null : _siberGiris,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.8),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.3),
                              blurRadius: 15),
                        ],
                      ),
                      child: Center(
                        child: _isLoading 
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                          'KİMLİĞİ DOĞRULA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🎯 YENİ HESAP AÇMA YÖNLENDİRMESİ
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    child: const Text('Siber Ağ\'a Katıl (Kayıt Ol)', style: TextStyle(color: Colors.white70)),
                  ),

                  const SizedBox(height: 15),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('VEYA', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 🎯 GOOGLE İLE GİRİŞ BUTONU
                  _buildSocialButton(
                    icon: Icons.g_mobiledata,
                    label: 'Google ile Mühürle',
                    color: Colors.redAccent,
                    onTap: _isLoading ? null : _siberGoogleGiris,
                  ),

                  // 🎯 APPLE İLE GİRİŞ BUTONU (Sadece iOS/macOS)
                  if (showAppleSignIn) ...[
                    const SizedBox(height: 15),
                    _buildSocialButton(
                      icon: Icons.apple,
                      label: 'Apple ile Mühürle',
                      color: Colors.white,
                      onTap: _isLoading ? null : _siberAppleGiris,
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSiberTextField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white30),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 5)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
