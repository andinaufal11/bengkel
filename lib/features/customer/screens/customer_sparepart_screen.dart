import 'package:flutter/material.dart';

class CustomerSparepartScreen extends StatefulWidget {
  const CustomerSparepartScreen({Key? key}) : super(key: key);

  @override
  State<CustomerSparepartScreen> createState() => _CustomerSparepartScreenState();
}

class _CustomerSparepartScreenState extends State<CustomerSparepartScreen> {
  // Navigation State
  // "list" | "detail" | "cart" | "checkout" | "success"
  String _currentScreen = "list";
  Map<String, dynamic>? _selectedProduct;

  // Search & Filter State
  String _activeCategory = "Semua";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Cart State
  final List<Map<String, dynamic>> _cartItems = [];

  // Checkout State
  String _selectedPaymentMethod = "Transfer Bank";

  // New Review Form State
  double _newRating = 5;
  final TextEditingController _reviewController = TextEditingController();

  final List<String> _categories = [
    "Semua",
    "Oli & Filter",
    "Ban & Velg",
    "Rem",
    "Aki",
  ];

  final List<Map<String, dynamic>> _products = [
    {
      "id": "1",
      "name": "Shell Helix Ultra 5W-30",
      "brand": "Shell",
      "category": "Oli & Filter",
      "price": 185000,
      "originalPrice": 220000,
      "discount": "-16%",
      "rating": 4.8,
      "reviewsCount": 432,
      "compatible": true,
      "imageUrl": "https://images.unsplash.com/photo-1580273916550-e323be2ae537?auto=format&fit=crop&w=500",
      "description": "Oli mesin mobil teknologi sintetis penuh yang dirancang khusus untuk memberikan kinerja maksimal dan perlindungan mesin luar biasa dalam segala kondisi berkendara.",
      "specifications": {
        "Volume": "1 Liter",
        "Viskositas": "5W-30",
        "Sertifikasi": "API SP, ACEA A3/B4",
        "Tipe Mesin": "Bensin & Diesel"
      },
      "reviews": [
        {"user": "Budi Santoso", "rating": 5.0, "comment": "Mesin jadi lebih halus dan tarikan enteng banget setelah ganti pakai Shell Helix Ultra ini.", "date": "12 Juni 2026"},
        {"user": "Rian Hidayat", "rating": 4.5, "comment": "Kualitas oli mantap, produk original. Sangat direkomendasikan untuk pengguna Avanza.", "date": "08 Juni 2026"},
        {"user": "Santi Wijaya", "rating": 5.0, "comment": "Gak pernah kecewa sama oli ini. Pemakaian jangka panjang mesin tetap bersih dan tidak berkerak.", "date": "03 Juni 2026"}
      ]
    },
    {
      "id": "2",
      "name": "Michelin Pilot Sport 4 205/55 R16",
      "brand": "Michelin",
      "category": "Ban & Velg",
      "price": 1250000,
      "originalPrice": 1450000,
      "discount": "-14%",
      "rating": 4.9,
      "reviewsCount": 218,
      "compatible": true,
      "imageUrl": "https://images.unsplash.com/photo-1506015391300-4802dc74de2e?auto=format&fit=crop&w=500",
      "description": "Ban mobil performa tinggi yang memberikan kendali kemudi yang sangat baik, keamanan ekstra saat jalan basah, dan masa pakai ban yang tahan lama.",
      "specifications": {
        "Ukuran": "205/55 R16",
        "Indeks Beban": "91 (615 kg)",
        "Simbol Kecepatan": "W (270 km/jam)",
        "Konstruksi": "Radial"
      },
      "reviews": [
        {"user": "Hendrawan", "rating": 5.0, "comment": "Grip di jalan basah sangat solid. Gak licin sama sekali pas hujan lebat.", "date": "15 Juni 2026"},
        {"user": "Agus Salim", "rating": 4.8, "comment": "Ban michelin emang ga usah diragukan lagi empuk dan kedap suaranya.", "date": "11 Juni 2026"}
      ]
    },
    {
      "id": "3",
      "name": "Brake Pad Brembo P50 037",
      "brand": "Brembo",
      "category": "Rem",
      "price": 450000,
      "originalPrice": 535000,
      "discount": "-16%",
      "rating": 4.7,
      "reviewsCount": 156,
      "compatible": true,
      "imageUrl": "https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=500",
      "description": "Kampas rem cakram Brembo dirancang untuk performa pengereman maksimum, ketahanan gesekan tinggi, dan meminimalkan debu serta kebisingan rem.",
      "specifications": {
        "Posisi": "Depan",
        "Material": "Keramik/Semi-Metalik",
        "Ketahanan Suhu": "Hingga 600°C",
        "Kompatibilitas": "Mobil Jepang & Eropa"
      },
      "reviews": [
        {"user": "Arif Budiman", "rating": 5.0, "comment": "Pengereman instan dan tidak berdecit. Brembo original memuaskan.", "date": "05 Juni 2026"},
        {"user": "Deni Setiawan", "rating": 4.5, "comment": "Sangat bagus, pas dipasang di mobil dan pengereman jauh lebih pakem dibanding orian.", "date": "01 Juni 2026"}
      ]
    },
    {
      "id": "4",
      "name": "Aki GS Astra MF 45Ah",
      "brand": "GS Astra",
      "category": "Aki",
      "price": 650000,
      "originalPrice": 750000,
      "discount": "-13%",
      "rating": 4.6,
      "reviewsCount": 89,
      "compatible": true,
      "imageUrl": "https://images.unsplash.com/photo-1507136566006-cfc505b114fc?auto=format&fit=crop&w=500",
      "description": "Aki bebas perawatan (Maintenance Free) dari GS Astra yang handal, awet, dan memiliki daya starter tinggi untuk kebutuhan listrik mobil modern.",
      "specifications": {
        "Kapasitas": "45 Ah",
        "Tegangan": "12 V",
        "Tipe Aki": "Maintenance Free (MF)",
        "Garansi": "6 Bulan"
      },
      "reviews": [
        {"user": "Kevin Sanjaya", "rating": 5.0, "comment": "Aki langsung joss starter lancar jaya. Pengiriman cepat.", "date": "14 Juni 2026"},
        {"user": "Mega Lestari", "rating": 4.2, "comment": "Aki MF awet banget, gampang perawatannya ga perlu isi air accu lagi.", "date": "09 Juni 2026"}
      ]
    },
  ];

  // Price Formatters
  String _formatIDR(int price) {
    if (price >= 1000000) {
      double million = price / 1000000;
      return "Rp ${million.toStringAsFixed(1).replaceAll('.0', '')}jt";
    }
    return "Rp ${(price / 1000).toStringAsFixed(0)}k";
  }

  String _formatFullIDR(int price) {
    final buffer = StringBuffer("Rp ");
    final str = price.toString();
    for (int i = 0; i < str.length; i++) {
      buffer.write(str[i]);
      if ((str.length - i - 1) % 3 == 0 && i < str.length - 1) {
        buffer.write(".");
      }
    }
    return buffer.toString();
  }

  // Cart Management
  void _addToCart(Map<String, dynamic> product, {int qty = 1}) {
    final existingIndex = _cartItems.indexWhere((item) => item['product']['id'] == product['id']);
    if (existingIndex >= 0) {
      setState(() {
        _cartItems[existingIndex]['quantity'] += qty;
      });
    } else {
      setState(() {
        _cartItems.add({
          'product': product,
          'quantity': qty,
        });
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${product['name']} ditambahkan ke keranjang!"),
        backgroundColor: const Color(0xFF1E293B),
        action: SnackBarAction(
          label: "LIHAT",
          textColor: Colors.blue.shade300,
          onPressed: () {
            setState(() {
              _currentScreen = "cart";
            });
          },
        ),
      ),
    );
  }

  int get _cartCount {
    int total = 0;
    for (var item in _cartItems) {
      total += item['quantity'] as int;
    }
    return total;
  }

  int get _cartSubtotal {
    int subtotal = 0;
    for (var item in _cartItems) {
      subtotal += (item['product']['price'] as int) * (item['quantity'] as int);
    }
    return subtotal;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case "detail":
        return _buildDetailScreen();
      case "cart":
        return _buildCartScreen();
      case "checkout":
        return _buildCheckoutScreen();
      case "success":
        return _buildSuccessScreen();
      case "list":
      default:
        return _buildListScreen();
    }
  }

  // --- SCREEN 1: PRODUCT LIST / MARKETPLACE ---
  Widget _buildListScreen() {
    final filteredProducts = _products.where((product) {
      final matchesCategory = _activeCategory == "Semua" || product['category'] == _activeCategory;
      final matchesSearch = product['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product['brand'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Marketplace",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentScreen = "cart";
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: Color(0xFF334155),
                            size: 22,
                          ),
                          if (_cartCount > 0)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  _cartCount.toString(),
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
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Filter
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "Cari sparepart...",
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Fitur filter lanjutan akan segera hadir!"),
                          backgroundColor: Color(0xFF233246),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Category Horizontal List
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _categories.map((category) {
                  final isActive = _activeCategory == category;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeCategory = category;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isActive ? Colors.white : const Color(0xFF475569),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // Product Grid View
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            "Tidak ada sparepart ditemukan",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      itemCount: filteredProducts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.61,
                      ),
                      itemBuilder: (context, index) {
                        return _buildProductCard(filteredProducts[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final discount = product['discount'] as String?;
    final originalPriceStr = product['originalPrice'] as String?;
    final isCompatible = product['compatible'] as bool? ?? false;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProduct = product;
          _currentScreen = "detail";
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        product['imageUrl'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF233246)),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 30),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (discount != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content Container
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Name
                  Text(
                    product['brand'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Product Name
                  Text(
                    product['name'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Compatibility Indicator
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompatible ? "Kompatibel" : "Tidak Kompatibel",
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Rating Block
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        "${product['rating']} (${product['reviewsCount']})",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Pricing Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatIDR(product['price']),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (originalPriceStr != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          originalPriceStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        _addToCart(product);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "Keranjang",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
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
  }

  // --- SCREEN 2: PRODUCT DETAIL (Includes Reviews from other users) ---
  Widget _buildDetailScreen() {
    if (_selectedProduct == null) return Container();
    final product = _selectedProduct!;
    final specs = product['specifications'] as Map<String, dynamic>;
    final reviews = product['reviews'] as List<dynamic>;

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
        title: const Text(
          "Detail Sparepart",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F172A)),
            onPressed: () {
              setState(() {
                _currentScreen = "cart";
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Slider / Product Hero
            Container(
              height: 250,
              width: double.infinity,
              color: const Color(0xFFF8FAFC),
              child: Image.network(
                product['imageUrl'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, size: 60),
              ),
            ),

            // Product Details Block
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product['brand'].toString().toUpperCase(),
                        style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                      if (product['discount'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Diskon ${product['discount']}",
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['name'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),

                  // Rating + Compatibility Row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        "${product['rating']} (${product['reviewsCount']} Ulasan)",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 4),
                            Text("Kompatibel", style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),

                  // Pricing block
                  Row(
                    children: [
                      Text(
                        _formatFullIDR(product['price']),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      if (product['originalPrice'] != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          product['originalPrice'],
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text("Deskripsi Produk", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  Text(
                    product['description'],
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5),
                  ),

                  const SizedBox(height: 20),
                  const Text("Spesifikasi", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Table(
                    border: TableBorder.all(color: const Color(0xFFF1F5F9), width: 1),
                    columnWidths: const {
                      0: FlexColumnWidth(1.2),
                      1: FlexColumnWidth(2.0),
                    },
                    children: specs.entries.map((entry) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Text(entry.value, style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
                          ),
                        ],
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),
                  
                  // REVIEWS FROM OTHER USERS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Ulasan Pembeli",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        "${reviews.length} Ulasan",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...reviews.map((r) => _buildReviewRow(Map<String, dynamic>.from(r))),
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _addToCart(product);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Beli Langsung", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _addToCart(product);
                  setState(() {
                    _currentScreen = "cart";
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF233246),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
                label: const Text("Masukkan Keranjang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(Map<String, dynamic> review) {
    final ratingVal = (review['rating'] as num).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review['user'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              Text(
                review['date'],
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < ratingVal ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.orange,
                size: 14,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            review['comment'],
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 3: SHOPPING CART SCREEN ---
  Widget _buildCartScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
        title: const Text(
          "Keranjang",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
      ),
      body: _cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("Keranjang belanja Anda kosong", style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentScreen = "list";
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Mulai Belanja", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final prod = item['product'];
                      final qty = item['quantity'] as int;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                prod['imageUrl'],
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prod['brand'].toString().toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 6),
                                  Text(_formatFullIDR(prod['price']), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                                ],
                              ),
                            ),
                            // Quantity Controls
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (qty > 1) {
                                        _cartItems[index]['quantity']--;
                                      } else {
                                        _cartItems.removeAt(index);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(qty > 1 ? Icons.remove : Icons.delete_outline_rounded, size: 14, color: const Color(0xFF475569)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  child: Text(qty.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _cartItems[index]['quantity']++;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, size: 14, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Summary Panel
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4)),
                    ],
                    border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Subtotal", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                            Text(_formatFullIDR(_cartSubtotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _currentScreen = "checkout";
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF233246),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Lanjut ke Checkout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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

  // --- SCREEN 4: CHECKOUT SCREEN ---
  Widget _buildCheckoutScreen() {
    final int itemTotal = _cartSubtotal;
    final int shippingFee = 15000;
    final int serviceFee = 2000;
    final int grandTotal = itemTotal + shippingFee + serviceFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            setState(() {
              _currentScreen = "cart";
            });
          },
        ),
        title: const Text(
          "Checkout",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shipping Address Card
            const Text("Alamat Pengiriman", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), shape: BoxShape.circle),
                    child: const Icon(Icons.location_on_outlined, color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Rumah (Fakhri)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        SizedBox(height: 2),
                        Text("Jl. Dago No. 123, Coblong, Kota Bandung, Jawa Barat 40135", style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Order Item List Summary
            const Text("Detail Pesanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  final prod = item['product'];
                  final qty = item['quantity'] as int;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(bottom: index < _cartItems.length - 1 ? BorderSide(color: Colors.grey.shade100, width: 1) : BorderSide.none),
                    ),
                    child: Row(
                      children: [
                        Text("${qty}x", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(prod['name'], style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 12),
                        Text(_formatFullIDR(prod['price'] * qty), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Payment Method Section
            const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            _buildPaymentOption("Transfer Bank", Icons.account_balance_rounded),
            const SizedBox(height: 8),
            _buildPaymentOption("Gopay / OVO", Icons.wallet_rounded),
            const SizedBox(height: 8),
            _buildPaymentOption("COD (Bayar di Tempat)", Icons.handshake_rounded),

            const SizedBox(height: 24),

            // Payment Breakdowns
            const Text("Rincian Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow("Subtotal Produk", _formatFullIDR(itemTotal)),
                  const SizedBox(height: 10),
                  _buildSummaryRow("Biaya Pengiriman", _formatFullIDR(shippingFee)),
                  const SizedBox(height: 10),
                  _buildSummaryRow("Biaya Layanan", _formatFullIDR(serviceFee)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(color: Color(0xFFF1F5F9)),
                  ),
                  _buildSummaryRow("Total Pembayaran", _formatFullIDR(grandTotal), isBold: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentScreen = "success";
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF233246),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Bayar Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                method,
                style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13, color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF475569)),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF3B82F6), size: 18)
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.bold,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  // --- SCREEN 5: SUCCESS / RATINGS SCREEN ---
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Success Checkmark
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 40),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Pembayaran Berhasil!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                "Pesanan sparepart Anda sedang diproses oleh bengkel.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4),
              ),

              const SizedBox(height: 24),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),

              // RATING AND REVIEW SECTION
              const Text(
                "Bagaimana Kualitas Pelayanan Kami?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                "Beri bintang dan rating agar pembeli lain dapat melihat kualitas produk yang dibeli.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Interactive Stars Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _newRating = starVal.toDouble();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Icon(
                        _newRating >= starVal ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.orange,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Review Feedback Textfield
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Tulis Ulasan Anda",
                  hintText: "Sangat membantu, pengemasan rapi dan produk orisinil...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF233246), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Kirim Review Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    final reviewText = _reviewController.text.trim();
                    if (reviewText.isNotEmpty) {
                      // Insert the new review to each product in our cart
                      for (var item in _cartItems) {
                        final prodId = item['product']['id'];
                        final prodIndex = _products.indexWhere((p) => p['id'] == prodId);
                        if (prodIndex >= 0) {
                          setState(() {
                            (_products[prodIndex]['reviews'] as List<dynamic>).add({
                              "user": "Fakhri",
                              "rating": _newRating,
                              "comment": reviewText,
                              "date": "Hari Ini",
                            });
                            // recalculate rating count
                            _products[prodIndex]['reviewsCount']++;
                          });
                        }
                      }
                    }

                    // Reset cart and go home list
                    setState(() {
                      _cartItems.clear();
                      _reviewController.clear();
                      _newRating = 5;
                      _currentScreen = "list";
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Terima kasih atas ulasan Anda!"),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF233246),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Kirim Ulasan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 12),

              // Skip / Kembali Button
              TextButton(
                onPressed: () {
                  setState(() {
                    _cartItems.clear();
                    _reviewController.clear();
                    _newRating = 5;
                    _currentScreen = "list";
                  });
                },
                child: const Text(
                  "Kembali Ke Marketplace",
                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
