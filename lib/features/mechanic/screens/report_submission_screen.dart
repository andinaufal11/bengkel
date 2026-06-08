import 'package:flutter/material.dart';

class ReportSubmissionScreen extends StatefulWidget {
  final String taskId;
  const ReportSubmissionScreen({super.key, required this.taskId});

  @override
  State<ReportSubmissionScreen> createState() => _ReportSubmissionScreenState();
}

class _ReportSubmissionScreenState extends State<ReportSubmissionScreen> {
  final _descController = TextEditingController();
  final _sparepartController = TextEditingController();

  void _submitReport() {
    if (_descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deskripsi wajib diisi!')));
      return;
    }
    // TODO: Panggil repository submitServiceReport di sini
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil dikirim, tugas selesai!')));
    Navigator.pop(context); // Kembali ke Dashboard
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Servis')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Deskripsi Pekerjaan')),
            const SizedBox(height: 10),
            TextField(controller: _sparepartController, decoration: const InputDecoration(labelText: 'Sparepart (Opsional)')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submitReport, child: const Text('Kirim Laporan & Selesaikan Tugas')),
          ],
        ),
      ),
    );
  }
}