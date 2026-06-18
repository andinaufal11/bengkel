import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerInventoryScreen extends StatefulWidget {
  final String bengkelId;
  const PartnerInventoryScreen({super.key, required this.bengkelId});

  @override
  State<PartnerInventoryScreen> createState() => _PartnerInventoryScreenState();
}

class _PartnerInventoryScreenState extends State<PartnerInventoryScreen> {
  List<Map<String, dynamic>> _parts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final List<String> _categories = ['Semua', 'Oli & Filter', 'Ban & Velg', 'Rem', 'Aki', 'Mesin', 'Lainnya'];
  String _activeCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchParts();
  }

  Future<void> _fetchParts() async {
    setState(() => _isLoading = true);
    try {
      var query = Supabase.instance.client
          .from('spare_parts')
          .select()
          .eq('bengkel_id', widget.bengkelId)
          .order('created_at', ascending: false);

      final response = await query;
      if (mounted) {
        setState(() {
          _parts = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat inventaris: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredParts {
    return _parts.where((p) {
      final matchCategory = _activeCategory == 'Semua' || p['category'] == _activeCategory;
      final matchSearch = p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  void _showAddEditDialog({Map<String, dynamic>? part}) {
    final nameCtrl = TextEditingController(text: part?['name'] ?? '');
    final priceCtrl = TextEditingController(text: part?['price']?.toString() ?? '');
    final stockCtrl = TextEditingController(text: part?['stock']?.toString() ?? '');
    final descCtrl = TextEditingController(text: part?['description'] ?? '');
    String selectedCategory = part?['category'] ?? 'Oli & Filter';
    List<String> compatibility = List<String>.from(part?['compatibility_tags'] ?? ['mobil']);
    final isEdit = part != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? 'Edit Spare Part' : 'Tambah Spare Part', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(nameCtrl, 'Nama Spare Part'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: _fieldDecoration('Kategori'),
                  items: ['Oli & Filter', 'Ban & Velg', 'Rem', 'Aki', 'Mesin', 'Lainnya']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField(priceCtrl, 'Harga (Rp)', keyboard: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField(stockCtrl, 'Stok', keyboard: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Kompatibilitas:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                Row(
                  children: ['mobil', 'motor'].map((type) {
                    final isSelected = compatibility.contains(type);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type == 'mobil' ? '🚗 Mobil' : '🏍️ Motor'),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        checkmarkColor: const Color(0xFF2563EB),
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              compatibility.add(type);
                            } else {
                              compatibility.remove(type);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _buildField(descCtrl, 'Deskripsi (opsional)', maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                Navigator.pop(ctx);
                final data = {
                  'bengkel_id': widget.bengkelId,
                  'name': nameCtrl.text.trim(),
                  'category': selectedCategory,
                  'price': int.tryParse(priceCtrl.text.trim()) ?? 0,
                  'stock': int.tryParse(stockCtrl.text.trim()) ?? 0,
                  'description': descCtrl.text.trim(),
                  'compatibility_tags': compatibility,
                };
                if (isEdit) {
                  await _updatePart(part['id'] as String, data);
                } else {
                  await _addPart(data);
                }
              },
              child: Text(isEdit ? 'Simpan' : 'Tambah', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  TextField _buildField(TextEditingController ctrl, String label, {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: _fieldDecoration(label),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
    );
  }

  Future<void> _addPart(Map<String, dynamic> data) async {
    try {
      await Supabase.instance.client.from('spare_parts').insert(data);
      _fetchParts();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spare part berhasil ditambahkan'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _updatePart(String id, Map<String, dynamic> data) async {
    try {
      await Supabase.instance.client.from('spare_parts').update(data).eq('id', id);
      _fetchParts();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spare part berhasil diperbarui'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deletePart(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Spare Part', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin menghapus spare part ini dari inventaris?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('spare_parts').delete().eq('id', id);
      _fetchParts();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spare part dihapus'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e'), backgroundColor: Colors.red));
    }
  }

  String _formatRupiah(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredParts;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inventaris Spare Part', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
            Text('${_parts.length} item tersimpan', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
              icon: const Icon(Icons.add, color: Colors.white, size: 16),
              label: const Text('Tambah', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Colors.grey.shade100)),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari spare part...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          // Category pills
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final isActive = _activeCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _activeCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade200),
                    ),
                    child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? Colors.white : const Color(0xFF475569))),
                  ),
                );
              },
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : RefreshIndicator(
                    onRefresh: _fetchParts,
                    color: const Color(0xFF2563EB),
                    child: filtered.isEmpty
                        ? ListView(children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text(_searchQuery.isNotEmpty ? 'Tidak ditemukan' : 'Belum ada spare part', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                  ],
                                ),
                              ),
                            )
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final p = filtered[i];
                              final stock = p['stock'] as int? ?? 0;
                              final tags = List<String>.from(p['compatibility_tags'] ?? []);
                              final isLowStock = stock < 5;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isLowStock ? Colors.orange.shade200 : Colors.grey.shade100),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                                      child: const Center(child: Icon(Icons.settings_rounded, color: Color(0xFF2563EB), size: 24)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(child: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                              if (isLowStock)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                                                  child: Text('Stok Rendah', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(p['category'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(_formatRupiah(p['price'] as int? ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text('Stok: $stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: stock > 0 ? Colors.green.shade700 : Colors.red.shade700)),
                                              ),
                                              const SizedBox(width: 8),
                                              ...tags.map((t) => Container(
                                                margin: const EdgeInsets.only(right: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                                child: Text(t == 'mobil' ? '🚗' : '🏍️', style: const TextStyle(fontSize: 10)),
                                              )),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 20),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      onSelected: (v) {
                                        if (v == 'edit') _showAddEditDialog(part: p);
                                        if (v == 'delete') _deletePart(p['id']);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Edit')])),
                                        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 16, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
