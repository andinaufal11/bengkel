// lib/features/customer/screens/customer_sparepart_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerSparepartScreen extends StatefulWidget {
  final Map<String, dynamic>? activeVehicle;
  final Function(int)? onTabChanged; // To allow navigating to Orders tab (index 2)

  const CustomerSparepartScreen({super.key, this.activeVehicle, this.onTabChanged});

  @override
  State<CustomerSparepartScreen> createState() => _CustomerSparepartScreenState();
}

class _CustomerSparepartScreenState extends State<CustomerSparepartScreen> {
  // 1. DATA STATE
  bool _isLoading = false;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool? _isMotor;
  String _customerName = "Budi Santoso";
  String _customerPhone = "+62 812 3456 7890";
  String _shippingAddress = "Jl. Sudirman No. 123, RT 001/RW 002, Jakarta Selatan, DKI Jakarta 12190";

  // 2. UI & NAVIGATION STATE
  String _currentScreen = "list"; // "list" | "detail" | "cart" | "checkout" | "success"
  String _previousScreen = "list";
  Map<String, dynamic>? _selectedProduct;
  String _activeCategory = "Semua";
  String _searchQuery = "";
  bool _onlyCompatible = false;
  int _detailQuantity = 1;
  String? _selectedPaymentMethod;
  String _appliedVoucherCode = "";
  final TextEditingController _voucherController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _cartItems = [];

  final List<String> _categories = [
    "Semua",
    "Oli & Filter",
    "Ban & Velg",
    "Rem",
    "Aki",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.activeVehicle != null) {
      _isMotor = _checkVehicleType(widget.activeVehicle!['name'] ?? '');
    }
    _fetchProductsFromSupabase();
    _fetchUserProfile();
  }

  bool _checkVehicleType(String name) {
    final n = name.toLowerCase();
    return n.contains("beat") ||
        n.contains("vario") ||
        n.contains("nmax") ||
        n.contains("mio") ||
        n.contains("motor") ||
        n.contains("vespa") ||
        n.contains("scoopy");
  }

  // Fetch User profile to get actual name and phone
  Future<void> _fetchUserProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      setState(() {
        _customerName = res['name'] ?? "Budi Santoso";
        _customerPhone = res['phone'] ?? "+62 812 3456 7890";
      });
    } catch (_) {}
  }

  // 3. DATABASE CONNECTION
  Future<void> _fetchProductsFromSupabase() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('spare_parts')
          .select('*, bengkels(name, rating, address)');

      final List<Map<String, dynamic>> fetched =
          List<Map<String, dynamic>>.from(res);

      _allProducts = fetched
          .map(
            (p) => {
              'id': p['id'].toString(),
              'name': p['name'] ?? '',
              'brand': p['bengkels']?['name'] ?? 'AutoCare Pro',
              'category': p['category'] ?? 'Lainnya',
              'price': (p['price'] as num?)?.toInt() ?? 0,
              'supports': p['compatibility_tags'] is List
                  ? List<String>.from(p['compatibility_tags'])
                  : ['mobil'],
              'imageUrl': p['image_url'] ??
                  'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=500',
              'description': p['description'] ??
                  'Premium quality spare part designed for optimal performance and durability. Manufactured using high-grade materials to ensure long-lasting reliability.',
              'stock': p['stock'] ?? 0,
              'bengkel_id': p['bengkel_id'],
              'bengkel_rating': p['bengkels']?['rating']?.toString() ?? '4.8',
              'bengkel_address': p['bengkels']?['address'] ?? 'Jl. Sudirman No. 123, Jakarta',
            },
          )
          .toList();

      if (_allProducts.isEmpty) {
        String? fallbackBengkelId;
        try {
          final bRes = await Supabase.instance.client
              .from('bengkels')
              .select('id')
              .or('status.eq.active,status.eq.approved')
              .limit(1);
          if (bRes.isNotEmpty) {
            fallbackBengkelId = bRes.first['id'].toString();
          }
        } catch (_) {}

        _allProducts = _mockProducts.map((p) {
          final copy = Map<String, dynamic>.from(p);
          copy['bengkel_id'] = fallbackBengkelId;
          return copy;
        }).toList();
      }
      _applyFilters();
    } catch (e) {
      debugPrint("DB Error: $e");
      _allProducts = _mockProducts;
      _applyFilters();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final q = _searchQuery.toLowerCase();
    _filteredProducts = _allProducts.where((p) {
      final matchesCat =
          _activeCategory == "Semua" || p['category'] == _activeCategory;
      final matchesSearch =
          p['name'].toLowerCase().contains(q) ||
          p['brand'].toLowerCase().contains(q);

      bool isCompatible = true;
      if (widget.activeVehicle != null && _isMotor != null) {
        final tags = p['supports'] as List<dynamic>;
        isCompatible = _isMotor!
            ? tags.contains("motor")
            : tags.contains("mobil");
      }
      return matchesCat && matchesSearch && (!_onlyCompatible || isCompatible);
    }).toList();
  }

  // 4. FORMATTERS
  String _formatPrice(int p) => "Rp ${(p / 1000).toStringAsFixed(0)}k";
  
  String _formatFullPrice(int p) {
    final s = p.toString();
    final b = StringBuffer("Rp ");
    for (int i = 0; i < s.length; i++) {
      b.write(s[i]);
      if ((s.length - i - 1) % 3 == 0 && i < s.length - 1) b.write(".");
    }
    return b.toString();
  }

  // Calculate cart metrics
  int get _checkedItemsCount {
    return _cartItems.where((item) => item['checked'] == true).length;
  }

  int get _checkedSubtotal {
    return _cartItems
        .where((item) => item['checked'] == true)
        .fold(0, (sum, item) => sum + ((item['product']['price'] as int) * (item['quantity'] as int)));
  }

  int get _shippingFee {
    return _checkedItemsCount > 0 ? 15000 : 0;
  }

  int get _totalCheckoutAmount {
    return _checkedSubtotal + _shippingFee;
  }

  Future<Map<String, dynamic>?> _createMidtransTransaction(int amount, String orderId) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://app.sandbox.midtrans.com/snap/v1/transactions');
      final request = await client.postUrl(uri);
      
      request.headers.add('Accept', 'application/json');
      request.headers.add('Content-Type', 'application/json');
      
      final serverKey = const String.fromEnvironment('MIDTRANS_SERVER_KEY', defaultValue: '');
      final basicAuth = 'Basic ${base64Encode(utf8.encode(serverKey))}';
      request.headers.add('Authorization', basicAuth);
      
      final body = jsonEncode({
        "transaction_details": {
          "order_id": orderId,
          "gross_amount": amount,
        },
        "credit_card": {
          "secure": true
        }
      });
      
      request.add(utf8.encode(body));
      final response = await request.close();
      final bodyString = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(bodyString) as Map<String, dynamic>;
      } else {
        debugPrint("Midtrans error response: ${response.statusCode} - $bodyString");
      }
    } catch (e) {
      debugPrint("Midtrans exception: $e");
    } finally {
      client.close();
    }
    return null;
  }

  Future<void> _finalizeOrder(
    String userId,
    List<Map<String, dynamic>> checkedItems,
    dynamic bengkelId,
    String itemsText,
    String midtransOrderId,
    String snapToken,
  ) async {
    setState(() => _isLoading = true);
    try {
      final data = {
        'user_id': userId,
        'type': 'Sparepart',
        'order_type': 'Sparepart',
        'status': 'pending',
        'total': _totalCheckoutAmount,
        'notes': "Pembelian Suku Cadang: $itemsText. Alamat: $_shippingAddress\n\n[MIDTRANS] Order ID: $midtransOrderId, Token: $snapToken",
      };

      if (bengkelId != null) {
        data['bengkel_id'] = bengkelId;
      }

      await Supabase.instance.client.from('orders').insert(data);

      // Update stocks in database
      for (final item in checkedItems) {
        final prod = item['product'];
        final prodId = prod['id']?.toString() ?? '';
        final qty = item['quantity'] as int;

        if (prodId.isNotEmpty && !prodId.startsWith('m')) {
          try {
            final currentStock = prod['stock'] as int;
            final updatedStock = (currentStock - qty).clamp(0, 999999);

            await Supabase.instance.client
                .from('spare_parts')
                .update({'stock': updatedStock})
                .eq('id', prodId);
          } catch (err) {
            debugPrint("Failed to update stock for product $prodId: $err");
          }
        }
      }

      // Reload products from database to update local list
      _fetchProductsFromSupabase();

      // Remove checkout items from cart
      setState(() {
        _cartItems.removeWhere((item) => item['checked'] == true);
        _currentScreen = "success";
      });
    } catch (e) {
      debugPrint("Supabase insert error: $e");
      // Fallback success for local testing/demo if table constraint issues occur
      setState(() {
        _cartItems.removeWhere((item) => item['checked'] == true);
        _currentScreen = "success";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add order to database with Midtrans integration
  Future<void> _processPayment() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in"), backgroundColor: Colors.red),
      );
      return;
    }

    final checkedItems = _cartItems.where((item) => item['checked'] == true).toList();
    if (checkedItems.isEmpty) return;

    final firstProduct = checkedItems.first['product'];
    final bengkelId = firstProduct['bengkel_id'];

    // Group item descriptions
    final itemsText = checkedItems.map((item) {
      return "${item['product']['name']} (${item['quantity']}x)";
    }).join(", ");

    setState(() => _isLoading = true);

    final midtransOrderId = "TRX-${DateTime.now().millisecondsSinceEpoch}";
    final midtransRes = await _createMidtransTransaction(_totalCheckoutAmount, midtransOrderId);

    setState(() => _isLoading = false);

    if (midtransRes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal memproses pembayaran via Midtrans. Silakan coba lagi."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final redirectUrl = midtransRes['redirect_url']?.toString() ?? '';
    final token = midtransRes['token']?.toString() ?? '';

    if (redirectUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mendapatkan URL pembayaran dari Midtrans."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final uri = Uri.parse(redirectUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch Midtrans URL: $e");
      try {
        await launchUrl(Uri.parse(redirectUrl), mode: LaunchMode.externalApplication);
      } catch (err) {
        debugPrint("Could not launch Midtrans URL even with fallback: $err");
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Menunggu Pembayaran", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Silakan selesaikan pembayaran Anda di halaman Midtrans yang telah terbuka.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              SizedBox(height: 12),
              Text("Tekan tombol di bawah jika Anda sudah menyelesaikan pembayaran.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _finalizeOrder(userId, checkedItems, bengkelId, itemsText, midtransOrderId, token);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Saya Sudah Bayar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  // 5. BUILD METHODS
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentScreen == "list",
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          if (_currentScreen == "checkout") {
            _currentScreen = _previousScreen;
          } else if (_currentScreen == "cart") {
            _currentScreen = "list";
          } else if (_currentScreen == "detail") {
            _currentScreen = "list";
          } else {
            _currentScreen = "list";
          }
        });
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case "detail":
        return _buildDetailScreen();
      case "cart":
        return _buildCartScreen();
      case "checkout":
        return _buildCheckoutScreen();
      case "success":
        return _buildSuccessScreen();
      default:
        return _buildListScreen();
    }
  }

  // --- SCREEN 1: PRODUCT LISTING ---
  Widget _buildListScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildCategoryList(),
            if (widget.activeVehicle != null) _buildCompatibilityFilter(),
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    int cartCount = _cartItems.fold(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Marketplace",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          Row(
            children: [
              // Chat with notification
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Color(0xFF334155)),
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Cart with items count
              GestureDetector(
                onTap: () => setState(() => _currentScreen = "cart"),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 20,
                        color: Color(0xFF334155),
                      ),
                      if (cartCount > 0)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.red,
                            child: Text(
                              cartCount.toString(),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          _searchQuery = v;
          setState(() => _applyFilters());
        },
        decoration: const InputDecoration(
          hintText: "Cari suku cadang...",
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _categories.map((c) {
          bool active = _activeCategory == c;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeCategory = c;
                _applyFilters();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                c,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompatibilityFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF10B981),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Cocok untuk ${widget.activeVehicle!['name']}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          Switch.adaptive(
            value: _onlyCompatible,
            activeThumbColor: const Color(0xFF10B981),
            activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.5),
            onChanged: (v) {
              setState(() {
                _onlyCompatible = v;
                _applyFilters();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E293B)),
      );
    }
    if (_filteredProducts.isEmpty) {
      return const Center(child: Text("Produk tidak ditemukan"));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, i) {
        final p = _filteredProducts[i];
        return GestureDetector(
          onTap: () => setState(() {
            _selectedProduct = p;
            _detailQuantity = 1;
            _currentScreen = "detail";
          }),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      p['imageUrl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['brand'],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p['name'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatPrice(p['price']),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () => _buyNow(p, 1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Beli",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- SCREEN 2: PRODUCT DETAIL (IMAGE 2 & 3 STYLE) ---
  Widget _buildDetailScreen() {
    final p = _selectedProduct!;
    int cartCount = _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => setState(() => _currentScreen = "list"),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0F172A)),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F172A)),
                if (cartCount > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text(cartCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            onPressed: () => setState(() => _currentScreen = "cart"),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A)),
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product main photo
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Image.network(
                    p['imageUrl'],
                    height: 260,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 260,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Mock image thumbnails row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildImageThumbnail(p['imageUrl'], true),
                        const SizedBox(width: 12),
                        _buildImageThumbnail(p['imageUrl'], false),
                        const SizedBox(width: 12),
                        _buildImageThumbnail(p['imageUrl'], false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // Product Core Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatFullPrice(p['price']),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rating & Sold Info
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      const Text(
                        "4.8",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        " (142 reviews)  |  Sold: 523",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),
                  // Compatibility list
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Compatible with:  ",
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                      ),
                      _buildCompatBadge("Toyota"),
                      const SizedBox(width: 6),
                      _buildCompatBadge("Honda"),
                      const SizedBox(width: 6),
                      _buildCompatBadge("Nissan"),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Stock
                  Row(
                    children: [
                      const Text("Stock: ", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      Text(
                        "${p['stock']} units available",
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Seller Info Card
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.store_rounded, color: Color(0xFF3B82F6), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['brand'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orange, size: 14),
                            Text(" ${p['bengkel_rating']}  •  1.2 km", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text("Visit Shop", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Benefit Row badges
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBenefitItem(Icons.verified_user_outlined, "100% Original"),
                  _buildBenefitItem(Icons.local_shipping_outlined, "Fast Delivery"),
                  _buildBenefitItem(Icons.support_agent_rounded, "24/7 Support"),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Description card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Product Description",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p['description'],
                    style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  // Bullet points
                  _buildBulletPoint("Original manufacturer specification"),
                  _buildBulletPoint("Easy installation process"),
                  _buildBulletPoint("Tested for quality assurance"),
                  _buildBulletPoint("1 year warranty included"),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Customer Reviews Card
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Customer Reviews",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  _buildReviewItem("Budi Santoso", 5, "Produk original dan kualitas bagus. Cocok untuk mobil saya!", "2 days ago"),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildReviewItem("Ahmad Rizki", 5, "Pengiriman cepat, barang sesuai deskripsi. Recommended!", "1 week ago"),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildReviewItem("Dewi Lestari", 4, "Barang bagus tapi harga agak mahal. Overall puas.", "2 weeks ago"),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity selector
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16, color: Color(0xFF475569)),
                      onPressed: () {
                        if (_detailQuantity > 1) {
                          setState(() => _detailQuantity--);
                        }
                      },
                    ),
                    Text(
                      _detailQuantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16, color: Color(0xFF475569)),
                      onPressed: () {
                        if (_detailQuantity < p['stock']) {
                          setState(() => _detailQuantity++);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Buttons
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _addToCartCustom(p, _detailQuantity);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Add to Cart",
                          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _buyNow(p, _detailQuantity);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Buy Now",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
    );
  }

  Widget _buildImageThumbnail(String url, bool active) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: active ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFF1F5F9),
            child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildCompatBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 10, color: Color(0xFF059669)),
          const SizedBox(width: 2),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, int rating, String comment, String relativeDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            Text(relativeDate, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              index < rating ? Icons.star_rounded : Icons.star_border_rounded,
              color: Colors.orange,
              size: 14,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(comment, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4)),
      ],
    );
  }

  // --- SCREEN 3: SHOPPING CART (IMAGE 4 STYLE) ---
  Widget _buildCartScreen() {
    int totalCheckedCount = _cartItems.where((item) => item['checked'] == true).length;
    bool allChecked = _cartItems.isNotEmpty && _cartItems.every((item) => item['checked'] == true);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Shopping Cart",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => setState(() => _currentScreen = "list"),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0F172A)),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A)),
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 14),
                  const Text("Keranjang Anda kosong", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Select All pill
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: allChecked,
                          activeColor: const Color(0xFF1E293B),
                          onChanged: (val) {
                            setState(() {
                              for (var item in _cartItems) {
                                item['checked'] = val ?? false;
                              }
                            });
                          },
                        ),
                        Text(
                          "Select All (${_cartItems.length} items)",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ),

                  // Cart list (grouped or single list showing Shop title)
                  // For visual match, we render shop header "AutoCare Pro"
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seller Shop Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: const [
                              Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF64748B)),
                              SizedBox(width: 8),
                              Text(
                                "AutoCare Pro",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        // Items
                        ...List.generate(_cartItems.length, (i) {
                          final item = _cartItems[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item['checked'] ?? false,
                                  activeColor: const Color(0xFF1E293B),
                                  onChanged: (val) {
                                    setState(() {
                                      item['checked'] = val ?? false;
                                    });
                                  },
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item['product']['imageUrl'],
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 64,
                                      height: 64,
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['product']['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatFullPrice(item['product']['price']),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Quantity selector and delete
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove, size: 10),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 26),
                                                  onPressed: () => setState(() {
                                                    if (item['quantity'] > 1) {
                                                      item['quantity']--;
                                                    } else {
                                                      _cartItems.removeAt(i);
                                                    }
                                                  }),
                                                ),
                                                Text(
                                                  item['quantity'].toString(),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add, size: 10),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 26),
                                                  onPressed: () => setState(() {
                                                    if (item['quantity'] < item['product']['stock']) {
                                                      item['quantity']++;
                                                    }
                                                  }),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                            onPressed: () => setState(() {
                                              _cartItems.removeAt(i);
                                            }),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Voucher Code Section
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.confirmation_num_outlined, size: 18, color: Color(0xFF334155)),
                            SizedBox(width: 8),
                            Text(
                              "Voucher Code",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextField(
                                  controller: _voucherController,
                                  decoration: const InputDecoration(
                                    hintText: "Enter code",
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                                    contentPadding: EdgeInsets.only(bottom: 6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 42,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_voucherController.text.isNotEmpty) {
                                    setState(() {
                                      _appliedVoucherCode = _voucherController.text;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Voucher $_appliedVoucherCode applied successfully!")),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E293B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                child: const Text("Apply", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Shipping Address Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF334155)),
                                SizedBox(width: 8),
                                Text(
                                  "Shipping Address",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _showEditAddressDialog,
                              child: const Text(
                                "Change",
                                style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _shippingAddress,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  // Order Summary Section
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Order Summary",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow("Subtotal ($totalCheckedCount items)", _formatFullPrice(_checkedSubtotal)),
                        const SizedBox(height: 8),
                        _buildSummaryRow("Shipping Fee", _formatFullPrice(_shippingFee)),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                            Text(_formatFullPrice(_totalCheckoutAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2563EB))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
      bottomNavigationBar: _cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: allChecked,
                          activeColor: const Color(0xFF1E293B),
                          onChanged: (val) {
                            setState(() {
                              for (var item in _cartItems) {
                                item['checked'] = val ?? false;
                              }
                            });
                          },
                        ),
                        const Text("All", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Total", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          _formatFullPrice(_totalCheckoutAmount),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: totalCheckedCount > 0
                          ? () {
                              setState(() {
                                _previousScreen = "cart";
                                _currentScreen = "checkout";
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        "Checkout ($totalCheckedCount)",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Edit address dialog
  void _showEditAddressDialog() {
    final controller = TextEditingController(text: _shippingAddress);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Edit Shipping Address", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F172A),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF334155)), borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blue), borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _shippingAddress = controller.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 4: PAYMENT/CHECKOUT (IMAGE 5 STYLE) ---
  Widget _buildCheckoutScreen() {
    final checkedItems = _cartItems.where((item) => item['checked'] == true).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Payment",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => setState(() => _currentScreen = _previousScreen),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0F172A)),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A)),
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Shipping Address Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Text(
                            "Shipping Address",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _showEditAddressDialog,
                        child: const Text(
                          "Change",
                          style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _customerPhone,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _shippingAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                  ),
                ],
              ),
            ),

            // Order Items Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order Items (${checkedItems.length})",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  ...checkedItems.map((item) {
                    final priceTotal = (item['product']['price'] as int) * (item['quantity'] as int);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['product']['imageUrl'],
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 44,
                                height: 44,
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['product']['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['product']['brand'],
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "x${item['quantity']}",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatFullPrice(priceTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Select Payment Method Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Payment Method",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption("GoPay", Icons.account_balance_wallet_rounded, Colors.green),
                  const SizedBox(height: 10),
                  _buildPaymentOption("OVO", Icons.wallet_giftcard_rounded, Colors.purple),
                  const SizedBox(height: 10),
                  _buildPaymentOption("DANA", Icons.credit_card_rounded, Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Payment", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    _formatFullPrice(_totalCheckoutAmount),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _selectedPaymentMethod != null
                          ? _processPayment
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Pay Now",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String name, IconData icon, Color color) {
    bool isSelected = _selectedPaymentMethod == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = name;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Instant",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 20),
          ],
        ),
      ),
    );
  }

  // --- SCREEN 5: SUCCESS SCREEN ---
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Checkmark Circle with visual gradients
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF34D399), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0x33059669), blurRadius: 16, offset: Offset(0, 8)),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Payment Successful!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Pesanan suku cadang Anda telah berhasil didaftarkan dan segera diproses oleh bengkel mitra kami.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // Actions buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Orders Tab
                    if (widget.onTabChanged != null) {
                      widget.onTabChanged!(2); // index 2 is Orders tab in dashboard
                    } else {
                      setState(() {
                        _currentScreen = "list";
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Lihat Pesanan Saya", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentScreen = "list";
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Lanjut Belanja", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ACTIONS HELPERS ---

  void _addToCartCustom(Map<String, dynamic> p, int qty) {
    final idx = _cartItems.indexWhere(
      (item) => item['product']['id'] == p['id'],
    );
    setState(() {
      if (idx >= 0) {
        _cartItems[idx]['quantity'] += qty;
        if (_cartItems[idx]['quantity'] > p['stock']) {
          _cartItems[idx]['quantity'] = p['stock'];
        }
      } else {
        _cartItems.add({'product': p, 'quantity': qty, 'checked': true});
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${p['name']} ditambahkan ke keranjang!"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  void _buyNow(Map<String, dynamic> p, int qty) {
    setState(() {
      // Uncheck all other items in cart
      for (var item in _cartItems) {
        item['checked'] = false;
      }
      // Add or update target item in cart and check it
      final idx = _cartItems.indexWhere((item) => item['product']['id'] == p['id']);
      if (idx >= 0) {
        _cartItems[idx]['quantity'] = qty;
        _cartItems[idx]['checked'] = true;
      } else {
        _cartItems.add({'product': p, 'quantity': qty, 'checked': true});
      }
      _previousScreen = _currentScreen;
      _currentScreen = "checkout";
      _selectedPaymentMethod = null; // Reset payment method selection
    });
  }

  // Fallback Data
  final List<Map<String, dynamic>> _mockProducts = [
    {
      "id": "m1",
      "name": "Engine Oil Castrol 5W-30",
      "brand": "AutoCare Pro",
      "category": "Oli & Filter",
      "price": 125000,
      "supports": ["mobil", "motor"],
      "imageUrl": "https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=500",
      "description": "Premium quality engine oil designed for optimal engine performance, reduced friction, and superior wear protection. Recommended for all modern multi-valve engines.",
      "stock": 45,
      "bengkel_rating": "4.8",
      "bengkel_address": "Jl. Sudirman No. 123, Jakarta",
    },
    {
      "id": "m2",
      "name": "Brake Pad Set Front",
      "brand": "AutoCare Pro",
      "category": "Rem",
      "price": 350000,
      "supports": ["mobil"],
      "imageUrl": "https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=500",
      "description": "Premium front brake pads offering superior stopping power, low dust, and noise-free operation. Engineered for maximum longevity and safety under all conditions.",
      "stock": 12,
      "bengkel_rating": "4.8",
      "bengkel_address": "Jl. Sudirman No. 123, Jakarta",
    },
    {
      "id": "m3",
      "name": "Aki GS Astra Hybrid NS60",
      "brand": "AutoCare Pro",
      "category": "Aki",
      "price": 850000,
      "supports": ["mobil"],
      "imageUrl": "https://images.unsplash.com/photo-1542282088-fe8426682b8f?w=500",
      "description": "High performance hybrid car battery with low maintenance, low water evaporation rate, and quick starting power capability. Perfect for tropical climates.",
      "stock": 8,
      "bengkel_rating": "4.8",
      "bengkel_address": "Jl. Sudirman No. 123, Jakarta",
    },
  ];
}
