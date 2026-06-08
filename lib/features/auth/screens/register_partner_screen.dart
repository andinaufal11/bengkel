import 'package:flutter/material.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/auth/repository/auth_repository.dart';
import 'package:bengkel/features/auth/widgets/auth_header.dart';
import 'package:bengkel/features/auth/widgets/document_picker_button.dart';
// Tambahan import untuk UserModel dan halaman Dasbor Partner
import 'package:bengkel/features/auth/models/user_model.dart';
import 'package:bengkel/features/partner/screens/partner_dashboard_screen.dart';

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

  // State untuk dropdown kategori spesialisasi (FR-BKL-01)
  String _selectedCategory = 'Hanya Mobil';
  final List<String> _categories = ['Hanya Mobil', 'Hanya Motor', 'Keduanya'];

  // State indikator dokumen terunggah
  String? _uploadedDocumentName;

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  title: 'Kemitraan Bengkel',
                  subtitle:
                      'Daftarkan bengkel fisik Anda ke dalam jaringan digital',
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _workshopNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama bengkel wajib diisi';
                    }

                    return null;
                  },
                  decoration: _buildInputDecoration(
                    'Nama Bengkel',
                    Icons.store_mall_directory_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _ownerNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama pemilik wajib diisi';
                    }

                    return null;
                  },
                  decoration: _buildInputDecoration(
                    'Nama Pemilik',
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email wajib diisi';
                    }

                    if (!value.contains('@')) {
                      return 'Format email tidak valid';
                    }

                    return null;
                  },
                  decoration: _buildInputDecoration(
                    'Email Operasional',
                    Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor HP wajib diisi';
                    }

                    return null;
                  },
                  decoration: _buildInputDecoration(
                    'Nomor HP Bengkel',
                    Icons.phone_android_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat bengkel wajib diisi';
                    }

                    return null;
                  },
                  decoration: _buildInputDecoration(
                    'Alamat Lengkap Bengkel',
                    Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                // Dropdown Kategori Spesialisasi Bengkel (FR-BKL-01)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: _buildInputDecoration(
                    'Spesialisasi Layanan',
                    Icons.handyman_outlined,
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Area Unggah Dokumen Toko (FR-AUTH-01)
                const Text(
                  'Dokumen Legalitas (SIUP/NIB/Foto Outlet)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),

                // --------------------------------------------------------
                // WIDGET KUSTOM DocumentPickerButton DIPANGGIL DI SINI
                // --------------------------------------------------------
                DocumentPickerButton(
                  fileName: _uploadedDocumentName,
                  onTap: () {
                    setState(() {
                      _uploadedDocumentName = 'dokumen_legalitas_bengkel.pdf';
                    });
                  },
                ),

                const SizedBox(height: 32),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi wajib diisi';
                    }

                    if (value.length < 6) {
                      return 'Kata sandi minimal 6 karakter';
                    }

                    return null;
                  },
                  decoration: _buildInputDecoration(
                    'Kata Sandi Akun',
                    Icons.lock_outline,
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate() ||
                              _uploadedDocumentName == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Lengkapi data dan unggah dokumen legalitas.',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            // 1. Jalankan fungsi pendaftaran dan simpan responsnya
                            final response = await _authRepository.signUpUser(
                              name: _ownerNameController.text.trim(),
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                              phone: _phoneController.text.trim(),
                              role: 'partner',
                              workshopName: _workshopNameController.text.trim(),
                              address: _addressController.text.trim(),
                            );

                            if (!mounted) {
                              return;
                            }

                            // 2. Tampilkan notifikasi sukses
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pendaftaran mitra bengkel berhasil.',
                                ),
                              ),
                            );

                            // 3. Ambil data user yang baru saja terdaftar dari respons
                            final authUser = response.user;
                            
                            if (authUser != null) {
                              // 4. Buat objek UserModel secara manual dari data inputan
                              final newUserProfile = UserModel(
                                id: authUser.id,
                                name: _ownerNameController.text.trim(),
                                email: _emailController.text.trim(),
                                role: 'partner',
                                phoneNumber: _phoneController.text.trim(),
                              );

                              // 5. Lempar ke halaman dasbor partner dan hapus tumpukan layar sebelumnya
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PartnerDashboardScreen(user: newUserProfile),
                                ),
                                (route) => false, 
                              );
                            }
                          } catch (e) {
                            if (!mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Ajukan Kemitraan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textGrey),
      prefixIcon: Icon(icon, color: AppColors.secondary),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}