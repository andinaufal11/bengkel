import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerMechanicScreen extends StatefulWidget {
  final String bengkelId;
  final String bengkelName;

  const PartnerMechanicScreen({
    super.key,
    required this.bengkelId,
    required this.bengkelName,
  });

  @override
  State<PartnerMechanicScreen> createState() => _PartnerMechanicScreenState();
}

class _PartnerMechanicScreenState extends State<PartnerMechanicScreen> {
  List<Map<String, dynamic>> _mechanics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMechanics();
  }

  Future<void> _fetchMechanics() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('mechanics')
          .select('*, profiles(name, email)')
          .eq('bengkels_id', widget.bengkelId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _mechanics = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data mekanik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateMechanicStatus(String mechanicId, String status) async {
    try {
      await Supabase.instance.client
          .from('mechanics')
          .update({'operational_status': status})
          .eq('id', mechanicId);
      _fetchMechanics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteMechanic(String mechanicId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Mekanik', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin menghapus mekanik ini dari bengkel Anda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('mechanics').delete().eq('id', mechanicId);
      _fetchMechanics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mekanik berhasil dihapus'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? mechanic}) {
    final nameCtrl = TextEditingController(text: mechanic?['full_name'] ?? '');
    final emailCtrl = TextEditingController(text: mechanic?['profiles']?['email'] ?? '');
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: mechanic?['phone'] ?? '');
    final isEdit = mechanic != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          isEdit ? 'Edit Mekanik' : 'Tambah Mekanik Baru',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(nameCtrl, 'Nama Lengkap', Icons.person_rounded),
              const SizedBox(height: 12),
              _buildDialogField(phoneCtrl, 'No. HP', Icons.phone_rounded, keyboard: TextInputType.phone),
              if (!isEdit) ...[
                const SizedBox(height: 12),
                _buildDialogField(emailCtrl, 'Email Login', Icons.email_rounded, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _buildDialogField(passwordCtrl, 'Password Awal', Icons.lock_rounded, obscure: true),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              if (isEdit) {
                await _updateMechanicData(mechanic['id'] as String, nameCtrl.text.trim(), phoneCtrl.text.trim());
              } else {
                await _createMechanic(nameCtrl.text.trim(), emailCtrl.text.trim(), passwordCtrl.text.trim(), phoneCtrl.text.trim());
              }
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String label, IconData icon, {TextInputType keyboard = TextInputType.text, bool obscure = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Future<void> _createMechanic(String name, String email, String password, String phone) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama, email, dan password wajib diisi'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    try {
      // Create auth user
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'role': 'mechanic', 'name': name},
      );
      if (authResponse.user == null) throw Exception('Gagal membuat akun');

      // Create profile
      await Supabase.instance.client.from('profiles').upsert({
        'id': authResponse.user!.id,
        'name': name,
        'email': email,
        'role': 'mechanic',
        'phone': phone,
      });

      // Create mechanic record
      await Supabase.instance.client.from('mechanics').insert({
        'user_id': authResponse.user!.id,
        'bengkels_id': widget.bengkelId,
        'full_name': name,
        'phone': phone,
        'operational_status': 'Offline',
      });

      _fetchMechanics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mekanik "$name" berhasil ditambahkan!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan mekanik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateMechanicData(String mechanicId, String name, String phone) async {
    try {
      await Supabase.instance.client.from('mechanics').update({
        'full_name': name,
        'phone': phone,
      }).eq('id', mechanicId);
      _fetchMechanics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data mekanik berhasil diperbarui'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Available': return const Color(0xFF10B981);
      case 'On-Duty': return const Color(0xFFF59E0B);
      default: return const Color(0xFF94A3B8);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Available': return 'Tersedia';
      case 'On-Duty': return 'Bertugas';
      default: return 'Offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kelola Mekanik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
            Text('${_mechanics.length} mekanik terdaftar', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 16),
              label: const Text('Tambah', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : RefreshIndicator(
              onRefresh: _fetchMechanics,
              color: const Color(0xFF2563EB),
              child: _mechanics.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                  child: const Icon(Icons.engineering_rounded, size: 48, color: Color(0xFF94A3B8)),
                                ),
                                const SizedBox(height: 16),
                                const Text('Belum ada mekanik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                const SizedBox(height: 8),
                                const Text('Tambahkan mekanik untuk mulai beroperasi', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddEditDialog(),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  label: const Text('Tambah Mekanik', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _mechanics.length,
                      itemBuilder: (context, index) {
                        final mechanic = _mechanics[index];
                        final status = mechanic['operational_status'] as String? ?? 'Offline';
                        final name = mechanic['full_name'] as String? ?? 'Mekanik';
                        final phone = mechanic['phone'] as String? ?? '-';
                        final avatarLetter = name.isNotEmpty ? name[0].toUpperCase() : 'M';

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
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                    child: Text(avatarLetter, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 18)),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: _statusColor(status),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                    const SizedBox(height: 2),
                                    Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor(status)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        _showAddEditDialog(mechanic: mechanic);
                                      } else if (value == 'delete') {
                                        _deleteMechanic(mechanic['id']);
                                      } else {
                                        _updateMechanicStatus(mechanic['id'], value);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Edit')])),
                                      PopupMenuItem(value: 'Available', child: Row(children: [Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)), const SizedBox(width: 8), const Text('Set Available')])),
                                      PopupMenuItem(value: 'On-Duty', child: Row(children: [Icon(Icons.work_rounded, size: 16, color: Color(0xFFF59E0B)), const SizedBox(width: 8), const Text('Set On-Duty')])),
                                      PopupMenuItem(value: 'Offline', child: Row(children: [Icon(Icons.cancel_rounded, size: 16, color: Color(0xFF94A3B8)), const SizedBox(width: 8), const Text('Set Offline')])),
                                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 16, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
