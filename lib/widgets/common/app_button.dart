import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// Custom Button Widget dengan berbagai variasi
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double height;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isFullWidth;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? borderColor;

  const AppButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height = 50,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isFullWidth = true,
    this.textStyle,
    this.backgroundColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: _buildButtonByVariant(isEnabled),
    );
  }

  /// Build button berdasarkan variant
  Widget _buildButtonByVariant(bool isEnabled) {
    switch (variant) {
      case ButtonVariant.primary:
        return _buildPrimaryButton(isEnabled);
      case ButtonVariant.secondary:
        return _buildSecondaryButton(isEnabled);
      case ButtonVariant.outline:
        return _buildOutlineButton(isEnabled);
      case ButtonVariant.text:
        return _buildTextButton(isEnabled);
      case ButtonVariant.danger:
        return _buildDangerButton(isEnabled);
      case ButtonVariant.success:
        return _buildSuccessButton(isEnabled);
    }
  }

  /// Primary button (filled)
  Widget _buildPrimaryButton(bool isEnabled) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: _buildIcon(),
      label: _buildLabel(),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.gray300,
        disabledForegroundColor: AppTheme.gray600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        elevation: isEnabled ? 4 : 0,
      ),
    );
  }

  /// Secondary button
  Widget _buildSecondaryButton(bool isEnabled) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: _buildIcon(),
      label: _buildLabel(),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.secondaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.gray300,
        disabledForegroundColor: AppTheme.gray600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    );
  }

  /// Outline button
  Widget _buildOutlineButton(bool isEnabled) {
    return OutlinedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: _buildIcon(),
      label: _buildLabel(),
      style: OutlinedButton.styleFrom(
        foregroundColor: backgroundColor ?? AppTheme.primaryColor,
        disabledForegroundColor: AppTheme.gray400,
        side: BorderSide(
          color: borderColor ?? AppTheme.primaryColor,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    );
  }

  /// Text button
  Widget _buildTextButton(bool isEnabled) {
    return TextButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: _buildIcon(),
      label: _buildLabel(),
      style: TextButton.styleFrom(
        foregroundColor: backgroundColor ?? AppTheme.primaryColor,
        disabledForegroundColor: AppTheme.gray400,
      ),
    );
  }

  /// Danger button (merah)
  Widget _buildDangerButton(bool isEnabled) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: _buildIcon(),
      label: _buildLabel(),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.errorColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.gray300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    );
  }

  /// Success button (hijau)
  Widget _buildSuccessButton(bool isEnabled) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: _buildIcon(),
      label: _buildLabel(),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.successColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.gray300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    );
  }

  /// Build icon atau loading indicator
  Widget _buildIcon() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Icon(icon);
    }

    return const SizedBox.shrink();
  }

  /// Build label text
  Widget _buildLabel() {
    return Text(
      isLoading ? '' : label,
      style: textStyle ??
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

/// Enum untuk button variants
enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
  danger,
  success,
}

// ============================================
// PRESET BUTTONS
// ============================================

/// Primary button yang paling sering dipakai
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.primary,
      icon: icon,
    );
  }
}

/// Secondary button
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const SecondaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.secondary,
      icon: icon,
    );
  }
}

/// Outline button
class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const OutlineButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.outline,
      icon: icon,
    );
  }
}

/// Danger button (untuk delete, cancel, dll)
class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const DangerButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.danger,
      icon: icon,
    );
  }
}

/// Success button
class SuccessButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const SuccessButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.success,
      icon: icon,
    );
  }
}