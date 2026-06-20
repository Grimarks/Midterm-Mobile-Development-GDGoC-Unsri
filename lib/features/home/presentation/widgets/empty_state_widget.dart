import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:focusdeck/core/theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.layers_outlined,
              color: AppColors.textMuted,
              size: 36,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'No decks yet',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 18),
          ),

          const SizedBox(height: 8),

          Text(
            'Create your first deck to start setting\nintentions before each focus session.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          OutlinedButton.icon(
            onPressed: () => context.push('/deck/new'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'Create first deck',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
    );
  }
}
