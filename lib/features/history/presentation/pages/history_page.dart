import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:focusdeck/core/theme/app_theme.dart';
import 'package:focusdeck/features/session/providers/session_provider.dart';
import 'package:focusdeck/features/session/data/session_model.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(userSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Session history'),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textSecondary),
        ),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 2),
        ),
        error: (e, _) => Center(
          child: Text('Failed to load history',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded,
                      color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No sessions yet',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your completed sessions will appear here.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ).animate().fadeIn(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SessionCard(session: sessions[index])
                    .animate(delay: Duration(milliseconds: 40 * index))
                    .fadeIn()
                    .slideY(begin: 0.05),
              );
            },
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isCompleted = session.status == SessionStatus.completed;
    final dateStr = DateFormat('MMM d · h:mm a').format(session.startedAt);
    final statusColor =
        isCompleted ? AppColors.success : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.deckTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCompleted ? 'Done' : 'Partial',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.bolt_rounded,
                label:
                    '${session.completedPomodoros}/${session.plannedPomodoros} pomodoros',
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.timer_outlined,
                label: '${session.focusMinutes}m focused',
                color: AppColors.info,
              ),
            ],
          ),

          if (session.cardTitles.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            ...session.cardTitles.take(2).map(
                  (title) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(right: 8, top: 1),
                          decoration: const BoxDecoration(
                            color: AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (session.cardTitles.length > 2)
              Text(
                '+${session.cardTitles.length - 2} more cards',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
          ],

          const SizedBox(height: 10),

          Text(
            dateStr,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
