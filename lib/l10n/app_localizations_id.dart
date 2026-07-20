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
  String get phoneLabel => 'Nomor Telepon';

  @override
  String get addressLabel => 'Alamat Lengkap';

  @override
  String get orderHistoryTitle => 'Riwayat Pesanan';

  @override
  String get viewAllOrdersComingSoon =>
      'Navigasi ke semua riwayat pesanan akan ditambahkan';

  @override
  String get noOrderHistoryLabel => 'Belum ada riwayat pesanan';

  @override
  String get orderStatusPending => 'Menunggu';

  @override
  String get orderStatusProcessing => 'Diproses';

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
  String get phoneNumberLabel => 'No. Telepon';

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
  String get cityLabel => 'Kota';

  @override
  String get provinceLabel => 'Provinsi';

  @override
  String get emailOptionalLabel => 'Email Cabang (Opsional)';

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
  String get addressHint => 'Contoh: Jl. Merdeka No. 123';

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
}
