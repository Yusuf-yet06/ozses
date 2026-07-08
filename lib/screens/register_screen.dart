import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  Future<void> _siberKayitOl() async {
    final username = _userController.text.trim();
    final email = _emailController.text.trim();
    final password = _passController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tüm alanları doldurun!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().registerWithEmailAndPassword(username, email, password);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıt Hatası: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "SİBER AĞA KATIL",
          style: TextStyle(
            color: Colors.purpleAccent,
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
            colors: [Colors.purpleAccent.withOpacity(0.15), Colors.black],
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
                  // 🎯 Profil Fotoğrafı Seçici (Şimdilik Görsel)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withOpacity(0.5),
                              blurRadius: 25,
                              spreadRadius: 2,
                            )
                          ],
                          border: Border.all(
                              color: Colors.purpleAccent.withOpacity(0.8),
                              width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.black87,
                          child: Icon(Icons.person,
                              size: 60, color: Colors.white24),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.cyanAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.black, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 🎯 SİBER FORM (Glassmorphism Mührü)
                  _buildGlassCard(
                    child: Column(
                      children: [
                        _buildSiberTextField(
                          hint: "Kullanıcı Adı",
                          icon: Icons.person_outline,
                          controller: _userController,
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _buildSiberTextField(
                          hint: "E-Posta Adresi",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _buildSiberTextField(
                          hint: "Siber Şifre",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _passController,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 🎯 KAYIT OL BUTONU (Neon Efektli)
                  InkWell(
                    onTap: _isLoading ? null : () {
                      _siberKayitOl();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.purpleAccent.withOpacity(0.8),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.purpleAccent.withOpacity(0.3),
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
                          "SİSTEME MÜHÜRLE",
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
        prefixIcon: Icon(icon, color: Colors.purpleAccent),
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
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.05),
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
}
