import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusdeck/core/theme/app_theme.dart';
import 'package:focusdeck/features/auth/providers/auth_provider.dart';
import 'package:focusdeck/core/widgets/app_button.dart';
import 'package:focusdeck/core/widgets/app_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authServiceProvider).signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _errorMessage = _parseError(e.toString());
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseError(String error) {
    if (error.contains('user-not-found')) return 'No account with that email.';
    if (error.contains('wrong-password')) return 'Incorrect password.';
    if (error.contains('invalid-email')) return 'Invalid email format.';
    if (error.contains('too-many-requests')) return 'Too many attempts. Try again later.';
    if (error.contains('invalid-credential')) return 'Invalid email or password.';
    return 'Something went wrong. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 64),

                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentDim,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.4), width: 1),
                      ),
                      child: const Icon(Icons.layers_rounded,
                          color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'FocusDeck',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 48),

                Text(
                  'Welcome back.',
                  style: Theme.of(context).textTheme.displaySmall,
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.15),

                const SizedBox(height: 6),

                Text(
                  'Sign in to your account to continue.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 40),

                // Error message
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 12),

                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Your password',
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                  onSubmitted: (_) => _login(),
                ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: implement forgot password if needed
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Forgot password?',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
                ).animate(delay: 300.ms).fadeIn(),

                const SizedBox(height: 28),

                AppButton(
                  label: 'Sign in',
                  onPressed: _login,
                  loading: _loading,
                  fullWidth: true,
                ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 400.ms).fadeIn(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
