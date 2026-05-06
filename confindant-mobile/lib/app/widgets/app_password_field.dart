import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.hintText,
    this.labelText,
    this.controller,
    this.prefixIcon,
    this.textInputAction,
    this.onChanged,
    this.enabled = true,
  });

  final String hintText;
  final String? labelText;
  final TextEditingController? controller;
  final Widget? prefixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
