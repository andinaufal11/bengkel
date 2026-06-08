import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/auth/models/user_model.dart';
import 'package:bengkel/features/auth/screens/login_screen.dart';

class PartnerDashboardScreen extends StatelessWidget {
  final UserModel user;

  const PartnerDashboardScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Panel Pemilik Bengkel', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
            Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppColors.error),
            onPressed: () async {
              await client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        // Mengambil status verifikasi bengkel secara asinkron langsung dari tabel bengkels
        future: client.from('bengkels').select().eq('owner_id', user.id).maybeSingle(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          }

          final dataBengkel = snapshot.data;
          final String statusACC = dataBengkel?['status'] ?? 'pending';
          final String namaBengkel = dataBengkel?['name'] ?? 'Nama Bengkel Tidak Terdaftar';
          final bool isApproved = statusACC == 'approved';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PANEL KONDISI: CEK STATUS ACC ADMIN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isApproved ? AppColors.secondary : Colors.orange.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(namaBengkel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isApproved ? Colors.green.withOpacity(0.3) : Colors.black.withOpacity(0.32),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isApproved ? 'AKTIF (ACC)' : 'MENUNGGU ACC',
                              style: TextStyle(
                                color: isApproved ? Colors.greenAccent : Colors.orangeAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isApproved
                            ? 'Dokumen legalitas disetujui. Anda sekarang bisa mengelola operasional penuh.'
                            : 'Pendaftaran Anda sedang ditinjau oleh Admin. Fitur manajemen saat ini dikunci.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const Text('Layanan Utama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 16),

                // WIDGET INTERAKTIF: JIKA BELUM ACC, TOMBOL DI-DISABLE (BURAM & TIDAK BISA DIKLIK)
                _buildMenuTile(
                  icon: Icons.people_outline,
                  title: 'Kelola & Daftarkan Mekanik',
                  subtitle: 'Tambah data mekanik baru ke dalam outlet Anda.',
                  isEnabled: isApproved,
                  onTap: () {
                    // TODO: Arahkan ke modul pendaftaran mekanik
                  },
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: Icons.storefront_outlined,
                  title: 'Manajemen Sparepart & Toko',
                  subtitle: 'Atur katalog komoditas servis fisik.',
                  isEnabled: isApproved,
                  onTap: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4, // Membuat visual menu buram jika belum di-ACC
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          leading: Icon(icon, color: AppColors.secondary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
          subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
          onTap: isEnabled ? onTap : null, // Menonaktifkan fungsi klik jika belum di-ACC
        ),
      ),
    );
  }
}