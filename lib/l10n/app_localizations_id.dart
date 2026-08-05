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
  String get notifPrefOrderStatusTitle => 'Status pesanan';

  @override
  String get notifPrefOrderStatusSubtitle => 'Update cuci, siap diambil, dll';

  @override
  String get notifPrefPromoTitle => 'Promo dan diskon';

  @override
  String get notifPrefPromoSubtitle => 'Penawaran spesial untukmu';

  @override
  String get notifPrefReminderTitle => 'Pengingat';

  @override
  String get notifPrefReminderSubtitle => 'Jadwal ambil dan antar cucian';

  @override
  String get notifPrefChatCsTitle => 'Chat dan CS';

  @override
  String get notifPrefChatCsSubtitle => 'Balasan dari customer service';

  @override
  String notifPrefSaveError(String error) {
    return 'Gagal menyimpan preferensi: $error';
  }

  @override
  String get notificationsPanelTitle => 'Pesanan Baru';

  @override
  String pendingOrdersNotifSubtitle(int count) {
    return '$count pesanan menunggu diproses';
  }

  @override
  String get noNewNotifications => 'Tidak ada notifikasi baru';

  @override
  String get noNewNotificationsSubtitle =>
      'Pesanan baru yang masuk akan muncul di sini';

  @override
  String get languageTitle => 'Bahasa';

  @override
  String get sectionCsTeam => 'Tim CS';

  @override
  String get manageCsChatTitle => 'Kelola Chat CS';

  @override
  String get manageCsChatSubtitle => 'Balas percakapan dari semua user';

  @override
  String get sectionOther => 'Lainnya';

  @override
  String get helpTitle => 'Bantuan';

  @override
  String get helpSubtitle => 'FAQ & dukungan';

  @override
  String get helpSectionGeneralTitle => 'Pertanyaan Umum';

  @override
  String get helpSectionAppGuideTitle => 'Panduan Aplikasi';

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
  String get activeBranchLabel => 'CABANG AKTIF';

  @override
  String get allBranchesLabel => 'Semua Cabang';

  @override
  String get selectBranchTitle => 'Pilih Cabang';

  @override
  String get searchBranchHint => 'Cari nama cabang...';

  @override
  String get noBranchesRegistered => 'Belum ada cabang terdaftar';

  @override
  String get branchNotFoundSearch => 'Cabang tidak ditemukan';

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
  String get reportsTitle => 'Laporan';

  @override
  String get reportsSubtitle => 'Pantau performa bisnis laundry Anda';

  @override
  String get periodToday => 'Hari Ini';

  @override
  String get periodThisWeek => 'Minggu Ini';

  @override
  String weekNumberLabel(int index) {
    return 'Minggu $index';
  }

  @override
  String weekNumberRangeLabel(int index, String start, String end) {
    return 'Minggu $index ($start - $end)';
  }

  @override
  String get periodThisMonth => 'Bulan Ini';

  @override
  String get periodThisYear => 'Tahun Ini';

  @override
  String get printButtonShort => 'Cetak';

  @override
  String get printReportButton => 'Cetak Laporan';

  @override
  String get generatingPdfButton => 'Membuat PDF...';

  @override
  String get growthThisPeriodLabel => 'Pertumbuhan Periode Ini';

  @override
  String get growthUpLabel => 'Naik';

  @override
  String get growthDownLabel => 'Turun';

  @override
  String get fromPreviousPeriodLabel => 'dari periode sebelumnya';

  @override
  String get revenueTrendTitle => 'Tren Pendapatan';

  @override
  String get last7DaysLabel => '7 hari terakhir';

  @override
  String get revenuePerServiceTitle => 'Pendapatan per Layanan';

  @override
  String get noOrdersThisPeriod => 'Belum ada data pesanan pada periode ini.';

  @override
  String get completionRateLabel => 'Tingkat Penyelesaian';

  @override
  String get ofAllOrdersLabel => 'dari seluruh pesanan';

  @override
  String exportPdfError(String error) {
    return 'Gagal membuat PDF: $error';
  }

  @override
  String get pdfReportTitle => 'Laporan Bisnis Laundry';

  @override
  String pdfHeaderInfo(String period, String branch, String date) {
    return 'Periode: $period   |   Cabang: $branch   |   Dibuat: $date';
  }

  @override
  String get pdfSummaryTitle => 'Ringkasan';

  @override
  String get totalRevenueLabel => 'Total Pendapatan';

  @override
  String get newCustomersLabel => 'Pelanggan Baru';

  @override
  String get avgOrderLabel => 'Rata-rata Order';

  @override
  String get growthLabel => 'Pertumbuhan';

  @override
  String growthValueTemplate(String rate) {
    return '+$rate% dari periode sebelumnya';
  }

  @override
  String get pdfWeeklyTrendTitle => 'Tren Pendapatan (7 hari terakhir)';

  @override
  String get pdfServiceColumn => 'Layanan';

  @override
  String get pdfOrdersColumn => 'Pesanan';

  @override
  String get pdfRevenueColumn => 'Pendapatan';

  @override
  String get pdfPercentageColumn => 'Persentase';

  @override
  String pdfPageOfPages(int page, int total) {
    return 'Halaman $page dari $total';
  }

  @override
  String get unnamedBranchLabel => 'Cabang Tanpa Nama';

  @override
  String get otherServiceLabel => 'Lainnya';

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
  String get manageBranchAction => 'Kelola\nCabang';

  @override
  String get manageEmployeesAction => 'Kelola\nKaryawan';

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
  String get serviceTypeSectionLabel => 'Tipe Layanan';

  @override
  String get pricingTypeKgChipLabel => 'Kiloan';

  @override
  String get pricingTypeItemChipLabel => 'Satuan';

  @override
  String get pricingTypeExpressLabel => 'Express';

  @override
  String get pricePerKgFieldLabel => 'Harga per Kg';

  @override
  String get pricePerItemFieldLabel => 'Harga per Item';

  @override
  String get baseFeeLabel => 'Harga Dasar';

  @override
  String get expressFeeLabel => 'Biaya Tambahan Express';

  @override
  String get minWeightLabel => 'Berat Minimum (Kg)';

  @override
  String get estimatedDurationSectionLabel => 'Estimasi Durasi';

  @override
  String get durationUnitHours => 'Jam';

  @override
  String get durationUnitDays => 'Hari';

  @override
  String durationChipHoursLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Jam',
    );
    return '$_temp0';
  }

  @override
  String durationChipDaysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Hari',
    );
    return '$_temp0';
  }

  @override
  String get availableAtBranchesLabel => 'Tersedia di Cabang';

  @override
  String get noBranchesForServiceHint =>
      'Belum ada cabang. Tambahkan cabang terlebih dahulu di menu Cabang.';

  @override
  String get noBranchSelectedLabel => 'Belum ada cabang dipilih';

  @override
  String branchesSelectedCountLabel(int count, int total) {
    return '$count dari $total cabang dipilih';
  }

  @override
  String get selectAllLabel => 'Pilih Semua';

  @override
  String get deselectAllLabel => 'Batal Semua';

  @override
  String get loadBranchesFailedLabel => 'Gagal memuat cabang.';

  @override
  String get searchServiceHint => 'Cari nama layanan...';

  @override
  String get noMatchingServicesTitle => 'Tidak ada layanan yang cocok';

  @override
  String get tryDifferentKeywordFilterHint =>
      'Coba ubah kata kunci atau filter';

  @override
  String get emptyBranchSelectionMeansAllHint =>
      'Kosongkan semua untuk tersedia di semua cabang.';

  @override
  String get sessionNotFoundError =>
      'Sesi pengguna tidak ditemukan. Silakan login kembali.';

  @override
  String get companyNotSetupError =>
      'Perusahaan belum diatur. Selesaikan onboarding terlebih dahulu.';

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
  String get unitPerKgSuffix => ' / Kg';

  @override
  String get unitPerItemSuffix => ' / Item';

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

  @override
  String get customersTitle => 'Pelanggan';

  @override
  String get customersSubtitle => 'Kelola data pelanggan laundry Anda';

  @override
  String get newCustomerButton => 'Baru';

  @override
  String get searchCustomerHint => 'Cari nama atau nomor telepon...';

  @override
  String get customerActiveLabel => 'Aktif';

  @override
  String get customerInactiveLabel => 'Tidak Aktif';

  @override
  String get totalCustomersLabel => 'Total Pelanggan';

  @override
  String get totalTransactionsLabel => 'Total Transaksi';

  @override
  String get emptyCustomersTitle => 'Tidak ada pelanggan';

  @override
  String get emptyCustomersSubtitle => 'Tambahkan pelanggan baru untuk memulai';

  @override
  String get addCustomerButton => 'Tambah Pelanggan';

  @override
  String ordersCountLabel(int count) {
    return '$count pesanan';
  }

  @override
  String get neverOrderedLabel => 'Belum pernah order';

  @override
  String get justNowLabel => 'Baru saja';

  @override
  String hoursAgoLabel(int hours) {
    return '$hours jam lalu';
  }

  @override
  String daysAgoLabel(int days) {
    return '$days hari lalu';
  }

  @override
  String get editCustomerComingSoon =>
      'Navigasi ke Edit Pelanggan akan ditambahkan';

  @override
  String get editCustomerMenuItem => 'Edit Pelanggan';

  @override
  String get deleteCustomerMenuItem => 'Hapus Pelanggan';

  @override
  String get deleteCustomerConfirmTitle => 'Hapus Pelanggan?';

  @override
  String deleteCustomerConfirmContent(String name) {
    return 'Data pelanggan \"$name\" akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get deleteButton => 'Hapus';

  @override
  String get deleteCustomerSuccessTesting =>
      'Pelanggan berhasil dihapus (Testing mode)';

  @override
  String get customerDetailTitle => 'Detail Pelanggan';

  @override
  String joinedSinceLabel(String date) {
    return 'Bergabung sejak $date';
  }

  @override
  String get activeCustomerLabel => 'Pelanggan Aktif';

  @override
  String get callButton => 'Telepon';

  @override
  String get openingPhoneApp => 'Membuka aplikasi telepon...';

  @override
  String get whatsappButton => 'WhatsApp';

  @override
  String get openingWhatsapp => 'Membuka WhatsApp...';

  @override
  String get totalOrdersLabel => 'Total Pesanan';

  @override
  String get totalSpentLabel => 'Total Belanja';

  @override
  String get contactInfoTitle => 'Informasi Kontak';

  @override
  String get phoneLabel => 'Telepon';

  @override
  String get customerAddressLabel => 'Alamat';

  @override
  String get orderHistoryTitle => 'Riwayat Pesanan';

  @override
  String get notifyReadyForPickupButtonLabel => 'Kabari Pelanggan Siap Diambil';

  @override
  String get viewAllOrdersComingSoon =>
      'Navigasi ke semua riwayat pesanan akan ditambahkan';

  @override
  String get noOrderHistoryLabel => 'Belum ada riwayat pesanan';

  @override
  String get orderStatusPending => 'Menunggu';

  @override
  String get customerOrderStatusConfirmed => 'Dikonfirmasi';

  @override
  String get orderStatusInProgress => 'Diproses';

  @override
  String get customerOrderStatusProcessing => 'Diproses';

  @override
  String get orderStatusCompleted => 'Selesai';

  @override
  String get orderStatusCancelled => 'Dibatalkan';

  @override
  String orderItemCountLabel(int count) {
    return '· $count item';
  }

  @override
  String get newCustomerHeaderTitle => 'Pelanggan Baru';

  @override
  String get newCustomerHeaderSubtitle =>
      'Lengkapi data pelanggan untuk menambahkannya ke sistem';

  @override
  String get customerNameHint => 'Masukkan nama pelanggan';

  @override
  String get customerNameEmptyError => 'Nama pelanggan tidak boleh kosong';

  @override
  String get customerPhoneNumberLabel => 'No. Telepon';

  @override
  String get phoneNumberHint => 'Contoh: 081234567890';

  @override
  String get phoneNumberEmptyError => 'No. telepon tidak boleh kosong';

  @override
  String get phoneNumberInvalidError => 'Format no. telepon tidak valid';

  @override
  String get optionalFieldSuffix => ' (Opsional)';

  @override
  String get customerEmailHint => 'Masukkan email pelanggan';

  @override
  String get emailInvalidError => 'Format email tidak valid';

  @override
  String get customerAddressHint => 'Masukkan alamat pelanggan';

  @override
  String get notesLabel => 'Catatan';

  @override
  String get notesHint => 'Catatan khusus untuk pelanggan ini';

  @override
  String get saveCustomerButton => 'Simpan Pelanggan';

  @override
  String get addCustomerSuccessTesting => 'Pelanggan berhasil ditambahkan!';

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String addCustomerError(String error) {
    return 'Gagal menambahkan pelanggan: $error';
  }

  @override
  String loadCustomersError(Object error) {
    return 'Gagal memuat data pelanggan: $error';
  }

  @override
  String get laundriesTitle => 'Cabang';

  @override
  String get laundriesSubtitle => 'Kelola cabang laundry Anda';

  @override
  String get searchLaundryHint => 'Cari nama, kode, atau kota cabang...';

  @override
  String get filterAllLaundries => 'Semua';

  @override
  String get filterActiveLaundries => 'Aktif';

  @override
  String get filterInactiveLaundries => 'Tidak Aktif';

  @override
  String get totalLaundriesLabel => 'Total Cabang';

  @override
  String get activeLaundriesLabel => 'Cabang Aktif';

  @override
  String get emptyLaundriesTitle => 'Belum ada cabang';

  @override
  String get emptyLaundriesSubtitle => 'Tambahkan cabang baru untuk memulai';

  @override
  String get newBranchButton => 'Cabang Baru';

  @override
  String get addBranchButton => 'Tambah Cabang';

  @override
  String get loadLaundriesError => 'Gagal memuat data cabang';

  @override
  String get addBranchTitle => 'Tambah Cabang Baru';

  @override
  String get editBranchTitle => 'Edit Data Cabang';

  @override
  String get addBranchInfo =>
      'Sistem akan memvalidasi limitasi kuota cabang sesuai paket langganan Anda secara otomatis sebelum menyimpan data.';

  @override
  String get editBranchInfo =>
      'Perubahan akan langsung tersimpan ke data cabang ini. Kuota paket langganan tidak berlaku untuk pengeditan.';

  @override
  String get ownerCompanyLabel => 'Perusahaan Pemilik Cabang';

  @override
  String get registerCompanyFirst => '+ Daftarkan Perusahaan Terlebih Dahulu';

  @override
  String get branchNameLabel => 'Nama Cabang';

  @override
  String get branchCodeLabel => 'Kode Cabang';

  @override
  String get branchFullAddressLabel => 'Alamat Lengkap';

  @override
  String get cityLabel => 'Kota';

  @override
  String get provinceLabel => 'Provinsi';

  @override
  String get branchContactPhoneLabel => 'Nomor Telepon';

  @override
  String get branchEmailOptionalLabel => 'Email Cabang (Opsional)';

  @override
  String get managerOptionalLabel => 'Manajer Cabang (Opsional)';

  @override
  String get noEmployeeDataInfo =>
      'Belum ada data karyawan. Manajer bisa ditugaskan belakangan.';

  @override
  String get dailyCapacityLabel => 'Kapasitas Harian (Jumlah Order)';

  @override
  String get mapLocationLabel => 'Titik Lokasi Peta (Opsional)';

  @override
  String get operatingHoursLabel => 'Jam Operasional';

  @override
  String get useSameHoursLabel => 'Gunakan jam yang sama untuk semua hari';

  @override
  String get everyDayLabel => 'Setiap Hari';

  @override
  String get activeStatusLabel => 'Status Cabang Aktif';

  @override
  String get saveBranchButton => 'Simpan Data Cabang';

  @override
  String get updateBranchButton => 'Simpan Perubahan';

  @override
  String get branchNameEmpty => 'Nama cabang tidak boleh kosong';

  @override
  String get branchCodeEmpty => 'Kode cabang tidak boleh kosong';

  @override
  String get addressEmpty => 'Alamat wajib diisi';

  @override
  String get fieldRequired => 'Wajib diisi';

  @override
  String get phoneEmpty => 'Nomor telepon wajib diisi';

  @override
  String get capacityEmpty => 'Kapasitas wajib diisi';

  @override
  String get quotaReachedTitle => 'Batas Kuota Tercapai';

  @override
  String get quotaReachedContent =>
      'Jumlah cabang Anda telah mencapai batas maksimal paket langganan saat ini.';

  @override
  String get upgradePlanButton => 'Upgrade Paket';

  @override
  String get branchAddSuccess => 'Cabang laundry berhasil ditambahkan!';

  @override
  String get branchUpdateSuccess => 'Perubahan cabang berhasil disimpan!';

  @override
  String get deleteBranchTitle => 'Hapus Cabang?';

  @override
  String deleteBranchConfirm(Object name) {
    return 'Cabang \"$name\" akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.';
  }

  @override
  String get contactInfoSection => 'Informasi Kontak';

  @override
  String get capacityLocationSection => 'Kapasitas & Lokasi';

  @override
  String get createdLabel => 'Dibuat';

  @override
  String get updatedLabel => 'Diperbarui';

  @override
  String get todayLabel => 'Hari ini';

  @override
  String get monday => 'Senin';

  @override
  String get tuesday => 'Selasa';

  @override
  String get wednesday => 'Rabu';

  @override
  String get thursday => 'Kamis';

  @override
  String get friday => 'Jumat';

  @override
  String get saturday => 'Sabtu';

  @override
  String get sunday => 'Minggu';

  @override
  String cardCapacityLabel(Object capacity) {
    return 'Kapasitas $capacity';
  }

  @override
  String get selectCompanyHint => 'Pilih perusahaan';

  @override
  String get branchNameHint => 'Contoh: Cabang Merdeka';

  @override
  String get branchCodeHint => 'Contoh: JKT001';

  @override
  String get branchAddressHint => 'Contoh: Jl. Merdeka No. 123';

  @override
  String get cityHint => 'Jakarta';

  @override
  String get provinceHint => 'DKI Jakarta';

  @override
  String get branchPhoneLabel => 'Nomor Telepon Cabang';

  @override
  String get branchPhoneHint => 'Contoh: +6281234567890';

  @override
  String get branchEmailHint => 'Contoh: cabang@laundry.com';

  @override
  String get selectManagerHint => 'Pilih manajer cabang';

  @override
  String get capacityHint => 'Contoh: 100';

  @override
  String get latitudeHint => 'Latitude';

  @override
  String get longitudeHint => 'Longitude';

  @override
  String get companyRequiredValidator => 'Perusahaan wajib dipilih';

  @override
  String get defaultCompanyName => 'Perusahaan Tanpa Nama';

  @override
  String get defaultEmployeeName => 'Karyawan';

  @override
  String get branchDataNotFoundError => 'Data cabang tidak ditemukan.';

  @override
  String loadBranchDataError(String error) {
    return 'Gagal memuat data cabang: $error';
  }

  @override
  String get companyNotSelectedWarning =>
      'Perusahaan belum dipilih atau belum dibuat!';

  @override
  String get userSessionExpiredError => 'Sesi user berakhir.';

  @override
  String saveBranchError(String error) {
    return 'Gagal menyimpan data cabang: $error';
  }

  @override
  String get branchDetailTitle => 'Detail Cabang';

  @override
  String deleteBranchConfirmDetail(String name, String code) {
    return 'Cabang \"$name\" ($code) akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.';
  }

  @override
  String branchDeleteSuccess(String name) {
    return 'Cabang \"$name\" berhasil dihapus.';
  }

  @override
  String deleteBranchError(String error) {
    return 'Gagal menghapus cabang: $error';
  }

  @override
  String get addressShortLabel => 'Alamat';

  @override
  String get phoneShortLabel => 'Telepon';

  @override
  String get capacityShortLabel => 'Kapasitas';

  @override
  String get coordinatesLabel => 'Koordinat';

  @override
  String get notSetLabel => 'Belum diatur';

  @override
  String get branchNotFoundTitle => 'Cabang tidak ditemukan';

  @override
  String get branchNotFoundSubtitle =>
      'Cabang mungkin sudah dihapus atau id tidak valid';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'Mei';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Agu';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Okt';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Des';

  @override
  String branchListTitle(int count) {
    return 'Daftar Cabang ($count)';
  }

  @override
  String get hideLabel => 'Sembunyikan';

  @override
  String openTodayStatus(String open, String close) {
    return 'Buka • $open - $close';
  }

  @override
  String get closedTemporarilyLabel => 'Tutup Sementara';

  @override
  String get totalStaffLabel => 'Total Staf';

  @override
  String get openTodayLabel => 'Jam Buka Hari Ini';

  @override
  String staffAtThisBranchLabel(int count) {
    return 'Staf di Cabang Ini ($count)';
  }

  @override
  String get noStaffAtBranch =>
      'Belum ada karyawan yang ditempatkan di cabang ini.';

  @override
  String get resignedLabel => 'Resign';

  @override
  String get deactivateBranchTitle => 'Nonaktifkan Cabang?';

  @override
  String get deactivateBranchContent =>
      'Cabang ini akan ditandai tutup sementara dan tidak menerima pesanan baru.';

  @override
  String get activeStatusSubtitle => 'Nonaktifkan untuk tutup sementara';

  @override
  String get generalInfoSection => 'Informasi Umum';

  @override
  String get deactivateBranchButton => 'Nonaktifkan Cabang';

  @override
  String get ordersListSubtitle => 'Kelola semua pesanan laundry Anda';

  @override
  String get newOrderButtonLabel => 'Baru';

  @override
  String get searchOrderHint => 'Cari pesanan...';

  @override
  String get orderWaitingStatus => 'Menunggu';

  @override
  String get orderProcessingStatus => 'Diproses';

  @override
  String get orderRetryButtonLabel => 'Coba Lagi';

  @override
  String get orderSessionNotFoundError =>
      'Sesi tidak ditemukan, silakan login ulang';

  @override
  String get createOrderAppBarTitle => 'Buat Pesanan Baru';

  @override
  String get createOrderSectionTitle => 'Detail Pesanan';

  @override
  String get createOrderSectionSubtitle => 'Isi informasi pesanan';

  @override
  String get selectCustomerLabel => 'Pelanggan';

  @override
  String get selectCustomerHint => 'Pilih pelanggan';

  @override
  String get selectServiceLabel => 'Pilih Layanan';

  @override
  String get selectServiceHint => 'Pilih jenis layanan';

  @override
  String get quantityLabel => 'Jumlah';

  @override
  String get priceLabel => 'Harga';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get taxLabel => 'Pajak';

  @override
  String get totalLabel => 'Total';

  @override
  String get notesOrderLabel => 'Catatan';

  @override
  String get notesOrderHint => 'Tambahkan catatan khusus untuk pesanan ini';

  @override
  String get addServiceItemButton => 'Tambah Layanan';

  @override
  String get removeServiceItemButton => 'Hapus';

  @override
  String get saveOrderButton => 'Simpan Pesanan';

  @override
  String get createOrderSuccess => 'Pesanan berhasil dibuat!';

  @override
  String createOrderError(String error) {
    return 'Gagal membuat pesanan: $error';
  }

  @override
  String get noActiveServicesError =>
      'Tidak ada layanan aktif. Tambahkan layanan dulu di menu Layanan sebelum membuat pesanan.';

  @override
  String get selectCustomerError => 'Silakan pilih pelanggan terlebih dahulu';

  @override
  String get orderDetailAppBarTitle => 'Detail Pesanan';

  @override
  String get orderDetailCustomerInfoTitle => 'Informasi Pelanggan';

  @override
  String get orderDetailItemsTitle => 'Item';

  @override
  String get orderDetailTimelineTitle => 'Timeline Status';

  @override
  String get orderDetailSummaryTitle => 'Ringkasan Pesanan';

  @override
  String get orderDetailNotesTitle => 'Catatan';

  @override
  String get orderDetailActionButtonsTitle => 'Aksi';

  @override
  String orderItemLabel(int count) {
    return '$count item';
  }

  @override
  String get closeButton => 'Tutup';

  @override
  String get selectOrderTitle => 'Pilih Pesanan';

  @override
  String get noOrdersWaitingPickupHint =>
      'Tidak ada pesanan yang menunggu dijemput.';

  @override
  String get noOrdersReadyDeliveryHint =>
      'Tidak ada pesanan yang siap diantar.';

  @override
  String get customerFallbackLabel => 'Pelanggan';

  @override
  String get orderNotFoundError => 'Pesanan tidak ditemukan';

  @override
  String loadOrderError(String error) {
    return 'Gagal memuat pesanan: $error';
  }

  @override
  String get loadingOrderLabel => 'Memuat pesanan...';

  @override
  String get schedulingDeliveryBadgeLabel => 'Menjadwalkan Pengantaran';

  @override
  String get scheduleDeliveryScreenTitle => 'Jadwalkan Antar Jemput';

  @override
  String get pickupModeLabel => 'Penjemputan';

  @override
  String get deliveryModeLabel => 'Pengantaran';

  @override
  String get newCustomerButtonShort => 'Baru';

  @override
  String get autoFilledScheduleHint =>
      'Tanggal & jam terisi otomatis dari saat pesanan dibuat';

  @override
  String get selectBranchLabel => 'Pilih Cabang';

  @override
  String get noActiveBranchesScheduleHint =>
      'Belum ada cabang aktif. Tambahkan cabang terlebih dahulu di menu Cabang.';

  @override
  String get createOrderSelectBranchHint => 'Pilih cabang';

  @override
  String get useMapLocationButton => 'Pakai lokasi peta';

  @override
  String get mapLocationComingSoon =>
      'Fitur pilih lokasi peta akan segera hadir';

  @override
  String get addressFieldExampleHint =>
      'Jl. Kebayoran Lama No. 123, Jakarta Selatan...';

  @override
  String get dateLabel => 'Tanggal';

  @override
  String get timeLabel => 'Jam';

  @override
  String get selectCourierLabel => 'Pilih Kurir';

  @override
  String get noCourierEmployeeScheduleHint =>
      'Belum ada karyawan dengan posisi \"Kurir\". Anda tetap bisa menyimpan jadwal tanpa memilih kurir.';

  @override
  String get searchCourierHint => 'Cari kurir terdekat...';

  @override
  String get courierListHint =>
      'Kurir aktif dengan posisi \"Kurir\" ditampilkan di daftar ini.';

  @override
  String get additionalNotesLabel => 'Catatan Tambahan (Opsional)';

  @override
  String get notesExampleHint =>
      'Contoh: Titipkan di satpam, pagar warna hitam...';

  @override
  String get scheduleSummaryTitle => 'RINGKASAN JADWAL';

  @override
  String get selectOrSearchOrderLabel => 'Pilih atau Cari Pesanan';

  @override
  String get addressNotSetLabel => 'Alamat belum ditentukan';

  @override
  String get notScheduledLabel => 'Belum dijadwalkan';

  @override
  String modeWithBranchLabel(String mode, String branch) {
    return 'Mode: $mode • $branch';
  }

  @override
  String modeOnlyLabel(String mode) {
    return 'Mode: $mode';
  }

  @override
  String get saveScheduleButton => 'Simpan Jadwal';

  @override
  String get selectOrderRequiredError => 'Pilih pesanan terlebih dahulu';

  @override
  String get addressRequiredError => 'Alamat wajib diisi';

  @override
  String get dateTimeRequiredError => 'Tanggal dan jam wajib dipilih';

  @override
  String get scheduleSaveSuccess => 'Jadwal berhasil disimpan';

  @override
  String scheduleSaveError(String error) {
    return 'Gagal menyimpan jadwal: $error';
  }

  @override
  String get waitingPickupStatus => 'Menunggu dijemput';

  @override
  String get readyDeliveryStatus => 'Siap diantar';

  @override
  String get readyPickupStatus => 'Siap diambil';

  @override
  String get waitingConfirmationStatus => 'Menunggu konfirmasi';

  @override
  String get confirmedStatus => 'Dikonfirmasi';

  @override
  String get inProgressStatus => 'Dalam proses';

  @override
  String markedPickedUpSnackbar(String orderNumber) {
    return '$orderNumber ditandai sudah dijemput';
  }

  @override
  String markedDeliveredSnackbar(String orderNumber) {
    return '$orderNumber ditandai sudah diantar';
  }

  @override
  String markedDeliveredCompletedSnackbar(String orderNumber) {
    return '$orderNumber ditandai sudah diantar & selesai';
  }

  @override
  String genericUpdateError(String error) {
    return 'Gagal update: $error';
  }

  @override
  String get addScheduleButton => 'Tambah Jadwal';

  @override
  String get pickupDeliveryTitle => 'Antar Jemput';

  @override
  String get pickupDeliverySubtitle => 'Kelola jemput, antar & ambil sendiri';

  @override
  String get searchOrderCustomerHint =>
      'Cari nama pelanggan atau no. pesanan...';

  @override
  String get filterNeedsPickup => 'Perlu dijemput';

  @override
  String get filterNeedsDelivery => 'Perlu diantar';

  @override
  String get filterSelfService => 'Ambil sendiri';

  @override
  String get filterOthers => 'Lainnya';

  @override
  String get statNeedsPickupTitle => 'Perlu Dijemput';

  @override
  String get statReadyDeliveryTitle => 'Siap Diantar';

  @override
  String get statSelfServiceTitle => 'Ambil Sendiri';

  @override
  String get noOrdersTitle => 'Tidak ada pesanan';

  @override
  String get noOrdersFilterSubtitle =>
      'Belum ada pesanan yang cocok dengan filter ini';

  @override
  String get selectScheduleModeSubtitle => 'Pilih mode jadwal yang mau dibuat';

  @override
  String get schedulePickupTileTitle => 'Jadwalkan Penjemputan';

  @override
  String get schedulePickupTileSubtitle =>
      'Untuk pesanan yang menunggu dijemput';

  @override
  String get scheduleDeliveryTileTitle => 'Jadwalkan Pengantaran';

  @override
  String get scheduleDeliveryTileSubtitle =>
      'Untuk pesanan yang sudah siap diantar';

  @override
  String get selectServiceTitle => 'Pilih Layanan';

  @override
  String get noActiveServicesHint => 'Belum ada layanan aktif.';

  @override
  String get dpAmountRequiredError => 'Isi nominal DP terlebih dahulu';

  @override
  String get dpAmountTooLargeError =>
      'Nominal DP harus lebih kecil dari total. Pilih \"Lunas\" kalau bayar penuh.';

  @override
  String get minOneItemError => 'Tambahkan minimal 1 item';

  @override
  String weightRequiredError(String itemName) {
    return 'Isi berat (kg) untuk \"$itemName\"';
  }

  @override
  String confirmFailedError(String error) {
    return 'Gagal konfirmasi: $error';
  }

  @override
  String get cashPaymentLabel => 'Tunai';

  @override
  String get bankTransferLabel => 'Transfer Bank';

  @override
  String get debitCardLabel => 'Kartu Debit';

  @override
  String get eWalletLabel => 'E-Wallet';

  @override
  String get paymentMethodLabel => 'Metode Pembayaran';

  @override
  String get transferPaymentPendingNotice =>
      'Status pembayaran akan \"Belum Dibayar\" sampai dikonfirmasi manual di halaman detail pesanan.';

  @override
  String get instantPaymentNotice =>
      'Metode ini dianggap dibayar langsung saat ini juga.';

  @override
  String get fullPaymentLabel => 'Lunas';

  @override
  String get partialPaymentLabel => 'DP (Sebagian)';

  @override
  String get dpAmountLabel => 'Nominal DP';

  @override
  String get dpAmountHint => 'Contoh: 20000';

  @override
  String get remainingBalanceHint =>
      'Sisa tagihan bisa dilunasi nanti lewat halaman detail pesanan.';

  @override
  String get confirmPickupTitle => 'Konfirmasi Jemput';

  @override
  String confirmPickupSubtitle(String customerName, String orderNumber) {
    return 'Catat item & berat cucian $customerName ($orderNumber)';
  }

  @override
  String get laundryItemsLabel => 'Item Cucian';

  @override
  String get addButtonLabel => 'Tambah';

  @override
  String get noItemsAddHint =>
      'Belum ada item. Tekan \"Tambah\" untuk memilih layanan.';

  @override
  String get confirmPickedUpButton => 'Konfirmasi Sudah Dijemput';

  @override
  String get confirmDeliveryTitle => 'Konfirmasi Antar';

  @override
  String confirmDeliverySubtitle(String customerName, String orderNumber) {
    return 'Antar cucian $customerName ($orderNumber)';
  }

  @override
  String get assignedCourierLabel => 'Kurir Bertugas (Opsional)';

  @override
  String get noCourierEmployeeDeliverHint =>
      'Belum ada karyawan dengan posisi \"Kurir\". Anda tetap bisa lanjut menandai order ini sudah diantar.';

  @override
  String get selectCourierHint => 'Pilih kurir';

  @override
  String get confirmDeliveredButton => 'Konfirmasi Sudah Diantar';

  @override
  String get pickupTypeLabel => 'Jemput';

  @override
  String get walkInTypeLabel => 'Walk-in';

  @override
  String get deliveryTypeLabel => 'Antar';

  @override
  String get selfPickupTypeLabel => 'Ambil Sendiri';

  @override
  String get genericCourierLabel => 'Kurir';

  @override
  String get courierNotAssignedLabel => 'Kurir belum ditentukan';

  @override
  String plannedPickupLabel(String date) {
    return 'Rencana jemput: $date';
  }

  @override
  String selfServicePickedUpLabel(String date) {
    return 'Diambil: $date';
  }

  @override
  String deliveredAtLabel(String date) {
    return 'Diantar: $date';
  }

  @override
  String pickedUpFromCustomerLabel(String date) {
    return 'Dijemput: $date';
  }

  @override
  String get markPickedUpButton => 'Tandai Sudah Dijemput';

  @override
  String get markSelfPickedUpButton => 'Tandai Sudah Diambil';

  @override
  String get markDeliveredButton => 'Tandai Sudah Diantar';

  @override
  String get employeeNotFoundError => 'Data karyawan tidak ditemukan.';

  @override
  String employeeLoadError(String error) {
    return 'Gagal memuat data karyawan: $error';
  }

  @override
  String employeeGenericError(String error) {
    return 'Terjadi kesalahan: $error';
  }

  @override
  String get branchNotSelectedWarning =>
      'Cabang laundry belum dipilih atau belum dibuat!';

  @override
  String get sessionExpiredError => 'Sesi user berakhir.';

  @override
  String get branchNotLinkedWarning =>
      'Cabang terpilih belum terhubung dengan data perusahaan. Periksa kembali data cabang.';

  @override
  String get quotaLimitReachedTitle => 'Batas Kuota Tercapai';

  @override
  String get quotaLimitReachedContent =>
      'Jumlah karyawan Anda telah mencapai batas maksimal kuota paket langganan saat ini. Silakan upgrade paket.';

  @override
  String get employeeUpdateSuccess => 'Data karyawan berhasil diperbarui!';

  @override
  String get employeeAddSuccess => 'Staf karyawan berhasil ditambahkan!';

  @override
  String employeeSaveError(String error) {
    return 'Gagal menyimpan data karyawan: $error';
  }

  @override
  String get deactivateEmployeeTitle => 'Nonaktifkan Karyawan';

  @override
  String get deactivateEmployeeConfirm =>
      'Apakah Anda yakin ingin menonaktifkan karyawan ini? Riwayat transaksi lama akan tetap aman.';

  @override
  String get deactivateEmployeeConfirmAlt =>
      'Apakah Anda yakin ingin menonaktifkan status aktif karyawan ini? Riwayat transaksi lama akan tetap aman.';

  @override
  String get yesDeactivateButton => 'Ya, Nonaktifkan';

  @override
  String get employeeDeactivatedSuccess => 'Karyawan telah dinonaktifkan.';

  @override
  String employeeDeactivateError(String error) {
    return 'Gagal menonaktifkan karyawan: $error';
  }

  @override
  String get editEmployeeTitle => 'Edit Data Karyawan';

  @override
  String get addEmployeeTitle => 'Tambah Karyawan';

  @override
  String get additionalDetailsDivider => 'DETAIL TAMBAHAN';

  @override
  String get editEmployeeInfoBanner =>
      'Perubahan akan langsung tersimpan pada data karyawan ini.';

  @override
  String get addEmployeeInfoBanner =>
      'Sistem akan memvalidasi limitasi kuota paket langganan Anda secara otomatis sebelum menyimpan data karyawan.';

  @override
  String get fullNameHint => 'Contoh: Siti Aminah';

  @override
  String get employeeNameRequiredError => 'Nama karyawan wajib diisi';

  @override
  String get phoneNumberLabel => 'Nomor Telepon';

  @override
  String get phoneNumberRequiredError => 'Nomor telepon wajib diisi';

  @override
  String get emailOptionalLabel => 'Email (Opsional)';

  @override
  String get invalidEmailFormatError => 'Format email tidak valid';

  @override
  String get addressLabel => 'Alamat';

  @override
  String get addressHint => 'Masukkan alamat lengkap rumah';

  @override
  String get roleLabel => 'Role / Jabatan';

  @override
  String get selectPositionHint => 'Pilih Jabatan';

  @override
  String get positionRequiredError => 'Posisi atau jabatan wajib dipilih';

  @override
  String get assignedBranchLabel => 'Cabang Bertugas';

  @override
  String get registerNewBranchFirstButton =>
      '+ Daftarkan Cabang Baru Terlebih Dahulu';

  @override
  String get selectBranchHint => 'Pilih Cabang';

  @override
  String get branchRequiredError => 'Cabang penempatan wajib dipilih';

  @override
  String get hireDateLabel => 'Tanggal Bergabung';

  @override
  String get appAccessTitle => 'Akses Aplikasi';

  @override
  String get appAccessSubtitle => 'Berikan akses login aplikasi';

  @override
  String get employeeStatusTitle => 'Status Karyawan';

  @override
  String employeeStatusCurrent(String status) {
    return 'Status saat ini: $status';
  }

  @override
  String get statusActive => 'Aktif';

  @override
  String get statusInactive => 'Tidak Aktif';

  @override
  String get employeeCodeLabel => 'Kode Karyawan';

  @override
  String get employeeCodeHint => 'Contoh: EMP01, KSR02';

  @override
  String get employeeCodeRequiredError => 'Kode karyawan tidak boleh kosong';

  @override
  String get baseSalaryLabel => 'Gaji Pokok (IDR)';

  @override
  String get baseSalaryRequiredError => 'Gaji pokok wajib diisi';

  @override
  String get commissionPerTransactionLabel => 'Komisi per Transaksi (%)';

  @override
  String get commissionHint => 'Contoh: 5.0';

  @override
  String get employeePermissionsTitle => 'Hak Akses Fitur Karyawan';

  @override
  String get employeePermissionsSubtitle =>
      'Atur fitur apa saja yang boleh diakses karyawan ini';

  @override
  String get canCreateOrderPermission => 'Dapat Membuat Pesanan (Order)';

  @override
  String get canManageCustomerPermission => 'Dapat Mengelola Data Pelanggan';

  @override
  String get canViewReportPermission =>
      'Dapat Melihat Laporan Keuangan (Report)';

  @override
  String get savingButton => 'Menyimpan...';

  @override
  String get saveEmployeeButton => 'Simpan Karyawan';

  @override
  String get completeRequiredFieldsWarning =>
      'Lengkapi dulu data yang wajib diisi';

  @override
  String get employeeDetailTitle => 'Detail Karyawan';

  @override
  String employeeCodeFallback(String code) {
    return 'Karyawan $code';
  }

  @override
  String get laundryStaffFallback => 'Staf Laundry';

  @override
  String get addressFullLabel => 'Alamat Lengkap';

  @override
  String get employmentInfoTitle => 'Informasi Pekerjaan';

  @override
  String get documentIdLabel => 'ID Dokumen';

  @override
  String get positionLabel => 'Posisi Kerja';

  @override
  String get baseSalaryShortLabel => 'Gaji Pokok';

  @override
  String get commissionLabel => 'Komisi';

  @override
  String get systemAccessTitle => 'Hak Akses Sistem';

  @override
  String get createOrdersPermissionShort => 'Membuat Pesanan';

  @override
  String get manageCustomersPermissionShort => 'Mengelola Pelanggan';

  @override
  String get viewReportsPermissionShort => 'Melihat Laporan';

  @override
  String get activityHistoryLabel => 'Riwayat Aktivitas';

  @override
  String activityLogEntryLabel(String stage, String orderNumber) {
    return '$stage · $orderNumber';
  }

  @override
  String get activityHistoryUnavailable => 'Riwayat aktivitas belum tersedia.';

  @override
  String get today => 'Hari Ini';

  @override
  String get yesterday => 'Kemarin';

  @override
  String get loggedInActivityLabel => 'Masuk ke akun';

  @override
  String get loggedOutActivityLabel => 'Keluar dari akun';

  @override
  String get latestActivityBadge => 'Terbaru';

  @override
  String get noActivityYet => 'Belum ada aktivitas.';

  @override
  String get viewAllActivityLabel => 'Lihat semua aktivitas';

  @override
  String get resetPasswordLabel => 'Reset Password';

  @override
  String get resetPasswordUnavailable => 'Reset password belum tersedia.';

  @override
  String get manageEmployeesTitle => 'Kelola Karyawan';

  @override
  String get searchEmployeeHint => 'Cari nama atau nomor telepon karyawan...';

  @override
  String get filterAllLabel => 'Semua';

  @override
  String get allRolesLabel => 'Semua Role';

  @override
  String get totalEmployeesLabel => 'Total Karyawan';

  @override
  String get noEmployeesFoundTitle => 'Data karyawan tidak ditemukan';

  @override
  String get noEmployeesFoundSubtitle =>
      'Coba ubah filter atau tambahkan karyawan baru';

  @override
  String get newEmployeeButton => 'Karyawan Baru';

  @override
  String get noNameFallback => 'Tanpa Nama';

  @override
  String get terminateEmployeeTitle => 'Terminasi Karyawan';

  @override
  String terminateEmployeeConfirm(String name, String position) {
    return 'Apakah Anda yakin ingin menonaktifkan $name ($position)?';
  }

  @override
  String employeeDeactivatedWithCodeSuccess(String code) {
    return 'Karyawan $code telah dinonaktifkan';
  }

  @override
  String get unnamedBranchFallback => 'Cabang Tanpa Nama';

  @override
  String get ordersListTitle => 'Pesanan';

  @override
  String get orderCompletedStatus => 'Selesai';

  @override
  String get orderCancelledStatus => 'Dibatalkan';

  @override
  String get orderNoOrdersLabel => 'Belum ada pesanan';

  @override
  String get orderCreateOrderButtonLabel =>
      'Buat pesanan pertama Anda sekarang';

  @override
  String get orderNoOrdersInBranch => 'Belum ada pesanan di cabang ini';

  @override
  String get orderSuggestNewOrChangeBranch =>
      'Silakan tambahkan pesanan baru atau coba pilih filter cabang yang berbeda.';

  @override
  String get orderStatusWaiting => 'Menunggu';

  @override
  String get orderStatusConfirmed => 'Dikonfirmasi';

  @override
  String get orderStatusProcessing => 'Diproses';

  @override
  String get orderStatusWashing => 'Dicuci';

  @override
  String get orderStatusDrying => 'Dikeringkan';

  @override
  String get orderStatusIroning => 'Disetrika';

  @override
  String get orderStatusQualityCheck => 'Cek Kualitas';

  @override
  String get orderStatusReady => 'Siap Diambil';

  @override
  String get orderTypePickup => 'Dijemput';

  @override
  String get orderTypeWalkIn => 'Walk-in';

  @override
  String get orderDeliveryDelivery => 'Diantar';

  @override
  String get orderDeliverySelfPickup => 'Ambil Sendiri';

  @override
  String get orderServiceMoreSuffix => 'lainnya';

  @override
  String get orderTotalPaymentLabel => 'Total Pembayaran';

  @override
  String get orderItemsLabel => 'item';

  @override
  String get linkOpenError => 'Tidak bisa membuka tautan';

  @override
  String appVersionLabel(String version) {
    return 'Versi $version';
  }

  @override
  String get aboutAppDescription =>
      'NetWash adalah aplikasi laundry on-demand yang memudahkan kamu menjemput, mencuci, dan mengantar pakaian tanpa repot.';

  @override
  String get privacyPolicyLabel => 'Kebijakan Privasi';

  @override
  String get termsConditionsLabel => 'Syarat dan Ketentuan';

  @override
  String get rateAppLabel => 'Beri Rating Aplikasi';

  @override
  String get copyrightNotice => '© 2026 NetWash. All rights reserved.';

  @override
  String get searchFaqHint => 'Cari pertanyaan...';

  @override
  String get notAnsweredContactUs => 'Belum terjawab? Hubungi kami';

  @override
  String get faqOrderQuestion => 'Bagaimana cara order cuci?';

  @override
  String get faqOrderAnswer =>
      'Buka menu Order, pilih layanan, tentukan alamat jemput, lalu konfirmasi pesanan. Kurir akan datang sesuai jadwal.';

  @override
  String get faqDurationQuestion => 'Berapa lama proses cucian?';

  @override
  String get faqDurationAnswer =>
      'Proses cuci reguler 1-2 hari kerja, express selesai dalam 6 jam sejak dijemput.';

  @override
  String get faqPaymentQuestion => 'Metode pembayaran apa saja?';

  @override
  String get faqPaymentAnswer =>
      'Kami menerima transfer bank, e-wallet, dan pembayaran tunai langsung ke kurir.';

  @override
  String get faqTrackQuestion => 'Cara lacak status pesanan?';

  @override
  String get faqTrackAnswer =>
      'Buka menu Orders, pilih pesanan aktif, status akan otomatis update mengikuti tahap pengerjaan.';

  @override
  String get chatBotTopicBranchQuestion =>
      'Bagaimana cara menambah cabang baru?';

  @override
  String get chatBotTopicBranchAnswer =>
      'Caranya:\n1. Dari dashboard, buka menu Cabang.\n2. Ketuk \"Cabang Baru\".\n3. Isi nama cabang, kode cabang, kota, provinsi, dan alamat lengkap.\n4. Kalau perlu, isi juga nomor telepon, email cabang, dan titik lokasi di peta.\n5. Isi kapasitas harian (jumlah pesanan maksimal per hari).\n6. Atur jam operasional per hari, atau centang \"Gunakan jam yang sama untuk semua hari\".\n7. Ketuk \"Simpan Data Cabang\".';

  @override
  String get chatBotTopicEmployeeQuestion =>
      'Bagaimana cara menambah karyawan baru?';

  @override
  String get chatBotTopicEmployeeAnswer =>
      'Caranya:\n1. Dari dashboard, buka menu Kelola Karyawan.\n2. Ketuk \"Karyawan Baru\".\n3. Isi nama lengkap, nomor telepon, dan (opsional) email & alamat.\n4. Isi kode karyawan, posisi, dan cabang penempatannya.\n5. Isi tanggal bergabung, gaji pokok, dan komisi per transaksi (opsional).\n6. Atur hak akses fitur (bisa buat pesanan, kelola pelanggan, lihat laporan).\n7. Aktifkan \"Akses Aplikasi\" kalau karyawan ini boleh login ke aplikasi.\n8. Ketuk \"Simpan Karyawan\".';

  @override
  String get chatBotTopicServiceQuestion =>
      'Bagaimana cara menambah layanan cuci dan mengatur harganya?';

  @override
  String get chatBotTopicServiceAnswer =>
      'Caranya:\n1. Dari dashboard, buka menu Layanan.\n2. Ketuk \"Layanan Baru\".\n3. Isi nama layanan dan deskripsi (opsional).\n4. Pilih jenis layanan: Per Berat, Per Item, atau Express.\n5. Isi harga (per Kg/Item, atau harga dasar + biaya express) dan berat minimum kalau ada.\n6. Atur estimasi waktu pengerjaan (jam atau hari).\n7. Pilih cabang mana saja yang menyediakan layanan ini, atau biarkan kosong supaya tersedia di semua cabang.\n8. Ketuk \"Simpan Layanan\".';

  @override
  String get chatBotTopicOrderQuestion =>
      'Bagaimana cara membuat pesanan baru?';

  @override
  String get chatBotTopicOrderAnswer =>
      'Caranya:\n1. Dari dashboard, ketuk \"Pesanan Baru\".\n2. Pilih cabang dan pelanggan (tambahkan pelanggan baru dulu kalau belum ada).\n3. Ketuk salah satu layanan untuk menambahkannya ke pesanan, lalu isi berat/jumlahnya.\n4. Kalau perlu, atur jadwal pickup, atau kosongkan dan jadwalkan nanti dari menu Pickup & Delivery.\n5. Pilih metode pembayaran dan apakah lunas atau bayar DP.\n6. Kalau DP, isi jumlah yang dibayar di muka.\n7. Ketuk \"Simpan Pesanan\".';

  @override
  String get chatBotTopicReportQuestion =>
      'Bagaimana cara melihat laporan bisnis saya?';

  @override
  String get chatBotTopicReportAnswer =>
      'Caranya:\n1. Dari dashboard, buka menu Laporan.\n2. Pilih periode: Hari Ini, Minggu Ini, Bulan Ini, atau Tahun Ini.\n3. Lihat ringkasan pendapatan, pelanggan baru, rata-rata pesanan, dan pertumbuhan.\n4. Scroll ke bawah untuk lihat grafik tren pendapatan dan pendapatan per layanan.\n5. Cek Completion Rate untuk lihat persentase pesanan yang sudah selesai.\n6. Ketuk \"Cetak Laporan\" kalau mau ekspor ke PDF.';

  @override
  String get chatBotTopicLanguageQuestion =>
      'Bagaimana cara mengganti bahasa aplikasi?';

  @override
  String get chatBotTopicLanguageAnswer =>
      'Caranya:\n1. Buka menu Pengaturan.\n2. Ketuk menu Bahasa.\n3. Pilih bahasa yang diinginkan (Indonesia/English).\n4. Perubahan langsung diterapkan ke seluruh aplikasi.';

  @override
  String get orderDetailStatusPending => 'Menunggu';

  @override
  String get orderDetailStatusConfirmed => 'Dikonfirmasi';

  @override
  String get orderDetailStatusInProgress => 'Diproses';

  @override
  String get orderDetailStatusWashing => 'Washing (Pencucian)';

  @override
  String get orderDetailStatusDrying => 'Drying (Pengeringan)';

  @override
  String get orderDetailStatusIroning => 'Ironing (Penyetrikaan)';

  @override
  String get orderDetailStatusQualityCheck => 'Quality Check';

  @override
  String get orderDetailStatusReady => 'Siap Diambil/Kirim';

  @override
  String get orderDetailStatusCompleted => 'Selesai';

  @override
  String get orderDetailStatusCancelled => 'Dibatalkan';

  @override
  String get orderDetailNotePending => 'Menunggu konfirmasi';

  @override
  String get orderDetailNoteConfirmed => 'Pesanan sudah dikonfirmasi';

  @override
  String get orderDetailNoteInProgress => 'Sedang diproses';

  @override
  String get orderDetailNoteWashing => 'Sedang dalam mesin cuci';

  @override
  String get orderDetailNoteDrying => 'Sedang dikeringkan';

  @override
  String get orderDetailNoteIroning => 'Sedang disetrika';

  @override
  String get orderDetailNoteQualityCheck => 'Sedang dicek kualitasnya';

  @override
  String get orderDetailNoteReady => 'Siap diambil / diantar';

  @override
  String get orderDetailNoteCompleted => 'Pesanan sudah selesai';

  @override
  String get paymentMethodCash => 'Tunai';

  @override
  String get paymentMethodTransfer => 'Transfer Bank';

  @override
  String get paymentMethodDebit => 'Kartu Debit';

  @override
  String get paymentMethodEwallet => 'E-Wallet';

  @override
  String get orderDetailPaymentStatusPaid => 'Lunas';

  @override
  String get orderDetailPaymentStatusPartial => 'DP Sebagian';

  @override
  String get orderDetailPaymentStatusRefunded => 'Refund';

  @override
  String get orderDetailPaymentStatusPending => 'Belum Dibayar';

  @override
  String statusUpdateSuccess(String status) {
    return 'Status berhasil diubah menjadi $status';
  }

  @override
  String statusUpdateError(String error) {
    return 'Gagal mengupdate status: $error';
  }

  @override
  String get paymentRecordSuccess => 'Pembayaran berhasil dicatat';

  @override
  String get customerPhoneUnavailable =>
      'Nomor telepon pelanggan tidak tersedia';

  @override
  String get whatsappOpenError => 'Tidak bisa membuka WhatsApp';

  @override
  String get amountMustBePositiveError => 'Nominal harus lebih dari Rp0';

  @override
  String get receiptDownloadWebUnsupported =>
      'Download struk cuma didukung di aplikasi HP, bukan di web';

  @override
  String get receiptImageGenerationError => 'Gagal membuat gambar struk';

  @override
  String get receiptSavedToGallery => 'Struk tersimpan di galeri';

  @override
  String receiptDownloadError(String error) {
    return 'Gagal mengunduh struk: $error';
  }

  @override
  String get cancellationReasonRequiredError => 'Alasan pembatalan wajib diisi';

  @override
  String cancelOrderError(String error) {
    return 'Gagal membatalkan pesanan: $error';
  }

  @override
  String get cancellationRequestSubmitted =>
      'Pengajuan pembatalan terkirim, menunggu persetujuan';

  @override
  String cancellationRequestSubmitError(String error) {
    return 'Gagal mengirim pengajuan: $error';
  }

  @override
  String get cancellationRequestApproved =>
      'Pengajuan pembatalan disetujui, pesanan dibatalkan';

  @override
  String cancellationRequestApproveError(String error) {
    return 'Gagal menyetujui pengajuan: $error';
  }

  @override
  String get cancellationRequestRejected => 'Pengajuan pembatalan ditolak';

  @override
  String cancellationRequestRejectError(String error) {
    return 'Gagal menolak pengajuan: $error';
  }

  @override
  String get deliveryScheduleSuccess => 'Pengantaran berhasil dijadwalkan';

  @override
  String statusChangedNoteTemplate(String status) {
    return 'Status diubah ke $status';
  }

  @override
  String get assignOperatorDialogTitle => 'Pilih Operator';

  @override
  String assignOperatorDialogSubtitle(String stage) {
    return 'Siapa yang akan mengerjakan tahap $stage?';
  }

  @override
  String get assignOperatorFieldLabel => 'Operator';

  @override
  String get assignOperatorEmptyState =>
      'Belum ada karyawan aktif yang bisa ditugaskan';

  @override
  String get assignOperatorConfirmButtonLabel => 'Tugaskan & Lanjut';

  @override
  String currentOperatorLabel(String name) {
    return 'Sedang dikerjakan oleh $name';
  }

  @override
  String activityLogByOperatorLabel(String name) {
    return 'oleh $name';
  }

  @override
  String orderCancelledNoteTemplate(String reason) {
    return 'Pesanan dibatalkan: $reason';
  }

  @override
  String cancellationRequestedNoteTemplate(String name, String reason) {
    return 'Pengajuan pembatalan oleh $name: $reason';
  }

  @override
  String cancellationApprovedNoteTemplate(String name) {
    return 'Pengajuan pembatalan disetujui oleh $name';
  }

  @override
  String cancellationRejectedNoteTemplate(String name) {
    return 'Pengajuan pembatalan ditolak oleh $name';
  }

  @override
  String whatsappOrderReadyDeliveryMessage(String name, String orderNumber) {
    return 'Halo kak $name!, ini Netwash 😊 . Pesanan kamu ($orderNumber) sudah selesai dan akan segera kami antar ke alamat kakak ya. Ditunggu ya kak 🙏';
  }

  @override
  String whatsappOrderReadyPickupMessage(String name, String orderNumber) {
    return 'Halo kak $name!, ini Netwash 😊 . Pesanan kamu ($orderNumber) sudah selesai dan siap diambil oleh kakak, mau diambil jam berapa ya kak?. Ditunggu ya 🙏';
  }

  @override
  String whatsappContactMessage(String name, String orderNumber) {
    return 'Halo kak $name, ini dari Netwash terkait pesanan $orderNumber.';
  }

  @override
  String get receiptWhatsappTitle => 'Struk Pesanan - Netwash';

  @override
  String get receiptOrderNumberLabel => 'No. Pesanan';

  @override
  String get receiptDateLabel => 'Tanggal';

  @override
  String get receiptCustomerLabel => 'Pelanggan';

  @override
  String get receiptItemsLabel => 'Item';

  @override
  String get receiptTotalLabel => 'Total';

  @override
  String get receiptPaymentMethodLabel => 'Metode Bayar';

  @override
  String get receiptPaymentStatusLabel => 'Status Bayar';

  @override
  String get receiptThankYouMessage => 'Terima kasih sudah pakai Netwash 🙏';

  @override
  String get receiptFallbackSubtitle => 'Struk Pesanan';

  @override
  String get confirmPaymentDialogTitle => 'Konfirmasi Pembayaran';

  @override
  String remainingBillDialogLabel(String amount) {
    return 'Sisa tagihan: $amount';
  }

  @override
  String get amountPaidFieldLabel => 'Nominal Dibayar';

  @override
  String get methodFieldLabel => 'Metode';

  @override
  String get saveButtonLabel => 'Simpan';

  @override
  String get cancelOrderDialogTitle => 'Batalkan Pesanan?';

  @override
  String get requestCancellationDialogTitle => 'Ajukan Pembatalan?';

  @override
  String get cancelOrderDialogContent =>
      'Tindakan ini akan mengubah status pesanan menjadi Dibatalkan.';

  @override
  String get requestCancellationDialogContent =>
      'Pengajuan ini perlu disetujui Admin/Owner/Manager sebelum status pesanan berubah jadi Dibatalkan.';

  @override
  String get cancellationReasonFieldLabel => 'Alasan pembatalan';

  @override
  String get noButtonLabel => 'Tidak';

  @override
  String get yesCancelButtonLabel => 'Ya, Batalkan';

  @override
  String get submitCancellationRequestButtonLabel => 'Ajukan Pembatalan';

  @override
  String get orderDetailTitle => 'Detail Pesanan';

  @override
  String get orderStatusSectionLabel => 'Status Pesanan';

  @override
  String get orderCancelledTitle => 'Pesanan Dibatalkan';

  @override
  String get trackProgressTitle => 'Lacak Progress';

  @override
  String get customerInfoSectionLabel => 'Informasi Pelanggan';

  @override
  String get registeredBranchLabel => 'Cabang Terdaftar';

  @override
  String get itemCountLabel => 'Jumlah Item';

  @override
  String itemCountValueTemplate(int count) {
    return '$count item';
  }

  @override
  String get serviceLabel => 'Layanan';

  @override
  String get costBreakdownSectionLabel => 'Rincian Biaya';

  @override
  String get totalBillLabel => 'Total Tagihan';

  @override
  String get paymentSectionLabel => 'Pembayaran';

  @override
  String get paidAmountLabel => 'Sudah Dibayar';

  @override
  String get remainingBillLabel => 'Sisa Tagihan';

  @override
  String get orderStatusPendingPayment => 'Belum Lunas';

  @override
  String get confirmPaymentButtonLabel => 'Konfirmasi Pembayaran';

  @override
  String get downloadReceiptButtonLabel => 'Download Struk';

  @override
  String get sendReceiptWhatsappButtonLabel => 'Kirim Struk via WA';

  @override
  String get paymentHistorySectionLabel => 'Riwayat Pembayaran';

  @override
  String get notesSectionLabel => 'Catatan';

  @override
  String get cancelOrderButtonLabel => 'Batalkan Pesanan';

  @override
  String get pendingCancellationApprovalTitle =>
      'Menunggu Persetujuan Pembatalan';

  @override
  String requestedByLabel(String name) {
    return 'Diajukan oleh $name';
  }

  @override
  String reasonLabel(String reason) {
    return 'Alasan: $reason';
  }

  @override
  String get employeeFallbackLabel => 'Karyawan';

  @override
  String get rejectButtonLabel => 'Tolak';

  @override
  String get approveButtonLabel => 'Setujui';

  @override
  String get notifyReadyForDeliveryButtonLabel => 'Kabari Siap Diantar';

  @override
  String get notifyViaWhatsappButtonLabel => 'Kabari via WhatsApp';

  @override
  String get scheduleDeliveryButtonLabel => 'Jadwalkan Pengantaran';

  @override
  String get editDeliveryScheduleButtonLabel => 'Ubah Jadwal Pengantaran';

  @override
  String get branchFollowsSelectedOrderHint =>
      'Cabang mengikuti pesanan yang dipilih';

  @override
  String get addressAutoFilledFromCustomerHint =>
      'Alamat otomatis dari data pelanggan - ganti kalau perlu';

  @override
  String noActiveCourierInBranchHint(String branchName) {
    return 'Belum ada kurir aktif di cabang $branchName';
  }

  @override
  String get courierMatchesScheduleHint =>
      'Sesuai jadwal yang sudah dibuat - ganti kalau perlu';

  @override
  String get deliveryScheduleUpdateSuccess =>
      'Jadwal pengantaran berhasil diperbarui';

  @override
  String get contactCustomerButtonLabel => 'Hubungi Pelanggan';

  @override
  String get confirmOrderButtonLabel => 'Konfirmasi Pesanan';

  @override
  String get startProcessButtonLabel => 'Mulai Proses';

  @override
  String get startWashingButtonLabel => 'Mulai Mencuci';

  @override
  String get finishWashingButtonLabel => 'Selesai Dicuci';

  @override
  String get finishDryingButtonLabel => 'Selesai Dikeringkan';

  @override
  String get finishIroningButtonLabel => 'Selesai Disetrika';

  @override
  String get passQualityCheckButtonLabel => 'Lolos Cek Kualitas';

  @override
  String get markCompletedButtonLabel => 'Tandai Selesai';

  @override
  String get createOrderSubtitle => 'Buat dan kelola pesanan laundry baru';

  @override
  String get noBranchesForOrderError =>
      'Belum ada cabang laundry. Tambahkan cabang dulu sebelum membuat pesanan.';

  @override
  String fillWeightForItemError(String itemName) {
    return 'Isi berat (kg) untuk \"$itemName\" terlebih dahulu';
  }

  @override
  String get businessContextNotReadyError =>
      'Data perusahaan/cabang belum siap. Coba lagi sebentar.';

  @override
  String get selectedCustomerNotFoundError =>
      'Pelanggan yang dipilih tidak ditemukan, coba pilih ulang.';

  @override
  String get orderCreatedSuccess => 'Pesanan berhasil dibuat!';

  @override
  String genericErrorTemplate(String error) {
    return 'Error: $error';
  }

  @override
  String get orderTypeSelfDropoffLabel => 'Antar Sendiri';

  @override
  String get orderDataSectionLabel => 'Data Pesanan';

  @override
  String get incomingLaundryLabel => 'Baju Masuk *';

  @override
  String get outgoingLaundryLabel => 'Baju Keluar *';

  @override
  String get remainingBillPayLaterNotice =>
      'Sisa tagihan bisa dilunasi nanti lewat halaman detail pesanan.';

  @override
  String get orderNotesFieldLabel => 'Catatan (Opsional)';

  @override
  String get orderNotesFieldHint => 'Tulis catatan khusus untuk pesanan ini';

  @override
  String get pickupPaymentPendingNotice =>
      'Metode & status pembayaran akan dikonfirmasi lagi setelah berat/jumlah cucian diketahui.';

  @override
  String get branchFieldLabel => 'Cabang *';

  @override
  String get selectBranchForOrderHint => 'Pilih cabang untuk pesanan ini';

  @override
  String get selectBranchRequiredError => 'Pilih cabang terlebih dahulu';

  @override
  String get customerFieldLabel => 'Pelanggan *';

  @override
  String get selectCustomerRequiredError => 'Pilih pelanggan terlebih dahulu';

  @override
  String get noCustomersForOrderHint =>
      'Belum ada pelanggan. Tambahkan pelanggan dulu sebelum membuat pesanan.';

  @override
  String get noCustomersInBranchHint =>
      'Belum ada pelanggan yang terdaftar di cabang ini. Tambahkan pelanggan baru, atau cek penempatan cabang pelanggan yang sudah ada.';

  @override
  String get orderItemsSectionLabel => 'Item Pesanan';

  @override
  String get noItemsTapServiceHint =>
      'Belum ada item. Ketuk salah satu layanan di atas untuk menambahkannya.';

  @override
  String get noActiveServicesForOrderHint =>
      'Belum ada layanan aktif. Tambahkan layanan dulu di menu Layanan sebelum membuat pesanan.';

  @override
  String get pickupScheduleLabel => 'Jadwal Jemput (Opsional)';

  @override
  String get pickupScheduleOptionalHint =>
      'Kosongkan kalau belum tau jamnya - bisa dijadwalkan belakangan di menu Antar Jemput.';

  @override
  String get itemsFilledAtPickupConfirmationHint =>
      'Item akan diisi saat konfirmasi jemput';

  @override
  String get savingLabel => 'Sedang Menyimpan...';

  @override
  String get dateFieldFallbackLabel => 'Tanggal';

  @override
  String get timeFieldFallbackLabel => 'Jam';

  @override
  String get perKgUnitSuffix => '/kg';
}
