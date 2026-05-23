import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final void Function()? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;
  final Color? fillColor;
  final Color? prefixIconColor;
  final Color? suffixIconColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.focusNode,
    this.onChanged,
    this.onSaved,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.enabled = true,
    this.autovalidateMode,
    this.fillColor,
    this.prefixIconColor,
    this.suffixIconColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      onTap: widget.onTap,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      autovalidateMode: widget.autovalidateMode,
      style: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 16.sp,
        color: const Color(0xFF000000), // active text color
      ),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: widget.prefixIconColor ?? AppColors.grey400,
              )
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: widget.suffixIconColor ?? AppColors.grey400,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : widget.suffixIcon,
        labelText: widget.labelText,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: widget.prefixIconColor ?? AppColors.grey400,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 16.sp,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: widget.borderColor ?? AppColors.grey300,
            width: 1.w,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: widget.focusedBorderColor ?? AppColors.primary,
            width: 1.w,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: widget.errorBorderColor ?? AppColors.error,
            width: 1.w,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: widget.errorBorderColor ?? AppColors.error,
            width: 1.w,
          ),
        ),
        filled: true,
        fillColor: widget.fillColor ?? AppColors.grey100,
      ),
    );
  }
}