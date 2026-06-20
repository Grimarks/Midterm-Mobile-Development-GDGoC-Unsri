import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusdeck/core/theme/app_theme.dart';
import 'package:focusdeck/features/auth/providers/auth_provider.dart';
import 'package:focusdeck/core/widgets/app_button.dart';
import 'package:focusdeck/core/widgets/app_text_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authServiceProvider).register(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _nameController.text,
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
    if (error.contains('email-already-in-use')) return 'An account with this email already exists.';
    if (error.contains('weak-password')) return 'Password is too weak.';
    if (error.contains('invalid-email')) return 'Invalid email format.';
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
                const SizedBox(height: 56),

                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textSecondary, size: 22),
                ).animate().fadeIn(),

                const SizedBox(height: 32),

                Text(
                  'Create account.',
                  style: Theme.of(context).textTheme.displaySmall,
                ).animate(delay: 50.ms).fadeIn().slideY(begin: 0.15),

                const SizedBox(height: 6),

                Text(
                  'Start setting intentions today.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 36),

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
                  ).animate().fadeIn(),

                AppTextField(
                  controller: _nameController,
                  label: 'Display name',
                  hint: 'How should we call you?',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'Name must be at least 2 characters';
                    return null;
                  },
                ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 12),

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
                  hint: 'Min. 6 characters',
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 12),

                AppTextField(
                  controller: _confirmController,
                  label: 'Confirm password',
                  hint: 'Repeat your password',
                  obscureText: true,
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                  onSubmitted: (_) => _register(),
                ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 28),

                AppButton(
                  label: 'Create account',
                  onPressed: _register,
                  loading: _loading,
                  fullWidth: true,
                ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        'Sign in',
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
