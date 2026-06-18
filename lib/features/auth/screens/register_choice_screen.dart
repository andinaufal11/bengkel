import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bengkel/features/auth/screens/register_partner_screen.dart';
import 'package:bengkel/features/auth/screens/register_user_screen.dart';

class RegisterChoiceScreen extends StatelessWidget {
  const RegisterChoiceScreen({Key? key}) : super(key: key);

  // Palet Warna Premium
  final Color _primaryNavy = const Color(0xFF1E293B);
  final Color _textMuted = const Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      // --- LOGO & HEADER ---
                      Center(
                        child: Image.asset(
                          'assets/images/logo_bengkel.png',
                          height: 64,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.directions_car,
                            color: _primaryNavy,
                            size: 64,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'BengkelKu',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: _primaryNavy,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Platform Otomotif #1 di Indonesia',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: _textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 48),

                      Center(
                        child: Text(
                          'DAFTAR SEBAGAI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _textMuted,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- ROLE CARDS ---
                      _RoleCard(
                        title: 'Pelanggan',
                        description: 'Cari bengkel & beli spare part',
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
                        description: 'Kelola usaha bengkel & mekanik',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RegisterPartnerScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      Text(
                        '*Catatan: Admin hanya via seed DB. Mekanik didaftarkan oleh Mitra Bengkel.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 32),

                      // --- FOOTER S&K ---
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            color: _textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Dengan mendaftar, kamu setuju dengan ',
                            ),
                            TextSpan(
                              text: 'Syarat & Ketentuan',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Warna Navy Gelap
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
