import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../service/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialCafeName;
  final String initialName;
  final String initialPhone;
  final String email;

  const EditProfileScreen({
    super.key,
    required this.initialCafeName,
    required this.initialName,
    required this.initialPhone,
    required this.email,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _cafeController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cafeController = TextEditingController(text: widget.initialCafeName);
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _cafeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final cafeName = _cafeController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (cafeName.isEmpty || name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nama Kafe, Nama Penanggung Jawab, dan No. HP wajib diisi.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ProfileService.updateProfileAndContact(
        name: name,
        phone: phone,
        cafeName: cafeName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil & kontak berhasil diperbarui!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true); // Kembalikan true agar ProfileScreen me-refresh data
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan perubahan: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.black100),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil & Kontak',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black100),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alto),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputField(
                    controller: _cafeController,
                    label: 'Nama Kafe / Outlet',
                    hint: 'Contoh: Kopi Senja - Watumas',
                    icon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _nameController,
                    label: 'Nama Penanggung Jawab',
                    hint: 'Masukkan nama lengkap',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _phoneController,
                    label: 'Nomor WhatsApp / HP',
                    hint: 'Contoh: 081234567890',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  // Email hanya tampil (Read-Only)
                  const Text(
                    'Email Akun',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.black100),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.alto),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined, color: AppColors.black50, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          widget.email,
                          style: const TextStyle(fontSize: 13, color: AppColors.black50),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cerulean,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.black100)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.black50),
            prefixIcon: Icon(icon, color: AppColors.black50, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
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
}