// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAccount => 'Akun';

  @override
  String get editProfileTitle => 'Edit Profil';

  @override
  String get editProfileSubtitle => 'Ubah nama & foto profil';

  @override
  String get changePasswordTitle => 'Ubah Password';

  @override
  String get changePasswordSubtitle => 'Perbarui kata sandi akun';

  @override
  String get sectionPreference => 'Preferensi';

  @override
  String get notificationTitle => 'Notifikasi';

  @override
  String get notificationSubtitle => 'Atur pemberitahuan aplikasi';

  @override
  String get languageTitle => 'Bahasa';

  @override
  String get sectionOther => 'Lainnya';

  @override
  String get helpTitle => 'Bantuan';

  @override
  String get helpSubtitle => 'FAQ & dukungan';

  @override
  String get aboutTitle => 'Tentang Aplikasi';

  @override
  String get logoutButton => 'Keluar / Logout';

  @override
  String get logoutDialogTitle => 'Keluar Akun?';

  @override
  String get logoutDialogContent =>
      'Kamu harus login lagi untuk mengakses akun ini.';

  @override
  String get cancel => 'Batal';

  @override
  String get logout => 'Keluar';

  @override
  String get roleOwner => 'Owner';

  @override
  String get fullNameLabel => 'Nama Lengkap';

  @override
  String get emailLabel => 'Email';

  @override
  String get nameEmptyError => 'Nama tidak boleh kosong';

  @override
  String get saveChangesButton => 'Simpan Perubahan';

  @override
  String galleryOpenError(String error) {
    return 'Gagal buka galeri: $error';
  }

  @override
  String get uploadTimeoutError => 'Upload timeout, cek koneksi kamu';

  @override
  String uploadFailedError(String code, String body) {
    return 'Upload gagal ($code): $body';
  }

  @override
  String get profileUpdateSuccess => 'Profil berhasil diperbarui';

  @override
  String profileUpdateError(String error) {
    return 'Gagal update profil: $error';
  }

  @override
  String get oldPasswordLabel => 'Password Lama';

  @override
  String get newPasswordLabel => 'Password Baru';

  @override
  String get confirmPasswordLabel => 'Konfirmasi Password Baru';

  @override
  String get oldPasswordRequiredError => 'Password lama wajib diisi';

  @override
  String get newPasswordRequiredError => 'Password baru wajib diisi';

  @override
  String get passwordMinLengthError => 'Minimal 6 karakter';

  @override
  String get newPasswordSameAsOldError =>
      'Password baru gak boleh sama dengan yang lama';

  @override
  String get confirmPasswordRequiredError => 'Konfirmasi password wajib diisi';

  @override
  String get confirmPasswordMismatchError =>
      'Konfirmasi tidak cocok dengan password baru';

  @override
  String get savePasswordButton => 'Simpan Password Baru';

  @override
  String get passwordChangeSuccess => 'Password berhasil diubah';

  @override
  String get wrongOldPasswordError => 'Password lama salah';

  @override
  String get weakPasswordError =>
      'Password baru terlalu lemah, minimal 6 karakter';

  @override
  String get requiresRecentLoginError =>
      'Sesi login kamu udah lama, silakan login ulang dulu';

  @override
  String get tooManyRequestsError =>
      'Terlalu banyak percobaan, coba lagi nanti';

  @override
  String passwordChangeGenericError(String error) {
    return 'Gagal ubah password: $error';
  }

  @override
  String get otherProviderNotice =>
      'Akun kamu login pakai provider lain (misalnya Google), jadi gak ada password yang bisa diubah di sini.';

  @override
  String get greetingMorning => 'Selamat Pagi';

  @override
  String get greetingAfternoon => 'Selamat Sore';

  @override
  String get greetingEvening => 'Selamat Malam';

  @override
  String get dashboardSubtitle => 'Berikut ringkasan bisnis laundry Anda';

  @override
  String get revenueThisMonthLabel => 'Pendapatan bulan ini';

  @override
  String get autoSyncLabel => 'Sinkronisasi otomatis';

  @override
  String get customersLabel => 'Pelanggan';

  @override
  String get activeOrdersLabel => 'Pesanan aktif';

  @override
  String get setupBranchTitle => 'Mulai Setup Cabang';

  @override
  String get setupBranchSubtitle => 'Lengkapi profil & alamat cabang';

  @override
  String get setupEmployeeTitle => 'Tambahkan Karyawan';

  @override
  String get setupEmployeeSubtitle => 'Undang staf untuk kelola pesanan';

  @override
  String get setupServiceTitle => 'Tambahkan Layanan';

  @override
  String get setupServiceSubtitle => 'Atur jenis cuci & harga';

  @override
  String get completeBranchSetupTitle => 'Selesaikan Setup Cabang';

  @override
  String setupStepsProgress(int done, int total) {
    return '$done dari $total langkah selesai';
  }

  @override
  String get newOrderAction => 'Pesanan\nBaru';

  @override
  String get newEmployeeAction => 'Karyawan\nBaru';

  @override
  String get manageServicesAction => 'Kelola\nLayanan';

  @override
  String get pickupDeliveryAction => 'Antar\nJemput';

  @override
  String get reportAction => 'Laporan';

  @override
  String get settingsAction => 'Pengaturan';

  @override
  String quotaLimitReached(String label) {
    return 'Batas kuota paket Starter untuk $label telah tercapai! Silakan upgrade.';
  }

  @override
  String get weeklyRevenueTitle => 'Pendapatan Mingguan';

  @override
  String get sevenDaysLabel => '7 hari';

  @override
  String get dayMon => 'Sen';

  @override
  String get dayTue => 'Sel';

  @override
  String get dayWed => 'Rab';

  @override
  String get dayThu => 'Kam';

  @override
  String get dayFri => 'Jum';

  @override
  String get daySat => 'Sab';

  @override
  String get daySun => 'Min';

  @override
  String get mainOrdersTitle => 'Pesanan Utama';

  @override
  String get viewAllLabel => 'Lihat Semua';

  @override
  String get filterAll => 'Semua';

  @override
  String get filterProcessing => 'Diproses';

  @override
  String get filterReady => 'Siap Diambil';

  @override
  String get filterCompleted => 'Selesai';

  @override
  String get noOrdersData => 'Tidak ada data pesanan.';

  @override
  String get noOrdersForStatus => 'Tidak ada pesanan dengan status ini.';

  @override
  String get statusCancelled => 'Batal';

  @override
  String get statusProcessing => 'Sedang Diproses';

  @override
  String get defaultCustomerName => 'Pelanggan Umum';

  @override
  String orderDetailSummary(String count, String amount) {
    return '$count item · Rp $amount';
  }
}
