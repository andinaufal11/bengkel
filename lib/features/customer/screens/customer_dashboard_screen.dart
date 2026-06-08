import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/auth/models/user_model.dart';
import 'package:bengkel/features/auth/screens/login_screen.dart';

class CustomerDashboardScreen extends StatelessWidget {
  final UserModel user;

  const CustomerDashboardScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.secondary.withOpacity(0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C',
                style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang,',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppColors.error),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PANEL 1: SEKSI GARASI KENDARAAN (FITUR CORE)
            const Text(
              'Garasi Saya',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary, // Nuansa Navy Solid Khas Otoretail
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_filled_outlined, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Belum Ada Kendaraan Terdaftar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tambahkan kendaraan Anda untuk mempermudah diagnosis servis.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.white, size: 32),
                    onPressed: () {
                      // TODO: Navigasi ke modul garage
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // PANEL 2: SMART FEED / REKOMENDASI KONDISI (FITUR KUSTOM)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Smart Feed & Rekomendasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Lihat Semua', style: TextStyle(color: AppColors.secondary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Item Feed Palsu untuk placeholder visual awal
            _buildFeedCard(
              icon: Icons.build_circle_outlined,
              title: 'Waktunya Servis Berkala Ganti Oli',
              subtitle: 'Berdasarkan rata-rata harian penggunaan Anda.',
              time: 'Baru Saja',
            ),
            const SizedBox(height: 12),
            _buildFeedCard(
              icon: Icons.shield_outlined,
              title: 'Tips Hardening Server Bengkel',
              subtitle: 'Pastikan kredensial IoT mekanik Anda menggunakan enkripsi TLS.',
              time: '2 jam yang lalu',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                      ),
                    ),
                    Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}