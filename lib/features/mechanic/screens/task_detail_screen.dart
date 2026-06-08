import 'package:flutter/material.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/mechanic/models/task_model.dart';
import 'package:bengkel/features/mechanic/screens/live_tracking_screen.dart'; // Nanti kita buat file ini

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isAccepted = false; // Simulasi status terima tugas

  @override
  void initState() {
    super.initState();
    // Cek apakah tugas sudah diterima sebelumnya (misal dari database)
    _isAccepted = widget.task.status == 'Accepted' || widget.task.status == 'On-the-way';
  }

  void _acceptTask() {
    // TODO: Update status tugas di Supabase menjadi 'Accepted' via MechanicRepository
    setState(() {
      _isAccepted = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tugas berhasil diterima!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _startJourney() {
    // Arahkan ke halaman Live Tracking sesuai FR-MKN-04
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTrackingScreen(taskId: widget.task.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Tugas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indikator SOS (Jika Ada)
            if (widget.task.isSos)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('LAYANAN DARURAT (SOS)', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            // Informasi Pelanggan & Kendaraan
            const Text('Informasi Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGrey)),
            const SizedBox(height: 8),
            _buildInfoCard(
              title: 'Budi Santoso', // Nanti ambil dari relasi database
              subtitle: 'Toyota Avanza 2021 (B 1234 XYZ)',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),

            // Keluhan / Permintaan
            const Text('Detail Permintaan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGrey)),
            const SizedBox(height: 8),
            _buildInfoCard(
              title: 'Ganti Oli + Filter',
              subtitle: 'Pelanggan meminta pergantian oli mesin standar dan filter oli. Lokasi di garasi rumah.',
              icon: Icons.build_circle_outlined,
            ),
            const SizedBox(height: 20),

            // Lokasi Pelanggan
            const Text('Lokasi Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGrey)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Expanded(child: Text('Jl. Merdeka Raya No. 45, Jakarta Selatan', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Jarak estimasi: 3.2 km', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Bagian Bawah: Tombol Aksi
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: _isAccepted
            ? ElevatedButton(
                onPressed: _startJourney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Mulai Perjalanan (Live Tracking)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context), // Tolak/Kembali
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tolak', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _acceptTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Terima Tugas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String subtitle, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textDark, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}