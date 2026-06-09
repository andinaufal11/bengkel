import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/core/constants/supabase_constants.dart';
import 'package:bengkel/features/auth/models/user_model.dart';
import 'package:bengkel/features/auth/screens/login_screen.dart';
import 'package:bengkel/features/customer/screens/customer_dashboard_screen.dart';
import 'package:bengkel/features/mechanic/screens/mechanic_dashboard_screen.dart';
import 'package:bengkel/features/partner/screens/partner_dashboard_screen.dart';
import 'package:bengkel/features/admin/screens/main_screen.dart'; // ← TAMBAHAN ADMIN

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: session == null
          ? const LoginScreen()
          : FutureBuilder<Map<String, dynamic>?>(
              future: client
                  .from('profiles')
                  .select()
                  .eq('id', session.user.id)
                  .maybeSingle(),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondary,
                      ),
                    ),
                  );
                }

                // Routing berdasarkan role
                if (snapshot.hasData && snapshot.data != null) {
                  final user = UserModel.fromJson(snapshot.data!);

                  switch (user.role) {
                    case 'admin':
                      return const MainScreen(); // ← ROUTE ADMIN
                    case 'mechanic':
                      return MechanicDashboardScreen(mechanicUserId: user.id);
                    case 'customer':
                      return CustomerDashboardScreen(user: user);
                    case 'partner':
                      return PartnerDashboardScreen(user: user);
                    default:
                      return const LoginScreen();
                  }
                }

                // Fallback ke login jika profile tidak ditemukan
                return const LoginScreen();
              },
            ),
    );
  }
}