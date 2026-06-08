import 'package:flutter/material.dart';
import 'package:bengkel/core/constants/app_colors.dart';

class StatusToggle extends StatelessWidget {
  final String currentStatus;
  final Function(String) onStatusChanged;
  final bool isLoading;

  const StatusToggle({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubah Status', 
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGrey, fontSize: 12)
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // Background abu-abu tipis (cardBg)
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: AppColors.border)
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  _buildOption('Available', 'Tersedia', AppColors.success),
                  _buildOption('On-Duty', 'Bertugas', Colors.orange),
                  _buildOption('Offline', 'Offline', AppColors.textGrey),
                ],
              ),
              if (isLoading) 
                const SizedBox(
                  height: 20, 
                  width: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary)
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOption(String statusCode, String displayLabel, Color activeColor) {
    bool isSelected = currentStatus == statusCode;

    return Expanded(
      child: GestureDetector(
        onTap: isLoading ? null : () => onStatusChanged(statusCode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              displayLabel,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}