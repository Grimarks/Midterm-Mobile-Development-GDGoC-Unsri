import 'package:flutter/material.dart';
import 'package:focusdeck/core/theme/app_theme.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final int? maxLength;
  final Widget? suffix;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.suffix,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText && !_visible,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      autofocus: widget.autofocus,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        counterText: '',
        suffixIcon: widget.obscureText
            ? GestureDetector(
                onTap: () => setState(() => _visible = !_visible),
                child: Icon(
                  _visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              )
            : widget.suffix,
      ),
    );
  }
}
