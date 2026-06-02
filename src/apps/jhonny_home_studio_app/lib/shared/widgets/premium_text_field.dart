import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

class PremiumTextField extends StatelessWidget {
  const PremiumTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.inputFormatters,
    this.onChanged,
    this.contentPadding,
    this.prefixIconSize = 20,
    this.isDense,
  });

  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  final double prefixIconSize;
  final bool? isDense;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      cursorColor: AppColors.gold,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: prefixIconSize),
        suffixIcon: suffixIcon,
        contentPadding: contentPadding,
        isDense: isDense,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }
}
