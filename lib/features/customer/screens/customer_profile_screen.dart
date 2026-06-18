import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/features/auth/models/user_model.dart';
import 'package:bengkel/features/auth/screens/login_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  final UserModel user;
  final Function(int tabIndex, String statusFilter) onOrderStatusSelected;

  const CustomerProfileScreen({
    Key? key,
    required this.user,
    required this.onOrderStatusSelected,
  }) : super(key: key);

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  UserModel? _profileUser;
  bool _isLoadingProfile = false;
  double _bengkelinPaySaldo = 150000;

  // Mock Data
  final List<String> _userAddresses = [
    "Rumah - Jl. Merdeka No. 45, Jakarta Pusat",
    "Kantor - Gedung AIS Lt. 5, Jakarta Selatan"
  ];

  final List<Map<String, dynamic>> _mockVouchers = [
    {"code": "DISKON50", "desc": "Diskon 50% Jasa Ganti Oli", "expiry": "Berlaku s/d 30 Jun 2026"},
    {"code": "TUNEUP30", "desc": "Diskon 30% Paket Tune Up", "expiry": "Berlaku s/d 15 Jul 2026"},
    {"code": "BENGKELIN10", "desc": "Potongan Rp 10.000 Semua Layanan", "expiry": "Berlaku s/d 31 Des 2026"}
  ];

  final List<Map<String, dynamic>> _mockReviews = [
    {"workshop": "Bengkel Jaya Motor", "date": "10 Jun 2026", "rating": 5, "comment": "Servis AC sangat dingin dan pengerjaan cepat!"},
    {"workshop": "Central Auto Service", "date": "02 Jun 2026", "rating": 4, "comment": "Mekanik ramah, ganti oli selesai kurang dari 30 menit."}
  ];

  @override
  void initState() {
    super.initState();
    _profileUser = widget.user;
    _fetchProfileFromSupabase();
  }

  // Fetch updated profile data from Supabase
  Future<void> _fetchProfileFromSupabase() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (mounted) {
      setState(() {
        _isLoadingProfile = true;
      });
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      if (mounted) {
        setState(() {
          _profileUser = UserModel.fromJson(response);
        });
      }
    } catch (e) {
      print("🚨 DEBUG ERROR: Gagal sinkronisasi profil dari Supabase: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  // Update profile name and phone in Supabase
  Future<void> _updateProfileInSupabase(String name, String phone) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (mounted) {
      setState(() {
        _isLoadingProfile = true;
      });
    }

    try {
      await Supabase.instance.client.from('profiles').update({
        'name': name,
        'phone': phone,
      }).eq('id', userId);

      await _fetchProfileFromSupabase();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil berhasil diperbarui!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memperbarui profil: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _profileUser?.name ?? widget.user.name;
    final displayPhone = _profileUser?.phoneNumber ?? "+62 812-3456-7890";

    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Deep slate dark background
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Header Card
                    GestureDetector(
                      onTap: _showEditProfileSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            // Large circular avatar
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: CircleAvatar(
                                radius: 38,
                                backgroundColor: Colors.white,
                                child: Text(
                                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    displayPhone,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF94A3B8), // slate 400
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF475569), size: 26),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bengkelin Pay Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B), // slate 800
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF334155)), // slate 700
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB), // blue 600
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Bengkelin Pay",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF334155),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "Verified",
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          GestureDetector(
                            onTap: _showBengkelinPaySheet,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      "Saldo: ",
                                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                    ),
                                    Text(
                                      "Rp ${_formatRupiah(_bengkelinPaySaldo)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF3B82F6), size: 22),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Pesanan Saya Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Pesanan Saya",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () => widget.onOrderStatusSelected(3, "Semua"),
                          child: const Text(
                            "Lihat Riwayat >",
                            style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Interactive Order Status Row
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          _buildProfileStatusButton(
                            icon: Icons.inventory_2_rounded,
                            iconColor: const Color(0xFF3B82F6),
                            label: "Menunggu",
                            badgeCount: 2,
                            onTap: () => widget.onOrderStatusSelected(3, "Menunggu"),
                          ),
                          _buildProfileDivider(),
                          _buildProfileStatusButton(
                            icon: Icons.local_shipping_rounded,
                            iconColor: const Color(0xFF3B82F6),
                            label: "Proses",
                            badgeCount: 1,
                            onTap: () => widget.onOrderStatusSelected(3, "Proses"),
                          ),
                          _buildProfileDivider(),
                          _buildProfileStatusButton(
                            icon: Icons.check_circle_rounded,
                            iconColor: const Color(0xFF10B981),
                            label: "Selesai",
                            badgeCount: 24,
                            onTap: () => widget.onOrderStatusSelected(3, "Selesai"),
                          ),
                          _buildProfileDivider(),
                          _buildProfileStatusButton(
                            icon: Icons.cancel_rounded,
                            iconColor: const Color(0xFFEF4444),
                            label: "Dibatalkan",
                            badgeCount: 3,
                            onTap: () => widget.onOrderStatusSelected(3, "Dibatalkan"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Akun Saya Section
                    const Text(
                      "Akun Saya",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        children: [
                          _buildProfileMenuItem(
                            icon: Icons.person_outline_rounded,
                            title: "Edit Profil",
                            subtitle: "Ubah nama, email, dan foto",
                            onTap: _showEditProfileSheet,
                          ),
                          _buildMenuDivider(),
                          _buildProfileMenuItem(
                            icon: Icons.location_on_outlined,
                            title: "Alamat Saya",
                            subtitle: "Kelola alamat pengiriman",
                            onTap: _showAddressesSheet,
                          ),
                          _buildMenuDivider(),
                          _buildProfileMenuItem(
                            icon: Icons.payment_rounded,
                            title: "Bengkelin Pay",
                            subtitle: "Saldo: Rp ${_formatRupiah(_bengkelinPaySaldo)}",
                            onTap: _showBengkelinPaySheet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pengaturan Section
                    const Text(
                      "Pengaturan",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        children: [
                          _buildProfileMenuItem(
                            icon: Icons.notifications_none_rounded,
                            title: "Notifikasi",
                            subtitle: "Kelola preferensi notifikasi",
                            onTap: _showNotificationSettingsSheet,
                          ),
                          _buildMenuDivider(),
                          _buildProfileMenuItem(
                            icon: Icons.credit_card_rounded,
                            title: "Metode Pembayaran",
                            subtitle: "Kartu, e-wallet, transfer",
                            onTap: _showPaymentMethodsSheet,
                          ),
                          _buildMenuDivider(),
                          _buildProfileMenuItem(
                            icon: Icons.shield_outlined,
                            title: "Keamanan",
                            subtitle: "Password & autentikasi 2FA",
                            onTap: _showSecuritySheet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lainnya Section
                    const Text(
                      "Lainnya",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        children: [
                          _buildProfileMenuItem(
                            icon: Icons.card_giftcard_rounded,
                            title: "Voucher Saya",
                            subtitle: "3 voucher tersedia",
                            onTap: _showVouchersSheet,
                          ),
                          _buildMenuDivider(),
                          _buildProfileMenuItem(
                            icon: Icons.star_outline_rounded,
                            title: "Ulasan Saya",
                            subtitle: "Riwayat ulasan yang diberikan",
                            onTap: _showReviewsSheet,
                          ),
                          _buildMenuDivider(),
                          _buildProfileMenuItem(
                            icon: Icons.help_outline_rounded,
                            title: "Bantuan",
                            subtitle: "FAQ & hubungi kami",
                            onTap: _showHelpSheet,
                          ),
                          _buildMenuDivider(),
                          _buildProfileMenuItem(
                            icon: Icons.settings_outlined,
                            title: "Pengaturan Aplikasi",
                            subtitle: "Bahasa, tema, notifikasi",
                            onTap: _showAppSettingsSheet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Logout Button
                    GestureDetector(
                      onTap: _handleLogout,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Keluar",
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        "Bengkelin v1.0.0",
                        style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // --- SUB-WIDGET BUILDERS & HELPER INTERACTIVE SHEETS ---

  Widget _buildProfileStatusButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444), // red 500
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFF334155),
    );
  }

  Widget _buildMenuDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 54),
      child: Divider(height: 1, color: Color(0xFF334155)),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF334155).withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF475569), size: 20),
      onTap: onTap,
    );
  }

  // Edit Profil Sheet
  void _showEditProfileSheet() {
    final displayName = _profileUser?.name ?? widget.user.name;
    final displayPhone = _profileUser?.phoneNumber ?? "";

    final nameController = TextEditingController(text: displayName);
    final phoneController = TextEditingController(text: displayPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Edit Profil", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Nama Lengkap",
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF334155))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Nomor Telepon",
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF334155))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateProfileInSupabase(
                      nameController.text.trim(),
                      phoneController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // Bengkelin Pay Sheet with Top Up
  void _showBengkelinPaySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bengkelin Pay",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Saldo Aktif", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                        Text(
                          "Rp ${_formatRupiah(_bengkelinPaySaldo)}",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Transaksi Terakhir", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildTransactionItem("Top Up Saldo", "+ Rp 50.000", "18 Jun 2026", Colors.green),
                  _buildTransactionItem("Pembayaran Servis", "- Rp 150.000", "15 Jun 2026", Colors.red),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showTopUpDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Isi Saldo (Top Up)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(String title, String amount, String date, Color amountColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(date, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            ],
          ),
          Text(amount, style: TextStyle(color: amountColor, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showTopUpDialog() {
    final topUpController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text("Top Up Saldo", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: topUpController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Masukkan nominal (Contoh: 50000)",
              hintStyle: TextStyle(color: Color(0xFF475569)),
              prefixText: "Rp ",
              prefixStyle: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () {
                final input = topUpController.text.trim();
                final amount = double.tryParse(input);
                if (amount != null && amount > 0) {
                  setState(() {
                    _bengkelinPaySaldo += amount;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Berhasil top up Rp ${_formatRupiah(amount)}!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text("Top Up"),
            ),
          ],
        );
      },
    );
  }

  // Address management bottom sheet
  void _showAddressesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Alamat Saya", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF3B82F6)),
                        onPressed: () {
                          _showAddAddressDialog(setSheetState);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _userAddresses.length,
                    itemBuilder: (context, index) {
                      final addr = _userAddresses[index];
                      final parts = addr.split(" - ");
                      final label = parts[0];
                      final detail = parts.length > 1 ? parts[1] : addr;
                      return Card(
                        color: const Color(0xFF111827),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: const Icon(Icons.location_on_rounded, color: Color(0xFF3B82F6)),
                          title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(detail, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              setSheetState(() {
                                setState(() {
                                  _userAddresses.removeAt(index);
                                });
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddAddressDialog(StateSetter setSheetState) {
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text("Tambah Alamat Baru", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Label Alamat (Contoh: Kost)",
                  hintStyle: TextStyle(color: Color(0xFF475569)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Alamat Lengkap",
                  hintStyle: TextStyle(color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () {
                final label = labelController.text.trim();
                final detail = addressController.text.trim();
                if (label.isNotEmpty && detail.isNotEmpty) {
                  setSheetState(() {
                    setState(() {
                      _userAddresses.add("$label - $detail");
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  // Security (Change Password) Sheet
  void _showSecuritySheet() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Keamanan & Sandi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                "Perbarui kata sandi akun Supabase Auth Anda secara langsung di bawah ini:",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Kata Sandi Baru",
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF334155))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Konfirmasi Kata Sandi Baru",
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF334155))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final pwd = passwordController.text;
                    final cpwd = confirmController.text;
                    if (pwd.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Kata sandi harus minimal 6 karakter!"), backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    if (pwd != cpwd) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Konfirmasi kata sandi tidak cocok!"), backgroundColor: Colors.orange),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    try {
                      await Supabase.instance.client.auth.updateUser(UserAttributes(password: pwd));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Kata sandi berhasil diperbarui di Supabase!"), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal memperbarui kata sandi: $e"), backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Perbarui Password", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // Voucher Saya Bottom Sheet
  void _showVouchersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Voucher Saya", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _mockVouchers.length,
                itemBuilder: (context, index) {
                  final v = _mockVouchers[index];
                  return Card(
                    color: const Color(0xFF111827),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.card_giftcard_rounded, color: Colors.orangeAccent),
                      title: Text(v['desc'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(v['expiry'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Kode Voucher '${v['code']}' berhasil diklaim & disalin!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text("Klaim", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Ulasan Saya Bottom Sheet
  void _showReviewsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ulasan Saya", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _mockReviews.length,
                itemBuilder: (context, index) {
                  final r = _mockReviews[index];
                  return Card(
                    color: const Color(0xFF111827),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(r['workshop'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(r['date'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                Icons.star_rounded,
                                color: i < r['rating'] ? Colors.orange : Colors.grey.shade700,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            r['comment'],
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // FAQ Bantuan Bottom Sheet
  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pusat Bantuan FAQ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildFAQTile("Bagaimana cara memesan servis?", "Pilih layanan di tab Beranda, temukan bengkel terdekat, masukkan detail kendaraan, dan ajukan pesanan."),
              _buildFAQTile("Bagaimana cara menggunakan Bengkelin Pay?", "Anda dapat melakukan top-up melalui tombol Isi Saldo pada kartu Bengkelin Pay di tab profil."),
              _buildFAQTile("Di mana saya dapat melihat status mekanik?", "Status mekanik yang datang dapat dipantau di tab Pesanan pada bagian pesanan berjalan."),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFAQTile(String q, String a) {
    return ExpansionTile(
      iconColor: const Color(0xFF3B82F6),
      collapsedIconColor: Colors.white,
      title: Text(q, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(a, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ),
        ),
      ],
    );
  }

  // App Settings
  void _showAppSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pengaturan Aplikasi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Bahasa Utama", style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text("Bahasa Indonesia", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                trailing: const Icon(Icons.arrow_drop_down, color: Colors.white),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Aplikasi saat ini hanya tersedia dalam Bahasa Indonesia.")),
                  );
                },
              ),
              const Divider(color: Color(0xFF334155)),
              SwitchListTile(
                value: true,
                onChanged: (val) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Aplikasi dikunci dalam Mode Gelap premium.")),
                  );
                },
                title: const Text("Tema Gelap (Dark Mode)", style: TextStyle(color: Colors.white, fontSize: 14)),
                activeColor: const Color(0xFF3B82F6),
              ),
            ],
          ),
        );
      },
    );
  }

  // Simulated placeholders
  void _showNotificationSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Preferensi Notifikasi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SwitchListTile(
                value: true,
                onChanged: (val) {},
                title: const Text("Notifikasi Transaksi", style: TextStyle(color: Colors.white, fontSize: 14)),
                activeColor: const Color(0xFF3B82F6),
              ),
              SwitchListTile(
                value: true,
                onChanged: (val) {},
                title: const Text("Notifikasi Obrolan/Chat", style: TextStyle(color: Colors.white, fontSize: 14)),
                activeColor: const Color(0xFF3B82F6),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentMethodsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Metode Pembayaran", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPaymentMethodTile("Bengkelin Pay (E-Wallet)", Icons.account_balance_wallet_rounded, true),
              _buildPaymentMethodTile("Transfer Bank (Virtual Account)", Icons.account_balance_rounded, false),
              _buildPaymentMethodTile("Kartu Kredit/Debit", Icons.credit_card_rounded, false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodTile(String name, IconData icon, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
      trailing: isSelected 
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF3B82F6)) 
          : const Icon(Icons.circle_outlined, color: Colors.grey),
    );
  }

  String _formatRupiah(double val) {
    final strVal = val.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = strVal.length - 1; i >= 0; i--) {
      buffer.write(strVal[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  void _handleLogout() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    try {
      await Supabase.instance.client.auth.signOut();
      
      if (!mounted) return;
      
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Berhasil keluar akun"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Gagal keluar akun: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
