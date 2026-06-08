import 'package:flutter/material.dart';

import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/auth/screens/register_partner_screen.dart';
import 'package:bengkel/features/auth/screens/register_user_screen.dart';
import 'package:bengkel/features/auth/widgets/auth_header.dart';

class RegisterChoiceScreen extends StatelessWidget {
  const RegisterChoiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // ----------------------------------------------------
      // TAMBAHAN: AppBar dengan tombol kembali ke Login
      // ----------------------------------------------------
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () {
            Navigator.pop(context); // Menutup halaman ini dan kembali ke LoginScreen
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(
                title: 'Pilih Jenis Akun',
                subtitle: 'Daftar sebagai pengguna biasa atau mitra bengkel',
              ),
              const SizedBox(height: 32),
              _RoleCard(
                title: 'Pengguna Biasa',
                description:
                    'Untuk pelanggan yang ingin beli sparepart, booking mekanik, dan akses fitur SOS.',
                icon: Icons.person_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterUserScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Mitra Bengkel',
                description:
                    'Untuk bengkel yang ingin mendaftarkan outlet dan mengelola akses mekanik.',
                icon: Icons.store_mall_directory_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPartnerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Catatan: admin hanya via seed akun, sedangkan mekanik hanya bisa dibuat dari akun bengkel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 24), // Tambahan jarak bawah agar lebih lega
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.secondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}