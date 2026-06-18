import 'package:flutter/material.dart';

class CustomerBengkelScreen extends StatefulWidget {
  const CustomerBengkelScreen({Key? key}) : super(key: key);

  @override
  State<CustomerBengkelScreen> createState() => _CustomerBengkelScreenState();
}

class _CustomerBengkelScreenState extends State<CustomerBengkelScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cari Bengkel",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  "Temukan bengkel mitra terbaik di sekitarmu",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
          // Search Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari lokasi atau nama bengkel...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Workshop list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                const SizedBox(height: 12),
                _buildBengkelCard(
                  name: "Sinar Surya AC",
                  type: "Spesialis AC Mobil",
                  rating: "4.7",
                  reviewsCount: "85",
                  distance: "2.1 km",
                  isOpen: false,
                  isTopRated: false,
                ),
              ],
            ),
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
}
