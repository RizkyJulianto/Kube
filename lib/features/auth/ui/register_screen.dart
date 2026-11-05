import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';
// import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cerulean, // Background atas biru
      body: SafeArea(
        bottom: false, // Biar card putih bisa penuh ke bawah
        child: Column(
          children: [
            // Bagian Atas: Tombol Back & Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Logo di tengah
            Image.asset(
              'assets/images/logo-icon.png',
              height: 64,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),

            // Bagian Bawah: Card Form Putih
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView( // Agar tidak overflow saat keyboard muncul
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        'Buat Akun',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black100,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Daftar sekarang untuk mulai memesan pasokan es batu higienis untuk kebutuhan Anda.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.black50,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Input Email
                      _buildTextField(
                        label: 'Email',
                        hint: 'nama@gmail.com',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Input Password
                      _buildPasswordField(
                        label: 'Kata Sandi',
                        hint: '••••••••',
                        isVisible: _isPasswordVisible,
                        onVisibilityChanged: () {
                          setState(() => _isPasswordVisible = !_isPasswordVisible);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Input Konfirmasi Password
                      _buildPasswordField(
                        label: 'Konfirmasi Kata Sandi',
                        hint: '••••••••',
                        isVisible: _isConfirmPasswordVisible,
                        onVisibilityChanged: () {
                          setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Checkbox Terms
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _isAgreed,
                              activeColor: AppColors.cerulean,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              side: const BorderSide(color: AppColors.alto),
                              onChanged: (val) {
                                setState(() => _isAgreed = val ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Saya setuju dengan Syarat & Ketentuan',
                            style: TextStyle(fontSize: 12, color: AppColors.black70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tombol Daftar
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cerulean,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isAgreed ? () {} : null, // Disable jika belum centang
                          child: const Text(
                            'Daftar',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider "atau daftar dengan"
                      Row(
                        children: const [
                          Expanded(child: Divider(color: AppColors.alto, thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'atau daftar dengan',
                              style: TextStyle(fontSize: 12, color: AppColors.black50),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.alto, thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tombol Google & Apple
                      Row(
                        children: [
                          Expanded(child: _buildSocialButton('Google', 'assets/images/google_icon.png')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSocialButton('Apple', 'assets/images/apple_icon.png', iconIcon: Icons.apple)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Link ke Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun? ',
                            style: TextStyle(fontSize: 13, color: AppColors.black50),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                            },
                            child: const Text(
                              'Masuk',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.cerulean),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Input Field Biasa
  Widget _buildTextField({required String label, required String hint, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.black100)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.black50),
            prefixIcon: Icon(icon, color: AppColors.black50, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.alto),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cerulean),
            ),
          ),
        ),
      ],
    );
  }

  // Helper Input Field Password
  Widget _buildPasswordField({
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.black100)),
        const SizedBox(height: 8),
        TextField(
          obscureText: !isVisible,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.black50),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.black50, size: 20),
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.black50, size: 20),
              onPressed: onVisibilityChanged,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.alto),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cerulean),
            ),
          ),
        ),
      ],
    );
  }

  // Helper Tombol Sosial Media
  Widget _buildSocialButton(String label, String imagePath, {IconData? iconIcon}) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: AppColors.alto),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconIcon != null) 
            Icon(iconIcon, color: AppColors.black100, size: 20)
          else 
            // Jika kamu belum punya aset logo google, ini akan error, ganti dengan Icon(Icons.g_mobiledata) sementara jika perlu
            const Icon(Icons.g_mobiledata, color: AppColors.black100, size: 24), // Fallback icon
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.black100),
          ),
        ],
      ),
    );
  }
}