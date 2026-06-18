import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/features/auth/screens/login_screen.dart';

class PartnerOrdersScreen extends StatefulWidget {
  final String bengkelId;
  const PartnerOrdersScreen({super.key, required this.bengkelId});

  @override
  State<PartnerOrdersScreen> createState() => _PartnerOrdersScreenState();
}

class _PartnerOrdersScreenState extends State<PartnerOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  Map<String, String> _userVehicles = {}; // Store user_id -> vehicle_info
  Map<String, dynamic>? _bengkelData;
  bool _isLoading = true;
  String _activeFilter = 'Semua';
  RealtimeChannel? _channel;

  final List<String> _filters = ['Semua', 'Menunggu', 'Aktif', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _fetchBengkelData();
    _fetchOrders();
    _subscribeToOrders();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToOrders() {
    _channel = Supabase.instance.client
        .channel('partner-orders-${widget.bengkelId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => _fetchOrders(),
        )
        .subscribe();
  }

  Future<void> _fetchBengkelData() async {
    try {
      final res = await Supabase.instance.client
          .from('bengkels')
          .select()
          .eq('id', widget.bengkelId)
          .single();
      if (mounted) {
        setState(() {
          _bengkelData = res;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch orders
      final response = await Supabase.instance.client
          .from('orders')
          .select('*, profiles(name)')
          .eq('bengkel_id', widget.bengkelId)
          .order('created_at', ascending: false);

      // 2. Fetch user vehicles to map them (handling database schema fallback)
      final vehiclesResponse = await Supabase.instance.client
          .from('vehicles')
          .select();

      final Map<String, String> vMap = {};
      for (var v in vehiclesResponse) {
        final nameVal = v['name'] as String? ?? '';
        String brandAndType = '';
        if (nameVal.startsWith('{') && nameVal.endsWith('}')) {
          try {
            final decoded = jsonDecode(nameVal) as Map<String, dynamic>;
            final brand = decoded['brand'] ?? '';
            final type = decoded['type'] ?? '';
            brandAndType = '$brand $type'.trim();
            if (brandAndType.isEmpty) {
              brandAndType = decoded['name'] ?? '';
            }
          } catch (_) {
            brandAndType = nameVal;
          }
        } else {
          brandAndType = nameVal;
        }

        if (brandAndType.isNotEmpty && v['user_id'] != null) {
          vMap[v['user_id'].toString()] = brandAndType;
        }
      }

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _userVehicles = vMap;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching orders in PartnerOrdersScreen: $e");
      debugPrint(stackTrace.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      setState(() => _isLoading = true);
      await Supabase.instance.client
          .from('orders')
          .update({'status': status}).eq('id', orderId);
      _fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status pesanan diperbarui: ${_statusLabel(status)}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_activeFilter == 'Semua') return _orders;
    if (_activeFilter == 'Menunggu') {
      return _orders.where((o) => o['status'] == 'pending').toList();
    }
    if (_activeFilter == 'Aktif') {
      return _orders
          .where((o) => ['Accepted', 'Processing', 'Shipping', 'Shipped', 'On Delivery']
              .contains(o['status']))
          .toList();
    }
    if (_activeFilter == 'Selesai') {
      return _orders.where((o) => o['status'] == 'Completed').toList();
    }
    return _orders;
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'Accepted':
        return const Color(0xFF2563EB);
      case 'Processing':
        return const Color(0xFF7C3AED);
      case 'Shipping':
      case 'Shipped':
      case 'On Delivery':
        return const Color(0xFFF97316); // Orange for delivery
      case 'Completed':
        return const Color(0xFF10B981);
      case 'Rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'Accepted':
        return 'Diterima';
      case 'Processing':
        return 'Diproses';
      case 'Shipping':
      case 'Shipped':
      case 'On Delivery':
        return 'Pengiriman';
      case 'Completed':
        return 'Selesai';
      case 'Rejected':
        return 'Ditolak';
      default:
        return status ?? '-';
    }
  }

  String _formatRupiah(dynamic price) {
    if (price == null) return 'Rp 0';
    final val = price is num ? price.toInt() : int.tryParse(price.toString()) ?? 0;
    return 'Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '00:00';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '00:00';
    }
  }

  String _getItemsFromNotes(String? notes) {
    if (notes == null) return 'Suku Cadang';
    if (notes.startsWith('Pembelian Suku Cadang: ')) {
      final parts = notes.split('. Alamat:');
      return parts.first.replaceFirst('Pembelian Suku Cadang: ', '');
    }
    return notes;
  }

  String _getDeliveryInfo(String? notes) {
    if (notes == null || !notes.contains('[DELIVERY]')) return '';
    try {
      final parts = notes.split('[DELIVERY] ');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    } catch (_) {}
    return '';
  }

  void _showDispatchSheet(Map<String, dynamic> order) {
    List<Map<String, dynamic>> mechanics = [];
    bool loadingMechanics = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String dispatchType = 'Mekanik'; // 'Mekanik' | 'Kurir'
        Map<String, dynamic>? selectedMechanic;
        final courierNameCtrl = TextEditingController(text: 'Gojek');
        final driverNameCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (loadingMechanics) {
              Supabase.instance.client
                  .from('mechanics')
                  .select()
                  .eq('bengkels_id', widget.bengkelId)
                  .then((value) {
                setModalState(() {
                  mechanics = List<Map<String, dynamic>>.from(value);
                  loadingMechanics = false;
                  if (mechanics.isNotEmpty) {
                    selectedMechanic = mechanics.first;
                  }
                });
              }).catchError((_) {
                setModalState(() {
                  loadingMechanics = false;
                });
              });
              return const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kirim Pesanan (Pilih Pengantar)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),

                  // Toggle dispatch type
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Mekanik Bengkel')),
                          selected: dispatchType == 'Mekanik',
                          selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: dispatchType == 'Mekanik' ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => dispatchType = 'Mekanik');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Kurir Eksternal')),
                          selected: dispatchType == 'Kurir',
                          selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: dispatchType == 'Kurir' ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => dispatchType = 'Kurir');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (dispatchType == 'Mekanik') ...[
                    const Text('Pilih Mekanik:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    mechanics.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Tidak ada mekanik terdaftar. Silakan gunakan Kurir Eksternal.', style: TextStyle(color: Colors.red, fontSize: 12)),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Map<String, dynamic>>(
                                value: selectedMechanic,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                                onChanged: (val) {
                                  setModalState(() => selectedMechanic = val);
                                },
                                items: mechanics.map((m) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: m,
                                    child: Text(m['full_name'] ?? 'Mekanik'),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ] else ...[
                    const Text('Nama Kurir / Logistik:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: courierNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Misal: Gojek, Grab, JNE',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Nama Driver / Resi Pengiriman:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: driverNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nama pengantar atau nomor resi',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (dispatchType == 'Mekanik' && selectedMechanic == null)
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              String deliveryDetails = '';
                              if (dispatchType == 'Mekanik') {
                                deliveryDetails = 'Mekanik - ${selectedMechanic!['full_name']}';
                              } else {
                                final cName = courierNameCtrl.text.trim();
                                final dName = driverNameCtrl.text.trim();
                                deliveryDetails = '$cName${dName.isNotEmpty ? ' ($dName)' : ''}';
                              }

                              final originalNotes = order['notes'] ?? '';
                              final updatedNotes = '$originalNotes\n\n[DELIVERY] Kurir: $deliveryDetails';

                              try {
                                setState(() => _isLoading = true);
                                await Supabase.instance.client
                                    .from('orders')
                                    .update({
                                      'status': 'Shipping',
                                      'notes': updatedNotes,
                                    })
                                    .eq('id', order['id']);
                                _fetchOrders();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Pesanan berhasil dikirim!'), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal mengirim pesanan: $e'), backgroundColor: Colors.red),
                                  );
                                }
                                setState(() => _isLoading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Konfirmasi & Kirim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    final status = order['status'] as String?;
    final isSparepart = order['type'] == 'Sparepart' || order['order_type'] == 'Sparepart';
    final deliveryInfo = _getDeliveryInfo(order['notes']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Detail Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow('ID Pesanan', '#${order['id'].toString().substring(0, 8).toUpperCase()}'),
              _detailRow('Pelanggan', order['profiles']?['name'] ?? 'Pelanggan'),
              _detailRow('Jenis', order['type'] ?? order['order_type'] ?? '-'),
              _detailRow('Total', _formatRupiah(order['total'])),
              _detailRow('Waktu', _formatTime(order['created_at'])),
              if (deliveryInfo.isNotEmpty) _detailRow('Pengiriman', deliveryInfo),
              if (order['notes'] != null) _detailRow('Catatan', order['notes']),
              const SizedBox(height: 24),

              if (status == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _updateOrderStatus(order['id'], 'Rejected');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Tolak', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _updateOrderStatus(order['id'], 'Accepted');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Terima Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ] else if (status == 'Accepted') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (isSparepart) {
                        _showDispatchSheet(order);
                      } else {
                        _updateOrderStatus(order['id'], 'Processing');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isSparepart ? 'Kirim Pesanan' : 'Mulai Proses',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else if (status == 'Processing') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateOrderStatus(order['id'], 'Completed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Tandai Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else if (status == 'Shipping') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateOrderStatus(order['id'], 'Completed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Tandai Terkirim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
          const Text(': ', style: TextStyle(color: Color(0xFF64748B))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;
    final bName = _bengkelData?['name'] ?? 'Bengkel Anda';
    final isVerified = _bengkelData?['is_verified'] ?? true;
    final avatarLetter = bName.isNotEmpty ? bName[0].toUpperCase() : 'B';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Style Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF1E293B),
                    child: Text(avatarLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              isVerified ? 'Mitra Terverifikasi' : 'Mitra Bengkel',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check, color: Color(0xFF10B981), size: 12),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (r) => false,
                        );
                      }
                    },
                    child: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 20),
                  ),
                ],
              ),
            ),

            // Manajemen Pesanan Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Manajemen Pesanan',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: Color(0xFF0F172A)),
              ),
            ),

            // Tab Filters
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                children: _filters.map((f) {
                  final isActive = _activeFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _activeFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // Listing
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E293B)))
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      color: const Color(0xFF1E293B),
                      child: filtered.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.5,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                                        const SizedBox(height: 12),
                                        Text(
                                          _activeFilter == 'Semua' ? 'Belum ada pesanan' : 'Tidak ada pesanan $_activeFilter',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final order = filtered[i];
                                final status = order['status'] as String?;
                                final customerName = order['profiles']?['name'] ?? 'Pelanggan';
                                final vehicleInfo = _userVehicles[order['user_id'].toString()] ?? 'Umum / Tanpa Kendaraan';
                                final isPending = status == 'pending';
                                final isSparepart = order['type'] == 'Sparepart' || order['order_type'] == 'Sparepart';
                                final displayId = 'ORD-${order['id'].toString().substring(0, 5).toUpperCase()}';
                                final deliveryInfo = _getDeliveryInfo(order['notes']);

                                return GestureDetector(
                                  onTap: () => _showOrderDetail(order),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header: ID, Badge Status, type tag, Price, Time
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Text(
                                                    displayId,
                                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: _statusColor(status).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      _statusLabel(status),
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor(status)),
                                                    ),
                                                  ),
                                                  if (!isSparepart) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF3E8FF),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Text(
                                                        'Home',
                                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED)),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _formatRupiah(order['total']),
                                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatTime(order['created_at']),
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        // Customer details
                                        Text(
                                          customerName,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          vehicleInfo,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                        ),

                                        const SizedBox(height: 12),

                                        // Description Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isSparepart ? Icons.inventory_2_outlined : Icons.construction_rounded,
                                                size: 14,
                                                color: const Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  isSparepart ? _getItemsFromNotes(order['notes']) : (order['notes'] ?? 'Servis'),
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        if (deliveryInfo.isNotEmpty && status == 'Shipping') ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(Icons.local_shipping_outlined, size: 14, color: Color(0xFFF97316)),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Pengantar: $deliveryInfo',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFFF97316), fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],

                                        // Action buttons
                                        if (isPending) ...[
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _updateOrderStatus(order['id'], 'Accepted'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF10B981),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    elevation: 0,
                                                  ),
                                                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                                  label: const Text(
                                                    'Terima',
                                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _updateOrderStatus(order['id'], 'Rejected'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFFFF1F2),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    elevation: 0,
                                                  ),
                                                  icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 16),
                                                  label: const Text(
                                                    'Tolak',
                                                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else if (status == 'Accepted') ...[
                                          const SizedBox(height: 14),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 38,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                if (isSparepart) {
                                                  _showDispatchSheet(order);
                                                } else {
                                                  _updateOrderStatus(order['id'], 'Processing');
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1E293B),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                elevation: 0,
                                              ),
                                              child: Text(
                                                isSparepart ? 'Kirim Pesanan' : 'Mulai Proses',
                                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ] else if (status == 'Processing') ...[
                                          const SizedBox(height: 14),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 38,
                                            child: ElevatedButton(
                                              onPressed: () => _updateOrderStatus(order['id'], 'Completed'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1E293B),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                elevation: 0,
                                              ),
                                              child: const Text(
                                                'Tandai Selesai',
                                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ] else if (status == 'Shipping') ...[
                                          const SizedBox(height: 14),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 38,
                                            child: ElevatedButton(
                                              onPressed: () => _updateOrderStatus(order['id'], 'Completed'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1E293B),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                elevation: 0,
                                              ),
                                              child: const Text(
                                                'Tandai Terkirim',
                                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
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
