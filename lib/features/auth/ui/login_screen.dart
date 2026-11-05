import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
// import 'register_screen.dart';
// import '../../main/ui/main_screen.dart'; // Ganti dengan path home screen kamu nantinya

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _isRememberMe = false;

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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black100,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selamat datang kembali! Silakan masukkan detail akun Anda untuk melanjutkan.',
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
                      const SizedBox(height: 12),

                      // Ingat Saya & Lupa Kata Sandi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _isRememberMe,
                                  activeColor: AppColors.cerulean,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  side: const BorderSide(color: AppColors.alto),
                                  onChanged: (val) {
                                    setState(() => _isRememberMe = val ?? false);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ingat saya',
                                style: TextStyle(fontSize: 12, color: AppColors.black70),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              // Aksi ketika Lupa Kata Sandi ditekan
                            },
                            child: const Text(
                              'Lupa Kata Sandi?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.cerulean,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tombol Masuk
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
                          onPressed: () {
                            // Simulasi Login: Hapus semua tumpukan halaman Auth dan langsung masuk ke MainScreen (Beranda)
                            // Navigator.pushAndRemoveUntil(
                            //   context,
                            //   MaterialPageRoute(builder: (context) => const MainScreen()),
                            //   (route) => false,
                            // );
                          },
                          child: const Text(
                            'Masuk',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider "atau masuk dengan"
                      Row(
                        children: const [
                          Expanded(child: Divider(color: AppColors.alto, thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'atau masuk dengan',
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
                          Expanded(child: _buildSocialButton('Google', Icons.g_mobiledata)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSocialButton('Apple', Icons.apple)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Link ke Daftar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: TextStyle(fontSize: 13, color: AppColors.black50),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Ganti halaman saat ini menjadi RegisterScreen
                              // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                            },
                            child: const Text(
                              'Daftar',
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
  Widget _buildSocialButton(String label, IconData iconIcon) {
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
          Icon(iconIcon, color: AppColors.black100, size: 24),
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