import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get sectionAccount;

  /// No description provided for @editProfileTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Profil'**
  String get editProfileTitle;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah nama & foto profil'**
  String get editProfileSubtitle;

  /// No description provided for @changePasswordTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah Password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Perbarui kata sandi akun'**
  String get changePasswordSubtitle;

  /// No description provided for @sectionPreference.
  ///
  /// In id, this message translates to:
  /// **'Preferensi'**
  String get sectionPreference;

  /// No description provided for @notificationTitle.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get notificationTitle;

  /// No description provided for @notificationSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Atur pemberitahuan aplikasi'**
  String get notificationSubtitle;

  /// No description provided for @notificationsPanelTitle.
  ///
  /// In id, this message translates to:
  /// **'Pesanan Baru'**
  String get notificationsPanelTitle;

  /// No description provided for @pendingOrdersNotifSubtitle.
  ///
  /// In id, this message translates to:
  /// **'{count} pesanan menunggu diproses'**
  String pendingOrdersNotifSubtitle(int count);

  /// No description provided for @noNewNotifications.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada notifikasi baru'**
  String get noNewNotifications;

  /// No description provided for @noNewNotificationsSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pesanan baru yang masuk akan muncul di sini'**
  String get noNewNotificationsSubtitle;

  /// No description provided for @languageTitle.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get languageTitle;

  /// No description provided for @sectionOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get sectionOther;

  /// No description provided for @helpTitle.
  ///
  /// In id, this message translates to:
  /// **'Bantuan'**
  String get helpTitle;

  /// No description provided for @helpSubtitle.
  ///
  /// In id, this message translates to:
  /// **'FAQ & dukungan'**
  String get helpSubtitle;

  /// No description provided for @aboutTitle.
  ///
  /// In id, this message translates to:
  /// **'Tentang Aplikasi'**
  String get aboutTitle;

  /// No description provided for @logoutButton.
  ///
  /// In id, this message translates to:
  /// **'Keluar / Logout'**
  String get logoutButton;

  /// No description provided for @logoutDialogTitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar Akun?'**
  String get logoutDialogTitle;

  /// No description provided for @logoutDialogContent.
  ///
  /// In id, this message translates to:
  /// **'Kamu harus login lagi untuk mengakses akun ini.'**
  String get logoutDialogContent;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @logout.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get logout;

  /// No description provided for @roleOwner.
  ///
  /// In id, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @fullNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama Lengkap'**
  String get fullNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @nameEmptyError.
  ///
  /// In id, this message translates to:
  /// **'Nama tidak boleh kosong'**
  String get nameEmptyError;

  /// No description provided for @saveChangesButton.
  ///
  /// In id, this message translates to:
  /// **'Simpan Perubahan'**
  String get saveChangesButton;

  /// No description provided for @galleryOpenError.
  ///
  /// In id, this message translates to:
  /// **'Gagal buka galeri: {error}'**
  String galleryOpenError(String error);

  /// No description provided for @uploadTimeoutError.
  ///
  /// In id, this message translates to:
  /// **'Upload timeout, cek koneksi kamu'**
  String get uploadTimeoutError;

  /// No description provided for @uploadFailedError.
  ///
  /// In id, this message translates to:
  /// **'Upload gagal ({code}): {body}'**
  String uploadFailedError(String code, String body);

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In id, this message translates to:
  /// **'Profil berhasil diperbarui'**
  String get profileUpdateSuccess;

  /// No description provided for @profileUpdateError.
  ///
  /// In id, this message translates to:
  /// **'Gagal update profil: {error}'**
  String profileUpdateError(String error);

  /// No description provided for @oldPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Password Lama'**
  String get oldPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Password Baru'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Password Baru'**
  String get confirmPasswordLabel;

  /// No description provided for @oldPasswordRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Password lama wajib diisi'**
  String get oldPasswordRequiredError;

  /// No description provided for @newPasswordRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Password baru wajib diisi'**
  String get newPasswordRequiredError;

  /// No description provided for @passwordMinLengthError.
  ///
  /// In id, this message translates to:
  /// **'Minimal 6 karakter'**
  String get passwordMinLengthError;

  /// No description provided for @newPasswordSameAsOldError.
  ///
  /// In id, this message translates to:
  /// **'Password baru gak boleh sama dengan yang lama'**
  String get newPasswordSameAsOldError;

  /// No description provided for @confirmPasswordRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password wajib diisi'**
  String get confirmPasswordRequiredError;

  /// No description provided for @confirmPasswordMismatchError.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi tidak cocok dengan password baru'**
  String get confirmPasswordMismatchError;

  /// No description provided for @savePasswordButton.
  ///
  /// In id, this message translates to:
  /// **'Simpan Password Baru'**
  String get savePasswordButton;

  /// No description provided for @passwordChangeSuccess.
  ///
  /// In id, this message translates to:
  /// **'Password berhasil diubah'**
  String get passwordChangeSuccess;

  /// No description provided for @wrongOldPasswordError.
  ///
  /// In id, this message translates to:
  /// **'Password lama salah'**
  String get wrongOldPasswordError;

  /// No description provided for @weakPasswordError.
  ///
  /// In id, this message translates to:
  /// **'Password baru terlalu lemah, minimal 6 karakter'**
  String get weakPasswordError;

  /// No description provided for @requiresRecentLoginError.
  ///
  /// In id, this message translates to:
  /// **'Sesi login kamu udah lama, silakan login ulang dulu'**
  String get requiresRecentLoginError;

  /// No description provided for @tooManyRequestsError.
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak percobaan, coba lagi nanti'**
  String get tooManyRequestsError;

  /// No description provided for @passwordChangeGenericError.
  ///
  /// In id, this message translates to:
  /// **'Gagal ubah password: {error}'**
  String passwordChangeGenericError(String error);

  /// No description provided for @otherProviderNotice.
  ///
  /// In id, this message translates to:
  /// **'Akun kamu login pakai provider lain (misalnya Google), jadi gak ada password yang bisa diubah di sini.'**
  String get otherProviderNotice;

  /// No description provided for @greetingMorning.
  ///
  /// In id, this message translates to:
  /// **'Selamat Pagi'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In id, this message translates to:
  /// **'Selamat Sore'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In id, this message translates to:
  /// **'Selamat Malam'**
  String get greetingEvening;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Berikut ringkasan bisnis laundry Anda'**
  String get dashboardSubtitle;

  /// No description provided for @revenueThisMonthLabel.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan bulan ini'**
  String get revenueThisMonthLabel;

  /// No description provided for @autoSyncLabel.
  ///
  /// In id, this message translates to:
  /// **'Sinkronisasi otomatis'**
  String get autoSyncLabel;

  /// No description provided for @customersLabel.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get customersLabel;

  /// No description provided for @activeOrdersLabel.
  ///
  /// In id, this message translates to:
  /// **'Pesanan aktif'**
  String get activeOrdersLabel;

  /// No description provided for @setupBranchTitle.
  ///
  /// In id, this message translates to:
  /// **'Mulai Setup Cabang'**
  String get setupBranchTitle;

  /// No description provided for @setupBranchSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi profil & alamat cabang'**
  String get setupBranchSubtitle;

  /// No description provided for @setupEmployeeTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan Karyawan'**
  String get setupEmployeeTitle;

  /// No description provided for @setupEmployeeSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Undang staf untuk kelola pesanan'**
  String get setupEmployeeSubtitle;

  /// No description provided for @setupServiceTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan Layanan'**
  String get setupServiceTitle;

  /// No description provided for @setupServiceSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Atur jenis cuci & harga'**
  String get setupServiceSubtitle;

  /// No description provided for @completeBranchSetupTitle.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan Setup Cabang'**
  String get completeBranchSetupTitle;

  /// No description provided for @setupStepsProgress.
  ///
  /// In id, this message translates to:
  /// **'{done} dari {total} langkah selesai'**
  String setupStepsProgress(int done, int total);

  /// No description provided for @newOrderAction.
  ///
  /// In id, this message translates to:
  /// **'Pesanan\nBaru'**
  String get newOrderAction;

  /// No description provided for @newEmployeeAction.
  ///
  /// In id, this message translates to:
  /// **'Karyawan\nBaru'**
  String get newEmployeeAction;

  /// No description provided for @manageBranchAction.
  ///
  /// In id, this message translates to:
  /// **'Kelola\nCabang'**
  String get manageBranchAction;

  /// No description provided for @manageEmployeesAction.
  ///
  /// In id, this message translates to:
  /// **'Kelola\nKaryawan'**
  String get manageEmployeesAction;

  /// No description provided for @manageServicesAction.
  ///
  /// In id, this message translates to:
  /// **'Kelola\nLayanan'**
  String get manageServicesAction;

  /// No description provided for @pickupDeliveryAction.
  ///
  /// In id, this message translates to:
  /// **'Antar\nJemput'**
  String get pickupDeliveryAction;

  /// No description provided for @reportAction.
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get reportAction;

  /// No description provided for @settingsAction.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settingsAction;

  /// No description provided for @quotaLimitReached.
  ///
  /// In id, this message translates to:
  /// **'Batas kuota paket Starter untuk {label} telah tercapai! Silakan upgrade.'**
  String quotaLimitReached(String label);

  /// No description provided for @weeklyRevenueTitle.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan Mingguan'**
  String get weeklyRevenueTitle;

  /// No description provided for @sevenDaysLabel.
  ///
  /// In id, this message translates to:
  /// **'7 hari'**
  String get sevenDaysLabel;

  /// No description provided for @dayMon.
  ///
  /// In id, this message translates to:
  /// **'Sen'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In id, this message translates to:
  /// **'Sel'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In id, this message translates to:
  /// **'Rab'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In id, this message translates to:
  /// **'Kam'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In id, this message translates to:
  /// **'Jum'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In id, this message translates to:
  /// **'Sab'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In id, this message translates to:
  /// **'Min'**
  String get daySun;

  /// No description provided for @mainOrdersTitle.
  ///
  /// In id, this message translates to:
  /// **'Pesanan Utama'**
  String get mainOrdersTitle;

  /// No description provided for @viewAllLabel.
  ///
  /// In id, this message translates to:
  /// **'Lihat Semua'**
  String get viewAllLabel;

  /// No description provided for @filterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get filterAll;

  /// No description provided for @filterProcessing.
  ///
  /// In id, this message translates to:
  /// **'Diproses'**
  String get filterProcessing;

  /// No description provided for @filterReady.
  ///
  /// In id, this message translates to:
  /// **'Siap Diambil'**
  String get filterReady;

  /// No description provided for @filterCompleted.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get filterCompleted;

  /// No description provided for @noOrdersData.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada data pesanan.'**
  String get noOrdersData;

  /// No description provided for @noOrdersForStatus.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pesanan dengan status ini.'**
  String get noOrdersForStatus;

  /// No description provided for @statusCancelled.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get statusCancelled;

  /// No description provided for @statusProcessing.
  ///
  /// In id, this message translates to:
  /// **'Sedang Diproses'**
  String get statusProcessing;

  /// No description provided for @defaultCustomerName.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan Umum'**
  String get defaultCustomerName;

  /// No description provided for @orderDetailSummary.
  ///
  /// In id, this message translates to:
  /// **'{count} item · Rp {amount}'**
  String orderDetailSummary(String count, String amount);

  /// No description provided for @serviceNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama Layanan'**
  String get serviceNameLabel;

  /// No description provided for @serviceNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Cuci Kering Setrika Reguler'**
  String get serviceNameHint;

  /// No description provided for @serviceNameError.
  ///
  /// In id, this message translates to:
  /// **'Nama layanan tidak boleh kosong'**
  String get serviceNameError;

  /// No description provided for @serviceDescriptionLabel.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi (Opsional)'**
  String get serviceDescriptionLabel;

  /// No description provided for @serviceDescriptionHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Proses cuci, pengeringan mesin, dan setrika rapi.'**
  String get serviceDescriptionHint;

  /// No description provided for @pricingMethodLabel.
  ///
  /// In id, this message translates to:
  /// **'Metode Perhitungan Harga'**
  String get pricingMethodLabel;

  /// No description provided for @pricePerKgLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga per Kg (Rp)'**
  String get pricePerKgLabel;

  /// No description provided for @pricePerItemLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga per Item (Rp)'**
  String get pricePerItemLabel;

  /// No description provided for @priceHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: 10000'**
  String get priceHint;

  /// No description provided for @priceEmptyError.
  ///
  /// In id, this message translates to:
  /// **'Harga tidak boleh kosong'**
  String get priceEmptyError;

  /// No description provided for @priceInvalidError.
  ///
  /// In id, this message translates to:
  /// **'Masukkan angka yang valid'**
  String get priceInvalidError;

  /// No description provided for @durationHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: 24'**
  String get durationHint;

  /// No description provided for @createServiceAppBarTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah Layanan Baru'**
  String get createServiceAppBarTitle;

  /// No description provided for @createServiceSectionTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Layanan Laundry'**
  String get createServiceSectionTitle;

  /// No description provided for @createServiceSectionSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Masukkan informasi jenis paket jasa laundry yang kamu sediakan.'**
  String get createServiceSectionSubtitle;

  /// No description provided for @pricingTypeKgFull.
  ///
  /// In id, this message translates to:
  /// **'Per Kilogram (Kg)'**
  String get pricingTypeKgFull;

  /// No description provided for @pricingTypeItemFull.
  ///
  /// In id, this message translates to:
  /// **'Per Satuan Item'**
  String get pricingTypeItemFull;

  /// No description provided for @durationLabelFull.
  ///
  /// In id, this message translates to:
  /// **'Estimasi Waktu Pengerjaan (Dalam Jam)'**
  String get durationLabelFull;

  /// No description provided for @durationEmptyErrorFull.
  ///
  /// In id, this message translates to:
  /// **'Estimasi durasi pengerjaan tidak boleh kosong'**
  String get durationEmptyErrorFull;

  /// No description provided for @durationInvalidErrorFull.
  ///
  /// In id, this message translates to:
  /// **'Masukkan angka bulat jam yang valid'**
  String get durationInvalidErrorFull;

  /// No description provided for @saveServiceButton.
  ///
  /// In id, this message translates to:
  /// **'Simpan Layanan'**
  String get saveServiceButton;

  /// No description provided for @sessionNotFoundError.
  ///
  /// In id, this message translates to:
  /// **'Sesi pengguna tidak ditemukan. Silakan login kembali.'**
  String get sessionNotFoundError;

  /// No description provided for @companyNotSetupError.
  ///
  /// In id, this message translates to:
  /// **'Perusahaan belum dibuat. Selesaikan proses onboarding (setup perusahaan) terlebih dahulu.'**
  String get companyNotSetupError;

  /// No description provided for @addServiceSuccess.
  ///
  /// In id, this message translates to:
  /// **'Layanan berhasil ditambahkan!'**
  String get addServiceSuccess;

  /// No description provided for @addServiceError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menambahkan layanan: {error}'**
  String addServiceError(String error);

  /// No description provided for @servicesListAppBarTitle.
  ///
  /// In id, this message translates to:
  /// **'Daftar Layanan'**
  String get servicesListAppBarTitle;

  /// No description provided for @servicesListSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Kelola jenis cuci, harga, dan estimasi durasi'**
  String get servicesListSubtitle;

  /// No description provided for @newServiceFab.
  ///
  /// In id, this message translates to:
  /// **'Layanan Baru'**
  String get newServiceFab;

  /// No description provided for @emptyServicesTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada layanan terdaftar'**
  String get emptyServicesTitle;

  /// No description provided for @emptyServicesSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Tekan tombol \"Layanan Baru\" untuk\nmenambahkan jenis cuci pertama Anda'**
  String get emptyServicesSubtitle;

  /// No description provided for @errorStateTitle.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan'**
  String get errorStateTitle;

  /// No description provided for @editServiceMenuItem.
  ///
  /// In id, this message translates to:
  /// **'Edit Layanan'**
  String get editServiceMenuItem;

  /// No description provided for @deactivateMenuItem.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan'**
  String get deactivateMenuItem;

  /// No description provided for @activateMenuItem.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan'**
  String get activateMenuItem;

  /// No description provided for @deleteMenuItem.
  ///
  /// In id, this message translates to:
  /// **'Hapus Permanen'**
  String get deleteMenuItem;

  /// No description provided for @serviceActivatedSnackbar.
  ///
  /// In id, this message translates to:
  /// **'Layanan \"{name}\" diaktifkan kembali'**
  String serviceActivatedSnackbar(String name);

  /// No description provided for @serviceDeactivatedSnackbar.
  ///
  /// In id, this message translates to:
  /// **'Layanan \"{name}\" dinonaktifkan'**
  String serviceDeactivatedSnackbar(String name);

  /// No description provided for @toggleStatusError.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengubah status: {error}'**
  String toggleStatusError(String error);

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus Permanen?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmContent.
  ///
  /// In id, this message translates to:
  /// **'Layanan \"{name}\" akan dihapus permanen dari database dan TIDAK BISA dikembalikan.\n\nJika layanan ini masih atau pernah dipakai di pesanan, sebaiknya gunakan opsi \"Nonaktifkan\" saja agar riwayat pesanan lama tetap tampil normal.'**
  String deleteConfirmContent(String name);

  /// No description provided for @deletePermanentButton.
  ///
  /// In id, this message translates to:
  /// **'Hapus Permanen'**
  String get deletePermanentButton;

  /// No description provided for @deleteServiceSuccess.
  ///
  /// In id, this message translates to:
  /// **'Layanan \"{name}\" berhasil dihapus permanen'**
  String deleteServiceSuccess(String name);

  /// No description provided for @deleteServiceError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus layanan: {error}'**
  String deleteServiceError(String error);

  /// No description provided for @durationInHours.
  ///
  /// In id, this message translates to:
  /// **'{hours} Jam'**
  String durationInHours(int hours);

  /// No description provided for @activeStatusChip.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get activeStatusChip;

  /// No description provided for @inactiveStatusChip.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get inactiveStatusChip;

  /// No description provided for @pricePerKgValue.
  ///
  /// In id, this message translates to:
  /// **'Rp {price} / Kg'**
  String pricePerKgValue(String price);

  /// No description provided for @pricePerItemValue.
  ///
  /// In id, this message translates to:
  /// **'Rp {price} / Item'**
  String pricePerItemValue(String price);

  /// No description provided for @editServiceSheetTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Layanan'**
  String get editServiceSheetTitle;

  /// No description provided for @editServiceSheetSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Perbarui detail jenis layanan laundry ini'**
  String get editServiceSheetSubtitle;

  /// No description provided for @pricingTypeKgShort.
  ///
  /// In id, this message translates to:
  /// **'Per Kg'**
  String get pricingTypeKgShort;

  /// No description provided for @pricingTypeItemShort.
  ///
  /// In id, this message translates to:
  /// **'Per Item'**
  String get pricingTypeItemShort;

  /// No description provided for @durationLabelShort.
  ///
  /// In id, this message translates to:
  /// **'Estimasi Waktu Pengerjaan (Jam)'**
  String get durationLabelShort;

  /// No description provided for @durationEmptyErrorShort.
  ///
  /// In id, this message translates to:
  /// **'Estimasi durasi tidak boleh kosong'**
  String get durationEmptyErrorShort;

  /// No description provided for @durationInvalidErrorShort.
  ///
  /// In id, this message translates to:
  /// **'Masukkan angka bulat yang valid'**
  String get durationInvalidErrorShort;

  /// No description provided for @activeServiceSwitchTitle.
  ///
  /// In id, this message translates to:
  /// **'Layanan Aktif'**
  String get activeServiceSwitchTitle;

  /// No description provided for @activeServiceSwitchSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan jika layanan sedang tidak ditawarkan'**
  String get activeServiceSwitchSubtitle;

  /// No description provided for @savingButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Menyimpan...'**
  String get savingButtonLabel;

  /// No description provided for @saveChangesSuccess.
  ///
  /// In id, this message translates to:
  /// **'Perubahan berhasil disimpan'**
  String get saveChangesSuccess;

  /// No description provided for @saveChangesError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan perubahan: {error}'**
  String saveChangesError(String error);

  /// No description provided for @customersTitle.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get customersTitle;

  /// No description provided for @customersSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Kelola data pelanggan laundry Anda'**
  String get customersSubtitle;

  /// No description provided for @newCustomerButton.
  ///
  /// In id, this message translates to:
  /// **'Baru'**
  String get newCustomerButton;

  /// No description provided for @searchCustomerHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau nomor telepon...'**
  String get searchCustomerHint;

  /// No description provided for @customerActiveLabel.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get customerActiveLabel;

  /// No description provided for @customerInactiveLabel.
  ///
  /// In id, this message translates to:
  /// **'Tidak Aktif'**
  String get customerInactiveLabel;

  /// No description provided for @totalCustomersLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Pelanggan'**
  String get totalCustomersLabel;

  /// No description provided for @totalTransactionsLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Transaksi'**
  String get totalTransactionsLabel;

  /// No description provided for @emptyCustomersTitle.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pelanggan'**
  String get emptyCustomersTitle;

  /// No description provided for @emptyCustomersSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan pelanggan baru untuk memulai'**
  String get emptyCustomersSubtitle;

  /// No description provided for @addCustomerButton.
  ///
  /// In id, this message translates to:
  /// **'Tambah Pelanggan'**
  String get addCustomerButton;

  /// No description provided for @ordersCountLabel.
  ///
  /// In id, this message translates to:
  /// **'{count} pesanan'**
  String ordersCountLabel(int count);

  /// No description provided for @neverOrderedLabel.
  ///
  /// In id, this message translates to:
  /// **'Belum pernah order'**
  String get neverOrderedLabel;

  /// No description provided for @justNowLabel.
  ///
  /// In id, this message translates to:
  /// **'Baru saja'**
  String get justNowLabel;

  /// No description provided for @hoursAgoLabel.
  ///
  /// In id, this message translates to:
  /// **'{hours} jam lalu'**
  String hoursAgoLabel(int hours);

  /// No description provided for @daysAgoLabel.
  ///
  /// In id, this message translates to:
  /// **'{days} hari lalu'**
  String daysAgoLabel(int days);

  /// No description provided for @editCustomerComingSoon.
  ///
  /// In id, this message translates to:
  /// **'Navigasi ke Edit Pelanggan akan ditambahkan'**
  String get editCustomerComingSoon;

  /// No description provided for @editCustomerMenuItem.
  ///
  /// In id, this message translates to:
  /// **'Edit Pelanggan'**
  String get editCustomerMenuItem;

  /// No description provided for @deleteCustomerMenuItem.
  ///
  /// In id, this message translates to:
  /// **'Hapus Pelanggan'**
  String get deleteCustomerMenuItem;

  /// No description provided for @deleteCustomerConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus Pelanggan?'**
  String get deleteCustomerConfirmTitle;

  /// No description provided for @deleteCustomerConfirmContent.
  ///
  /// In id, this message translates to:
  /// **'Data pelanggan \"{name}\" akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.'**
  String deleteCustomerConfirmContent(String name);

  /// No description provided for @deleteButton.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get deleteButton;

  /// No description provided for @deleteCustomerSuccessTesting.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan berhasil dihapus (Testing mode)'**
  String get deleteCustomerSuccessTesting;

  /// No description provided for @customerDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Pelanggan'**
  String get customerDetailTitle;

  /// No description provided for @joinedSinceLabel.
  ///
  /// In id, this message translates to:
  /// **'Bergabung sejak {date}'**
  String joinedSinceLabel(String date);

  /// No description provided for @activeCustomerLabel.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan Aktif'**
  String get activeCustomerLabel;

  /// No description provided for @callButton.
  ///
  /// In id, this message translates to:
  /// **'Telepon'**
  String get callButton;

  /// No description provided for @openingPhoneApp.
  ///
  /// In id, this message translates to:
  /// **'Membuka aplikasi telepon...'**
  String get openingPhoneApp;

  /// No description provided for @whatsappButton.
  ///
  /// In id, this message translates to:
  /// **'WhatsApp'**
  String get whatsappButton;

  /// No description provided for @openingWhatsapp.
  ///
  /// In id, this message translates to:
  /// **'Membuka WhatsApp...'**
  String get openingWhatsapp;

  /// No description provided for @totalOrdersLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Pesanan'**
  String get totalOrdersLabel;

  /// No description provided for @totalSpentLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Belanja'**
  String get totalSpentLabel;

  /// No description provided for @contactInfoTitle.
  ///
  /// In id, this message translates to:
  /// **'Informasi Kontak'**
  String get contactInfoTitle;

  /// No description provided for @phoneLabel.
  ///
  /// In id, this message translates to:
  /// **'Nomor Telepon'**
  String get phoneLabel;

  /// No description provided for @addressLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat Lengkap'**
  String get addressLabel;

  /// No description provided for @orderHistoryTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Pesanan'**
  String get orderHistoryTitle;

  /// No description provided for @viewAllOrdersComingSoon.
  ///
  /// In id, this message translates to:
  /// **'Navigasi ke semua riwayat pesanan akan ditambahkan'**
  String get viewAllOrdersComingSoon;

  /// No description provided for @noOrderHistoryLabel.
  ///
  /// In id, this message translates to:
  /// **'Belum ada riwayat pesanan'**
  String get noOrderHistoryLabel;

  /// No description provided for @orderStatusPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get orderStatusPending;

  /// No description provided for @orderStatusProcessing.
  ///
  /// In id, this message translates to:
  /// **'Diproses'**
  String get orderStatusProcessing;

  /// No description provided for @orderStatusCompleted.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get orderStatusCompleted;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In id, this message translates to:
  /// **'Dibatalkan'**
  String get orderStatusCancelled;

  /// No description provided for @orderItemCountLabel.
  ///
  /// In id, this message translates to:
  /// **'· {count} item'**
  String orderItemCountLabel(int count);

  /// No description provided for @newCustomerHeaderTitle.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan Baru'**
  String get newCustomerHeaderTitle;

  /// No description provided for @newCustomerHeaderSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi data pelanggan untuk menambahkannya ke sistem'**
  String get newCustomerHeaderSubtitle;

  /// No description provided for @customerNameHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan nama pelanggan'**
  String get customerNameHint;

  /// No description provided for @customerNameEmptyError.
  ///
  /// In id, this message translates to:
  /// **'Nama pelanggan tidak boleh kosong'**
  String get customerNameEmptyError;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In id, this message translates to:
  /// **'No. Telepon'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: 081234567890'**
  String get phoneNumberHint;

  /// No description provided for @phoneNumberEmptyError.
  ///
  /// In id, this message translates to:
  /// **'No. telepon tidak boleh kosong'**
  String get phoneNumberEmptyError;

  /// No description provided for @phoneNumberInvalidError.
  ///
  /// In id, this message translates to:
  /// **'Format no. telepon tidak valid'**
  String get phoneNumberInvalidError;

  /// No description provided for @optionalFieldSuffix.
  ///
  /// In id, this message translates to:
  /// **' (Opsional)'**
  String get optionalFieldSuffix;

  /// No description provided for @customerEmailHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan email pelanggan'**
  String get customerEmailHint;

  /// No description provided for @emailInvalidError.
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid'**
  String get emailInvalidError;

  /// No description provided for @customerAddressHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan alamat pelanggan'**
  String get customerAddressHint;

  /// No description provided for @notesLabel.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get notesLabel;

  /// No description provided for @notesHint.
  ///
  /// In id, this message translates to:
  /// **'Catatan khusus untuk pelanggan ini'**
  String get notesHint;

  /// No description provided for @saveCustomerButton.
  ///
  /// In id, this message translates to:
  /// **'Simpan Pelanggan'**
  String get saveCustomerButton;

  /// No description provided for @addCustomerSuccessTesting.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan berhasil ditambahkan!'**
  String get addCustomerSuccessTesting;

  /// No description provided for @errorWithMessage.
  ///
  /// In id, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(String error);

  /// No description provided for @addCustomerError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menambahkan pelanggan: {error}'**
  String addCustomerError(String error);

  /// No description provided for @loadCustomersError.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data pelanggan: {error}'**
  String loadCustomersError(Object error);

  /// No description provided for @laundriesTitle.
  ///
  /// In id, this message translates to:
  /// **'Cabang'**
  String get laundriesTitle;

  /// No description provided for @laundriesSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Kelola cabang laundry Anda'**
  String get laundriesSubtitle;

  /// No description provided for @searchLaundryHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama, kode, atau kota cabang...'**
  String get searchLaundryHint;

  /// No description provided for @filterAllLaundries.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get filterAllLaundries;

  /// No description provided for @filterActiveLaundries.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get filterActiveLaundries;

  /// No description provided for @filterInactiveLaundries.
  ///
  /// In id, this message translates to:
  /// **'Tidak Aktif'**
  String get filterInactiveLaundries;

  /// No description provided for @totalLaundriesLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Cabang'**
  String get totalLaundriesLabel;

  /// No description provided for @activeLaundriesLabel.
  ///
  /// In id, this message translates to:
  /// **'Cabang Aktif'**
  String get activeLaundriesLabel;

  /// No description provided for @emptyLaundriesTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada cabang'**
  String get emptyLaundriesTitle;

  /// No description provided for @emptyLaundriesSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan cabang baru untuk memulai'**
  String get emptyLaundriesSubtitle;

  /// No description provided for @newBranchButton.
  ///
  /// In id, this message translates to:
  /// **'Cabang Baru'**
  String get newBranchButton;

  /// No description provided for @addBranchButton.
  ///
  /// In id, this message translates to:
  /// **'Tambah Cabang'**
  String get addBranchButton;

  /// No description provided for @loadLaundriesError.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data cabang'**
  String get loadLaundriesError;

  /// No description provided for @addBranchTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah Cabang Baru'**
  String get addBranchTitle;

  /// No description provided for @editBranchTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Data Cabang'**
  String get editBranchTitle;

  /// No description provided for @addBranchInfo.
  ///
  /// In id, this message translates to:
  /// **'Sistem akan memvalidasi limitasi kuota cabang sesuai paket langganan Anda secara otomatis sebelum menyimpan data.'**
  String get addBranchInfo;

  /// No description provided for @editBranchInfo.
  ///
  /// In id, this message translates to:
  /// **'Perubahan akan langsung tersimpan ke data cabang ini. Kuota paket langganan tidak berlaku untuk pengeditan.'**
  String get editBranchInfo;

  /// No description provided for @ownerCompanyLabel.
  ///
  /// In id, this message translates to:
  /// **'Perusahaan Pemilik Cabang'**
  String get ownerCompanyLabel;

  /// No description provided for @registerCompanyFirst.
  ///
  /// In id, this message translates to:
  /// **'+ Daftarkan Perusahaan Terlebih Dahulu'**
  String get registerCompanyFirst;

  /// No description provided for @branchNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama Cabang'**
  String get branchNameLabel;

  /// No description provided for @branchCodeLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode Cabang'**
  String get branchCodeLabel;

  /// No description provided for @cityLabel.
  ///
  /// In id, this message translates to:
  /// **'Kota'**
  String get cityLabel;

  /// No description provided for @provinceLabel.
  ///
  /// In id, this message translates to:
  /// **'Provinsi'**
  String get provinceLabel;

  /// No description provided for @emailOptionalLabel.
  ///
  /// In id, this message translates to:
  /// **'Email Cabang (Opsional)'**
  String get emailOptionalLabel;

  /// No description provided for @managerOptionalLabel.
  ///
  /// In id, this message translates to:
  /// **'Manajer Cabang (Opsional)'**
  String get managerOptionalLabel;

  /// No description provided for @noEmployeeDataInfo.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data karyawan. Manajer bisa ditugaskan belakangan.'**
  String get noEmployeeDataInfo;

  /// No description provided for @dailyCapacityLabel.
  ///
  /// In id, this message translates to:
  /// **'Kapasitas Harian (Jumlah Order)'**
  String get dailyCapacityLabel;

  /// No description provided for @mapLocationLabel.
  ///
  /// In id, this message translates to:
  /// **'Titik Lokasi Peta (Opsional)'**
  String get mapLocationLabel;

  /// No description provided for @operatingHoursLabel.
  ///
  /// In id, this message translates to:
  /// **'Jam Operasional'**
  String get operatingHoursLabel;

  /// No description provided for @useSameHoursLabel.
  ///
  /// In id, this message translates to:
  /// **'Gunakan jam yang sama untuk semua hari'**
  String get useSameHoursLabel;

  /// No description provided for @everyDayLabel.
  ///
  /// In id, this message translates to:
  /// **'Setiap Hari'**
  String get everyDayLabel;

  /// No description provided for @activeStatusLabel.
  ///
  /// In id, this message translates to:
  /// **'Status Cabang Aktif'**
  String get activeStatusLabel;

  /// No description provided for @saveBranchButton.
  ///
  /// In id, this message translates to:
  /// **'Simpan Data Cabang'**
  String get saveBranchButton;

  /// No description provided for @updateBranchButton.
  ///
  /// In id, this message translates to:
  /// **'Simpan Perubahan'**
  String get updateBranchButton;

  /// No description provided for @branchNameEmpty.
  ///
  /// In id, this message translates to:
  /// **'Nama cabang tidak boleh kosong'**
  String get branchNameEmpty;

  /// No description provided for @branchCodeEmpty.
  ///
  /// In id, this message translates to:
  /// **'Kode cabang tidak boleh kosong'**
  String get branchCodeEmpty;

  /// No description provided for @addressEmpty.
  ///
  /// In id, this message translates to:
  /// **'Alamat wajib diisi'**
  String get addressEmpty;

  /// No description provided for @fieldRequired.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi'**
  String get fieldRequired;

  /// No description provided for @phoneEmpty.
  ///
  /// In id, this message translates to:
  /// **'Nomor telepon wajib diisi'**
  String get phoneEmpty;

  /// No description provided for @capacityEmpty.
  ///
  /// In id, this message translates to:
  /// **'Kapasitas wajib diisi'**
  String get capacityEmpty;

  /// No description provided for @quotaReachedTitle.
  ///
  /// In id, this message translates to:
  /// **'Batas Kuota Tercapai'**
  String get quotaReachedTitle;

  /// No description provided for @quotaReachedContent.
  ///
  /// In id, this message translates to:
  /// **'Jumlah cabang Anda telah mencapai batas maksimal paket langganan saat ini.'**
  String get quotaReachedContent;

  /// No description provided for @upgradePlanButton.
  ///
  /// In id, this message translates to:
  /// **'Upgrade Paket'**
  String get upgradePlanButton;

  /// No description provided for @branchAddSuccess.
  ///
  /// In id, this message translates to:
  /// **'Cabang laundry berhasil ditambahkan!'**
  String get branchAddSuccess;

  /// No description provided for @branchUpdateSuccess.
  ///
  /// In id, this message translates to:
  /// **'Perubahan cabang berhasil disimpan!'**
  String get branchUpdateSuccess;

  /// No description provided for @deleteBranchTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus Cabang?'**
  String get deleteBranchTitle;

  /// No description provided for @deleteBranchConfirm.
  ///
  /// In id, this message translates to:
  /// **'Cabang \"{name}\" akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.'**
  String deleteBranchConfirm(Object name);

  /// No description provided for @contactInfoSection.
  ///
  /// In id, this message translates to:
  /// **'Informasi Kontak'**
  String get contactInfoSection;

  /// No description provided for @capacityLocationSection.
  ///
  /// In id, this message translates to:
  /// **'Kapasitas & Lokasi'**
  String get capacityLocationSection;

  /// No description provided for @createdLabel.
  ///
  /// In id, this message translates to:
  /// **'Dibuat'**
  String get createdLabel;

  /// No description provided for @updatedLabel.
  ///
  /// In id, this message translates to:
  /// **'Diperbarui'**
  String get updatedLabel;

  /// No description provided for @todayLabel.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get todayLabel;

  /// No description provided for @monday.
  ///
  /// In id, this message translates to:
  /// **'Senin'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In id, this message translates to:
  /// **'Selasa'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In id, this message translates to:
  /// **'Rabu'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In id, this message translates to:
  /// **'Kamis'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In id, this message translates to:
  /// **'Jumat'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In id, this message translates to:
  /// **'Sabtu'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In id, this message translates to:
  /// **'Minggu'**
  String get sunday;

  /// No description provided for @cardCapacityLabel.
  ///
  /// In id, this message translates to:
  /// **'Kapasitas {capacity}'**
  String cardCapacityLabel(Object capacity);

  /// No description provided for @selectCompanyHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih perusahaan'**
  String get selectCompanyHint;

  /// No description provided for @branchNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Cabang Merdeka'**
  String get branchNameHint;

  /// No description provided for @branchCodeHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: JKT001'**
  String get branchCodeHint;

  /// No description provided for @addressHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Jl. Merdeka No. 123'**
  String get addressHint;

  /// No description provided for @cityHint.
  ///
  /// In id, this message translates to:
  /// **'Jakarta'**
  String get cityHint;

  /// No description provided for @provinceHint.
  ///
  /// In id, this message translates to:
  /// **'DKI Jakarta'**
  String get provinceHint;

  /// No description provided for @branchPhoneLabel.
  ///
  /// In id, this message translates to:
  /// **'Nomor Telepon Cabang'**
  String get branchPhoneLabel;

  /// No description provided for @branchPhoneHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: +6281234567890'**
  String get branchPhoneHint;

  /// No description provided for @branchEmailHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: cabang@laundry.com'**
  String get branchEmailHint;

  /// No description provided for @selectManagerHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih manajer cabang'**
  String get selectManagerHint;

  /// No description provided for @capacityHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: 100'**
  String get capacityHint;

  /// No description provided for @latitudeHint.
  ///
  /// In id, this message translates to:
  /// **'Latitude'**
  String get latitudeHint;

  /// No description provided for @longitudeHint.
  ///
  /// In id, this message translates to:
  /// **'Longitude'**
  String get longitudeHint;

  /// No description provided for @companyRequiredValidator.
  ///
  /// In id, this message translates to:
  /// **'Perusahaan wajib dipilih'**
  String get companyRequiredValidator;

  /// No description provided for @defaultCompanyName.
  ///
  /// In id, this message translates to:
  /// **'Perusahaan Tanpa Nama'**
  String get defaultCompanyName;

  /// No description provided for @defaultEmployeeName.
  ///
  /// In id, this message translates to:
  /// **'Karyawan'**
  String get defaultEmployeeName;

  /// No description provided for @branchDataNotFoundError.
  ///
  /// In id, this message translates to:
  /// **'Data cabang tidak ditemukan.'**
  String get branchDataNotFoundError;

  /// No description provided for @loadBranchDataError.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data cabang: {error}'**
  String loadBranchDataError(String error);

  /// No description provided for @companyNotSelectedWarning.
  ///
  /// In id, this message translates to:
  /// **'Perusahaan belum dipilih atau belum dibuat!'**
  String get companyNotSelectedWarning;

  /// No description provided for @userSessionExpiredError.
  ///
  /// In id, this message translates to:
  /// **'Sesi user berakhir.'**
  String get userSessionExpiredError;

  /// No description provided for @saveBranchError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan data cabang: {error}'**
  String saveBranchError(String error);

  /// No description provided for @branchDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Cabang'**
  String get branchDetailTitle;

  /// No description provided for @deleteBranchConfirmDetail.
  ///
  /// In id, this message translates to:
  /// **'Cabang \"{name}\" ({code}) akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.'**
  String deleteBranchConfirmDetail(String name, String code);

  /// No description provided for @branchDeleteSuccess.
  ///
  /// In id, this message translates to:
  /// **'Cabang \"{name}\" berhasil dihapus.'**
  String branchDeleteSuccess(String name);

  /// No description provided for @deleteBranchError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus cabang: {error}'**
  String deleteBranchError(String error);

  /// No description provided for @addressShortLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat'**
  String get addressShortLabel;

  /// No description provided for @phoneShortLabel.
  ///
  /// In id, this message translates to:
  /// **'Telepon'**
  String get phoneShortLabel;

  /// No description provided for @capacityShortLabel.
  ///
  /// In id, this message translates to:
  /// **'Kapasitas'**
  String get capacityShortLabel;

  /// No description provided for @coordinatesLabel.
  ///
  /// In id, this message translates to:
  /// **'Koordinat'**
  String get coordinatesLabel;

  /// No description provided for @notSetLabel.
  ///
  /// In id, this message translates to:
  /// **'Belum diatur'**
  String get notSetLabel;

  /// No description provided for @branchNotFoundTitle.
  ///
  /// In id, this message translates to:
  /// **'Cabang tidak ditemukan'**
  String get branchNotFoundTitle;

  /// No description provided for @branchNotFoundSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Cabang mungkin sudah dihapus atau id tidak valid'**
  String get branchNotFoundSubtitle;

  /// No description provided for @monthJan.
  ///
  /// In id, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In id, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In id, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In id, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In id, this message translates to:
  /// **'Mei'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In id, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In id, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In id, this message translates to:
  /// **'Agu'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In id, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In id, this message translates to:
  /// **'Okt'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In id, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In id, this message translates to:
  /// **'Des'**
  String get monthDec;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
