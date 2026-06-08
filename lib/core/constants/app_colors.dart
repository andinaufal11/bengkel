import 'package:flutter/material.dart';

class AppColors {
  // Basis utama aplikasi sesuai spesifikasi
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  
  // Warna secondary (Biru Navy) untuk tombol utama, aksen, dan teks penegas
  static const Color secondary = Color(0xFF1A365D);
  
  // Warna pendukung fungsional
  static const Color textDark = Color(0xFF1E293B);  // Untuk teks utama agar kontras di atas putih
  static const Color textGrey = Color(0xFF64748B);  // Untuk sub-teks atau petunjuk (hint)
  static const Color border = Color(0xFFE2E8F0);    // Untuk garis tepi input form
  static const Color error = Color(0xFFEF4444);     // Untuk validasi error
  static const Color success = Color(0xFF10B981); // Emerald Green untuk status 'Tersedia'
  static const Color cardBg = Color(0xFFF8FAFC);  // Warna abu-abu sangat muda untuk background card
}