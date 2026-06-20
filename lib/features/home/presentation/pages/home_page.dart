import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusdeck/core/theme/app_theme.dart';
import 'package:focusdeck/features/auth/providers/auth_provider.dart';
import 'package:focusdeck/features/deck/providers/deck_provider.dart';
import 'package:focusdeck/features/home/presentation/widgets/deck_card_widget.dart';
import 'package:focusdeck/features/home/presentation/widgets/stats_row_widget.dart';
import 'package:focusdeck/features/home/presentation/widgets/empty_state_widget.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final decksAsync = ref.watch(userDecksProvider);

    String greeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'Good morning';
      if (hour < 17) return 'Good afternoon';
      return 'Good evening';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting(),
                          style:
                              Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.displayName?.split(' ').first ?? 'there',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(fontSize: 24),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.1),
                    Row(
                      children: [
                        _IconBtn(
                          icon: Icons.history_rounded,
                          onTap: () => context.push('/history'),
                        ),
                        const SizedBox(width: 8),
                        _IconBtn(
                          icon: Icons.logout_rounded,
                          onTap: () async {
                            await ref.read(authServiceProvider).signOut();
                          },
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms),
                  ],
                ),
              ),
            ),

            // Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: const StatsRowWidget()
                    .animate(delay: 150.ms)
                    .fadeIn()
                    .slideY(begin: 0.1),
              ),
            ),

            // Section label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'YOUR DECKS',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    decksAsync.maybeWhen(
                      data: (decks) => decks.isNotEmpty
                          ? Text(
                              '${decks.length} deck${decks.length != 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.labelLarge,
                            )
                          : const SizedBox.shrink(),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ).animate(delay: 200.ms).fadeIn(),
              ),
            ),

            // Deck list
            decksAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Text('Failed to load decks',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
              data: (decks) {
                if (decks.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyStateWidget(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DeckCardWidget(deck: decks[index])
                              .animate(delay: Duration(milliseconds: 50 * index))
                              .fadeIn()
                              .slideY(begin: 0.1),
                        );
                      },
                      childCount: decks.length,
                    ),
                  ),
                );
              },
            ),

            // Bottom space + FAB clearance
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/deck/new'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'New deck',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}
