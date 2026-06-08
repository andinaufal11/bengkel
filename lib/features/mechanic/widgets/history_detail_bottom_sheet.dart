import 'package:flutter/material.dart';
import 'package:bengkel/core/constants/app_colors.dart';

class HistoryDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  const HistoryDetailBottomSheet({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isRejected = data['status'] == 'Rejected';

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Garis handle minimalis di paling atas sheet
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detail Riwayat Tugas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isRejected ? AppColors.error : AppColors.success,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isRejected ? 'DITOLAK' : 'SELESAI',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: AppColors.border),

          // Rincian Informasi Lengkap
          _buildDetailRow('Nama Order', data['service']),
          _buildDetailRow('Pelanggan', data['customer']),
          _buildDetailRow('Kendaraan', data['vehicle']),
          _buildDetailRow('Waktu Eksekusi', '${data['date']} | ${data['time']}'),
          _buildDetailRow('Lokasi Servis', data['address']),
          
          // Kondisi kondisional: jika ditolak munculkan alasan, jika sukses munculkan catatan
          if (isRejected)
            _buildDetailRow('Alasan Penolakan', data['reason'], isAlert: true)
          else
            _buildDetailRow('Catatan Servis Mekanik', data['note']),

          const Divider(height: 32, color: AppColors.border),
          
          // Pendapatan bersih
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pendapatan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                data['income'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isRejected ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Helper widget untuk baris detail
  Widget _buildDetailRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w600,
              color: isAlert ? AppColors.error : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}