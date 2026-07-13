import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/themes/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../../services/stripe_service.dart';

/// Payment Screen — Step 6 dari onboarding.
/// Sesuai PRD section 5.1 User Flow, Step 6: Pembayaran.
/// Alur: Pilih Paket → [halaman ini] → Stripe Checkout (browser) →
/// Stripe Webhook menulis subscription aktif → Dashboard.
///
/// Desain konsisten dengan screen onboarding lain (card putih, step
/// indicator, GoogleFonts.poppins, AppTheme).
///
/// PENTING soal alur async: setelah user menekan "Lanjutkan ke
/// Pembayaran", kita:
///   1) panggil Cloud Function createCheckoutSession → dapat URL Stripe
///      Checkout hosted page
///   2) buka URL itu di browser eksternal (bukan WebView) — ini mengikuti
///      rekomendasi Stripe untuk Checkout hosted page
///   3) SEGERA mulai mendengarkan `watchActiveSubscription()` dari
///      Firestore, karena status pembayaran final ditulis oleh
///      `stripeWebhook` secara independen dari sesi browser user.
///      Begitu dokumen subscription berstatus 'active' muncul, kita
///      otomatis lanjut ke /dashboard — user tidak perlu manual kembali
///      ke app dan klik apa pun.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({
    Key? key,
    required this.planName,
    required this.isYearly,
    required this.price,
  }) : super(key: key);

  final String planName;
  final bool isYearly;
  final double price;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

enum _PaymentStage { idle, openingCheckout, waitingConfirmation, error }

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _stripeService = StripeService();

  _PaymentStage _stage = _PaymentStage.idle;
  String? _errorMessage;
  StreamSubscription<bool>? _subscriptionListener;

  @override
  void dispose() {
    _subscriptionListener?.cancel();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return 'Rp ${(amount / 1000).toStringAsFixed(0)}K';
  }

  Future<void> _handlePayNow() async {
    setState(() {
      _stage = _PaymentStage.openingCheckout;
      _errorMessage = null;
    });

    try {
      // TODO: ganti dengan domain production kamu. URL ini cuma untuk
      // menentukan halaman apa yang dilihat user setelah checkout di
      // browser — status pembayaran sesungguhnya tetap ditentukan lewat
      // webhook + Firestore listener di bawah, jadi URL placeholder ini
      // aman dipakai sementara backend belum live.
      final session = await _stripeService.createCheckoutSession(
        planName: widget.planName,
        isYearly: widget.isYearly,
        successUrl: 'https://netwash-stripe-backend.vercel.app/payment-success.html',
        cancelUrl: 'https://netwash.app/payment/cancel',
      );

      final uri = Uri.parse(session.url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Tidak bisa membuka halaman pembayaran Stripe.');
      }

      if (!mounted) return;
      setState(() {
        _stage = _PaymentStage.waitingConfirmation;
      });

      _listenForActiveSubscription();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _PaymentStage.error;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  /// Dengarkan Firestore sampai Stripe webhook menuliskan subscription
  /// dengan status 'active', lalu lanjut ke dashboard.
  /// (planChosen sudah disimpan lebih awal di ChoosePlanScreen — lihat
  /// komentar di ChoosePlanScreen._handleSelectPlan — jadi di sini kita
  /// cuma perlu nunggu konfirmasi pembayarannya.)
  void _listenForActiveSubscription() {
    final authRepo = ref.read(authRepositoryProvider);
    _subscriptionListener?.cancel();
    _subscriptionListener = authRepo.watchActiveSubscription().listen((
      isActive,
    ) {
      if (!isActive || !mounted) return;

      // Tampilkan popup singkat dulu sebelum pindah ke dashboard.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pembayaran berhasil! Mengarahkan ke dashboard...',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) context.go('/dashboard');
      });
    });
  }

  void _handleBack() {
    _subscriptionListener?.cancel();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/choose-plan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _buildCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopRow(),
          const SizedBox(height: 20),
          _buildStepIndicator(),
          const SizedBox(height: 24),
          _buildHeader(),
          const SizedBox(height: 28),
          if (_errorMessage != null) ...[
            _buildErrorMessage(),
            const SizedBox(height: 20),
          ],
          _buildOrderSummary(),
          const SizedBox(height: 28),
          _buildActionArea(),
          const SizedBox(height: 16),
          _buildBackLink(),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Material(
          color: AppTheme.backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _stage == _PaymentStage.idle ? _handleBack : null,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Step indicator — 7 langkah sesuai PRD. Posisi saat ini: 6.
  Widget _buildStepIndicator() {
    const totalSteps = 7;
    const currentStep = 6;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          final stepBefore = (index + 1) ~/ 2;
          final isDone = stepBefore < currentStep;
          return Container(
            width: 16,
            height: 2,
            color: isDone ? AppTheme.primaryColor : AppTheme.borderColor,
          );
        }
        final step = (index ~/ 2) + 1;
        final isActive = step == currentStep;
        final isDone = step < currentStep;
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: (isActive || isDone)
                ? AppTheme.primaryColor
                : AppTheme.borderColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.credit_card_outlined,
            color: AppTheme.primaryColor,
            size: 34,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Pembayaran',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selesaikan pembayaran untuk mengaktifkan paket Anda',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.08),
        border:
            Border.all(color: AppTheme.errorColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.errorColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? 'Terjadi kesalahan',
              style: GoogleFonts.poppins(
                color: AppTheme.errorColor,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pesanan',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paket ${widget.planName}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                widget.isYearly ? 'Tahunan' : 'Bulanan',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total tagihan',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${_formatCurrency(widget.price)}/${widget.isYearly ? 'tahun' : 'bulan'}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea() {
    switch (_stage) {
      case _PaymentStage.waitingConfirmation:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(height: 14),
              Text(
                'Menunggu konfirmasi pembayaran...',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Selesaikan pembayaran di tab browser yang terbuka. '
                'Halaman ini akan otomatis lanjut begitu pembayaran '
                'terkonfirmasi.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _handlePayNow,
                child: Text(
                  'Buka lagi halaman pembayaran',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      case _PaymentStage.openingCheckout:
      case _PaymentStage.idle:
      case _PaymentStage.error:
        return _buildPayButton();
    }
  }

  Widget _buildPayButton() {
    final isLoading = _stage == _PaymentStage.openingCheckout;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: !isLoading ? _handlePayNow : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Membuka Halaman Pembayaran...',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lanjutkan ke Pembayaran',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.lock_outline_rounded, size: 16),
                ],
              ),
      ),
    );
  }

  Widget _buildBackLink() {
    if (_stage == _PaymentStage.waitingConfirmation) {
      return const SizedBox.shrink();
    }
    return Center(
      child: TextButton(
        onPressed: _handleBack,
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
        ),
        child: Text(
          'Ganti Paket',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}