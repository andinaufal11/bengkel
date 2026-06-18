import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/auth/models/user_model.dart';
import 'package:bengkel/features/customer/screens/customer_profile_screen.dart';
import 'package:bengkel/features/customer/screens/customer_sparepart_screen.dart';
import 'package:bengkel/features/customer/screens/customer_bengkel_screen.dart';
import 'package:bengkel/features/customer/screens/customer_orders_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  final UserModel user;

  const CustomerDashboardScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _selectedIndex = 0;
  String _selectedVehicle = "Tambah Kendaraan";
  List<Map<String, dynamic>> _myVehicles = [];

  List<String> get _userVehicles {
    final list = _myVehicles.map((v) => v['name'] as String).toList();
    list.add("+ Tambah Kendaraan");
    return list;
  }

  UserModel? _profileUser;
  bool _isLoadingProfile = false;
  String _selectedOrderStatusFilter = "Semua";

  @override
  void initState() {
    super.initState();
    _profileUser = widget.user;
    _fetchProfileFromSupabase();
    _fetchVehicles();
  }

  // Fetch updated profile data from Supabase (for home screen header)
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

  // Fetch user's vehicles from Supabase
  Future<void> _fetchVehicles() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('vehicles')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      
      if (mounted) {
        setState(() {
          _myVehicles = List<Map<String, dynamic>>.from(response);
          if (_myVehicles.isNotEmpty) {
            // Check if selected vehicle is still in the fetched list
            final names = _myVehicles.map((v) => v['name'] as String).toList();
            if (!names.contains(_selectedVehicle)) {
              _selectedVehicle = names.first;
            }
          }
        });
      }
    } catch (e) {
      print("🚨 DEBUG ERROR: Gagal fetch kendaraan dari Supabase: $e");
    }
  }

  // Insert a new vehicle to Supabase under current user
  Future<void> _addVehicle(String name) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('vehicles').insert({
        'user_id': userId,
        'name': name,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Berhasil menambahkan kendaraan: $name"),
            backgroundColor: const Color(0xFF10B981), // Emerald 500
          ),
        );
      }
      _fetchVehicles(); // Refresh the list
    } catch (e) {
      print("🚨 DEBUG ERROR: Gagal tambah kendaraan ke Supabase: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menyimpan kendaraan: $e"),
            backgroundColor: const Color(0xFFEF4444), // Red 500
          ),
        );
      }
    }
  }

  // Dialog to type in vehicle name
  void _showAddVehicleDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Tambah Kendaraan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Masukkan nama kendaraan Anda (contoh: Toyota Avanza 2022, Yamaha NMAX 2021).",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Nama Kendaraan",
                  hintText: "cth: Toyota Avanza 2021",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  _addVehicle(name);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF233246),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedIndex == 4 ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          const CustomerSparepartScreen(),
          const CustomerBengkelScreen(),
          CustomerOrdersScreen(
            selectedStatusFilter: _selectedOrderStatusFilter,
            onFilterChanged: (String newFilter) {
              setState(() {
                _selectedOrderStatusFilter = newFilter;
              });
            },
          ),
          CustomerProfileScreen(
            user: widget.user,
            onOrderStatusSelected: (int tabIndex, String statusFilter) {
              setState(() {
                _selectedIndex = tabIndex;
                _selectedOrderStatusFilter = statusFilter;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index != 3) {
              _selectedOrderStatusFilter = "Semua"; // Reset order filter when changing tabs
            }
          });
          if (index == 0) {
            _fetchProfileFromSupabase(); // Refresh greeting name on home tab
            _fetchVehicles(); // Refresh user vehicles from Supabase
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _selectedIndex == 4 ? const Color(0xFF3B82F6) : AppColors.primary,
        unselectedItemColor: const Color(0xFF94A3B8), // slate 400
        backgroundColor: _selectedIndex == 4 ? const Color(0xFF1F2937) : Colors.white,
        elevation: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Sparepart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined),
            activeIcon: Icon(Icons.build),
            label: 'Bengkel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Saya',
          ),
        ],
      ),
    );
  }

  // --- TAB 1: BERANDA ---
  Widget _buildHomeTab() {
    final displayName = _profileUser?.name ?? widget.user.name;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Background (Dark slate blue with gradient)
          Container(
            padding: const EdgeInsets.only(bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2B3A4E), // Top left
                  Color(0xFF1E2837), // Bottom right
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Profile Avatar + Greetings
                        Row(
                          children: [
                            // Avatar with Premium Gradient Border and Background
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = 4; // Navigate to profile tab
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.transparent,
                                  child: Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text("👋", style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Right: Notification & Cart
                        Row(
                          children: [
                            // Notification Bell with Badge
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                                    Positioned(
                                      right: 1,
                                      top: 1,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444), // red 500
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF223042), width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Shopping Cart
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = 1; // Navigate to Spareparts / Store tab
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                                ),
                                child: const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Overlapping Search Bar
          Transform.translate(
            offset: const Offset(0, -25),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Cari bengkel, sparepart, layanan...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          
          // Compensate for search bar translation
          const SizedBox(height: 4),

          // Vehicle Selector Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<String>(
                initialValue: _selectedVehicle,
                onSelected: (String value) {
                  if (value == "+ Tambah Kendaraan") {
                    _showAddVehicleDialog();
                  } else {
                    setState(() {
                      _selectedVehicle = value;
                    });
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                offset: const Offset(0, 38),
                elevation: 4,
                itemBuilder: (BuildContext context) {
                  return _userVehicles.map((String vehicle) {
                    final isAdd = vehicle == "+ Tambah Kendaraan";
                    return PopupMenuItem<String>(
                      value: vehicle,
                      child: Row(
                        children: [
                          Text(
                            isAdd ? "➕" : (_isMotor(vehicle) ? "🏍️" : "🚗"),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            vehicle,
                            style: TextStyle(
                              fontWeight: isAdd ? FontWeight.bold : FontWeight.w500,
                              color: isAdd ? const Color(0xFF3B82F6) : const Color(0xFF0F172A),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1), // slate 200
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedVehicle == "Tambah Kendaraan" || _selectedVehicle == "Pilih Kendaraan"
                            ? "➕"
                            : (_isMotor(_selectedVehicle) ? "🏍️" : "🚗"),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedVehicle,
                        style: const TextStyle(
                          color: Color(0xFF334155), // slate 700
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          
          // Services Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildServiceCard(Icons.build_rounded, "Ganti Oli", iconColor: const Color(0xFF6366F1))), // indigo/purple
                    const SizedBox(width: 12),
                    Expanded(child: _buildServiceCard(Icons.battery_charging_full_rounded, "Aki &\nListrik", iconColor: const Color(0xFF10B981))), // emerald
                    const SizedBox(width: 12),
                    Expanded(child: _buildServiceCard(Icons.ac_unit_rounded, "AC Mobil", iconColor: const Color(0xFF06B6D4))), // cyan
                    const SizedBox(width: 12),
                    Expanded(child: _buildServiceCard(Icons.adjust_rounded, "Ban & Velg", iconColor: const Color(0xFFB45309))), // brown/amber
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildServiceCard(Icons.handyman_rounded, "Rem &\nKopling", iconColor: const Color(0xFF64748B))), // slate
                    const SizedBox(width: 12),
                    Expanded(child: _buildServiceCard(Icons.speed_rounded, "Tune Up", iconColor: const Color(0xFFD946EF))), // fuchsia
                    const SizedBox(width: 12),
                    Expanded(child: _buildServiceCard(Icons.local_car_wash_rounded, "Cuci Mobil", iconColor: const Color(0xFF3B82F6))), // blue
                    const SizedBox(width: 12),
                    Expanded(child: _buildServiceCard(Icons.bolt_rounded, "Lainnya", iconColor: const Color(0xFFF59E0B))), // amber
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 28),
          
          // Promo Hari Ini Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Promo Hari Ini",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    "Semua >",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Promo Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildPromoCard(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3F355A), Color(0xFFE91E63)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  discount: "Diskon 50%",
                  title: "Ganti Oli Gratis Jasa",
                  subtitle: "Klaim sekarang →",
                ),
                const SizedBox(width: 16),
                _buildPromoCard(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  discount: "Diskon 30%",
                  title: "Tune Up Hemat",
                  subtitle: "Klaim sekarang →",
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 28),
          
          // Bengkel Terdekat Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bengkel Terdekat",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    "Lihat semua >",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Bengkel List Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildBengkelCard(
                  name: "Bengkel Jaya Motor",
                  type: "Mobil & Motor",
                  rating: "4.9",
                  reviewsCount: "234",
                  distance: "0.8 km",
                  isOpen: true,
                  isTopRated: true,
                ),
                const SizedBox(height: 12),
                _buildBengkelCard(
                  name: "Central Auto Service",
                  type: "Spesialis Rem & Oli",
                  rating: "4.8",
                  reviewsCount: "118",
                  distance: "1.5 km",
                  isOpen: true,
                  isTopRated: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- REUSABLE UI BUILDERS ---

  Widget _buildServiceCard(IconData icon, String label, {required Color iconColor}) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)), // slate 100
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155), // slate 700
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard({
    required Gradient gradient,
    required String discount,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: 260,
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              discount,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBengkelCard({
    required String name,
    required String type,
    required String rating,
    required String reviewsCount,
    required String distance,
    required bool isOpen,
    required bool isTopRated,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)), // slate 100
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Graphic container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.build_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isTopRated) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF), // blue 50
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Top Rated",
                          style: TextStyle(color: Color(0xFF2563EB), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.orange, size: 15),
                    const SizedBox(width: 2),
                    Text(
                      "$rating ($reviewsCount)",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "•",
                      style: TextStyle(color: Colors.grey.shade300),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.location_on_outlined, color: Colors.grey.shade400, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      distance,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "•",
                      style: TextStyle(color: Colors.grey.shade300),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOpen ? "Buka" : "Tutup",
                      style: TextStyle(
                        color: isOpen ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  bool _isMotor(String name) {
    final lower = name.toLowerCase();
    return lower.contains("honda beat") ||
        lower.contains("beat") ||
        lower.contains("vario") ||
        lower.contains("mio") ||
        lower.contains("nmax") ||
        lower.contains("scoopy") ||
        lower.contains("yamaha") ||
        lower.contains("motor") ||
        lower.contains("vespa") ||
        lower.contains("ninja");
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}