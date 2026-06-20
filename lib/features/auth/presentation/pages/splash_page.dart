import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusdeck/core/theme/app_theme.dart';
import 'package:focusdeck/features/auth/providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo mark
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1.5),
              ),
              child: const Icon(
                Icons.layers_rounded,
                color: AppColors.accent,
                size: 36,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOut),

            const SizedBox(height: 20),

            Text(
              'FocusDeck',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.2, curve: Curves.easeOut),

            const SizedBox(height: 8),

            Text(
              'Set your intention. Stay focused.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.2, curve: Curves.easeOut),

            const SizedBox(height: 56),

            // Loading indicator
            SizedBox(
              width: 32,
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                borderRadius: BorderRadius.circular(2),
              ),
            )
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
