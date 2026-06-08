import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/features/auth/models/user_model.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Logika Masuk Email & Password + Mengambil Role [cite: 104-105, 639]
  // Future<UserModel?> signIn({
  //   required String email,
  //   required String password,
  // }) async {
  //   try {
  //     final AuthResponse response = await _supabase.auth.signInWithPassword(
  //       email: email,
  //       password: password,
  //     );

  //     final user = response.user;
  //     if (user != null) {
  //       // Setelah login berhasil, ambil detail profil (termasuk role) dari tabel 'profiles'
  //       try {
  //         return await getUserProfile(user.id);
  //       } catch (_) {
  //         final metadata = user.userMetadata ?? <String, dynamic>{};
  //         return UserModel(
  //           id: user.id,
  //           name: (metadata['name'] ?? user.email ?? '').toString(),
  //           email: user.email ?? email,
  //           role: (metadata['role'] ?? 'customer').toString(),
  //           phoneNumber: metadata['phone_number']?.toString(),
  //         );
  //       }
  //     }
  //     return null;
  //   } catch (e) {
  //     throw Exception('Login gagal: $e');
  //   }
  // }

  // 1. Logika Masuk Email & Password + Mengambil Role (Sudah Diperbaiki untuk Debugging)
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        try {
          // Mencoba mengambil data asli dari tabel profiles
          final userProfile = await getUserProfile(user.id);
          print("🚨 DEBUG SUCCESS: Berhasil mengambil dari profiles! Role asli database = ${userProfile.role}");
          return userProfile;
        } catch (errorFromMapping) {
          print("🚨 DEBUG ERROR: Fungsi getUserProfile GAGAL! Ini penyebab erornya: $errorFromMapping");
          
          // Tetap jalankan fallback metadata agar aplikasi tidak langsung crash, tapi sekarang kita tahu masalahnya
          final metadata = user.userMetadata ?? <String, dynamic>{};
          return UserModel(
            id: user.id,
            name: (metadata['name'] ?? user.email ?? '').toString(),
            email: user.email ?? email,
            role: (metadata['role'] ?? 'customer').toString(),
            phoneNumber: metadata['phone_number']?.toString(),
          );
        }
      }
      return null;
    } catch (e) {
      throw Exception('Login gagal: $e');
    }
  }

  // 2. Fungsi Login dengan Google (SSO) [cite: 104]
  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.bengkel://login-callback', 
    );
  }

  // 3. Mengambil Profil User
  Future<UserModel> getUserProfile(String userId) async {
    // Diubah ke 'profiles' agar sinkron dengan pendaftaran mekanik dan customer
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserModel.fromJson(response);
  }

  // 4. Pendaftaran User (Customer) [cite: 103]
  Future<AuthResponse> signUpUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? workshopName, // Tambahan opsional
    String? address,      // Tambahan opsional

  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'phone_number': phone, 'role': role, 'workshop_name': workshopName, 'address': address},
    );
  }

  // 5. Sign Out [cite: 105]
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // 6. FR-BKL-02 & FR-MKN-01: Pembuatan Akun Mekanik Oleh Mitra Bengkel [cite: 122, 136-138]
  Future<void> addMechanicByMitra({
    required String email,
    required String password,
    required String fullName,
    required String bengkelId,
  }) async {
    // 1. Buat akun auth untuk mekanik di Supabase Auth [cite: 138]
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'role': 'mechanic', 'name': fullName},
    );

    // 2. Simpan ke tabel 'profiles' dan tabel 'mechanics' jika auth berhasil [cite: 138]
    if (authResponse.user != null) {
      final mechanicId = authResponse.user!.id;
      
      // Simpan ke tabel profiles umum untuk kebutuhan login check 
      await _supabase.from('profiles').insert({
        'id': mechanicId,
        'name': fullName,
        'role': 'mechanic',
      });

      // Simpan ke tabel relasi khusus mekanik internal bengkel [cite: 122, 138]
      await _supabase.from('mechanics').insert({
        'user_id': mechanicId,
        'bengkel_id': bengkelId,
        'full_name': fullName,
      });
    }
  }
} // <--- SEKARANG FUNGSI SUDAH DI DALAM KURUNG PENUTUP CLASS