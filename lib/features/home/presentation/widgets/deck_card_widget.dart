import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusdeck/core/theme/app_theme.dart';
import 'package:focusdeck/features/deck/data/deck_model.dart';
import 'package:focusdeck/features/deck/providers/deck_provider.dart';
import 'package:focusdeck/features/auth/providers/auth_provider.dart';

class DeckCardWidget extends ConsumerWidget {
  final Deck deck;

  const DeckCardWidget({super.key, required this.deck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorIndex = deck.colorIndex % AppColors.cardColors.length;
    final bgColor = AppColors.cardColors[colorIndex];
    final accentColor = AppColors.cardAccents[colorIndex];

    return GestureDetector(
      onTap: () => context.push('/session/${deck.id}'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.title,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${deck.cards.length} card${deck.cards.length != 1 ? 's' : ''} · ${deck.sessionCount} session${deck.sessionCount != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: accentColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _MenuButton(deck: deck, accentColor: accentColor),
              ],
            ),

            if (deck.cards.isNotEmpty) ...[
              const SizedBox(height: 14),
              // Card previews
              ...deck.cards.take(3).map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(right: 10, top: 1),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            card.title,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary.withOpacity(0.85),
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 14),

            // Start button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded,
                      color: accentColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Start session',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends ConsumerWidget {
  final Deck deck;
  final Color accentColor;

  const _MenuButton({required this.deck, required this.accentColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit') {
          context.push('/deck/edit/${deck.id}');
        } else if (value == 'delete') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Delete deck',
                  style: TextStyle(color: AppColors.textPrimary)),
              content: Text('Delete "${deck.title}"? This cannot be undone.',
                  style: const TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await ref.read(deckServiceProvider).deleteDeck(deck.id);
          }
        }
      },
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded,
                  size: 16, color: AppColors.textSecondary),
              SizedBox(width: 10),
              Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 16, color: AppColors.danger),
              SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.more_horiz_rounded,
            color: accentColor.withOpacity(0.8), size: 16),
      ),
    );
  }
}
