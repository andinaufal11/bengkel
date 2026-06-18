import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/features/mechanic/repository/mechanic_repository.dart';

class ReportSubmissionScreen extends StatefulWidget {
  final String taskId;
  final String mechanicId;
  const ReportSubmissionScreen({super.key, required this.taskId, required this.mechanicId});

  @override
  State<ReportSubmissionScreen> createState() => _ReportSubmissionScreenState();
}

class _ReportSubmissionScreenState extends State<ReportSubmissionScreen> {
  final MechanicRepository _repository = MechanicRepository();
  final _descController = TextEditingController();
  final _sparepartController = TextEditingController();
  final _costController = TextEditingController();

  bool _isSubmitting = false;
  Map<String, dynamic>? _taskData;
  bool _isLoadingTask = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      final task = await Supabase.instance.client
          .from('home_service_tasks')
          .select()
          .eq('id', widget.taskId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _taskData = task;
          _isLoadingTask = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTask = false);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _sparepartController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi pekerjaan wajib diisi!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Update estimated cost if provided
      if (_costController.text.trim().isNotEmpty) {
        final cost = int.tryParse(_costController.text.trim());
        if (cost != null) {
          await Supabase.instance.client
              .from('home_service_tasks')
              .update({'estimated_cost': cost})
              .eq('id', widget.taskId);
        }
      }

      await _repository.submitServiceReport(
        taskId: widget.taskId,
        mechanicId: widget.mechanicId,
        description: _descController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Laporan berhasil dikirim! Tugas selesai.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate completion
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim laporan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Laporan Servis',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: _isLoadingTask
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task summary card
                  if (_taskData != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tugas yang diselesaikan', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            _taskData!['customer_name'] ?? 'Pelanggan',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _taskData!['address'] ?? '-',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _taskData!['notes'] ?? 'Tidak ada catatan',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    'Detail Laporan Servis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Isi laporan dengan jujur. Laporan ini akan dikirim ke pelanggan dan mitra bengkel.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Deskripsi pekerjaan
                  _buildLabel('Deskripsi Pekerjaan *'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    maxLines: 5,
                    decoration: _inputDecoration(
                      hint: 'Jelaskan pekerjaan yang sudah dilakukan (contoh: Ganti oli mesin, cek tekanan ban, bersihkan filter udara...)',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sparepart yang digunakan
                  _buildLabel('Sparepart yang Digunakan (Opsional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sparepartController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      hint: 'Contoh: Oli Mesin Shell 1L, Filter Udara Honda Original',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Biaya servis
                  _buildLabel('Total Biaya Servis (Rp)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      hint: 'Contoh: 250000',
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Kirim Laporan & Selesaikan Tugas',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151)));
  }

  InputDecoration _inputDecoration({required String hint, String? prefixText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixText: prefixText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
    );
  }
}