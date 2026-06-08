import 'package:flutter/material.dart';
import 'package:bengkel/core/constants/app_colors.dart';

class DocumentPickerButton extends StatelessWidget {
  final String? fileName;
  final VoidCallback onTap;

  const DocumentPickerButton({
    Key? key,
    required this.fileName,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isFileSelected = fileName != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: isFileSelected ? Colors.green : AppColors.secondary,
            style: BorderStyle.solid, // PERBAIKAN DI SINI: Ubah dashed menjadi solid
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              isFileSelected ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
              color: isFileSelected ? Colors.green : AppColors.secondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              isFileSelected ? fileName! : 'Pilih Dokumen Legalitas (PDF/PNG)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isFileSelected ? Colors.green : AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (!isFileSelected) ...[
              const SizedBox(height: 4),
              const Text(
                'Maksimal ukuran file 5MB',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}