import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/themes/app_theme.dart';

/// Custom Text Input Field Widget
class AppInput extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? initialValue;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool showCounter;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final EdgeInsetsGeometry? contentPadding;
  final TextAlignVertical? textAlignVertical;

  const AppInput({
    Key? key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.showCounter = false,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.contentPadding,
    this.textAlignVertical,
  }) : super(key: key);

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: widget.enabled ? AppTheme.darkColor : AppTheme.gray500,
            ),
          ),
          const SizedBox(height: AppTheme.sm),
        ],

        // Text Field
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          textAlignVertical: widget.textAlignVertical,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.enabled ? AppTheme.darkColor : AppTheme.gray500,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
              widget.prefixIcon,
              color: _isFocused ? AppTheme.primaryColor : AppTheme.gray500,
            )
                : null,
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: widget.fillColor ?? AppTheme.gray50,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: AppTheme.lg,
                  vertical: AppTheme.md,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              borderSide: BorderSide(
                color: widget.borderColor ?? AppTheme.borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              borderSide: BorderSide(
                color: widget.borderColor ?? AppTheme.borderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              borderSide: BorderSide(
                color: widget.focusedBorderColor ?? AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            errorStyle: const TextStyle(
              color: AppTheme.errorColor,
              fontSize: 12,
            ),
            counterText: widget.showCounter ? null : '',
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              borderSide: const BorderSide(
                color: AppTheme.gray300,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================
// SPECIALIZED INPUT FIELDS
// ============================================

/// Email input field dengan validation
class EmailInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final Function(String)? onChanged;

  const EmailInput({
    Key? key,
    this.label = 'Email',
    required this.controller,
    this.enabled = true,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppInput(
      label: label,
      controller: controller,
      hintText: 'Masukkan email Anda',
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.email_outlined,
      enabled: enabled,
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email tidak boleh kosong';
        }
        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(value)) {
          return 'Format email tidak valid';
        }
        return null;
      },
    );
  }
}

/// Password input field dengan toggle visibility
class PasswordInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final Function(String)? onChanged;
  final String? Function(String?)? customValidator;

  const PasswordInput({
    Key? key,
    this.label = 'Password',
    required this.controller,
    this.enabled = true,
    this.onChanged,
    this.customValidator,
  }) : super(key: key);

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return AppInput(
      label: widget.label,
      controller: widget.controller,
      hintText: 'Masukkan password Anda',
      prefixIcon: Icons.lock_outlined,
      obscureText: !_isPasswordVisible,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      suffixIcon: IconButton(
        icon: Icon(
          _isPasswordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppTheme.gray500,
        ),
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      ),
      validator: widget.customValidator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Password tidak boleh kosong';
            }
            if (value.length < 6) {
              return 'Password minimal 6 karakter';
            }
            return null;
          },
    );
  }
}

/// Phone number input field
class PhoneInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final Function(String)? onChanged;

  const PhoneInput({
    Key? key,
    this.label = 'Nomor Telepon',
    required this.controller,
    this.enabled = true,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppInput(
      label: label,
      controller: controller,
      hintText: 'Contoh: 081234567890',
      keyboardType: TextInputType.phone,
      prefixIcon: Icons.phone_outlined,
      enabled: enabled,
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nomor telepon tidak boleh kosong';
        }
        if (value.length < 10) {
          return 'Nomor telepon minimal 10 digit';
        }
        return null;
      },
    );
  }
}

/// Number input field
class NumberInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final Function(String)? onChanged;
  final String? hintText;
  final int? maxLength;

  const NumberInput({
    Key? key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.onChanged,
    this.hintText,
    this.maxLength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppInput(
      label: label,
      controller: controller,
      hintText: hintText ?? 'Masukkan angka',
      keyboardType: TextInputType.number,
      enabled: enabled,
      onChanged: onChanged,
      maxLength: maxLength,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }
}

/// Multiline text area
class TextArea extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final Function(String)? onChanged;
  final String? hintText;
  final int maxLines;
  final int? maxLength;

  const TextArea({
    Key? key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.onChanged,
    this.hintText,
    this.maxLines = 5,
    this.maxLength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppInput(
      label: label,
      controller: controller,
      hintText: hintText ?? 'Masukkan deskripsi',
      keyboardType: TextInputType.multiline,
      maxLines: maxLines,
      minLines: 3,
      enabled: enabled,
      onChanged: onChanged,
      maxLength: maxLength,
      showCounter: maxLength != null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }
}

/// Search input field
class SearchInput extends StatelessWidget {
  final String? hintText;
  final TextEditingController controller;
  final Function(String)? onChanged;
  final VoidCallback? onClear;

  const SearchInput({
    Key? key,
    this.hintText = 'Cari...',
    required this.controller,
    this.onChanged,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppInput(
      label: '',
      controller: controller,
      hintText: hintText,
      keyboardType: TextInputType.text,
      prefixIcon: Icons.search_outlined,
      onChanged: onChanged,
      suffixIcon: controller.text.isNotEmpty
          ? IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          controller.clear();
          onClear?.call();
        },
      )
          : null,
    );
  }
}