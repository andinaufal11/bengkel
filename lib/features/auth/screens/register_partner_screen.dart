import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Tambahan wajib untuk akses tabel verifikasi
import 'package:bengkel/features/auth/repository/auth_repository.dart';
import 'package:bengkel/features/auth/models/user_model.dart';
import 'package:bengkel/features/partner/screens/partner_dashboard_screen.dart';
import 'package:bengkel/features/auth/screens/login_screen.dart';

class RegisterPartnerScreen extends StatefulWidget {
  const RegisterPartnerScreen({Key? key}) : super(key: key);

  @override
  State<RegisterPartnerScreen> createState() => _RegisterPartnerScreenState();
}

class _RegisterPartnerScreenState extends State<RegisterPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workshopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _selectedCategory = 'Hanya Mobil';
  final List<String> _categories = ['Hanya Mobil', 'Hanya Motor', 'Keduanya'];
  String? _uploadedDocumentName;

  final Color _primaryNavy = const Color(0xFF1E293B);
  final Color _btnNavy = const Color(0xFF0F172A);
  final Color _formBg = const Color(0xFFF1F5F9);
  final Color _textMuted = const Color(0xFF64748B);

  @override
  void dispose() {
    _workshopNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Kemitraan Bengkel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Daftarkan bengkel fisik Anda ke dalam jaringan digital',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 32),

                _buildTextField(
                  _workshopNameController,
                  'NAMA BENGKEL',
                  'Nama Bengkel Anda',
                  Icons.store_mall_directory_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _ownerNameController,
                  'NAMA PEMILIK',
                  'Nama Pemilik',
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _emailController,
                  'EMAIL OPERASIONAL',
                  'nama@email.com',
                  Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _phoneController,
                  'NOMOR HP BENGKEL',
                  '08123456789',
                  Icons.phone_android_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _addressController,
                  'ALAMAT LENGKAP',
                  'Jl. Contoh No. 123',
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),

                Text(
                  'SPESIALISASI LAYANAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _formBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories
                          .map(
                            (val) => DropdownMenuItem(
                              value: val,
                              child: Text(
                                val,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: _primaryNavy,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'DOKUMEN LEGALITAS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setState(
                    () => _uploadedDocumentName = 'legalitas_bengkel.pdf',
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _formBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: _textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _uploadedDocumentName ?? 'Unggah PDF/PNG (Max 5MB)',
                            style: GoogleFonts.plusJakartaSans(
                              color: _textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  _passwordController,
                  'KATA SANDI AKUN',
                  '••••••••',
                  Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _btnNavy,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Ajukan Kemitraan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah memiliki akun? ',
                      style: GoogleFonts.plusJakartaSans(color: _textMuted),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      ),
                      child: Text(
                        'Masuk',
                        style: GoogleFonts.plusJakartaSans(
                          color: _btnNavy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _textMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? !_isPasswordVisible : false,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _primaryNavy),

          // Validator otomatis mencegah input kosong & password pendek lolos ke server
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Wajib diisi';
            }
            if (isPassword && val.length < 6) {
              return 'Kata sandi minimal 6 karakter';
            }
            return null;
          },

          decoration: InputDecoration(
            filled: true,
            fillColor: _formBg,
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF475569), size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: _textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    // 1. Cek field kosong atau password kurang dari 6 karakter
    if (!_formKey.currentState!.validate()) return;

    // 2. Cek apakah dokumen sudah di-upload
    if (_uploadedDocumentName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap unggah dokumen legalitas terlebih dahulu!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. Simpan akun ke Auth dan tabel 'profiles'
      final response = await _authRepository.signUpUser(
        name: _ownerNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        role: 'partner',
        workshopName: _workshopNameController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (!mounted) return;

      final authUser = response.user;
      if (authUser != null) {
        // 4. SIMPAN DATA KE TABEL 'mitra_verifikasi' AGAR DIBACA ADMIN
        try {
          await Supabase.instance.client.from('mitra_verifikasi').insert({
            'id': authUser
                .id, // ID ini menghubungkan mitra_verifikasi dengan profiles
            'name': _workshopNameController.text.trim(),
            'owner': _ownerNameController.text.trim(),
            'city': _addressController.text
                .trim(), // Asumsi alamat dipakai sebagai kota sementara
            'status': 'menunggu',
            'docs': 1, // Jumlah dokumen
          });
        } catch (insertError) {
          debugPrint('Gagal insert ke mitra_verifikasi: $insertError');
        }

        // 5. Masuk ke Dashboard Partner
        final newUserProfile = UserModel(
          id: authUser.id,
          name: _ownerNameController.text.trim(),
          email: _emailController.text.trim(),
          role: 'partner',
          phoneNumber: _phoneController.text.trim(),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => PartnerDashboardScreen(user: newUserProfile),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal daftar: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
