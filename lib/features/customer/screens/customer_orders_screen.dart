import 'package:flutter/material.dart';
import 'package:bengkel/core/constants/app_colors.dart';

class CustomerOrdersScreen extends StatefulWidget {
  final String selectedStatusFilter;
  final ValueChanged<String> onFilterChanged;

  const CustomerOrdersScreen({
    Key? key,
    required this.selectedStatusFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  // Mock Data for Orders
  final List<Map<String, dynamic>> _mockOrders = [
    {
      "title": "Home Service - Tune Up",
      "workshop": "Bengkel Jaya Motor",
      "date": "18 Jun 2026 • 10:00 WIB",
      "price": "Rp 250.000",
      "status": "Menunggu",
      "statusColor": Colors.orange,
    },
    {
      "title": "Ganti Kampas Rem",
      "workshop": "Bengkel Jaya Motor",
      "date": "18 Jun 2026 • 15:30 WIB",
      "price": "Rp 260.000",
      "status": "Menunggu",
      "statusColor": Colors.orange,
    },
    {
      "title": "Ganti Oli Mesin",
      "workshop": "Central Auto Service",
      "date": "17 Jun 2026 • 11:30 WIB",
      "price": "Rp 385.000",
      "status": "Proses",
      "statusColor": Colors.blue,
    },
    {
      "title": "Booking Servis AC",
      "workshop": "Sinar Surya AC",
      "date": "12 Jun 2026 • 14:00 WIB",
      "price": "Rp 450.000",
      "status": "Selesai",
      "statusColor": Colors.green,
    },
    {
      "title": "Ganti Aki Mobil",
      "workshop": "Bengkel Jaya Motor",
      "date": "05 Jun 2026 • 09:00 WIB",
      "price": "Rp 780.000",
      "status": "Dibatalkan",
      "statusColor": Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter mock orders dynamically using widget properties
    final filteredOrders = _mockOrders.where((o) {
      if (widget.selectedStatusFilter == "Semua") return true;
      return o['status'] == widget.selectedStatusFilter;
    }).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Pesanan Saya",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          // Horizontal filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                _buildOrderStatusFilterPill("Semua"),
                const SizedBox(width: 8),
                _buildOrderStatusFilterPill("Menunggu"),
                const SizedBox(width: 8),
                _buildOrderStatusFilterPill("Proses"),
                const SizedBox(width: 8),
                _buildOrderStatusFilterPill("Selesai"),
                const SizedBox(width: 8),
                _buildOrderStatusFilterPill("Dibatalkan"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "Tidak ada pesanan",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildOrderCard(
                          title: order['title'],
                          workshop: order['workshop'],
                          date: order['date'],
                          price: order['price'],
                          status: order['status'] == "Menunggu" ? "Menunggu Konfirmasi" : order['status'],
                          statusColor: order['statusColor'],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusFilterPill(String status) {
    final isActive = widget.selectedStatusFilter == status;
    return GestureDetector(
      onTap: () {
        widget.onFilterChanged(status);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF64748B),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String title,
    required String workshop,
    required String date,
    required String price,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(workshop, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: Colors.grey.shade400, size: 14),
              const SizedBox(width: 6),
              Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
