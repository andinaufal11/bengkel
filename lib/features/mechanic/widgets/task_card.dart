import 'package:flutter/material.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/mechanic/models/task_model.dart';
import 'package:bengkel/features/mechanic/screens/task_detail_screen.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    // Menentukan warna tag di pojok kanan atas berdasarkan urgensi tugas
    Color tagColor = AppColors.secondary;
    String tagText = 'Berlangsung';

    if (task.status == 'Pending') {
      tagColor = Colors.orange;
      tagText = 'Baru';
    } else if (task.isSos) {
      tagColor = AppColors.error;
      tagText = 'SOS';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(task: task),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), // cardBg
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: AppColors.border)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Text(
                  task.isSos ? 'TUGAS DARURAT' : 'TUGAS AKTIF', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: task.isSos ? AppColors.error : AppColors.secondary,
                    fontSize: 12
                  )
                ), 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                  decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(4)), 
                  child: Text(
                    tagText, 
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                  )
                )
              ]
            ),
            const SizedBox(height: 8),
            
            // -----------------------------------------------------------------
            // PERUBAHAN POIN 2: NAMA SERVIS & JADWAL DINAMIS DARI MODEL
            // -----------------------------------------------------------------
            Text(
              task.serviceName, // Data dinamis
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)
            ),
            Text(
              'ID Pelanggan: ${task.customerId}', // Data dinamis
              style: const TextStyle(color: AppColors.textGrey, fontSize: 14)
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  task.isSos ? Icons.warning_amber_rounded : Icons.calendar_month, 
                  size: 16, 
                  color: task.isSos ? AppColors.error : AppColors.secondary
                ),
                const SizedBox(width: 4),
                Text(
                  // Jika SOS munculkan peringatan, jika biasa munculkan Tanggal & Jam
                  task.isSos 
                      ? 'Respons Segera (SOS Darurat)' 
                      : '${task.date} • ${task.time}', 
                  style: TextStyle(
                    fontSize: 12, 
                    color: task.isSos ? AppColors.error : AppColors.secondary, 
                    fontWeight: FontWeight.w500
                  )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}