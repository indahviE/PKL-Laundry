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

  @override
  String get serviceNameLabel => 'Nama Layanan';

  @override
  String get serviceNameHint => 'Contoh: Cuci Kering Setrika Reguler';

  @override
  String get serviceNameError => 'Nama layanan tidak boleh kosong';

  @override
  String get serviceDescriptionLabel => 'Deskripsi (Opsional)';

  @override
  String get serviceDescriptionHint =>
      'Contoh: Proses cuci, pengeringan mesin, dan setrika rapi.';

  @override
  String get pricingMethodLabel => 'Metode Perhitungan Harga';

  @override
  String get pricePerKgLabel => 'Harga per Kg (Rp)';

  @override
  String get pricePerItemLabel => 'Harga per Item (Rp)';

  @override
  String get priceHint => 'Contoh: 10000';

  @override
  String get priceEmptyError => 'Harga tidak boleh kosong';

  @override
  String get priceInvalidError => 'Masukkan angka yang valid';

  @override
  String get durationHint => 'Contoh: 24';

  @override
  String get createServiceAppBarTitle => 'Tambah Layanan Baru';

  @override
  String get createServiceSectionTitle => 'Detail Layanan Laundry';

  @override
  String get createServiceSectionSubtitle =>
      'Masukkan informasi jenis paket jasa laundry yang kamu sediakan.';

  @override
  String get pricingTypeKgFull => 'Per Kilogram (Kg)';

  @override
  String get pricingTypeItemFull => 'Per Satuan Item';

  @override
  String get durationLabelFull => 'Estimasi Waktu Pengerjaan (Dalam Jam)';

  @override
  String get durationEmptyErrorFull =>
      'Estimasi durasi pengerjaan tidak boleh kosong';

  @override
  String get durationInvalidErrorFull => 'Masukkan angka bulat jam yang valid';

  @override
  String get saveServiceButton => 'Simpan Layanan';

  @override
  String get sessionNotFoundError =>
      'Sesi pengguna tidak ditemukan. Silakan login kembali.';

  @override
  String get companyNotSetupError =>
      'Perusahaan belum dibuat. Selesaikan proses onboarding (setup perusahaan) terlebih dahulu.';

  @override
  String get addServiceSuccess => 'Layanan berhasil ditambahkan!';

  @override
  String addServiceError(String error) {
    return 'Gagal menambahkan layanan: $error';
  }

  @override
  String get servicesListAppBarTitle => 'Daftar Layanan';

  @override
  String get servicesListSubtitle =>
      'Kelola jenis cuci, harga, dan estimasi durasi';

  @override
  String get newServiceFab => 'Layanan Baru';

  @override
  String get emptyServicesTitle => 'Belum ada layanan terdaftar';

  @override
  String get emptyServicesSubtitle =>
      'Tekan tombol \"Layanan Baru\" untuk\nmenambahkan jenis cuci pertama Anda';

  @override
  String get errorStateTitle => 'Terjadi kesalahan';

  @override
  String get editServiceMenuItem => 'Edit Layanan';

  @override
  String get deactivateMenuItem => 'Nonaktifkan';

  @override
  String get activateMenuItem => 'Aktifkan';

  @override
  String get deleteMenuItem => 'Hapus Permanen';

  @override
  String serviceActivatedSnackbar(String name) {
    return 'Layanan \"$name\" diaktifkan kembali';
  }

  @override
  String serviceDeactivatedSnackbar(String name) {
    return 'Layanan \"$name\" dinonaktifkan';
  }

  @override
  String toggleStatusError(String error) {
    return 'Gagal mengubah status: $error';
  }

  @override
  String get deleteConfirmTitle => 'Hapus Permanen?';

  @override
  String deleteConfirmContent(String name) {
    return 'Layanan \"$name\" akan dihapus permanen dari database dan TIDAK BISA dikembalikan.\n\nJika layanan ini masih atau pernah dipakai di pesanan, sebaiknya gunakan opsi \"Nonaktifkan\" saja agar riwayat pesanan lama tetap tampil normal.';
  }

  @override
  String get deletePermanentButton => 'Hapus Permanen';

  @override
  String deleteServiceSuccess(String name) {
    return 'Layanan \"$name\" berhasil dihapus permanen';
  }

  @override
  String deleteServiceError(String error) {
    return 'Gagal menghapus layanan: $error';
  }

  @override
  String durationInHours(int hours) {
    return '$hours Jam';
  }

  @override
  String get activeStatusChip => 'Aktif';

  @override
  String get inactiveStatusChip => 'Nonaktif';

  @override
  String pricePerKgValue(String price) {
    return 'Rp $price / Kg';
  }

  @override
  String pricePerItemValue(String price) {
    return 'Rp $price / Item';
  }

  @override
  String get editServiceSheetTitle => 'Edit Layanan';

  @override
  String get editServiceSheetSubtitle =>
      'Perbarui detail jenis layanan laundry ini';

  @override
  String get pricingTypeKgShort => 'Per Kg';

  @override
  String get pricingTypeItemShort => 'Per Item';

  @override
  String get durationLabelShort => 'Estimasi Waktu Pengerjaan (Jam)';

  @override
  String get durationEmptyErrorShort => 'Estimasi durasi tidak boleh kosong';

  @override
  String get durationInvalidErrorShort => 'Masukkan angka bulat yang valid';

  @override
  String get activeServiceSwitchTitle => 'Layanan Aktif';

  @override
  String get activeServiceSwitchSubtitle =>
      'Nonaktifkan jika layanan sedang tidak ditawarkan';

  @override
  String get savingButtonLabel => 'Menyimpan...';

  @override
  String get saveChangesSuccess => 'Perubahan berhasil disimpan';

  @override
  String saveChangesError(String error) {
    return 'Gagal menyimpan perubahan: $error';
  }
}
