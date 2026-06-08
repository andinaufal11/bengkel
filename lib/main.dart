import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/core/constants/supabase_constants.dart';
import 'package:bengkel/features/auth/models/user_model.dart'; // Ditambahkan
import 'package:bengkel/features/auth/screens/login_screen.dart';
import 'package:bengkel/features/customer/screens/customer_dashboard_screen.dart'; // Ditambahkan
import 'package:bengkel/features/mechanic/screens/mechanic_dashboard_screen.dart';
import 'package:bengkel/features/partner/screens/partner_dashboard_screen.dart'; // Ditambahkan

void main() async {
  // Wajib dipanggil sebelum inisialisasi layanan cloud
  WidgetsFlutterBinding.ensureInitialized();

  // Menyambungkan aplikasi ke project Supabase kamu
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  runApp(const BengkelApp());
}

class BengkelApp extends StatelessWidget {
  const BengkelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mengambil sesi login saat ini dari Supabase Auth secara langsung
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    return MaterialApp(
      title: 'Otoretail App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.secondary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.secondary,
          primary: AppColors.secondary,
          background: AppColors.background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textDark),
        ),
      ),
      // GERBANG LOGIKA PINTU MASUK OTOMATIS DENGAN KONDISI ROLE
      home: session == null
          ? const LoginScreen() // Jika belum login, ke layar Login
          : FutureBuilder<Map<String, dynamic>?>(
              // Jika sudah ada sesi, cek ke tabel 'profiles' di Supabase berdasarkan id user
              future: client
                  .from('profiles')
                  .select()
                  .eq('id', session.user.id)
                  .maybeSingle(),
              builder: (context, snapshot) {
                // Tampilkan indikator loading saat aplikasi sedang mengecek database
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondary,
                      ),
                    ),
                  );
                }

                // Jika data profile berhasil diambil
                if (snapshot.hasData && snapshot.data != null) {
                  final user = UserModel.fromJson(snapshot.data!);

                  // Arahkan ke halaman sesuai dengan role masing-masing
                  if (user.role == 'mechanic') {
                    return MechanicDashboardScreen(mechanicUserId: user.id);
                  } else if (user.role == 'customer') {
                    return CustomerDashboardScreen(user: user);
                  } else if (user.role == 'partner') {
                    return PartnerDashboardScreen(
                      user: user,
                    ); // <-- Tambahkan baris ini agar Partner tidak terlempar keluar
                  }
                }

                // Jika data profile tidak ditemukan atau error, kembalikan ke LoginScreen demi keamanan
                return const LoginScreen();
              },
            ),
    );
  }
}
