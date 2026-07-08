import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// Error Widget dengan berbagai varian untuk menampilkan error state
class ErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final ErrorType type;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;

  const ErrorWidget({
    Key? key,
    required this.title,
    required this.message,
    this.type = ErrorType.general,
    this.icon,
    this.onRetry,
    this.retryButtonText = 'Coba Lagi',
    this.iconColor,
    this.padding = const EdgeInsets.all(AppTheme.lg),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultIcon = _getDefaultIcon();
    final defaultColor = _getErrorColor();

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              icon ?? defaultIcon,
              size: 80,
              color: iconColor ?? defaultColor,
            ),

            const SizedBox(height: AppTheme.xl),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.darkColor,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.md),

            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray600,
                  ),
              textAlign: TextAlign.center,
            ),

            // Retry Button
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryButtonText ?? 'Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: defaultColor,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case ErrorType.general:
        return Icons.error_outline;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.unauthorized:
        return Icons.lock_outline;
      case ErrorType.forbidden:
        return Icons.block;
      case ErrorType.timeout:
        return Icons.schedule;
      case ErrorType.validation:
        return Icons.warning_amber;
    }
  }

  Color _getErrorColor() {
    switch (type) {
      case ErrorType.general:
      case ErrorType.server:
      case ErrorType.unauthorized:
        return AppTheme.errorColor;
      case ErrorType.notFound:
      case ErrorType.forbidden:
        return AppTheme.warningColor;
      case ErrorType.network:
      case ErrorType.timeout:
        return Colors.orange;
      case ErrorType.validation:
        return AppTheme.warningColor;
    }
  }
}

// ============================================
// ERROR TYPE ENUM
// ============================================

enum ErrorType {
  general,
  notFound,
  network,
  server,
  unauthorized,
  forbidden,
  timeout,
  validation,
}

// ============================================
// EMPTY STATE WIDGET
// ============================================

/// Empty state widget (untuk data yang kosong)
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionButtonText;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionButtonText = 'Tambah Data',
    this.iconColor,
    this.padding = const EdgeInsets.all(AppTheme.lg),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              icon,
              size: 80,
              color: iconColor ?? AppTheme.gray400,
            ),

            const SizedBox(height: AppTheme.xl),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.darkColor,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.md),

            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray600,
                  ),
              textAlign: TextAlign.center,
            ),

            // Action Button
            if (onAction != null) ...[
              const SizedBox(height: AppTheme.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionButtonText ?? 'Tambah Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================
// CONVENIENCE ERROR WIDGETS
// ============================================

/// General error
class GeneralErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const GeneralErrorWidget({
    Key? key,
    this.message = 'Terjadi kesalahan. Silakan coba lagi.',
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Oops!',
      message: message,
      type: ErrorType.general,
      onRetry: onRetry,
    );
  }
}

/// Network error
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    Key? key,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Tidak Ada Koneksi',
      message: 'Periksa koneksi internet Anda dan coba lagi.',
      type: ErrorType.network,
      onRetry: onRetry,
    );
  }
}

/// Server error
class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const ServerErrorWidget({
    Key? key,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Server Error',
      message: 'Server sedang mengalami gangguan. Coba lagi nanti.',
      type: ErrorType.server,
      onRetry: onRetry,
    );
  }
}

/// Not found error
class NotFoundErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const NotFoundErrorWidget({
    Key? key,
    this.title = 'Tidak Ditemukan',
    this.message = 'Data yang Anda cari tidak ditemukan.',
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: title,
      message: message,
      type: ErrorType.notFound,
      onRetry: onRetry,
    );
  }
}

/// Unauthorized error
class UnauthorizedErrorWidget extends StatelessWidget {
  final VoidCallback? onLogin;

  const UnauthorizedErrorWidget({
    Key? key,
    this.onLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Anda Harus Login',
      message: 'Silakan login untuk mengakses fitur ini.',
      type: ErrorType.unauthorized,
      onRetry: onLogin,
      retryButtonText: 'Login Sekarang',
    );
  }
}

/// Timeout error
class TimeoutErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const TimeoutErrorWidget({
    Key? key,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Waktu Tunggu Habis',
      message: 'Permintaan memakan waktu terlalu lama. Coba lagi.',
      type: ErrorType.timeout,
      onRetry: onRetry,
    );
  }
}

// ============================================
// ERROR SNACKBAR
// ============================================

/// Show error snackbar
void showErrorSnackBar(
  BuildContext context, {
  required String message,
  String? title,
  Duration duration = const Duration(seconds: 4),
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
          ],
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      backgroundColor: AppTheme.errorColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      action: action,
    ),
  );
}

/// Show success snackbar
void showSuccessSnackBar(
  BuildContext context, {
  required String message,
  String? title,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
          ],
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      backgroundColor: AppTheme.successColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
    ),
  );
}

/// Show warning snackbar
void showWarningSnackBar(
  BuildContext context, {
  required String message,
  String? title,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
          ],
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      backgroundColor: AppTheme.warningColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
    ),
  );
}

// ============================================
// ERROR DIALOG
// ============================================

/// Show error dialog
Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? buttonText = 'OK',
  VoidCallback? onPressed,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Text(title),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onPressed ?? () => Navigator.pop(context),
          child: Text(buttonText ?? 'OK'),
        ),
      ],
    ),
  );
}

// ============================================
// ERROR STATE BUILDER
// ============================================

/// Widget untuk handle berbagai state (loading, error, data)
class StateBuilder<T> extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final ErrorType errorType;
  final bool isEmpty;
  final VoidCallback? onRetry;
  final Widget Function(T? data) builder;
  final T? data;

  const StateBuilder({
    Key? key,
    required this.builder,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.errorType = ErrorType.general,
    this.isEmpty = false,
    this.onRetry,
    this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (hasError) {
      return ErrorWidget(
        title: 'Error',
        message: errorMessage ?? 'Terjadi kesalahan',
        type: errorType,
        onRetry: onRetry,
      );
    }

    if (isEmpty) {
      return EmptyStateWidget(
        title: 'Tidak Ada Data',
        message: 'Data yang Anda cari tidak tersedia',
        onAction: onRetry,
      );
    }

    return builder(data);
  }
}