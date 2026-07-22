import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/themes/app_theme.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';

/// Bungkus screen admin/CS dengan ini. Cek role user yang lagi login
/// lewat dokumen profilnya sendiri (users/{uid}.role) -- BUKAN custom
/// claims, karena project ini belum pakai custom claims sama sekali.
///
/// PENTING: ini cuma penjaga di sisi UI (mencegah user non-admin nyasar
/// ke screen ini). Penjaga yang SEBENARNYA tetap firestore.rules
/// (isAdmin() di rule support_messages) -- jangan andalkan widget ini
/// doang buat keamanan data.
class AdminGuard extends ConsumerWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const _AdminDenied();
    }

    return StreamBuilder<UserModel?>(
      stream: ref.read(userRepositoryProvider).getUserProfileStream(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat profil:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }
        final role = snapshot.data?.role;
        if (role != 'admin') {
          return const _AdminDenied();
        }
        return child;
      },
    );
  }
}

class _AdminDenied extends StatelessWidget {
  const _AdminDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 48, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Halaman ini khusus tim CS/admin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}