import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      // Fetch pesanan sparepart & booking
      final orders = await Supabase.instance.client
          .from('orders')
          .select('*, bengkels(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Fetch home service tasks
      final tasks = await Supabase.instance.client
          .from('home_service_tasks')
          .select('*, bengkels(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Fetch bookings
      final bookings = await Supabase.instance.client
          .from('bookings')
          .select('*, bengkels(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        final allOrders = <Map<String, dynamic>>[];

        // Merge orders
        for (final o in List<Map<String, dynamic>>.from(orders)) {
          allOrders.add({
            ...o,
            'display_title': o['type'] ?? 'Pembelian Sparepart',
            'display_workshop': o['bengkels']?['name'] ?? 'Bengkel Mitra',
            'display_status': _mapOrderStatus(o['status']),
            'display_price': _formatRupiah((o['total'] as num?)?.toInt() ?? 0),
            'display_date': _formatDate(o['created_at']),
            'order_category': 'sparepart',
          });
        }

        // Merge tasks
        for (final t in List<Map<String, dynamic>>.from(tasks)) {
          allOrders.add({
            ...t,
            'display_title': t['is_sos'] == true ? '🚨 Home Service SOS' : 'Home Service',
            'display_workshop': t['bengkels']?['name'] ?? 'Bengkel Mitra',
            'display_status': _mapTaskStatus(t['status']),
            'display_price': _formatRupiah((t['estimated_cost'] as num?)?.toInt() ?? 0),
            'display_date': _formatDate(t['created_at']),
            'order_category': 'homeservice',
          });
        }

        // Merge bookings
        for (final b in List<Map<String, dynamic>>.from(bookings)) {
          allOrders.add({
            ...b,
            'display_title': 'Booking Servis',
            'display_workshop': b['bengkels']?['name'] ?? 'Bengkel Mitra',
            'display_status': _mapBookingStatus(b['status']),
            'display_price': '-',
            'display_date': _formatDate(b['created_at']),
            'order_category': 'booking',
          });
        }

        // Sort by created_at desc
        allOrders.sort((a, b) {
          final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
          final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

        setState(() {
          _orders = allOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error fetch orders: $e');
      }
    }
  }

  String _mapOrderStatus(String? s) {
    switch (s) {
      case 'pending': return 'Menunggu';
      case 'Accepted': return 'Proses';
      case 'Processing': return 'Proses';
      case 'Shipping': return 'Proses';
      case 'Shipped': return 'Proses';
      case 'Completed': return 'Selesai';
      case 'Rejected': return 'Dibatalkan';
      default: return 'Menunggu';
    }
  }

  String _mapTaskStatus(String? s) {
    switch (s) {
      case 'Pending': return 'Menunggu';
      case 'Accepted': return 'Proses';
      case 'Completed': return 'Selesai';
      case 'Rejected': return 'Dibatalkan';
      default: return 'Menunggu';
    }
  }

  String _mapBookingStatus(String? s) {
    switch (s) {
      case 'pending': return 'Menunggu';
      case 'confirmed': return 'Proses';
      case 'completed': return 'Selesai';
      case 'cancelled': return 'Dibatalkan';
      default: return 'Menunggu';
    }
  }

  String _formatRupiah(int price) {
    if (price == 0) return '-';
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Menunggu': return const Color(0xFFF59E0B);
      case 'Proses': return const Color(0xFF3B82F6);
      case 'Selesai': return const Color(0xFF10B981);
      case 'Dibatalkan': return const Color(0xFFEF4444);
      default: return const Color(0xFF94A3B8);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'homeservice': return Icons.home_repair_service_rounded;
      case 'booking': return Icons.calendar_month_rounded;
      default: return Icons.shopping_bag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter orders based on selected status
    final filteredOrders = _orders.where((o) {
      if (widget.selectedStatusFilter == 'Semua') return true;
      return o['display_status'] == widget.selectedStatusFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pesanan Saya',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3B82F6)),
                    onPressed: _fetchOrders,
                  ),
                ],
              ),
            ),
            // Filter pills
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: ['Semua', 'Menunggu', 'Proses', 'Selesai', 'Dibatalkan'].map((s) {
                  final isActive = widget.selectedStatusFilter == s;
                  return GestureDetector(
                    onTap: () => widget.onFilterChanged(s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? AppColors.primary : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(color: isActive ? Colors.white : const Color(0xFF64748B), fontWeight: isActive ? FontWeight.bold : FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Orders list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      color: const Color(0xFF3B82F6),
                      child: filteredOrders.isEmpty
                          ? ListView(children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        _orders.isEmpty ? 'Belum ada pesanan' : 'Tidak ada pesanan "${widget.selectedStatusFilter}"',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
                                final status = order['display_status'] as String;
                                final statusColor = _statusColor(status);
                                final category = order['order_category'] as String;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(_categoryIcon(category), size: 16, color: const Color(0xFF64748B)),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                                                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                            Text(order['display_price'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(order['display_title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                                        const SizedBox(height: 4),
                                        Text(order['display_workshop'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                        const SizedBox(height: 8),
                                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, color: Colors.grey.shade400, size: 14),
                                            const SizedBox(width: 6),
                                            Text(order['display_date'] as String, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
