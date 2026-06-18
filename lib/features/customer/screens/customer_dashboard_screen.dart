import 'dart:convert';
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
  String? _selectedVehicleId;
  List<Map<String, dynamic>> _myVehicles = [];
  List<Map<String, dynamic>> _supabaseBengkels = [];
  bool _loadingBengkels = false;

  // Parse detail kendaraan secara aman (handle full schema / fallback JSON)
  Map<String, dynamic> _parseVehicle(Map<String, dynamic> v) {
    final nameVal = v['name'] as String? ?? '';
    if (nameVal.startsWith('{') && nameVal.endsWith('}')) {
      try {
        final decoded = jsonDecode(nameVal) as Map<String, dynamic>;
        return {
          'id': v['id']?.toString() ?? '',
          'user_id': v['user_id']?.toString() ?? '',
          'name': decoded['name'] ?? '${decoded['brand']} ${decoded['type']}',
          'brand': decoded['brand'] ?? '',
          'type': decoded['type'] ?? '',
          'year': decoded['year']?.toString() ?? '',
          'plate_number': decoded['plate_number'] ?? '',
          'is_active': decoded['is_active'] == true || v['is_active'] == true,
        };
      } catch (_) {}
    }
    return {
      'id': v['id']?.toString() ?? '',
      'user_id': v['user_id']?.toString() ?? '',
      'name': nameVal,
      'brand': v['brand'] as String? ?? '',
      'type': v['type'] as String? ?? nameVal,
      'year': v['year']?.toString() ?? '',
      'plate_number': v['plate_number'] as String? ?? '',
      'is_active': v['is_active'] == true,
    };
  }

  List<Map<String, dynamic>> get _parsedVehicles {
    return _myVehicles.map((v) => _parseVehicle(v)).toList();
  }

  Map<String, dynamic>? get _activeVehicle {
    final list = _parsedVehicles;
    if (list.isEmpty) return null;
    final index = list.indexWhere((v) => v['id'] == _selectedVehicleId);
    if (index >= 0) return list[index];
    final activeIndex = list.indexWhere((v) => v['is_active'] == true);
    if (activeIndex >= 0) return list[activeIndex];
    return list.first;
  }

  UserModel? _profileUser;
  // ignore: unused_field
  bool _isLoadingProfile = false;
  String _selectedOrderStatusFilter = "Semua";

  final List<Map<String, dynamic>> _allPromos = [
    {
      "discount": "Diskon 50%",
      "title": "Ganti Oli Gratis Jasa",
      "subtitle": "Klaim sekarang →",
      "colors": [const Color(0xFF3F355A), const Color(0xFFE91E63)],
      "supports": ["mobil", "motor"]
    },
    {
      "discount": "Diskon 30%",
      "title": "Tune Up Mobil Hemat",
      "subtitle": "Klaim sekarang →",
      "colors": [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      "supports": ["mobil"]
    },
    {
      "discount": "Diskon 25%",
      "title": "Upgrade CVT Matic",
      "subtitle": "Klaim sekarang →",
      "colors": [const Color(0xFF10B981), const Color(0xFF047857)],
      "supports": ["motor"]
    }
  ];

  @override
  void initState() {
    super.initState();
    _profileUser = widget.user;
    _fetchProfileFromSupabase();
    _fetchVehicles();
    _fetchBengkelsFromSupabase();
  }

  Future<void> _fetchBengkelsFromSupabase() async {
    if (!mounted) return;
    setState(() {
      _loadingBengkels = true;
    });
    try {
      final response = await Supabase.instance.client
          .from('bengkels')
          .select()
          .or('status.eq.active,status.eq.approved');
      
      final List<Map<String, dynamic>> fetched = [];
      for (var b in response) {
        final specList = (b['specialization'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        String typeDesc = "Umum";
        if (specList.contains("mobil") && specList.contains("motor")) {
          typeDesc = "Mobil & Motor";
        } else if (specList.contains("mobil")) {
          typeDesc = "Spesialis Mobil";
        } else if (specList.contains("motor")) {
          typeDesc = "Spesialis Motor";
        }

        fetched.add({
          "id": b['id']?.toString() ?? '',
          "name": b['name'] ?? 'Bengkel',
          "type": typeDesc,
          "rating": (b['rating'] ?? 4.5).toString(),
          "reviewsCount": b['review_count'] ?? 0,
          "distance": "1.2 km",
          "isOpen": _checkIfOpen(b['open_hour'], b['close_hour']),
          "isTopRated": (b['rating'] ?? 0.0) >= 4.7,
          "supports": specList.isEmpty ? ["mobil", "motor"] : specList,
          "description": b['description'] ?? 'Bengkel terpercaya dengan layanan prima.',
          "image": b['image_url'] ?? 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=500',
          "reviews": [],
          "open_hour": b['open_hour'] ?? '08:00',
          "close_hour": b['close_hour'] ?? '17:00',
          "phone": b['phone'] ?? '',
        });
      }

      if (mounted) {
        setState(() {
          _supabaseBengkels = fetched;
        });
      }
    } catch (e) {
      print("🚨 DEBUG ERROR: Gagal fetch bengkels di dashboard: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loadingBengkels = false;
        });
      }
    }
  }

  bool _checkIfOpen(String? openHour, String? closeHour) {
    try {
      if (openHour == null || closeHour == null) return true;
      final now = TimeOfDay.now();
      final openParts = openHour.split(':');
      final closeParts = closeHour.split(':');
      if (openParts.length < 2 || closeParts.length < 2) return true;
      final openMin = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      final closeMin = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
      final nowMin = now.hour * 60 + now.minute;
      return nowMin >= openMin && nowMin <= closeMin;
    } catch (_) {
      return true;
    }
  }

  bool _isBengkelCompatible(Map<String, dynamic> bengkel) {
    final active = _activeVehicle;
    if (active == null) return true;
    final activeName = active['name'] as String? ?? '';
    final activeIsMotor = _isMotor(activeName);
    final supports = bengkel['supports'] as List<dynamic>? ?? [];
    if (activeIsMotor) {
      return supports.contains("motor");
    } else {
      return supports.contains("mobil");
    }
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
          // Set selected vehicle ID if empty or not valid
          final list = _parsedVehicles;
          if (list.isNotEmpty) {
            final ids = list.map((v) => v['id'] as String).toList();
            if (_selectedVehicleId == null || !ids.contains(_selectedVehicleId)) {
              final activeItem = list.firstWhere((v) => v['is_active'] == true, orElse: () => list.first);
              _selectedVehicleId = activeItem['id'];
            }
          } else {
            _selectedVehicleId = null;
          }
        });
      }
    } catch (e) {
      print("🚨 DEBUG ERROR: Gagal fetch kendaraan dari Supabase: $e");
    }
  }

  // Insert a new vehicle to Supabase under current user
  Future<void> _addVehicle({
    required String brand,
    required String type,
    required String year,
    required String plateNumber,
    bool isActive = false,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final name = "$brand $type";
    
    // Coba insert skema penuh terlebih dahulu
    final fullData = {
      'user_id': userId,
      'brand': brand,
      'type': type,
      'year': int.tryParse(year) ?? 0,
      'plate_number': plateNumber,
      'is_active': isActive,
      'name': name,
    };

    try {
      await Supabase.instance.client.from('vehicles').insert(fullData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Berhasil menambahkan kendaraan: $name"),
            backgroundColor: const Color(0xFF10B981), // Emerald 500
          ),
        );
      }
      _fetchVehicles();
    } catch (e) {
      print("🚨 DB WARN: Gagal insert skema penuh, mencoba fallback JSON ke name: $e");
      try {
        final fallbackDetails = {
          'brand': brand,
          'type': type,
          'year': year,
          'plate_number': plateNumber,
          'is_active': isActive,
          'name': name,
        };
        await Supabase.instance.client.from('vehicles').insert({
          'user_id': userId,
          'name': jsonEncode(fallbackDetails),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Berhasil menambahkan kendaraan (fallback): $name"),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
        _fetchVehicles();
      } catch (err) {
        print("🚨 DB ERROR: Gagal menyimpan kendaraan (fallback): $err");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal menyimpan kendaraan: $err"),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  // Update kendaraan aktif
  Future<void> _updateActiveVehicle(String vehicleId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final _ = _parsedVehicles;
      for (var v in _myVehicles) {
        final isTarget = v['id'] == vehicleId;
        final nameVal = v['name'] as String? ?? '';
        
        if (nameVal.startsWith('{') && nameVal.endsWith('}')) {
          try {
            final decoded = jsonDecode(nameVal) as Map<String, dynamic>;
            decoded['is_active'] = isTarget;
            await Supabase.instance.client.from('vehicles').update({
              'name': jsonEncode(decoded),
            }).eq('id', v['id']);
          } catch (_) {}
        } else {
          try {
            await Supabase.instance.client.from('vehicles').update({
              'is_active': isTarget,
            }).eq('id', v['id']);
          } catch (_) {
            final fallbackDetails = {
              'brand': v['brand'] ?? '',
              'type': v['type'] ?? nameVal,
              'year': v['year']?.toString() ?? '',
              'plate_number': v['plate_number'] ?? '',
              'is_active': isTarget,
              'name': nameVal,
            };
            await Supabase.instance.client.from('vehicles').update({
              'name': jsonEncode(fallbackDetails),
            }).eq('id', v['id']);
          }
        }
      }
      setState(() {
        _selectedVehicleId = vehicleId;
      });
      _fetchVehicles();
    } catch (e) {
      print("🚨 DEBUG ERROR: Gagal update kendaraan aktif: $e");
    }
  }

  // Dialog to type in vehicle name
  void _showAddVehicleDialog() {
    final TextEditingController brandController = TextEditingController();
    final TextEditingController typeController = TextEditingController();
    final TextEditingController yearController = TextEditingController();
    final TextEditingController plateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF334155))),
          title: const Text(
            "Tambah Kendaraan Baru",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Isi detail profil kendaraan Anda di bawah ini.",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: brandController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration("Merek (cth: Toyota, Honda)"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: typeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration("Tipe (cth: Avanza, Vario)"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: yearController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration("Tahun (cth: 2021)"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: plateController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration("Plat Nomor (cth: D 1234 ABC)"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                final brand = brandController.text.trim();
                final type = typeController.text.trim();
                final year = yearController.text.trim();
                final plate = plateController.text.trim();
                if (brand.isNotEmpty && type.isNotEmpty) {
                  Navigator.pop(context);
                  _addVehicle(
                    brand: brand,
                    type: type,
                    year: year,
                    plateNumber: plate,
                    isActive: _parsedVehicles.isEmpty, // set active if first vehicle
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicleData = _activeVehicle;
    return Scaffold(
      backgroundColor: _selectedIndex == 3 ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          CustomerSparepartScreen(
            activeVehicle: activeVehicleData,
            onTabChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
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
            activeVehicle: activeVehicleData,
            onOrderStatusSelected: (int tabIndex, String statusFilter) {
              setState(() {
                _selectedIndex = tabIndex == 4 ? 3 : (tabIndex == 3 ? 2 : tabIndex);
                _selectedOrderStatusFilter = statusFilter;
              });
            },
            onVehiclesChanged: () {
              _fetchVehicles();
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index != 2) {
              _selectedOrderStatusFilter = "Semua"; // Reset order filter when changing tabs
            }
          });
          if (index == 0) {
            _fetchProfileFromSupabase(); // Refresh greeting name on home tab
            _fetchVehicles(); // Refresh user vehicles from Supabase
            _fetchBengkelsFromSupabase(); // Refresh workshops list
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _selectedIndex == 3 ? const Color(0xFF3B82F6) : const Color(0xFF0F172A),
        unselectedItemColor: const Color(0xFF94A3B8), // slate 400
        backgroundColor: _selectedIndex == 3 ? const Color(0xFF1F2937) : Colors.white,
        elevation: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag_rounded),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Active Vehicle Selector Card helper
  Widget _buildVehicleSelectorCard(Map<String, dynamic>? activeVehicle) {
    return PopupMenuButton<Map<String, dynamic>>(
      initialValue: activeVehicle,
      onSelected: (Map<String, dynamic> value) {
        if (value['id'] == "add") {
          _showAddVehicleDialog();
        } else {
          _updateActiveVehicle(value['id']);
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      offset: const Offset(0, 50),
      elevation: 4,
      itemBuilder: (BuildContext context) {
        final list = _parsedVehicles;
        final List<PopupMenuEntry<Map<String, dynamic>>> items = list.map((Map<String, dynamic> v) {
          final isMotorBike = _isMotor(v['name'] as String);
          return PopupMenuItem<Map<String, dynamic>>(
            value: v,
            child: Row(
              children: [
                Text(
                  isMotorBike ? "🏍️" : "🚗",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        v['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                        ),
                      ),
                      if ((v['plate_number'] as String).isNotEmpty)
                        Text(
                          v['plate_number'] as String,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                if (v['id'] == _selectedVehicleId)
                  const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 16),
              ],
            ),
          );
        }).toList();

        items.add(
          PopupMenuItem<Map<String, dynamic>>(
            value: const {'id': 'add', 'name': '+ Tambah Kendaraan'},
            child: Row(
              children: const [
                Text("➕", style: TextStyle(fontSize: 14)),
                SizedBox(width: 10),
                Text(
                  "Tambah Kendaraan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );

        return items;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                activeVehicle == null
                    ? Icons.directions_car_filled_rounded
                    : (_isMotor(activeVehicle['name'] as String)
                        ? Icons.motorcycle_rounded
                        : Icons.directions_car_filled_rounded),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeVehicle == null ? "Toyota Avanza" : (activeVehicle['name'] as String),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeVehicle == null ? "B 1234 XYZ" : (activeVehicle['plate_number'] as String),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: BERANDA ---
  Widget _buildHomeTab() {
    final activeVehicleData = _activeVehicle;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Background (Dark slate blue with gradient)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1E3A8A), // Deep blue
                  Color(0xFF0F172A), // Slate 900
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome greeting + Bell icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome back!",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Bengkelin",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      // Bell notification icon with badge
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                            Positioned(
                              right: 1,
                              top: 1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Active Vehicle Selector Card
                  _buildVehicleSelectorCard(activeVehicleData),
                  const SizedBox(height: 20),

                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search_rounded, color: Colors.grey),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search workshops, services, parts...",
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // 4 Horizontal Quick Actions Cards (Service, Parts, Nearby, Promo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    Icons.build_outlined,
                    "Service",
                    const Color(0xFF3B82F6),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerBengkelScreen(activeVehicle: activeVehicleData),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    Icons.widgets_outlined,
                    "Parts",
                    const Color(0xFF6366F1),
                    () {
                      setState(() {
                        _selectedIndex = 1; // Open Marketplace
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    Icons.location_on_outlined,
                    "Nearby",
                    const Color(0xFF10B981),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerBengkelScreen(activeVehicle: activeVehicleData),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    Icons.trending_up_outlined,
                    "Promo",
                    const Color(0xFFF59E0B),
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Menampilkan Promo Hari Ini")),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 28),
          
          // Nearby Workshops Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Nearby Workshops",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerBengkelScreen(activeVehicle: activeVehicleData),
                      ),
                    );
                  },
                  child: const Text(
                    "See All",
                    style: TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nearby Workshops list cards matching Image 1
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _loadingBengkels
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _supabaseBengkels.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "Tidak ada bengkel terdaftar.",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ),
                      )
                    : Column(
                        children: _supabaseBengkels
                            .where((b) => _isBengkelCompatible(b))
                            .map((b) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildNearbyWorkshopCard(
                              name: b['name'],
                              rating: b['rating'],
                              reviewsCount: b['reviewsCount'].toString(),
                              distance: b['distance'],
                              address: b['address'] ?? 'Alamat Bengkel',
                              imageUrl: b['image'] ?? 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=500',
                              tags: List<String>.from(b['supports'] ?? []),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerBengkelScreen(
                                      activeVehicle: activeVehicleData,
                                      initialBengkel: b,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Quick Action Card Builder
  Widget _buildQuickActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nearby Workshop Card Builder
  Widget _buildNearbyWorkshopCard({
    required String name,
    required String rating,
    required String reviewsCount,
    required String distance,
    required String address,
    required String imageUrl,
    required List<String> tags,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 76,
                  height: 76,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF94A3B8), size: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 14),
                      Text(
                        " $rating ($reviewsCount)  •  $distance",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: Colors.grey.shade400, size: 12),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
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
}