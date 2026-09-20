import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/currency_input_formatter.dart';

/// Modular, highly reusable CustomTextFormField for the Ojol Daily app.
class CustomTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? suffix;
  final bool obscureText;
  final bool isPassword;
  final bool isCurrency;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextStyle? style;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextCapitalization? textCapitalization;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.obscureText = false,
    this.isPassword = false,
    this.isCurrency = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autofocus = false,
    this.focusNode,
    this.style,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
    this.textCapitalization,
  });

  /// Factory constructor for currency / monetary inputs (Rupiah).
  factory CustomTextFormField.currency({
    Key? key,
    TextEditingController? controller,
    required String labelText,
    String? hintText = "0",
    Widget? prefixIcon = const Text('Rp '),
    Widget? suffixIcon,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    bool autofocus = false,
    FocusNode? focusNode,
    bool readOnly = false,
    bool enabled = true,
    TextStyle? style,
    Color? fillColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? contentPadding,
    TextInputAction? textInputAction,
  }) {
    return CustomTextFormField(
      key: key,
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      textInputAction: textInputAction,
      isCurrency: true,
      keyboardType: TextInputType.number,
      inputFormatters: [CurrencyInputFormatter()],
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      autofocus: autofocus,
      focusNode: focusNode,
      readOnly: readOnly,
      enabled: enabled,
      style: style,
      fillColor: fillColor,
      borderRadius: borderRadius,
      contentPadding: contentPadding,
    );
  }

  /// Factory constructor for password inputs with automatic toggle visibility.
  factory CustomTextFormField.password({
    Key? key,
    TextEditingController? controller,
    required String labelText,
    String? hintText,
    Widget? prefixIcon = const Icon(Icons.lock_outline, size: 20),
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    TextInputAction? textInputAction,
    FocusNode? focusNode,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return CustomTextFormField(
      key: key,
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      isPassword: true,
      obscureText: true,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      textInputAction: textInputAction,
      focusNode: focusNode,
      contentPadding: contentPadding,
    );
  }

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText || widget.isPassword;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputStyle =
        widget.style ??
        const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurface,
        );

    // Ensure prefix widget is ALWAYS visible (focused or unfocused, empty or filled)
    Widget? effectivePrefixIcon = widget.prefixIcon;
    BoxConstraints? effectivePrefixConstraints;

    if (widget.isCurrency) {
      final String prefixString = (widget.prefixIcon is Text)
          ? ((widget.prefixIcon as Text).data ?? 'Rp ')
          : 'Rp ';
      effectivePrefixIcon = Padding(
        padding: const EdgeInsets.only(left: 14, right: 4),
        child: Text(
          prefixString,
          style: inputStyle, // Match input style for seamless visual alignment
        ),
      );
      effectivePrefixConstraints = const BoxConstraints(
        minWidth: 0,
        minHeight: 0,
      );
    } else if (widget.prefixIcon != null) {
      if (widget.prefixIcon is Text) {
        effectivePrefixIcon = Padding(
          padding: const EdgeInsets.only(left: 14, right: 4),
          child: DefaultTextStyle(style: inputStyle, child: widget.prefixIcon!),
        );
        effectivePrefixConstraints = const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
        );
      } else {
        effectivePrefixIcon = widget.prefixIcon;
      }
    }

    // Combine input formatters for currency if requested
    List<TextInputFormatter>? formatters = widget.inputFormatters;
    if (widget.isCurrency &&
        (formatters == null ||
            !formatters.any((f) => f is CurrencyInputFormatter))) {
      formatters = [...?formatters, CurrencyInputFormatter()];
    }

    Widget? effectiveSuffixIcon = widget.suffixIcon;
    if (widget.isPassword) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppTheme.onSurfaceVariant,
          size: 20,
        ),
        onPressed: _toggleObscureText,
      );
    }

    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          initialValue: widget.initialValue,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization:
              widget.textCapitalization ?? TextCapitalization.none,
          inputFormatters: formatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,

          style: inputStyle,
          onTapOutside: (event) =>
              FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            prefixIcon: effectivePrefixIcon,
            prefixIconConstraints: effectivePrefixConstraints,
            suffixIcon: effectiveSuffixIcon,
            suffix: widget.suffix,

            filled: true,
            fillColor: widget.fillColor ?? AppTheme.surfaceContainerLow,
            contentPadding:
                widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: AppTheme.error, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
