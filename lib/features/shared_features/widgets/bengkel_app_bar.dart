import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class BengkelAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;

  const BengkelAppBar({super.key, required this.subtitle});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.build_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'BENGKEL',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    TextSpan(
                      text: 'PRO',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                subtitle.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const Spacer(),
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 24),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                'SA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}