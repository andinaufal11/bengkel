import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerFinanceScreen extends StatefulWidget {
  final String bengkelId;
  const PartnerFinanceScreen({super.key, required this.bengkelId});

  @override
  State<PartnerFinanceScreen> createState() => _PartnerFinanceScreenState();
}

class _PartnerFinanceScreenState extends State<PartnerFinanceScreen> {
  Map<String, dynamic> _summary = {
    'total_revenue': 0,
    'monthly_revenue': 0,
    'pending_revenue': 0,
    'total_orders': 0,
  };
  List<Map<String, dynamic>> _withdrawals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch completed orders
      final orders = await Supabase.instance.client
          .from('orders')
          .select('total, status, created_at')
          .eq('bengkel_id', widget.bengkelId);

      // Fetch withdrawals
      final withdrawals = await Supabase.instance.client
          .from('withdrawals')
          .select()
          .eq('bengkel_id', widget.bengkelId)
          .order('created_at', ascending: false);

      if (mounted) {
        final orderList = List<Map<String, dynamic>>.from(orders);
        final now = DateTime.now();
        final firstOfMonth = DateTime(now.year, now.month, 1);

        int totalRevenue = 0;
        int monthlyRevenue = 0;
        int pendingRevenue = 0;

        for (final o in orderList) {
          final total = (o['total'] as num?)?.toInt() ?? 0;
          if (o['status'] == 'Completed') {
            totalRevenue += total;
            final createdAt = DateTime.tryParse(o['created_at'] ?? '') ?? DateTime(2000);
            if (createdAt.isAfter(firstOfMonth)) monthlyRevenue += total;
          } else if (o['status'] == 'Accepted' || o['status'] == 'Processing') {
            pendingRevenue += total;
          }
        }

        setState(() {
          _summary = {
            'total_revenue': totalRevenue,
            'monthly_revenue': monthlyRevenue,
            'pending_revenue': pendingRevenue,
            'total_orders': orderList.where((o) => o['status'] == 'Completed').length,
          };
          _withdrawals = List<Map<String, dynamic>>.from(withdrawals);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  void _showWithdrawDialog() {
    final amountCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final accountCtrl = TextEditingController();
    final accountNameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Ajukan Penarikan Dana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text('Saldo tersedia: ${_formatRupiah(_summary['total_revenue'] as int)}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            _inputField(amountCtrl, 'Jumlah Penarikan (Rp)', TextInputType.number),
            const SizedBox(height: 12),
            _inputField(bankCtrl, 'Nama Bank (contoh: BCA, BRI)'),
            const SizedBox(height: 12),
            _inputField(accountCtrl, 'Nomor Rekening', TextInputType.number),
            const SizedBox(height: 12),
            _inputField(accountNameCtrl, 'Nama Pemilik Rekening'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _submitWithdrawal(
                    amount: int.tryParse(amountCtrl.text.trim()) ?? 0,
                    bankName: bankCtrl.text.trim(),
                    accountNumber: accountCtrl.text.trim(),
                    accountName: accountNameCtrl.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Ajukan Penarikan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, [TextInputType keyboard = TextInputType.text]) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
      ),
    );
  }

  Future<void> _submitWithdrawal({required int amount, required String bankName, required String accountNumber, required String accountName}) async {
    if (amount <= 0 || bankName.isEmpty || accountNumber.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi semua field'), backgroundColor: Colors.orange));
      return;
    }
    try {
      await Supabase.instance.client.from('withdrawals').insert({
        'bengkel_id': widget.bengkelId,
        'amount': amount,
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_name': accountName,
        'status': 'pending',
      });
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Penarikan ${_formatRupiah(amount)} berhasil diajukan!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  Color _withdrawStatusColor(String? status) {
    switch (status) {
      case 'approved': return const Color(0xFF10B981);
      case 'rejected': return const Color(0xFFEF4444);
      default: return const Color(0xFFF59E0B);
    }
  }

  String _withdrawStatusLabel(String? status) {
    switch (status) {
      case 'approved': return 'Disetujui';
      case 'rejected': return 'Ditolak';
      default: return 'Menunggu';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text('Dashboard Keuangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF10B981)), onPressed: _loadData),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Colors.grey.shade100)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF10B981),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revenue Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Pendapatan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(
                            _formatRupiah(_summary['total_revenue'] as int),
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _miniStat('Bulan Ini', _formatRupiah(_summary['monthly_revenue'] as int), Colors.white70),
                              const SizedBox(width: 24),
                              _miniStat('Dalam Proses', _formatRupiah(_summary['pending_revenue'] as int), Colors.white70),
                              const SizedBox(width: 24),
                              _miniStat('Pesanan Selesai', '${_summary['total_orders']}x', Colors.white70),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Withdraw Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showWithdrawDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.account_balance_rounded, color: Colors.white),
                        label: const Text('Ajukan Penarikan Dana', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Riwayat Penarikan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),

                    if (_withdrawals.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text('Belum ada riwayat penarikan', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...(_withdrawals.map((w) {
                        final status = w['status'] as String?;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: _withdrawStatusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.account_balance_rounded, color: _withdrawStatusColor(status), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_formatRupiah((w['amount'] as num?)?.toInt() ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                    const SizedBox(height: 2),
                                    Text('${w['bank_name']} • ${w['account_number']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    Text(_formatDate(w['created_at']), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _withdrawStatusColor(status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_withdrawStatusLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _withdrawStatusColor(status))),
                              ),
                            ],
                          ),
                        );
                      }).toList()),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
