import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Token desain gabungan ("NetWash Utility System").
///
/// Sebelumnya ada 2 sumber terpisah yang isinya banyak tumpang tindih:
/// - order_detail_screen.dart -> konstanta top-level `_c...`
/// - employees_list_screen.dart -> class `_DS`
///
/// Digabung di sini jadi SATU sumber kebenaran. Nilai warna yang sama
/// persis di kedua file lama dipertahankan apa adanya. Warna yang cuma
/// ada di salah satu file (mis. yellow/red badge di order detail, atau
/// `navy` di employees list) tetap dipertahankan sebagai token terpisah
/// supaya tidak ada tampilan yang berubah.
///
/// CATATAN KONFLIK: kedua file lama sama-sama punya konsep "warna
/// sukses/hijau" tapi dengan nilai berbeda (order detail pakai
/// 0xFF15803D untuk teks status hijau, employees list pakai 0xFF27AE60
/// untuk dot status aktif). Keduanya dipertahankan sebagai token
/// terpisah (`greenText` vs `success`) daripada dipaksa disamakan, biar
/// tidak mengubah tampilan yang sudah ada di kedua screen.
class DesignTokens {
  DesignTokens._();

  // --- Surface / canvas ---
  static const Color canvas = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F3F3);
  static const Color surfaceContainer = Color(0xFFF0EDED);
  static const Color surfaceContainerHighest = Color(0xFFE4E2E1);

  // --- On-surface / teks ---
  static const Color onSurface = Color(0xFF1B1C1C);
  static const Color onSurfaceVariant = Color(0xFF404752);
  static const Color outline = Color(0xFF707883);
  static const Color outlineVariant = Color(0xFFBFC7D4);

  // --- Primary / brand ---
  static const Color navy = Color(0xFF0B3B66);
  static const Color primary = Color(0xFF0061A4);
  static const Color primaryContainer = Color(0xFF2196F3);
  static const Color primaryFixed = Color(0xFFD1E4FF);
  static const Color onPrimaryFixedVariant = Color(0xFF00497D);

  // --- Secondary / tertiary ---
  static const Color secondary = Color(0xFF5B5F61);
  static const Color secondaryContainer = Color(0xFFE0E3E6);
  static const Color tertiaryFixed = Color(0xFFD6E5EF);
  static const Color onTertiaryFixed = Color(0xFF0F1D25);

  // --- Status / semantic ---
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF27AE60); // dot status aktif (employees list)
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color greenText = Color(0xFF15803D); // teks status "selesai" (order detail)
  static const Color yellowBg = Color(0xFFFEF9C3);
  static const Color yellowText = Color(0xFFA16207);
  static const Color redBg = Color(0xFFFEE2E2);
  static const Color redText = Color(0xFFB91C1C);

  // --- Radius ---
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  // --- Shadow ---
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration cardDecoration({bool withBorder = false, Color? borderColor}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radiusXl),
      border: withBorder ? Border.all(color: borderColor ?? surfaceContainer) : null,
      boxShadow: cardShadow,
    );
  }

  // --- Typography (Be Vietnam Pro, dipakai di kedua screen) ---
  static TextStyle headlineMd({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: color ?? onSurface,
        letterSpacing: -0.2,
      );

  static TextStyle bodyMd({Color? color, FontWeight? weight}) => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? onSurface,
      );

  static TextStyle bodySm({Color? color, FontWeight? weight}) => GoogleFonts.beVietnamPro(
        fontSize: 12.5,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? onSurfaceVariant,
      );

  static TextStyle labelBold({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color ?? onSurfaceVariant,
      );
}