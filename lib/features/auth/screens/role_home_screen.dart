import 'package:flutter/material.dart';

import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/auth/models/user_model.dart';

class RoleHomeScreen extends StatelessWidget {
  final UserModel user;

  const RoleHomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final roleTitle = _roleTitle(user.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(roleTitle),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 44,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Login berhasil',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Akun ${user.email} terdeteksi sebagai $roleTitle.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey, height: 1.4),
              ),
              const SizedBox(height: 24),
              Text(
                _roleDescription(user.role),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDark, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleTitle(String role) {
    switch (role) {
      case 'admin':
        return 'Dashboard Admin';
      case 'mechanic':
        return 'Dashboard Mekanik';
      case 'partner':
        return 'Dashboard Mitra Bengkel';
      default:
        return 'Dashboard Pengguna';
    }
  }

  String _roleDescription(String role) {
    switch (role) {
      case 'admin':
        return 'Akun admin tidak bisa register. Akses ini idealnya menuju panel seed akun untuk moderasi dan pengelolaan sistem.';
      case 'mechanic':
        return 'Akun mekanik hanya dibuat oleh mitra bengkel. Nanti halaman ini bisa diarahkan ke daftar tugas atau jadwal servis.';
      case 'partner':
        return 'Akun mitra bengkel bisa mengelola outlet, dokumen legalitas, dan pembuatan akun mekanik.';
      default:
        return 'Akun pengguna biasa bisa melanjutkan ke katalog sparepart, booking mekanik, dan fitur SOS.';
    }
  }
}
