import 'package:flutter/material.dart';
import 'package:bengkel/core/constants/app_colors.dart';

class SsoButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SsoButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Menggunakan Icon bawaan atau jika ada gambar asset bisa diganti Image.asset
          const Icon(
            Icons.g_mobiledata_rounded, 
            size: 32, 
            color: AppColors.textDark,
          ),
          const SizedBox(width: 8),
          const Text(
            'Lanjutkan dengan Google',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}