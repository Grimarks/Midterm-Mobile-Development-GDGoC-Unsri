import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusdeck/core/theme/app_theme.dart';
import 'package:focusdeck/features/auth/providers/auth_provider.dart';

final userStatsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value({});
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.data() ?? {});
});

class StatsRowWidget extends ConsumerWidget {
  const StatsRowWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);

    return statsAsync.when(
      loading: () => _buildRow(context, sessions: '-', minutes: '-', streak: '-'),
      error: (_, __) => _buildRow(context, sessions: '0', minutes: '0', streak: '-'),
      data: (data) {
        final sessions = (data['totalSessions'] as num?)?.toInt() ?? 0;
        final minutes = (data['totalFocusMinutes'] as num?)?.toInt() ?? 0;
        final hours = minutes >= 60 ? '${minutes ~/ 60}h' : '${minutes}m';
        final streak = (data['currentStreak'] as num?)?.toInt() ?? 0;
        return _buildRow(
          context,
          sessions: '$sessions',
          minutes: hours,
          streak: streak > 0 ? '$streak' : '-',
        );
      },
    );
  }

  Widget _buildRow(BuildContext context,
      {required String sessions,
        required String minutes,
        required String streak}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatItem(
            value: sessions,
            label: 'Sessions',
            icon: Icons.bolt_rounded,
            iconColor: AppColors.accent,
          ),
          _Divider(),
          _StatItem(
            value: minutes,
            label: 'Focus time',
            icon: Icons.timer_rounded,
            iconColor: AppColors.info,
          ),
          _Divider(),
          _StatItem(
            value: streak,
            label: 'Streak',
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
    );
  }
}