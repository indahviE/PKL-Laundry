import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

// Provider yang sudah ada sebelumnya
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

// 1. Buat class State untuk menampung status login
class LoginState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  LoginState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error, // Jika tidak diisi, otomatis reset jadi null
    );
  }
}

// 2. Buat Notifier untuk menghandle fungsi login
class LoginNotifier extends StateNotifier<LoginState> {
  final Ref ref;

  LoginNotifier(this.ref) : super(LoginState());

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.loginWithEmailAndPassword(email, password); 
      
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on FirebaseAuthException catch (e) {
      // Mengirim 'code' bawaan Firebase (misal: 'user-not-found') 
      // agar pas dionvert di _handleAuthError()
      state = state.copyWith(isLoading: false, error: e.code);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// 3. Deklarasikan loginProvider agar bisa dibaca di login_screen.dart
final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref);
});

final currentUserIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.uid ?? '';
});