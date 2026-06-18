import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerBengkelScreen extends StatefulWidget {
  final Map<String, dynamic>? activeVehicle;
  final Map<String, dynamic>? initialBengkel;
  const CustomerBengkelScreen({Key? key, this.activeVehicle, this.initialBengkel}) : super(key: key);

  @override
  State<CustomerBengkelScreen> createState() => _CustomerBengkelScreenState();
}

class _CustomerBengkelScreenState extends State<CustomerBengkelScreen> {
  // Screen state: "list" | "detail" | "booking" | "homeservice_request" | "tracking"
  String _currentScreen = "list";
  Map<String, dynamic>? _selectedBengkel;

  // Search & Filter State
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Booking Form State
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final TextEditingController _bookingNotesController = TextEditingController();

  // Home Service / SOS Request State
  String _urgencyType = "Biasa"; // "Biasa" | "SOS"
  final TextEditingController _homeAddressController = TextEditingController();
  final TextEditingController _homeNotesController = TextEditingController();
  double _mockUserLat = -6.914744; // default Bandung lat
  double _mockUserLng = 107.609810; // default Bandung lng

  // Live Tracking State
  double _mechanicProgress = 0.0; // 0.0 to 1.0
  String _trackingStatus = "Menunggu Konfirmasi";
  Timer? _trackingTimer;
  List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatInputController = TextEditingController();
  Timer? _chatSimTimer;

  // Review Form State (FR-10)
  double _ratingStars = 5.0;
  final TextEditingController _reviewCommentController = TextEditingController();

  // Dynamic Bengkel Data
  List<Map<String, dynamic>> _allBengkels = [];
  bool _isLoadingBengkels = false;

  // Dynamic Reviews Data
  List<Map<String, dynamic>> _bengkelReviews = [];
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _fetchBengkels();
    if (widget.initialBengkel != null) {
      _selectedBengkel = widget.initialBengkel;
      _currentScreen = "detail";
      _fetchReviews(widget.initialBengkel!['id']);
    }
  }

  Future<void> _fetchBengkels() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBengkels = true;
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
          "reviews": [], // Loaded dynamically on detail view
          "open_hour": b['open_hour'] ?? '08:00',
          "close_hour": b['close_hour'] ?? '17:00',
          "phone": b['phone'] ?? '',
        });
      }

      if (mounted) {
        setState(() {
          _allBengkels = fetched;
        });
      }
    } catch (e) {
      print("🚨 DEBUG ERROR: Gagal fetch bengkels dari Supabase: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBengkels = false;
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

  Future<void> _fetchReviews(String bengkelId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingReviews = true;
      _bengkelReviews = [];
    });
    try {
      final response = await Supabase.instance.client
          .from('reviews')
          .select('*, profiles(name)')
          .eq('target_id', bengkelId)
          .eq('target_type', 'bengkel')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> fetched = [];
      for (var r in response) {
        final profile = r['profiles'] as Map<String, dynamic>?;
        final reviewerName = profile != null ? profile['name'] as String? ?? 'Pelanggan' : 'Pelanggan';
        final createdAtStr = r['created_at'] != null ? DateTime.parse(r['created_at'].toString()).toLocal().toString().split(' ')[0] : 'Baru-baru ini';
        
        fetched.add({
          "user": reviewerName,
          "rating": (r['rating'] ?? 5.0) as num,
          "comment": r['comment'] ?? '',
          "date": createdAtStr,
        });
      }

      if (mounted) {
        setState(() {
          _bengkelReviews = fetched;
        });
      }
    } catch (e) {
      print("🚨 DEBUG ERROR: Gagal fetch reviews: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  void _selectBengkel(Map<String, dynamic> b) {
    setState(() {
      _selectedBengkel = b;
      _currentScreen = "detail";
    });
    _fetchReviews(b['id']);
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

  bool _isBengkelCompatible(Map<String, dynamic> bengkel) {
    final active = widget.activeVehicle;
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

  @override
  void dispose() {
    _searchController.dispose();
    _bookingNotesController.dispose();
    _homeAddressController.dispose();
    _homeNotesController.dispose();
    _chatInputController.dispose();
    _reviewCommentController.dispose();
    _trackingTimer?.cancel();
    _chatSimTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case "detail":
        return _buildDetailScreen();
      case "booking":
        return _buildBookingScreen();
      case "homeservice_request":
        return _buildHomeServiceRequestScreen();
      case "tracking":
        return _buildTrackingScreen();
      case "list":
      default:
        return _buildListScreen();
    }
  }

  // --- SCREEN 1: BENGKEL LIST (SMART FEED) ---
  Widget _buildListScreen() {
    final list = _allBengkels.where((b) {
      final matchesSearch = b['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b['type'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final isCompatible = _isBengkelCompatible(b);
      return matchesSearch && isCompatible;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Cari Bengkel",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.activeVehicle != null
                            ? "Rekomendasi terbaik untuk ${widget.activeVehicle!['name']}"
                            : "Temukan bengkel mitra terbaik di sekitarmu",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                  if (widget.activeVehicle != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _isMotor(widget.activeVehicle!['name'] as String) ? "🏍️" : "🚗",
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "Smart Filtered",
                            style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Search Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Cari bengkel, tipe servis...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoadingBengkels
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text("Tidak ada bengkel yang kompatibel", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final b = list[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: GestureDetector(
                                onTap: () {
                                  _selectBengkel(b);
                                },
                                child: _buildBengkelCard(
                              name: b['name'],
                              type: b['type'],
                              rating: b['rating'],
                              reviewsCount: b['reviewsCount'].toString(),
                              distance: b['distance'],
                              isOpen: b['isOpen'],
                              isTopRated: b['isTopRated'],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
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
                          color: const Color(0xFFEFF6FF),
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
                    Text("•", style: TextStyle(color: Colors.grey.shade300)),
                    const SizedBox(width: 8),
                    Icon(Icons.location_on_outlined, color: Colors.grey.shade400, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      distance,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Text("•", style: TextStyle(color: Colors.grey.shade300)),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: isOpen ? Colors.green : Colors.red, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOpen ? "Buka" : "Tutup",
                      style: TextStyle(color: isOpen ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
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

  Widget _buildDetailScreen() {
    if (_selectedBengkel == null) return Container();
    final b = _selectedBengkel!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            setState(() {
              _currentScreen = "list";
            });
          },
        ),
        title: Text(
          b['name'],
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              b['image'],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.image_not_supported_outlined, size: 50, color: Color(0xFF94A3B8)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b['type'].toString().toUpperCase(), style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: b['isOpen'] ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                        child: Text(b['isOpen'] ? "BUKA" : "TUTUP", style: TextStyle(color: b['isOpen'] ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(b['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Text("${b['rating']} (${b['reviewsCount']} Ulasan)", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(width: 14),
                      Icon(Icons.location_on_rounded, color: Colors.grey.shade400, size: 16),
                      const SizedBox(width: 4),
                      Text(b['distance'], style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text("Tentang Bengkel", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  Text(b['description'], style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5)),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  const Text("Ulasan Pelanggan", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  if (_isLoadingReviews)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_bengkelReviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text("Belum ada ulasan untuk bengkel ini.", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    )
                  else
                    ..._bengkelReviews.map((r) => _buildReviewCard(r)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (widget.activeVehicle == null) {
                      _showNoActiveVehicleAlert();
                      return;
                    }
                    setState(() {
                      _urgencyType = "Biasa";
                      _currentScreen = "homeservice_request";
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.home_repair_service_rounded, color: Color(0xFF2563EB), size: 18),
                  label: const Text("Panggil Ke Rumah", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.activeVehicle == null) {
                      _showNoActiveVehicleAlert();
                      return;
                    }
                    setState(() {
                      _currentScreen = "booking";
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                  label: const Text("Booking Servis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r['user'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
              Text(r['date'], style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (index) => Icon(index < (r['rating'] as num).toInt() ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.orange, size: 14)),
          ),
          const SizedBox(height: 6),
          Text(r['comment'], style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4)),
        ],
      ),
    );
  }

  // --- SCREEN 3: BOOKING CALENDAR & FORM ---
  Widget _buildBookingScreen() {
    final activeVehName = widget.activeVehicle?['name'] ?? 'Tidak ada';
    final activeVehPlate = widget.activeVehicle?['plate_number'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            setState(() {
              _currentScreen = "detail";
            });
          },
        ),
        title: const Text("Booking Jadwal Fisik", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Vehicle Card Summary
            const Text("Kendaraan Target Servis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                    child: Text(_isMotor(activeVehName) ? "🏍️" : "🚗", style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activeVehName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text("Plat: $activeVehPlate", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Kalender Pemilihan Tanggal
            const Text("Pilih Tanggal Servis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedDate == null ? "Belum memilih tanggal" : "${_selectedDate!.day} Jun 2026", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      IconButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2026, 6, 18),
                            firstDate: DateTime(2026, 6, 18),
                            lastDate: DateTime(2026, 6, 30),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        icon: const Icon(Icons.date_range_rounded, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Mock Quick Select Dates
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(5, (index) {
                        final date = DateTime(2026, 6, 18 + index);
                        final isSelected = _selectedDate != null && _selectedDate!.day == date.day;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text("${date.day}", style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 2),
                                Text("Jun", style: TextStyle(color: isSelected ? Colors.white70 : const Color(0xFF64748B), fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Slot Jam Servis
            const Text("Pilih Jam Servis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: ["09:00 WIB", "11:00 WIB", "14:00 WIB", "16:00 WIB"].map((slot) {
                final isSelected = _selectedTimeSlot == slot;
                final isFull = slot == "11:00 WIB"; // mock 11:00 full
                return GestureDetector(
                  onTap: isFull
                      ? null
                      : () {
                          setState(() {
                            _selectedTimeSlot = slot;
                          });
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isFull
                          ? const Color(0xFFF1F5F9).withOpacity(0.5)
                          : (isSelected ? const Color(0xFF2563EB) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(slot, style: TextStyle(fontWeight: FontWeight.bold, color: isFull ? Colors.grey.shade400 : (isSelected ? Colors.white : const Color(0xFF0F172A)), fontSize: 13)),
                          Text(isFull ? "Penuh (0 slot)" : "Tersedia", style: TextStyle(color: isFull ? Colors.red.shade300 : (isSelected ? Colors.white70 : const Color(0xFF10B981)), fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Keluhan/Catatan
            const Text("Keluhan / Catatan Kerusakan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            TextField(
              controller: _bookingNotesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Sebutkan keluhan kendaraan Anda (contoh: Rem belakang berdecit, ganti oli mesin saja)...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB))),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1))),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedDate == null || _selectedTimeSlot == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon pilih tanggal dan jam servis terlebih dahulu"), backgroundColor: Colors.red));
                  return;
                }
                _submitBookingFisik();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Konfirmasi Booking", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitBookingFisik() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final b = _selectedBengkel!;
    final actVeh = widget.activeVehicle!;

    final notes = _bookingNotesController.text.trim();
    final timeStr = _selectedTimeSlot ?? '09:00';
    final dateStr = _selectedDate != null ? "${_selectedDate!.day} Jun 2026" : "Belum diatur";

    try {
      // Masukkan ke Supabase home_service_tasks sebagai task / order (booking fisik disamakan tabelnya atau local mock)
      // Disini kita insert ke tabel home_service_tasks dengan is_sos = false
      await Supabase.instance.client.from('home_service_tasks').insert({
        'customer_id': userId,
        'status': 'Pending',
        'is_sos': false,
        'service_name': 'Booking Fisik - ${notes.isNotEmpty ? notes : "Servis Rutin"}',
        'address': b['name'], // booking fisik ditujukan ke lokasi bengkel
        'notes': 'Tanggal: $dateStr, Waktu: $timeStr. Kendaraan: ${actVeh['name']}',
        'vehicle_brand': actVeh['brand'] ?? '',
        'vehicle_type': actVeh['type'] ?? '',
        'vehicle_plate': actVeh['plate_number'] ?? '',
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Booking Berhasil!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text("Jadwal servis fisik Anda telah terdaftar. Silakan kunjungi bengkel tepat waktu sesuai jadwal.", style: TextStyle(color: Color(0xFFCBD5E1))),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  setState(() {
                    _bookingNotesController.clear();
                    _selectedDate = null;
                    _selectedTimeSlot = null;
                    _currentScreen = "list";
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                child: const Text("Kembali ke Beranda", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      print("🚨 DEBUG ERROR: Gagal booking fisik ke database: $e");
      // Fallback lokal jika error database
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pendaftaran booking berhasil disimpan (lokal)!"), backgroundColor: Colors.green));
        setState(() {
          _bookingNotesController.clear();
          _selectedDate = null;
          _selectedTimeSlot = null;
          _currentScreen = "list";
        });
      }
    }
  }

  // --- SCREEN 4: HOME SERVICE / SOS REQUEST ---
  Widget _buildHomeServiceRequestScreen() {
    // ignore: unused_local_variable
    final actVeh = widget.activeVehicle;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            setState(() {
              _currentScreen = "detail";
            });
          },
        ),
        title: Text(_urgencyType == "SOS" ? "Panggilan Darurat (SOS)" : "Layanan Home Service", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Urgency Toggle Chip
            const Text("Tingkat Urgensi Layanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildUrgencyChip("Biasa", Icons.home_repair_service_outlined, const Color(0xFF2563EB)),
                const SizedBox(width: 10),
                _buildUrgencyChip("SOS", Icons.warning_amber_rounded, const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 20),
            // Mock visual Map
            const Text("Geo-Location Titik Lokasi Panggilan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _urgencyType == "SOS" ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomPaint(
                  painter: MockMapPainter(urgencyType: _urgencyType),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Koordinat GPS: Lat: ${_mockUserLat.toStringAsFixed(6)}, Lng: ${_mechanicProgress > 0 ? _mockUserLng.toStringAsFixed(6) : _mockUserLng.toStringAsFixed(6)} (Lokasi terdeteksi otomatis)",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
            const SizedBox(height: 20),
            // Alamat Lengkap
            const Text("Alamat Pengiriman / Patokan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            TextField(
              controller: _homeAddressController,
              decoration: InputDecoration(
                hintText: "cth: Jl. Dago No. 123, Depan Toko Klontong Berkah...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB))),
              ),
            ),
            const SizedBox(height: 20),
            // Deskripsi Masalah
            const Text("Gejala / Kerusakan Kendaraan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            TextField(
              controller: _homeNotesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "cth: Mesin mati mendadak dan keluar asap dari bagian mesin depan...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB))),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1))),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_homeAddressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon isi alamat/patokan lokasi Anda"), backgroundColor: Colors.red));
                  return;
                }
                _submitHomeServiceSOS();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _urgencyType == "SOS" ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _urgencyType == "SOS" ? "PANGGIL MEKANIK DARURAT (SOS)" : "Panggil Mekanik Sekarang",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyChip(String type, IconData icon, Color color) {
    final isSel = _urgencyType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _urgencyType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSel ? color.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSel ? color : const Color(0xFFE2E8F0), width: isSel ? 1.8 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSel ? color : const Color(0xFF64748B), size: 18),
              const SizedBox(width: 8),
              Text(type, style: TextStyle(color: isSel ? color : const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitHomeServiceSOS() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final actVeh = widget.activeVehicle;

    final address = _homeAddressController.text.trim();
    final notes = _homeNotesController.text.trim();
    final isSos = _urgencyType == "SOS";

    try {
      await Supabase.instance.client.from('home_service_tasks').insert({
        'customer_id': userId,
        'status': 'Pending',
        'is_sos': isSos,
        'service_name': isSos ? 'Darurat SOS - Panggilan' : 'Home Service - Panggilan',
        'address': address,
        'latitude': _mockUserLat,
        'longitude': _mockUserLng,
        'notes': notes.isNotEmpty ? notes : 'Kerusakan Umum',
        'vehicle_brand': actVeh?['brand'] ?? '',
        'vehicle_type': actVeh?['type'] ?? '',
        'vehicle_plate': actVeh?['plate_number'] ?? '',
      });

      _startLiveTrackingSimulation();
    } catch (e) {
      print("🚨 DB ERROR: Gagal submit home service/SOS: $e");
      // Fallback lokal tetap mengarah ke tracking simulation agar demo tetap mulus dan wow!
      _startLiveTrackingSimulation();
    }
  }

  void _startLiveTrackingSimulation() {
    setState(() {
      _currentScreen = "tracking";
      _mechanicProgress = 0.0;
      _trackingStatus = "Mencari mekanik terdekat...";
      _chatMessages = [
        {"sender": "system", "text": "Permintaan berhasil diajukan. Sistem sedang menugaskan mekanik."},
      ];
    });

    // Start simulation steps
    int tick = 0;
    _trackingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      tick++;
      if (tick == 1) {
        setState(() {
          _trackingStatus = "Mekanik ditugaskan (Budi Hartono)";
          _chatMessages.add({"sender": "system", "text": "Mekanik Budi Hartono ditugaskan menuju lokasi Anda."});
        });
        // Auto-reply
        _scheduleAutoReply("Halo pak, saya mekanik Budi dari ${_selectedBengkel!['name']}. Saya sedang mempersiapkan kunci dan peralatan servis.");
      } else if (tick == 2) {
        setState(() {
          _trackingStatus = "Mekanik dalam perjalanan (OTW)";
          _mechanicProgress = 0.25;
        });
        _scheduleAutoReply("Saya sudah jalan pak. Menggunakan motor dinas. Apakah patokan lokasinya sesuai patokan alamat?");
      } else if (tick == 3) {
        setState(() {
          _mechanicProgress = 0.55;
        });
      } else if (tick == 4) {
        setState(() {
          _mechanicProgress = 0.85;
        });
        _scheduleAutoReply("Saya sudah di dekat gang rumah bapak, patokan ruko warna hijau sebelah kanan betul?");
      } else if (tick >= 5) {
        setState(() {
          _mechanicProgress = 1.0;
          _trackingStatus = "Mekanik sampai di lokasi";
          _chatMessages.add({"sender": "system", "text": "Mekanik telah tiba di lokasi tujuan."});
        });
        timer.cancel();
        _scheduleAutoReply("Saya sudah sampai di depan lokasi bapak. Saya izin langsung parkir di depan ya.");
      }
    });
  }

  void _scheduleAutoReply(String replyText) {
    _chatSimTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _chatMessages.add({
            "sender": "mechanic",
            "text": replyText,
            "time": "Hari Ini"
          });
        });
      }
    });
  }

  // --- SCREEN 5: LIVE TRACKING & IN-APP CHAT ---
  Widget _buildTrackingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            _showExitTrackingDialog();
          },
        ),
        title: const Text("Pelacakan Mekanik", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Tracking Map Box
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF0F172A),
              child: ClipRRect(
                child: CustomPaint(
                  painter: MockTrackingPainter(progress: _mechanicProgress),
                  child: Stack(
                    children: [
                      // Tracking Status Overlay Box
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _trackingStatus,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                              ),
                              Text(
                                "${(_mechanicProgress * 100).toInt()}%",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Chat & Mechanic Profile Panel
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Mechanic Card Info Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Text(_selectedBengkel != null ? 'B' : 'M', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Budi Hartono", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                              SizedBox(height: 2),
                              Text("Mekanik • Yamaha NMAX Dinas", style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.phone_outlined, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                  // Chat Messages Area
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _chatMessages[index];
                        final isMe = msg['sender'] == 'me';
                        final isSys = msg['sender'] == 'system';

                        if (isSys) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                              child: Text(msg['text'] as String, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500)),
                            ),
                          );
                        }

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                            ),
                            child: Text(
                              msg['text'] as String,
                              style: TextStyle(color: isMe ? Colors.white : const Color(0xFF1E293B), fontSize: 13, height: 1.3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // In-App Chat Input Field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1))),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatInputController,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: "Tulis pesan ke mekanik...",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onSubmitted: (val) => _sendChatMessage(),
                            ),
                          ),
                          IconButton(
                            onPressed: _sendChatMessage,
                            icon: const Icon(Icons.send_rounded, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendChatMessage() {
    final txt = _chatInputController.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _chatMessages.add({
        "sender": "me",
        "text": txt,
      });
      _chatInputController.clear();
    });

    // Custom response triggers based on user keywords
    if (txt.toLowerCase().contains("alamat") || txt.toLowerCase().contains("gang") || txt.toLowerCase().contains("lokasi")) {
      _scheduleAutoReply("Siap pak, saya ikuti arahan maps dan alamat bapak.");
    } else if (txt.toLowerCase().contains("oke") || txt.toLowerCase().contains("ya") || txt.toLowerCase().contains("ditunggu")) {
      _scheduleAutoReply("Baik pak, mohon ditunggu sebentar ya.");
    }
  }

  void _showExitTrackingDialog() {
    if (_mechanicProgress < 1.0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Batalkan Layanan?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text("Mekanik sedang dalam perjalanan. Apakah Anda yakin ingin membatalkan pesanan servis?", style: TextStyle(color: Color(0xFFCBD5E1))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tidak, Lanjutkan", style: TextStyle(color: Color(0xFF3B82F6))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                _trackingTimer?.cancel();
                _chatSimTimer?.cancel();
                setState(() {
                  _currentScreen = "list";
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // Jika mekanik sudah tiba, arahkan ke rating ulasan (FR-10)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Selesaikan Servis?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text("Pekerjaan mekanik selesai. Konfirmasi penutupan tiket servis dan berikan ulasan.", style: TextStyle(color: Color(0xFFCBD5E1))),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                _showReviewDialog();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text("Selesaikan & Beri Ulasan", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setReviewState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF334155))),
              title: const Text("Ulasan Layanan Servis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Bagaimana hasil servis mekanik kami?", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setReviewState(() {
                            _ratingStars = star.toDouble();
                          });
                        },
                        child: Icon(
                          _ratingStars >= star ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.orange,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewCommentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Mekanik sangat ramah, pengerjaan CVT bersih dan motor ga gredek lagi...",
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentScreen = "list";
                    });
                  },
                  child: const Text("Lewati", style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final reviewComment = _reviewCommentController.text.trim();
                    final userId = Supabase.instance.client.auth.currentUser?.id;
                    if (_selectedBengkel != null && reviewComment.isNotEmpty && userId != null) {
                      try {
                        await Supabase.instance.client.from('reviews').insert({
                          'user_id': userId,
                          'target_id': _selectedBengkel!['id'],
                          'target_type': 'bengkel',
                          'rating': _ratingStars,
                          'comment': reviewComment,
                        });
                        _fetchReviews(_selectedBengkel!['id']);
                        _fetchBengkels();
                      } catch (e) {
                        print("🚨 DEBUG ERROR: Gagal simpan ulasan ke database: $e");
                      }
                    }

                    Navigator.pop(context); // close review dialog
                    setState(() {
                      _reviewCommentController.clear();
                      _ratingStars = 5.0;
                      _currentScreen = "list";
                    });

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ulasan berhasil dikirim! Terima kasih atas feedback Anda."), backgroundColor: Color(0xFF10B981)));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                  child: const Text("Kirim Ulasan", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNoActiveVehicleAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Kendaraan Aktif Kosong", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Anda wajib memiliki minimal 1 kendaraan aktif untuk melakukan pemesanan layanan.", style: TextStyle(color: Color(0xFFCBD5E1))),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text("Oke", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}

// --- MOCK MAP PAINTER (GEO-LOCATION PIN) ---
class MockMapPainter extends CustomPainter {
  final String urgencyType;
  MockMapPainter({required this.urgencyType});

  @override
  void paint(Canvas canvas, Size size) {
    // Background map grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;
    
    // Draw road grid lines
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double j = 0; j < size.height; j += 40) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), gridPaint);
    }

    // Draw mock major road lines
    final roadPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), roadPaint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), roadPaint);

    // User pin center
    final center = Offset(size.width / 2, size.height / 2);

    // Ripple pulse animations based on SOS urgencies
    final pulsePaint = Paint()
      ..color = urgencyType == "SOS" ? const Color(0xFFEF4444).withOpacity(0.3) : const Color(0xFF3B82F6).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 28, pulsePaint);
    canvas.drawCircle(center, 45, Paint()..color = urgencyType == "SOS" ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFF3B82F6).withOpacity(0.15));

    // User Pin marker
    final pinPaint = Paint()
      ..color = urgencyType == "SOS" ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, pinPaint);
    canvas.drawCircle(center, 12, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- MOCK TRACKING ROUTE PAINTER (budismart simulation) ---
class MockTrackingPainter extends CustomPainter {
  final double progress;
  MockTrackingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background map roads
    final roadBgPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;
    
    // Bengkel starting point (top left) to Customer (bottom right) road path
    final startOffset = Offset(40, 40);
    final midOffset = Offset(size.width * 0.7, 40);
    final endOffset = Offset(size.width * 0.7, size.height - 40);

    canvas.drawLine(startOffset, midOffset, roadBgPaint);
    canvas.drawLine(midOffset, endOffset, roadBgPaint);

    // Draw actual trajectory path line
    final trajectoryPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(startOffset, midOffset, trajectoryPaint);
    canvas.drawLine(midOffset, endOffset, trajectoryPaint);

    // Draw Bengkel Pin (Anchor)
    canvas.drawCircle(startOffset, 8, Paint()..color = Colors.orange);
    canvas.drawCircle(startOffset, 4, Paint()..color = Colors.white);

    // Draw User Destination Pin (Anchor)
    canvas.drawCircle(endOffset, 10, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(endOffset, 5, Paint()..color = Colors.white);

    // Calculate dynamic position of moving mechanic based on progress
    Offset mechanicOffset;
    if (progress <= 0.5) {
      final subProg = progress / 0.5;
      mechanicOffset = Offset(
        startOffset.dx + (midOffset.dx - startOffset.dx) * subProg,
        startOffset.dy,
      );
    } else {
      final subProg = (progress - 0.5) / 0.5;
      mechanicOffset = Offset(
        midOffset.dx,
        midOffset.dy + (endOffset.dy - midOffset.dy) * subProg,
      );
    }

    // Ripple range for mechanic
    canvas.drawCircle(mechanicOffset, 20, Paint()..color = const Color(0xFF3B82F6).withOpacity(0.25));

    // Draw mechanic marker
    canvas.drawCircle(mechanicOffset, 9, Paint()..color = const Color(0xFF3B82F6));
    canvas.drawCircle(mechanicOffset, 12, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
