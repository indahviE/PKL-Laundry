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

  /// No description provided for @notifPrefOrderStatusTitle.
  ///
  /// In id, this message translates to:
  /// **'Status pesanan'**
  String get notifPrefOrderStatusTitle;

  /// No description provided for @notifPrefOrderStatusSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Update cuci, siap diambil, dll'**
  String get notifPrefOrderStatusSubtitle;

  /// No description provided for @notifPrefPromoTitle.
  ///
  /// In id, this message translates to:
  /// **'Promo dan diskon'**
  String get notifPrefPromoTitle;

  /// No description provided for @notifPrefPromoSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Penawaran spesial untukmu'**
  String get notifPrefPromoSubtitle;

  /// No description provided for @notifPrefReminderTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengingat'**
  String get notifPrefReminderTitle;

  /// No description provided for @notifPrefReminderSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Jadwal ambil dan antar cucian'**
  String get notifPrefReminderSubtitle;

  /// No description provided for @notifPrefChatCsTitle.
  ///
  /// In id, this message translates to:
  /// **'Chat dan CS'**
  String get notifPrefChatCsTitle;

  /// No description provided for @notifPrefChatCsSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Balasan dari customer service'**
  String get notifPrefChatCsSubtitle;

  /// No description provided for @notifPrefSaveError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan preferensi: {error}'**
  String notifPrefSaveError(String error);

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

  /// No description provided for @sectionCsTeam.
  ///
  /// In id, this message translates to:
  /// **'Tim CS'**
  String get sectionCsTeam;

  /// No description provided for @manageCsChatTitle.
  ///
  /// In id, this message translates to:
  /// **'Kelola Chat CS'**
  String get manageCsChatTitle;

  /// No description provided for @manageCsChatSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Balas percakapan dari semua user'**
  String get manageCsChatSubtitle;

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

  /// No description provided for @helpSectionGeneralTitle.
  ///
  /// In id, this message translates to:
  /// **'Pertanyaan Umum'**
  String get helpSectionGeneralTitle;

  /// No description provided for @helpSectionAppGuideTitle.
  ///
  /// In id, this message translates to:
  /// **'Panduan Aplikasi'**
  String get helpSectionAppGuideTitle;

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

  /// No description provided for @activeBranchLabel.
  ///
  /// In id, this message translates to:
  /// **'CABANG AKTIF'**
  String get activeBranchLabel;

  /// No description provided for @allBranchesLabel.
  ///
  /// In id, this message translates to:
  /// **'Semua Cabang'**
  String get allBranchesLabel;

  /// No description provided for @selectBranchTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Cabang'**
  String get selectBranchTitle;

  /// No description provided for @searchBranchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama cabang...'**
  String get searchBranchHint;

  /// No description provided for @noBranchesRegistered.
  ///
  /// In id, this message translates to:
  /// **'Belum ada cabang terdaftar'**
  String get noBranchesRegistered;

  /// No description provided for @branchNotFoundSearch.
  ///
  /// In id, this message translates to:
  /// **'Cabang tidak ditemukan'**
  String get branchNotFoundSearch;

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

  /// No description provided for @reportsTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get reportsTitle;

  /// No description provided for @reportsSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pantau performa bisnis laundry Anda'**
  String get reportsSubtitle;

  /// No description provided for @periodToday.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get periodToday;

  /// No description provided for @periodThisWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu Ini'**
  String get periodThisWeek;

  /// No description provided for @weekNumberLabel.
  ///
  /// In id, this message translates to:
  /// **'Minggu {index}'**
  String weekNumberLabel(int index);

  /// No description provided for @weekNumberRangeLabel.
  ///
  /// In id, this message translates to:
  /// **'Minggu {index} ({start} - {end})'**
  String weekNumberRangeLabel(int index, String start, String end);

  /// No description provided for @periodThisMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan Ini'**
  String get periodThisMonth;

  /// No description provided for @periodThisYear.
  ///
  /// In id, this message translates to:
  /// **'Tahun Ini'**
  String get periodThisYear;

  /// No description provided for @printButtonShort.
  ///
  /// In id, this message translates to:
  /// **'Cetak'**
  String get printButtonShort;

  /// No description provided for @printReportButton.
  ///
  /// In id, this message translates to:
  /// **'Cetak Laporan'**
  String get printReportButton;

  /// No description provided for @generatingPdfButton.
  ///
  /// In id, this message translates to:
  /// **'Membuat PDF...'**
  String get generatingPdfButton;

  /// No description provided for @growthThisPeriodLabel.
  ///
  /// In id, this message translates to:
  /// **'Pertumbuhan Periode Ini'**
  String get growthThisPeriodLabel;

  /// No description provided for @growthUpLabel.
  ///
  /// In id, this message translates to:
  /// **'Naik'**
  String get growthUpLabel;

  /// No description provided for @growthDownLabel.
  ///
  /// In id, this message translates to:
  /// **'Turun'**
  String get growthDownLabel;

  /// No description provided for @fromPreviousPeriodLabel.
  ///
  /// In id, this message translates to:
  /// **'dari periode sebelumnya'**
  String get fromPreviousPeriodLabel;

  /// No description provided for @revenueTrendTitle.
  ///
  /// In id, this message translates to:
  /// **'Tren Pendapatan'**
  String get revenueTrendTitle;

  /// No description provided for @last7DaysLabel.
  ///
  /// In id, this message translates to:
  /// **'7 hari terakhir'**
  String get last7DaysLabel;

  /// No description provided for @revenuePerServiceTitle.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan per Layanan'**
  String get revenuePerServiceTitle;

  /// No description provided for @noOrdersThisPeriod.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data pesanan pada periode ini.'**
  String get noOrdersThisPeriod;

  /// No description provided for @completionRateLabel.
  ///
  /// In id, this message translates to:
  /// **'Tingkat Penyelesaian'**
  String get completionRateLabel;

  /// No description provided for @ofAllOrdersLabel.
  ///
  /// In id, this message translates to:
  /// **'dari seluruh pesanan'**
  String get ofAllOrdersLabel;

  /// No description provided for @exportPdfError.
  ///
  /// In id, this message translates to:
  /// **'Gagal membuat PDF: {error}'**
  String exportPdfError(String error);

  /// No description provided for @pdfReportTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan Bisnis Laundry'**
  String get pdfReportTitle;

  /// No description provided for @pdfHeaderInfo.
  ///
  /// In id, this message translates to:
  /// **'Periode: {period}   |   Cabang: {branch}   |   Dibuat: {date}'**
  String pdfHeaderInfo(String period, String branch, String date);

  /// No description provided for @pdfSummaryTitle.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan'**
  String get pdfSummaryTitle;

  /// No description provided for @totalRevenueLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Pendapatan'**
  String get totalRevenueLabel;

  /// No description provided for @newCustomersLabel.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan Baru'**
  String get newCustomersLabel;

  /// No description provided for @avgOrderLabel.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata Order'**
  String get avgOrderLabel;

  /// No description provided for @growthLabel.
  ///
  /// In id, this message translates to:
  /// **'Pertumbuhan'**
  String get growthLabel;

  /// No description provided for @growthValueTemplate.
  ///
  /// In id, this message translates to:
  /// **'+{rate}% dari periode sebelumnya'**
  String growthValueTemplate(String rate);

  /// No description provided for @pdfWeeklyTrendTitle.
  ///
  /// In id, this message translates to:
  /// **'Tren Pendapatan (7 hari terakhir)'**
  String get pdfWeeklyTrendTitle;

  /// No description provided for @pdfServiceColumn.
  ///
  /// In id, this message translates to:
  /// **'Layanan'**
  String get pdfServiceColumn;

  /// No description provided for @pdfOrdersColumn.
  ///
  /// In id, this message translates to:
  /// **'Pesanan'**
  String get pdfOrdersColumn;

  /// No description provided for @pdfRevenueColumn.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan'**
  String get pdfRevenueColumn;

  /// No description provided for @pdfPercentageColumn.
  ///
  /// In id, this message translates to:
  /// **'Persentase'**
  String get pdfPercentageColumn;

  /// No description provided for @pdfPageOfPages.
  ///
  /// In id, this message translates to:
  /// **'Halaman {page} dari {total}'**
  String pdfPageOfPages(int page, int total);

  /// No description provided for @unnamedBranchLabel.
  ///
  /// In id, this message translates to:
  /// **'Cabang Tanpa Nama'**
  String get unnamedBranchLabel;

  /// No description provided for @otherServiceLabel.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get otherServiceLabel;

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

  /// No description provided for @serviceTypeSectionLabel.
  ///
  /// In id, this message translates to:
  /// **'Tipe Layanan'**
  String get serviceTypeSectionLabel;

  /// No description provided for @pricingTypeKgChipLabel.
  ///
  /// In id, this message translates to:
  /// **'Kiloan'**
  String get pricingTypeKgChipLabel;

  /// No description provided for @pricingTypeItemChipLabel.
  ///
  /// In id, this message translates to:
  /// **'Satuan'**
  String get pricingTypeItemChipLabel;

  /// No description provided for @pricingTypeExpressLabel.
  ///
  /// In id, this message translates to:
  /// **'Express'**
  String get pricingTypeExpressLabel;

  /// No description provided for @pricePerKgFieldLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga per Kg'**
  String get pricePerKgFieldLabel;

  /// No description provided for @pricePerItemFieldLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga per Item'**
  String get pricePerItemFieldLabel;

  /// No description provided for @baseFeeLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga Dasar'**
  String get baseFeeLabel;

  /// No description provided for @expressFeeLabel.
  ///
  /// In id, this message translates to:
  /// **'Biaya Tambahan Express'**
  String get expressFeeLabel;

  /// No description provided for @minWeightLabel.
  ///
  /// In id, this message translates to:
  /// **'Berat Minimum (Kg)'**
  String get minWeightLabel;

  /// No description provided for @estimatedDurationSectionLabel.
  ///
  /// In id, this message translates to:
  /// **'Estimasi Durasi'**
  String get estimatedDurationSectionLabel;

  /// No description provided for @durationUnitHours.
  ///
  /// In id, this message translates to:
  /// **'Jam'**
  String get durationUnitHours;

  /// No description provided for @durationUnitDays.
  ///
  /// In id, this message translates to:
  /// **'Hari'**
  String get durationUnitDays;

  /// No description provided for @durationChipHoursLabel.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} Jam}}'**
  String durationChipHoursLabel(int count);

  /// No description provided for @durationChipDaysLabel.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} Hari}}'**
  String durationChipDaysLabel(int count);

  /// No description provided for @availableAtBranchesLabel.
  ///
  /// In id, this message translates to:
  /// **'Tersedia di Cabang'**
  String get availableAtBranchesLabel;

  /// No description provided for @noBranchesForServiceHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada cabang. Tambahkan cabang terlebih dahulu di menu Cabang.'**
  String get noBranchesForServiceHint;

  /// No description provided for @noBranchSelectedLabel.
  ///
  /// In id, this message translates to:
  /// **'Belum ada cabang dipilih'**
  String get noBranchSelectedLabel;

  /// No description provided for @branchesSelectedCountLabel.
  ///
  /// In id, this message translates to:
  /// **'{count} dari {total} cabang dipilih'**
  String branchesSelectedCountLabel(int count, int total);

  /// No description provided for @selectAllLabel.
  ///
  /// In id, this message translates to:
  /// **'Pilih Semua'**
  String get selectAllLabel;

  /// No description provided for @deselectAllLabel.
  ///
  /// In id, this message translates to:
  /// **'Batal Semua'**
  String get deselectAllLabel;

  /// No description provided for @loadBranchesFailedLabel.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat cabang.'**
  String get loadBranchesFailedLabel;

  /// No description provided for @searchServiceHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama layanan...'**
  String get searchServiceHint;

  /// No description provided for @noMatchingServicesTitle.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada layanan yang cocok'**
  String get noMatchingServicesTitle;

  /// No description provided for @tryDifferentKeywordFilterHint.
  ///
  /// In id, this message translates to:
  /// **'Coba ubah kata kunci atau filter'**
  String get tryDifferentKeywordFilterHint;

  /// No description provided for @emptyBranchSelectionMeansAllHint.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan semua untuk tersedia di semua cabang.'**
  String get emptyBranchSelectionMeansAllHint;

  /// No description provided for @sessionNotFoundError.
  ///
  /// In id, this message translates to:
  /// **'Sesi pengguna tidak ditemukan. Silakan login kembali.'**
  String get sessionNotFoundError;

  /// No description provided for @companyNotSetupError.
  ///
  /// In id, this message translates to:
  /// **'Perusahaan belum diatur. Selesaikan onboarding terlebih dahulu.'**
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

  /// No description provided for @unitPerKgSuffix.
  ///
  /// In id, this message translates to:
  /// **' / Kg'**
  String get unitPerKgSuffix;

  /// No description provided for @unitPerItemSuffix.
  ///
  /// In id, this message translates to:
  /// **' / Item'**
  String get unitPerItemSuffix;

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

  /// No description provided for @deleteCustomerSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan \"{name}\" berhasil dihapus permanen'**
  String deleteCustomerSuccess(String name);

  /// No description provided for @deleteCustomerError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus pelanggan: {error}'**
  String deleteCustomerError(String error);

  /// No description provided for @customerDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Pelanggan'**
  String get customerDetailTitle;

  /// No description provided for @activeCustomerLabel.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan Aktif'**
  String get activeCustomerLabel;

  /// No description provided for @joinedSinceLabel.
  ///
  /// In id, this message translates to:
  /// **'Bergabung sejak {date}'**
  String joinedSinceLabel(String date);

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
  /// **'Telepon'**
  String get phoneLabel;

  /// No description provided for @customerAddressLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat'**
  String get customerAddressLabel;

  /// No description provided for @orderHistoryTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Pesanan'**
  String get orderHistoryTitle;

  /// Tombol di order detail (status ready, self-pickup) untuk mengabari pelanggan lewat WhatsApp sebelum order ditandai selesai
  ///
  /// In id, this message translates to:
  /// **'Kabari Pelanggan Siap Diambil'**
  String get notifyReadyForPickupButtonLabel;

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

  /// No description provided for @customerOrderStatusConfirmed.
  ///
  /// In id, this message translates to:
  /// **'Dikonfirmasi'**
  String get customerOrderStatusConfirmed;

  /// No description provided for @orderStatusInProgress.
  ///
  /// In id, this message translates to:
  /// **'Diproses'**
  String get orderStatusInProgress;

  /// No description provided for @customerOrderStatusProcessing.
  ///
  /// In id, this message translates to:
  /// **'Diproses'**
  String get customerOrderStatusProcessing;

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

  /// No description provided for @customerPhoneNumberLabel.
  ///
  /// In id, this message translates to:
  /// **'No. Telepon'**
  String get customerPhoneNumberLabel;

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

  /// No description provided for @deleteCustomerSuccessTesting.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan berhasil dihapus!'**
  String get deleteCustomerSuccessTesting;

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

  /// No description provided for @branchFullAddressLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat Lengkap'**
  String get branchFullAddressLabel;

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

  /// No description provided for @branchContactPhoneLabel.
  ///
  /// In id, this message translates to:
  /// **'Nomor Telepon'**
  String get branchContactPhoneLabel;

  /// No description provided for @branchEmailOptionalLabel.
  ///
  /// In id, this message translates to:
  /// **'Email Cabang (Opsional)'**
  String get branchEmailOptionalLabel;

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

  /// No description provided for @branchAddressHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Jl. Merdeka No. 123'**
  String get branchAddressHint;

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

  /// No description provided for @branchListTitle.
  ///
  /// In id, this message translates to:
  /// **'Daftar Cabang ({count})'**
  String branchListTitle(int count);

  /// No description provided for @hideLabel.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan'**
  String get hideLabel;

  /// No description provided for @openTodayStatus.
  ///
  /// In id, this message translates to:
  /// **'Buka • {open} - {close}'**
  String openTodayStatus(String open, String close);

  /// No description provided for @closedTemporarilyLabel.
  ///
  /// In id, this message translates to:
  /// **'Tutup Sementara'**
  String get closedTemporarilyLabel;

  /// Label saat cabang libur di hari tertentu (switch jam operasional dimatikan)
  ///
  /// In id, this message translates to:
  /// **'Libur'**
  String get dayOffLabel;

  /// No description provided for @totalStaffLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Staf'**
  String get totalStaffLabel;

  /// No description provided for @openTodayLabel.
  ///
  /// In id, this message translates to:
  /// **'Jam Buka Hari Ini'**
  String get openTodayLabel;

  /// No description provided for @staffAtThisBranchLabel.
  ///
  /// In id, this message translates to:
  /// **'Staf di Cabang Ini ({count})'**
  String staffAtThisBranchLabel(int count);

  /// No description provided for @noStaffAtBranch.
  ///
  /// In id, this message translates to:
  /// **'Belum ada karyawan yang ditempatkan di cabang ini.'**
  String get noStaffAtBranch;

  /// No description provided for @resignedLabel.
  ///
  /// In id, this message translates to:
  /// **'Resign'**
  String get resignedLabel;

  /// No description provided for @deactivateBranchTitle.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan Cabang?'**
  String get deactivateBranchTitle;

  /// No description provided for @deactivateBranchContent.
  ///
  /// In id, this message translates to:
  /// **'Cabang ini akan ditandai tutup sementara dan tidak menerima pesanan baru.'**
  String get deactivateBranchContent;

  /// No description provided for @activeStatusSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan untuk tutup sementara'**
  String get activeStatusSubtitle;

  /// No description provided for @generalInfoSection.
  ///
  /// In id, this message translates to:
  /// **'Informasi Umum'**
  String get generalInfoSection;

  /// No description provided for @deactivateBranchButton.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan Cabang'**
  String get deactivateBranchButton;

  /// No description provided for @ordersListSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Kelola semua pesanan laundry Anda'**
  String get ordersListSubtitle;

  /// No description provided for @newOrderButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Baru'**
  String get newOrderButtonLabel;

  /// No description provided for @searchOrderHint.
  ///
  /// In id, this message translates to:
  /// **'Cari pesanan...'**
  String get searchOrderHint;

  /// No description provided for @orderWaitingStatus.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get orderWaitingStatus;

  /// No description provided for @orderProcessingStatus.
  ///
  /// In id, this message translates to:
  /// **'Diproses'**
  String get orderProcessingStatus;

  /// No description provided for @orderRetryButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get orderRetryButtonLabel;

  /// No description provided for @orderSessionNotFoundError.
  ///
  /// In id, this message translates to:
  /// **'Sesi tidak ditemukan, silakan login ulang'**
  String get orderSessionNotFoundError;

  /// No description provided for @createOrderAppBarTitle.
  ///
  /// In id, this message translates to:
  /// **'Buat Pesanan Baru'**
  String get createOrderAppBarTitle;

  /// No description provided for @createOrderSectionTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Pesanan'**
  String get createOrderSectionTitle;

  /// No description provided for @createOrderSectionSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Isi informasi pesanan'**
  String get createOrderSectionSubtitle;

  /// No description provided for @selectCustomerLabel.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get selectCustomerLabel;

  /// No description provided for @selectCustomerHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih pelanggan'**
  String get selectCustomerHint;

  /// No description provided for @selectServiceLabel.
  ///
  /// In id, this message translates to:
  /// **'Pilih Layanan'**
  String get selectServiceLabel;

  /// No description provided for @selectServiceHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih jenis layanan'**
  String get selectServiceHint;

  /// No description provided for @quantityLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get quantityLabel;

  /// No description provided for @priceLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga'**
  String get priceLabel;

  /// No description provided for @subtotalLabel.
  ///
  /// In id, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @taxLabel.
  ///
  /// In id, this message translates to:
  /// **'Pajak'**
  String get taxLabel;

  /// No description provided for @totalLabel.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @notesOrderLabel.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get notesOrderLabel;

  /// No description provided for @notesOrderHint.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan catatan khusus untuk pesanan ini'**
  String get notesOrderHint;

  /// No description provided for @addServiceItemButton.
  ///
  /// In id, this message translates to:
  /// **'Tambah Layanan'**
  String get addServiceItemButton;

  /// No description provided for @removeServiceItemButton.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get removeServiceItemButton;

  /// No description provided for @saveOrderButton.
  ///
  /// In id, this message translates to:
  /// **'Simpan Pesanan'**
  String get saveOrderButton;

  /// No description provided for @createOrderSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pesanan berhasil dibuat!'**
  String get createOrderSuccess;

  /// No description provided for @createOrderError.
  ///
  /// In id, this message translates to:
  /// **'Gagal membuat pesanan: {error}'**
  String createOrderError(String error);

  /// No description provided for @noActiveServicesError.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada layanan aktif. Tambahkan layanan dulu di menu Layanan sebelum membuat pesanan.'**
  String get noActiveServicesError;

  /// No description provided for @selectCustomerError.
  ///
  /// In id, this message translates to:
  /// **'Silakan pilih pelanggan terlebih dahulu'**
  String get selectCustomerError;

  /// No description provided for @orderDetailAppBarTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Pesanan'**
  String get orderDetailAppBarTitle;

  /// No description provided for @orderDetailCustomerInfoTitle.
  ///
  /// In id, this message translates to:
  /// **'Informasi Pelanggan'**
  String get orderDetailCustomerInfoTitle;

  /// No description provided for @orderDetailItemsTitle.
  ///
  /// In id, this message translates to:
  /// **'Item'**
  String get orderDetailItemsTitle;

  /// No description provided for @orderDetailTimelineTitle.
  ///
  /// In id, this message translates to:
  /// **'Timeline Status'**
  String get orderDetailTimelineTitle;

  /// No description provided for @orderDetailSummaryTitle.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan Pesanan'**
  String get orderDetailSummaryTitle;

  /// No description provided for @orderDetailNotesTitle.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get orderDetailNotesTitle;

  /// No description provided for @orderDetailActionButtonsTitle.
  ///
  /// In id, this message translates to:
  /// **'Aksi'**
  String get orderDetailActionButtonsTitle;

  /// No description provided for @orderItemLabel.
  ///
  /// In id, this message translates to:
  /// **'{count} item'**
  String orderItemLabel(int count);

  /// No description provided for @closeButton.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get closeButton;

  /// No description provided for @selectOrderTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Pesanan'**
  String get selectOrderTitle;

  /// No description provided for @noOrdersWaitingPickupHint.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pesanan yang menunggu dijemput.'**
  String get noOrdersWaitingPickupHint;

  /// No description provided for @noOrdersReadyDeliveryHint.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pesanan yang siap diantar.'**
  String get noOrdersReadyDeliveryHint;

  /// No description provided for @customerFallbackLabel.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get customerFallbackLabel;

  /// No description provided for @orderNotFoundError.
  ///
  /// In id, this message translates to:
  /// **'Pesanan tidak ditemukan'**
  String get orderNotFoundError;

  /// No description provided for @loadOrderError.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat pesanan: {error}'**
  String loadOrderError(String error);

  /// No description provided for @loadingOrderLabel.
  ///
  /// In id, this message translates to:
  /// **'Memuat pesanan...'**
  String get loadingOrderLabel;

  /// No description provided for @schedulingDeliveryBadgeLabel.
  ///
  /// In id, this message translates to:
  /// **'Menjadwalkan Pengantaran'**
  String get schedulingDeliveryBadgeLabel;

  /// No description provided for @scheduleDeliveryScreenTitle.
  ///
  /// In id, this message translates to:
  /// **'Jadwalkan Antar Jemput'**
  String get scheduleDeliveryScreenTitle;

  /// No description provided for @pickupModeLabel.
  ///
  /// In id, this message translates to:
  /// **'Penjemputan'**
  String get pickupModeLabel;

  /// No description provided for @deliveryModeLabel.
  ///
  /// In id, this message translates to:
  /// **'Pengantaran'**
  String get deliveryModeLabel;

  /// No description provided for @newCustomerButtonShort.
  ///
  /// In id, this message translates to:
  /// **'Baru'**
  String get newCustomerButtonShort;

  /// No description provided for @autoFilledScheduleHint.
  ///
  /// In id, this message translates to:
  /// **'Tanggal & jam terisi otomatis dari saat pesanan dibuat'**
  String get autoFilledScheduleHint;

  /// No description provided for @selectBranchLabel.
  ///
  /// In id, this message translates to:
  /// **'Pilih Cabang'**
  String get selectBranchLabel;

  /// No description provided for @noActiveBranchesScheduleHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada cabang aktif. Tambahkan cabang terlebih dahulu di menu Cabang.'**
  String get noActiveBranchesScheduleHint;

  /// No description provided for @createOrderSelectBranchHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih cabang'**
  String get createOrderSelectBranchHint;

  /// No description provided for @useMapLocationButton.
  ///
  /// In id, this message translates to:
  /// **'Pakai lokasi peta'**
  String get useMapLocationButton;

  /// No description provided for @mapLocationComingSoon.
  ///
  /// In id, this message translates to:
  /// **'Fitur pilih lokasi peta akan segera hadir'**
  String get mapLocationComingSoon;

  /// No description provided for @addressFieldExampleHint.
  ///
  /// In id, this message translates to:
  /// **'Jl. Kebayoran Lama No. 123, Jakarta Selatan...'**
  String get addressFieldExampleHint;

  /// No description provided for @dateLabel.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In id, this message translates to:
  /// **'Jam'**
  String get timeLabel;

  /// No description provided for @selectCourierLabel.
  ///
  /// In id, this message translates to:
  /// **'Pilih Kurir'**
  String get selectCourierLabel;

  /// No description provided for @noCourierEmployeeScheduleHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada karyawan dengan posisi \"Kurir\". Anda tetap bisa menyimpan jadwal tanpa memilih kurir.'**
  String get noCourierEmployeeScheduleHint;

  /// No description provided for @searchCourierHint.
  ///
  /// In id, this message translates to:
  /// **'Cari kurir terdekat...'**
  String get searchCourierHint;

  /// No description provided for @courierListHint.
  ///
  /// In id, this message translates to:
  /// **'Kurir aktif dengan posisi \"Kurir\" ditampilkan di daftar ini.'**
  String get courierListHint;

  /// No description provided for @additionalNotesLabel.
  ///
  /// In id, this message translates to:
  /// **'Catatan Tambahan (Opsional)'**
  String get additionalNotesLabel;

  /// No description provided for @notesExampleHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Titipkan di satpam, pagar warna hitam...'**
  String get notesExampleHint;

  /// No description provided for @scheduleSummaryTitle.
  ///
  /// In id, this message translates to:
  /// **'RINGKASAN JADWAL'**
  String get scheduleSummaryTitle;

  /// No description provided for @selectOrSearchOrderLabel.
  ///
  /// In id, this message translates to:
  /// **'Pilih atau Cari Pesanan'**
  String get selectOrSearchOrderLabel;

  /// No description provided for @addressNotSetLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat belum ditentukan'**
  String get addressNotSetLabel;

  /// No description provided for @notScheduledLabel.
  ///
  /// In id, this message translates to:
  /// **'Belum dijadwalkan'**
  String get notScheduledLabel;

  /// No description provided for @modeWithBranchLabel.
  ///
  /// In id, this message translates to:
  /// **'Mode: {mode} • {branch}'**
  String modeWithBranchLabel(String mode, String branch);

  /// No description provided for @modeOnlyLabel.
  ///
  /// In id, this message translates to:
  /// **'Mode: {mode}'**
  String modeOnlyLabel(String mode);

  /// No description provided for @saveScheduleButton.
  ///
  /// In id, this message translates to:
  /// **'Simpan Jadwal'**
  String get saveScheduleButton;

  /// No description provided for @selectOrderRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Pilih pesanan terlebih dahulu'**
  String get selectOrderRequiredError;

  /// No description provided for @addressRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Alamat wajib diisi'**
  String get addressRequiredError;

  /// No description provided for @dateTimeRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Tanggal dan jam wajib dipilih'**
  String get dateTimeRequiredError;

  /// No description provided for @scheduleSaveSuccess.
  ///
  /// In id, this message translates to:
  /// **'Jadwal berhasil disimpan'**
  String get scheduleSaveSuccess;

  /// No description provided for @scheduleSaveError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan jadwal: {error}'**
  String scheduleSaveError(String error);

  /// No description provided for @waitingPickupStatus.
  ///
  /// In id, this message translates to:
  /// **'Menunggu dijemput'**
  String get waitingPickupStatus;

  /// No description provided for @readyDeliveryStatus.
  ///
  /// In id, this message translates to:
  /// **'Siap diantar'**
  String get readyDeliveryStatus;

  /// No description provided for @readyPickupStatus.
  ///
  /// In id, this message translates to:
  /// **'Siap diambil'**
  String get readyPickupStatus;

  /// No description provided for @waitingConfirmationStatus.
  ///
  /// In id, this message translates to:
  /// **'Menunggu konfirmasi'**
  String get waitingConfirmationStatus;

  /// No description provided for @confirmedStatus.
  ///
  /// In id, this message translates to:
  /// **'Dikonfirmasi'**
  String get confirmedStatus;

  /// No description provided for @inProgressStatus.
  ///
  /// In id, this message translates to:
  /// **'Dalam proses'**
  String get inProgressStatus;

  /// No description provided for @markedPickedUpSnackbar.
  ///
  /// In id, this message translates to:
  /// **'{orderNumber} ditandai sudah dijemput'**
  String markedPickedUpSnackbar(String orderNumber);

  /// No description provided for @markedDeliveredSnackbar.
  ///
  /// In id, this message translates to:
  /// **'{orderNumber} ditandai sudah diantar'**
  String markedDeliveredSnackbar(String orderNumber);

  /// No description provided for @markedDeliveredCompletedSnackbar.
  ///
  /// In id, this message translates to:
  /// **'{orderNumber} ditandai sudah diantar & selesai'**
  String markedDeliveredCompletedSnackbar(String orderNumber);

  /// No description provided for @genericUpdateError.
  ///
  /// In id, this message translates to:
  /// **'Gagal update: {error}'**
  String genericUpdateError(String error);

  /// No description provided for @addScheduleButton.
  ///
  /// In id, this message translates to:
  /// **'Tambah Jadwal'**
  String get addScheduleButton;

  /// No description provided for @pickupDeliveryTitle.
  ///
  /// In id, this message translates to:
  /// **'Antar Jemput'**
  String get pickupDeliveryTitle;

  /// No description provided for @pickupDeliverySubtitle.
  ///
  /// In id, this message translates to:
  /// **'Kelola jemput, antar & ambil sendiri'**
  String get pickupDeliverySubtitle;

  /// No description provided for @searchOrderCustomerHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama pelanggan atau no. pesanan...'**
  String get searchOrderCustomerHint;

  /// No description provided for @filterNeedsPickup.
  ///
  /// In id, this message translates to:
  /// **'Perlu dijemput'**
  String get filterNeedsPickup;

  /// No description provided for @filterNeedsDelivery.
  ///
  /// In id, this message translates to:
  /// **'Perlu diantar'**
  String get filterNeedsDelivery;

  /// No description provided for @filterSelfService.
  ///
  /// In id, this message translates to:
  /// **'Ambil sendiri'**
  String get filterSelfService;

  /// No description provided for @filterOthers.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get filterOthers;

  /// No description provided for @statNeedsPickupTitle.
  ///
  /// In id, this message translates to:
  /// **'Perlu Dijemput'**
  String get statNeedsPickupTitle;

  /// No description provided for @statReadyDeliveryTitle.
  ///
  /// In id, this message translates to:
  /// **'Siap Diantar'**
  String get statReadyDeliveryTitle;

  /// No description provided for @statSelfServiceTitle.
  ///
  /// In id, this message translates to:
  /// **'Ambil Sendiri'**
  String get statSelfServiceTitle;

  /// No description provided for @noOrdersTitle.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pesanan'**
  String get noOrdersTitle;

  /// No description provided for @noOrdersFilterSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pesanan yang cocok dengan filter ini'**
  String get noOrdersFilterSubtitle;

  /// No description provided for @selectScheduleModeSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih mode jadwal yang mau dibuat'**
  String get selectScheduleModeSubtitle;

  /// No description provided for @schedulePickupTileTitle.
  ///
  /// In id, this message translates to:
  /// **'Jadwalkan Penjemputan'**
  String get schedulePickupTileTitle;

  /// No description provided for @schedulePickupTileSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Untuk pesanan yang menunggu dijemput'**
  String get schedulePickupTileSubtitle;

  /// No description provided for @scheduleDeliveryTileTitle.
  ///
  /// In id, this message translates to:
  /// **'Jadwalkan Pengantaran'**
  String get scheduleDeliveryTileTitle;

  /// No description provided for @scheduleDeliveryTileSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Untuk pesanan yang sudah siap diantar'**
  String get scheduleDeliveryTileSubtitle;

  /// No description provided for @selectServiceTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Layanan'**
  String get selectServiceTitle;

  /// No description provided for @noActiveServicesHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada layanan aktif.'**
  String get noActiveServicesHint;

  /// No description provided for @dpAmountRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Isi nominal DP terlebih dahulu'**
  String get dpAmountRequiredError;

  /// No description provided for @dpAmountTooLargeError.
  ///
  /// In id, this message translates to:
  /// **'Nominal DP harus lebih kecil dari total. Pilih \"Lunas\" kalau bayar penuh.'**
  String get dpAmountTooLargeError;

  /// No description provided for @minOneItemError.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan minimal 1 item'**
  String get minOneItemError;

  /// No description provided for @weightRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Isi berat (kg) untuk \"{itemName}\"'**
  String weightRequiredError(String itemName);

  /// No description provided for @confirmFailedError.
  ///
  /// In id, this message translates to:
  /// **'Gagal konfirmasi: {error}'**
  String confirmFailedError(String error);

  /// No description provided for @cashPaymentLabel.
  ///
  /// In id, this message translates to:
  /// **'Tunai'**
  String get cashPaymentLabel;

  /// No description provided for @bankTransferLabel.
  ///
  /// In id, this message translates to:
  /// **'Transfer Bank'**
  String get bankTransferLabel;

  /// No description provided for @debitCardLabel.
  ///
  /// In id, this message translates to:
  /// **'Kartu Debit'**
  String get debitCardLabel;

  /// No description provided for @eWalletLabel.
  ///
  /// In id, this message translates to:
  /// **'E-Wallet'**
  String get eWalletLabel;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In id, this message translates to:
  /// **'Metode Pembayaran'**
  String get paymentMethodLabel;

  /// No description provided for @transferPaymentPendingNotice.
  ///
  /// In id, this message translates to:
  /// **'Status pembayaran akan \"Belum Dibayar\" sampai dikonfirmasi manual di halaman detail pesanan.'**
  String get transferPaymentPendingNotice;

  /// No description provided for @instantPaymentNotice.
  ///
  /// In id, this message translates to:
  /// **'Metode ini dianggap dibayar langsung saat ini juga.'**
  String get instantPaymentNotice;

  /// No description provided for @fullPaymentLabel.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get fullPaymentLabel;

  /// No description provided for @partialPaymentLabel.
  ///
  /// In id, this message translates to:
  /// **'DP (Sebagian)'**
  String get partialPaymentLabel;

  /// No description provided for @dpAmountLabel.
  ///
  /// In id, this message translates to:
  /// **'Nominal DP'**
  String get dpAmountLabel;

  /// No description provided for @dpAmountHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: 20000'**
  String get dpAmountHint;

  /// No description provided for @remainingBalanceHint.
  ///
  /// In id, this message translates to:
  /// **'Sisa tagihan bisa dilunasi nanti lewat halaman detail pesanan.'**
  String get remainingBalanceHint;

  /// No description provided for @confirmPickupTitle.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Jemput'**
  String get confirmPickupTitle;

  /// No description provided for @confirmPickupSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Catat item & berat cucian {customerName} ({orderNumber})'**
  String confirmPickupSubtitle(String customerName, String orderNumber);

  /// No description provided for @laundryItemsLabel.
  ///
  /// In id, this message translates to:
  /// **'Item Cucian'**
  String get laundryItemsLabel;

  /// No description provided for @addButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get addButtonLabel;

  /// No description provided for @noItemsAddHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada item. Tekan \"Tambah\" untuk memilih layanan.'**
  String get noItemsAddHint;

  /// No description provided for @confirmPickedUpButton.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Sudah Dijemput'**
  String get confirmPickedUpButton;

  /// No description provided for @confirmDeliveryTitle.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Antar'**
  String get confirmDeliveryTitle;

  /// No description provided for @confirmDeliverySubtitle.
  ///
  /// In id, this message translates to:
  /// **'Antar cucian {customerName} ({orderNumber})'**
  String confirmDeliverySubtitle(String customerName, String orderNumber);

  /// No description provided for @assignedCourierLabel.
  ///
  /// In id, this message translates to:
  /// **'Kurir Bertugas (Opsional)'**
  String get assignedCourierLabel;

  /// No description provided for @noCourierEmployeeDeliverHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada karyawan dengan posisi \"Kurir\". Anda tetap bisa lanjut menandai order ini sudah diantar.'**
  String get noCourierEmployeeDeliverHint;

  /// No description provided for @selectCourierHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih kurir'**
  String get selectCourierHint;

  /// No description provided for @confirmDeliveredButton.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Sudah Diantar'**
  String get confirmDeliveredButton;

  /// No description provided for @pickupTypeLabel.
  ///
  /// In id, this message translates to:
  /// **'Jemput'**
  String get pickupTypeLabel;

  /// No description provided for @walkInTypeLabel.
  ///
  /// In id, this message translates to:
  /// **'Walk-in'**
  String get walkInTypeLabel;

  /// No description provided for @deliveryTypeLabel.
  ///
  /// In id, this message translates to:
  /// **'Antar'**
  String get deliveryTypeLabel;

  /// No description provided for @selfPickupTypeLabel.
  ///
  /// In id, this message translates to:
  /// **'Ambil Sendiri'**
  String get selfPickupTypeLabel;

  /// No description provided for @genericCourierLabel.
  ///
  /// In id, this message translates to:
  /// **'Kurir'**
  String get genericCourierLabel;

  /// No description provided for @courierNotAssignedLabel.
  ///
  /// In id, this message translates to:
  /// **'Kurir belum ditentukan'**
  String get courierNotAssignedLabel;

  /// No description provided for @plannedPickupLabel.
  ///
  /// In id, this message translates to:
  /// **'Rencana jemput: {date}'**
  String plannedPickupLabel(String date);

  /// No description provided for @selfServicePickedUpLabel.
  ///
  /// In id, this message translates to:
  /// **'Diambil: {date}'**
  String selfServicePickedUpLabel(String date);

  /// No description provided for @deliveredAtLabel.
  ///
  /// In id, this message translates to:
  /// **'Diantar: {date}'**
  String deliveredAtLabel(String date);

  /// No description provided for @pickedUpFromCustomerLabel.
  ///
  /// In id, this message translates to:
  /// **'Dijemput: {date}'**
  String pickedUpFromCustomerLabel(String date);

  /// No description provided for @markPickedUpButton.
  ///
  /// In id, this message translates to:
  /// **'Tandai Sudah Dijemput'**
  String get markPickedUpButton;

  /// No description provided for @markSelfPickedUpButton.
  ///
  /// In id, this message translates to:
  /// **'Tandai Sudah Diambil'**
  String get markSelfPickedUpButton;

  /// No description provided for @markDeliveredButton.
  ///
  /// In id, this message translates to:
  /// **'Tandai Sudah Diantar'**
  String get markDeliveredButton;

  /// No description provided for @employeeNotFoundError.
  ///
  /// In id, this message translates to:
  /// **'Data karyawan tidak ditemukan.'**
  String get employeeNotFoundError;

  /// No description provided for @employeeLoadError.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data karyawan: {error}'**
  String employeeLoadError(String error);

  /// No description provided for @employeeGenericError.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan: {error}'**
  String employeeGenericError(String error);

  /// No description provided for @branchNotSelectedWarning.
  ///
  /// In id, this message translates to:
  /// **'Cabang laundry belum dipilih atau belum dibuat!'**
  String get branchNotSelectedWarning;

  /// No description provided for @sessionExpiredError.
  ///
  /// In id, this message translates to:
  /// **'Sesi user berakhir.'**
  String get sessionExpiredError;

  /// No description provided for @branchNotLinkedWarning.
  ///
  /// In id, this message translates to:
  /// **'Cabang terpilih belum terhubung dengan data perusahaan. Periksa kembali data cabang.'**
  String get branchNotLinkedWarning;

  /// No description provided for @quotaLimitReachedTitle.
  ///
  /// In id, this message translates to:
  /// **'Batas Kuota Tercapai'**
  String get quotaLimitReachedTitle;

  /// No description provided for @quotaLimitReachedContent.
  ///
  /// In id, this message translates to:
  /// **'Jumlah karyawan Anda telah mencapai batas maksimal kuota paket langganan saat ini. Silakan upgrade paket.'**
  String get quotaLimitReachedContent;

  /// No description provided for @employeeUpdateSuccess.
  ///
  /// In id, this message translates to:
  /// **'Data karyawan berhasil diperbarui!'**
  String get employeeUpdateSuccess;

  /// No description provided for @employeeAddSuccess.
  ///
  /// In id, this message translates to:
  /// **'Staf karyawan berhasil ditambahkan!'**
  String get employeeAddSuccess;

  /// No description provided for @employeeSaveError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan data karyawan: {error}'**
  String employeeSaveError(String error);

  /// No description provided for @deactivateEmployeeTitle.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan Karyawan'**
  String get deactivateEmployeeTitle;

  /// No description provided for @deactivateEmployeeConfirm.
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin menonaktifkan karyawan ini? Riwayat transaksi lama akan tetap aman.'**
  String get deactivateEmployeeConfirm;

  /// No description provided for @deactivateEmployeeConfirmAlt.
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin menonaktifkan status aktif karyawan ini? Riwayat transaksi lama akan tetap aman.'**
  String get deactivateEmployeeConfirmAlt;

  /// No description provided for @yesDeactivateButton.
  ///
  /// In id, this message translates to:
  /// **'Ya, Nonaktifkan'**
  String get yesDeactivateButton;

  /// No description provided for @employeeDeactivatedSuccess.
  ///
  /// In id, this message translates to:
  /// **'Karyawan telah dinonaktifkan.'**
  String get employeeDeactivatedSuccess;

  /// No description provided for @employeeDeactivateError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menonaktifkan karyawan: {error}'**
  String employeeDeactivateError(String error);

  /// No description provided for @editEmployeeTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Data Karyawan'**
  String get editEmployeeTitle;

  /// No description provided for @addEmployeeTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah Karyawan'**
  String get addEmployeeTitle;

  /// No description provided for @additionalDetailsDivider.
  ///
  /// In id, this message translates to:
  /// **'DETAIL TAMBAHAN'**
  String get additionalDetailsDivider;

  /// No description provided for @editEmployeeInfoBanner.
  ///
  /// In id, this message translates to:
  /// **'Perubahan akan langsung tersimpan pada data karyawan ini.'**
  String get editEmployeeInfoBanner;

  /// No description provided for @addEmployeeInfoBanner.
  ///
  /// In id, this message translates to:
  /// **'Sistem akan memvalidasi limitasi kuota paket langganan Anda secara otomatis sebelum menyimpan data karyawan.'**
  String get addEmployeeInfoBanner;

  /// No description provided for @fullNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Siti Aminah'**
  String get fullNameHint;

  /// No description provided for @employeeNameRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Nama karyawan wajib diisi'**
  String get employeeNameRequiredError;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In id, this message translates to:
  /// **'Nomor Telepon'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Nomor telepon wajib diisi'**
  String get phoneNumberRequiredError;

  /// No description provided for @emailOptionalLabel.
  ///
  /// In id, this message translates to:
  /// **'Email (Opsional)'**
  String get emailOptionalLabel;

  /// No description provided for @invalidEmailFormatError.
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid'**
  String get invalidEmailFormatError;

  /// No description provided for @addressLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat'**
  String get addressLabel;

  /// No description provided for @addressHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan alamat lengkap rumah'**
  String get addressHint;

  /// No description provided for @roleLabel.
  ///
  /// In id, this message translates to:
  /// **'Role / Jabatan'**
  String get roleLabel;

  /// No description provided for @selectPositionHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih Jabatan'**
  String get selectPositionHint;

  /// No description provided for @positionRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Posisi atau jabatan wajib dipilih'**
  String get positionRequiredError;

  /// No description provided for @assignedBranchLabel.
  ///
  /// In id, this message translates to:
  /// **'Cabang Bertugas'**
  String get assignedBranchLabel;

  /// No description provided for @registerNewBranchFirstButton.
  ///
  /// In id, this message translates to:
  /// **'+ Daftarkan Cabang Baru Terlebih Dahulu'**
  String get registerNewBranchFirstButton;

  /// No description provided for @selectBranchHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih Cabang'**
  String get selectBranchHint;

  /// No description provided for @branchRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Cabang penempatan wajib dipilih'**
  String get branchRequiredError;

  /// No description provided for @hireDateLabel.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Bergabung'**
  String get hireDateLabel;

  /// No description provided for @appAccessTitle.
  ///
  /// In id, this message translates to:
  /// **'Akses Aplikasi'**
  String get appAccessTitle;

  /// No description provided for @appAccessSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Berikan akses login aplikasi'**
  String get appAccessSubtitle;

  /// No description provided for @employeeStatusTitle.
  ///
  /// In id, this message translates to:
  /// **'Status Karyawan'**
  String get employeeStatusTitle;

  /// No description provided for @employeeStatusCurrent.
  ///
  /// In id, this message translates to:
  /// **'Status saat ini: {status}'**
  String employeeStatusCurrent(String status);

  /// No description provided for @statusActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In id, this message translates to:
  /// **'Tidak Aktif'**
  String get statusInactive;

  /// No description provided for @employeeCodeLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode Karyawan'**
  String get employeeCodeLabel;

  /// No description provided for @employeeCodeHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: EMP01, KSR02'**
  String get employeeCodeHint;

  /// No description provided for @employeeCodeRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Kode karyawan tidak boleh kosong'**
  String get employeeCodeRequiredError;

  /// No description provided for @baseSalaryLabel.
  ///
  /// In id, this message translates to:
  /// **'Gaji Pokok (IDR)'**
  String get baseSalaryLabel;

  /// No description provided for @baseSalaryRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Gaji pokok wajib diisi'**
  String get baseSalaryRequiredError;

  /// No description provided for @commissionPerTransactionLabel.
  ///
  /// In id, this message translates to:
  /// **'Komisi per Transaksi (%)'**
  String get commissionPerTransactionLabel;

  /// No description provided for @commissionHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: 5.0'**
  String get commissionHint;

  /// No description provided for @employeePermissionsTitle.
  ///
  /// In id, this message translates to:
  /// **'Hak Akses Fitur Karyawan'**
  String get employeePermissionsTitle;

  /// No description provided for @employeePermissionsSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Atur fitur apa saja yang boleh diakses karyawan ini'**
  String get employeePermissionsSubtitle;

  /// No description provided for @canCreateOrderPermission.
  ///
  /// In id, this message translates to:
  /// **'Dapat Membuat Pesanan (Order)'**
  String get canCreateOrderPermission;

  /// No description provided for @canManageCustomerPermission.
  ///
  /// In id, this message translates to:
  /// **'Dapat Mengelola Data Pelanggan'**
  String get canManageCustomerPermission;

  /// No description provided for @canViewReportPermission.
  ///
  /// In id, this message translates to:
  /// **'Dapat Melihat Laporan Keuangan (Report)'**
  String get canViewReportPermission;

  /// No description provided for @permissionsResetForPosition.
  ///
  /// In id, this message translates to:
  /// **'Hak akses disesuaikan otomatis untuk jabatan {position}'**
  String permissionsResetForPosition(String position);

  /// No description provided for @savingButton.
  ///
  /// In id, this message translates to:
  /// **'Menyimpan...'**
  String get savingButton;

  /// No description provided for @saveEmployeeButton.
  ///
  /// In id, this message translates to:
  /// **'Simpan Karyawan'**
  String get saveEmployeeButton;

  /// No description provided for @completeRequiredFieldsWarning.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi dulu data yang wajib diisi'**
  String get completeRequiredFieldsWarning;

  /// No description provided for @employeeDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Karyawan'**
  String get employeeDetailTitle;

  /// No description provided for @employeeCodeFallback.
  ///
  /// In id, this message translates to:
  /// **'Karyawan {code}'**
  String employeeCodeFallback(String code);

  /// No description provided for @laundryStaffFallback.
  ///
  /// In id, this message translates to:
  /// **'Staf Laundry'**
  String get laundryStaffFallback;

  /// No description provided for @addressFullLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat Lengkap'**
  String get addressFullLabel;

  /// No description provided for @employmentInfoTitle.
  ///
  /// In id, this message translates to:
  /// **'Informasi Pekerjaan'**
  String get employmentInfoTitle;

  /// No description provided for @documentIdLabel.
  ///
  /// In id, this message translates to:
  /// **'ID Dokumen'**
  String get documentIdLabel;

  /// No description provided for @positionLabel.
  ///
  /// In id, this message translates to:
  /// **'Posisi Kerja'**
  String get positionLabel;

  /// No description provided for @baseSalaryShortLabel.
  ///
  /// In id, this message translates to:
  /// **'Gaji Pokok'**
  String get baseSalaryShortLabel;

  /// No description provided for @commissionLabel.
  ///
  /// In id, this message translates to:
  /// **'Komisi'**
  String get commissionLabel;

  /// No description provided for @systemAccessTitle.
  ///
  /// In id, this message translates to:
  /// **'Hak Akses Sistem'**
  String get systemAccessTitle;

  /// No description provided for @createOrdersPermissionShort.
  ///
  /// In id, this message translates to:
  /// **'Membuat Pesanan'**
  String get createOrdersPermissionShort;

  /// No description provided for @manageCustomersPermissionShort.
  ///
  /// In id, this message translates to:
  /// **'Mengelola Pelanggan'**
  String get manageCustomersPermissionShort;

  /// No description provided for @viewReportsPermissionShort.
  ///
  /// In id, this message translates to:
  /// **'Melihat Laporan'**
  String get viewReportsPermissionShort;

  /// No description provided for @activityHistoryLabel.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Aktivitas'**
  String get activityHistoryLabel;

  /// No description provided for @activityLogEntryLabel.
  ///
  /// In id, this message translates to:
  /// **'{stage} · {orderNumber}'**
  String activityLogEntryLabel(String stage, String orderNumber);

  /// No description provided for @activityHistoryUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Riwayat aktivitas belum tersedia.'**
  String get activityHistoryUnavailable;

  /// No description provided for @today.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In id, this message translates to:
  /// **'Kemarin'**
  String get yesterday;

  /// No description provided for @loggedInActivityLabel.
  ///
  /// In id, this message translates to:
  /// **'Masuk ke akun'**
  String get loggedInActivityLabel;

  /// No description provided for @loggedOutActivityLabel.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari akun'**
  String get loggedOutActivityLabel;

  /// No description provided for @latestActivityBadge.
  ///
  /// In id, this message translates to:
  /// **'Terbaru'**
  String get latestActivityBadge;

  /// No description provided for @noActivityYet.
  ///
  /// In id, this message translates to:
  /// **'Belum ada aktivitas.'**
  String get noActivityYet;

  /// No description provided for @viewAllActivityLabel.
  ///
  /// In id, this message translates to:
  /// **'Lihat semua aktivitas'**
  String get viewAllActivityLabel;

  /// No description provided for @resetPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordLabel;

  /// No description provided for @resetPasswordUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Reset password belum tersedia.'**
  String get resetPasswordUnavailable;

  /// No description provided for @manageEmployeesTitle.
  ///
  /// In id, this message translates to:
  /// **'Kelola Karyawan'**
  String get manageEmployeesTitle;

  /// No description provided for @searchEmployeeHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau nomor telepon karyawan...'**
  String get searchEmployeeHint;

  /// No description provided for @filterAllLabel.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get filterAllLabel;

  /// No description provided for @allRolesLabel.
  ///
  /// In id, this message translates to:
  /// **'Semua Role'**
  String get allRolesLabel;

  /// No description provided for @totalEmployeesLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Karyawan'**
  String get totalEmployeesLabel;

  /// No description provided for @noEmployeesFoundTitle.
  ///
  /// In id, this message translates to:
  /// **'Data karyawan tidak ditemukan'**
  String get noEmployeesFoundTitle;

  /// No description provided for @noEmployeesFoundSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Coba ubah filter atau tambahkan karyawan baru'**
  String get noEmployeesFoundSubtitle;

  /// No description provided for @newEmployeeButton.
  ///
  /// In id, this message translates to:
  /// **'Karyawan Baru'**
  String get newEmployeeButton;

  /// No description provided for @noNameFallback.
  ///
  /// In id, this message translates to:
  /// **'Tanpa Nama'**
  String get noNameFallback;

  /// No description provided for @terminateEmployeeTitle.
  ///
  /// In id, this message translates to:
  /// **'Terminasi Karyawan'**
  String get terminateEmployeeTitle;

  /// No description provided for @terminateEmployeeConfirm.
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin menonaktifkan {name} ({position})?'**
  String terminateEmployeeConfirm(String name, String position);

  /// No description provided for @employeeDeactivatedWithCodeSuccess.
  ///
  /// In id, this message translates to:
  /// **'Karyawan {code} telah dinonaktifkan'**
  String employeeDeactivatedWithCodeSuccess(String code);

  /// No description provided for @deleteEmployeeConfirmContent.
  ///
  /// In id, this message translates to:
  /// **'Karyawan \"{name}\" akan dihapus permanen dari database dan TIDAK BISA dikembalikan.\n\nJika karyawan ini masih atau pernah tercatat dalam riwayat transaksi, sebaiknya gunakan opsi \"Nonaktifkan\" saja agar riwayat lama tetap tampil normal.'**
  String deleteEmployeeConfirmContent(String name);

  /// No description provided for @deleteEmployeeSuccess.
  ///
  /// In id, this message translates to:
  /// **'Karyawan \"{name}\" berhasil dihapus permanen'**
  String deleteEmployeeSuccess(String name);

  /// No description provided for @deleteEmployeeError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus karyawan: {error}'**
  String deleteEmployeeError(String error);

  /// No description provided for @unnamedBranchFallback.
  ///
  /// In id, this message translates to:
  /// **'Cabang Tanpa Nama'**
  String get unnamedBranchFallback;

  /// No description provided for @ordersListTitle.
  ///
  /// In id, this message translates to:
  /// **'Pesanan'**
  String get ordersListTitle;

  /// No description provided for @orderCompletedStatus.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get orderCompletedStatus;

  /// No description provided for @orderCancelledStatus.
  ///
  /// In id, this message translates to:
  /// **'Dibatalkan'**
  String get orderCancelledStatus;

  /// No description provided for @orderNoOrdersLabel.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pesanan'**
  String get orderNoOrdersLabel;

  /// No description provided for @orderCreateOrderButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Buat pesanan pertama Anda sekarang'**
  String get orderCreateOrderButtonLabel;

  /// No description provided for @orderNoOrdersInBranch.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pesanan di cabang ini'**
  String get orderNoOrdersInBranch;

  /// No description provided for @orderSuggestNewOrChangeBranch.
  ///
  /// In id, this message translates to:
  /// **'Silakan tambahkan pesanan baru atau coba pilih filter cabang yang berbeda.'**
  String get orderSuggestNewOrChangeBranch;

  /// No description provided for @orderStatusWaiting.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get orderStatusWaiting;

  /// No description provided for @orderStatusConfirmed.
  ///
  /// In id, this message translates to:
  /// **'Dikonfirmasi'**
  String get orderStatusConfirmed;

  /// No description provided for @orderStatusProcessing.
  ///
  /// In id, this message translates to:
  /// **'Diproses'**
  String get orderStatusProcessing;

  /// No description provided for @orderStatusWashing.
  ///
  /// In id, this message translates to:
  /// **'Dicuci'**
  String get orderStatusWashing;

  /// No description provided for @orderStatusDrying.
  ///
  /// In id, this message translates to:
  /// **'Dikeringkan'**
  String get orderStatusDrying;

  /// No description provided for @orderStatusIroning.
  ///
  /// In id, this message translates to:
  /// **'Disetrika'**
  String get orderStatusIroning;

  /// No description provided for @orderStatusQualityCheck.
  ///
  /// In id, this message translates to:
  /// **'Cek Kualitas'**
  String get orderStatusQualityCheck;

  /// No description provided for @orderStatusReady.
  ///
  /// In id, this message translates to:
  /// **'Siap Diambil'**
  String get orderStatusReady;

  /// No description provided for @orderTypePickup.
  ///
  /// In id, this message translates to:
  /// **'Dijemput'**
  String get orderTypePickup;

  /// No description provided for @orderTypeWalkIn.
  ///
  /// In id, this message translates to:
  /// **'Walk-in'**
  String get orderTypeWalkIn;

  /// No description provided for @orderDeliveryDelivery.
  ///
  /// In id, this message translates to:
  /// **'Diantar'**
  String get orderDeliveryDelivery;

  /// No description provided for @orderDeliverySelfPickup.
  ///
  /// In id, this message translates to:
  /// **'Ambil Sendiri'**
  String get orderDeliverySelfPickup;

  /// No description provided for @orderServiceMoreSuffix.
  ///
  /// In id, this message translates to:
  /// **'lainnya'**
  String get orderServiceMoreSuffix;

  /// No description provided for @orderTotalPaymentLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Pembayaran'**
  String get orderTotalPaymentLabel;

  /// No description provided for @orderItemsLabel.
  ///
  /// In id, this message translates to:
  /// **'item'**
  String get orderItemsLabel;

  /// No description provided for @linkOpenError.
  ///
  /// In id, this message translates to:
  /// **'Tidak bisa membuka tautan'**
  String get linkOpenError;

  /// No description provided for @appVersionLabel.
  ///
  /// In id, this message translates to:
  /// **'Versi {version}'**
  String appVersionLabel(String version);

  /// No description provided for @aboutAppDescription.
  ///
  /// In id, this message translates to:
  /// **'NetWash adalah aplikasi laundry on-demand yang memudahkan kamu menjemput, mencuci, dan mengantar pakaian tanpa repot.'**
  String get aboutAppDescription;

  /// No description provided for @privacyPolicyLabel.
  ///
  /// In id, this message translates to:
  /// **'Kebijakan Privasi'**
  String get privacyPolicyLabel;

  /// No description provided for @termsConditionsLabel.
  ///
  /// In id, this message translates to:
  /// **'Syarat dan Ketentuan'**
  String get termsConditionsLabel;

  /// No description provided for @rateAppLabel.
  ///
  /// In id, this message translates to:
  /// **'Beri Rating Aplikasi'**
  String get rateAppLabel;

  /// No description provided for @copyrightNotice.
  ///
  /// In id, this message translates to:
  /// **'© 2026 NetWash. All rights reserved.'**
  String get copyrightNotice;

  /// No description provided for @searchFaqHint.
  ///
  /// In id, this message translates to:
  /// **'Cari pertanyaan...'**
  String get searchFaqHint;

  /// No description provided for @notAnsweredContactUs.
  ///
  /// In id, this message translates to:
  /// **'Belum terjawab? Hubungi kami'**
  String get notAnsweredContactUs;

  /// No description provided for @faqOrderQuestion.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana cara order cuci?'**
  String get faqOrderQuestion;

  /// No description provided for @faqOrderAnswer.
  ///
  /// In id, this message translates to:
  /// **'Buka menu Order, pilih layanan, tentukan alamat jemput, lalu konfirmasi pesanan. Kurir akan datang sesuai jadwal.'**
  String get faqOrderAnswer;

  /// No description provided for @faqDurationQuestion.
  ///
  /// In id, this message translates to:
  /// **'Berapa lama proses cucian?'**
  String get faqDurationQuestion;

  /// No description provided for @faqDurationAnswer.
  ///
  /// In id, this message translates to:
  /// **'Proses cuci reguler 1-2 hari kerja, express selesai dalam 6 jam sejak dijemput.'**
  String get faqDurationAnswer;

  /// No description provided for @faqPaymentQuestion.
  ///
  /// In id, this message translates to:
  /// **'Metode pembayaran apa saja?'**
  String get faqPaymentQuestion;

  /// No description provided for @faqPaymentAnswer.
  ///
  /// In id, this message translates to:
  /// **'Kami menerima transfer bank, e-wallet, dan pembayaran tunai langsung ke kurir.'**
  String get faqPaymentAnswer;

  /// No description provided for @faqTrackQuestion.
  ///
  /// In id, this message translates to:
  /// **'Cara lacak status pesanan?'**
  String get faqTrackQuestion;

  /// No description provided for @faqTrackAnswer.
  ///
  /// In id, this message translates to:
  /// **'Buka menu Orders, pilih pesanan aktif, status akan otomatis update mengikuti tahap pengerjaan.'**
  String get faqTrackAnswer;

  /// No description provided for @chatBotTopicBranchQuestion.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana cara menambah cabang baru?'**
  String get chatBotTopicBranchQuestion;

  /// No description provided for @chatBotTopicBranchAnswer.
  ///
  /// In id, this message translates to:
  /// **'Caranya:\n1. Dari dashboard, buka menu Cabang.\n2. Ketuk \"Cabang Baru\".\n3. Isi nama cabang, kode cabang, kota, provinsi, dan alamat lengkap.\n4. Kalau perlu, isi juga nomor telepon, email cabang, dan titik lokasi di peta.\n5. Isi kapasitas harian (jumlah pesanan maksimal per hari).\n6. Atur jam operasional per hari, atau centang \"Gunakan jam yang sama untuk semua hari\".\n7. Ketuk \"Simpan Data Cabang\".'**
  String get chatBotTopicBranchAnswer;

  /// No description provided for @chatBotTopicEmployeeQuestion.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana cara menambah karyawan baru?'**
  String get chatBotTopicEmployeeQuestion;

  /// No description provided for @chatBotTopicEmployeeAnswer.
  ///
  /// In id, this message translates to:
  /// **'Caranya:\n1. Dari dashboard, buka menu Kelola Karyawan.\n2. Ketuk \"Karyawan Baru\".\n3. Isi nama lengkap, nomor telepon, dan (opsional) email & alamat.\n4. Isi kode karyawan, posisi, dan cabang penempatannya.\n5. Isi tanggal bergabung, gaji pokok, dan komisi per transaksi (opsional).\n6. Atur hak akses fitur (bisa buat pesanan, kelola pelanggan, lihat laporan).\n7. Aktifkan \"Akses Aplikasi\" kalau karyawan ini boleh login ke aplikasi.\n8. Ketuk \"Simpan Karyawan\".'**
  String get chatBotTopicEmployeeAnswer;

  /// No description provided for @chatBotTopicServiceQuestion.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana cara menambah layanan cuci dan mengatur harganya?'**
  String get chatBotTopicServiceQuestion;

  /// No description provided for @chatBotTopicServiceAnswer.
  ///
  /// In id, this message translates to:
  /// **'Caranya:\n1. Dari dashboard, buka menu Layanan.\n2. Ketuk \"Layanan Baru\".\n3. Isi nama layanan dan deskripsi (opsional).\n4. Pilih jenis layanan: Per Berat, Per Item, atau Express.\n5. Isi harga (per Kg/Item, atau harga dasar + biaya express) dan berat minimum kalau ada.\n6. Atur estimasi waktu pengerjaan (jam atau hari).\n7. Pilih cabang mana saja yang menyediakan layanan ini, atau biarkan kosong supaya tersedia di semua cabang.\n8. Ketuk \"Simpan Layanan\".'**
  String get chatBotTopicServiceAnswer;

  /// No description provided for @chatBotTopicOrderQuestion.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana cara membuat pesanan baru?'**
  String get chatBotTopicOrderQuestion;

  /// No description provided for @chatBotTopicOrderAnswer.
  ///
  /// In id, this message translates to:
  /// **'Caranya:\n1. Dari dashboard, ketuk \"Pesanan Baru\".\n2. Pilih cabang dan pelanggan (tambahkan pelanggan baru dulu kalau belum ada).\n3. Ketuk salah satu layanan untuk menambahkannya ke pesanan, lalu isi berat/jumlahnya.\n4. Kalau perlu, atur jadwal pickup, atau kosongkan dan jadwalkan nanti dari menu Pickup & Delivery.\n5. Pilih metode pembayaran dan apakah lunas atau bayar DP.\n6. Kalau DP, isi jumlah yang dibayar di muka.\n7. Ketuk \"Simpan Pesanan\".'**
  String get chatBotTopicOrderAnswer;

  /// No description provided for @chatBotTopicReportQuestion.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana cara melihat laporan bisnis saya?'**
  String get chatBotTopicReportQuestion;

  /// No description provided for @chatBotTopicReportAnswer.
  ///
  /// In id, this message translates to:
  /// **'Caranya:\n1. Dari dashboard, buka menu Laporan.\n2. Pilih periode: Hari Ini, Minggu Ini, Bulan Ini, atau Tahun Ini.\n3. Lihat ringkasan pendapatan, pelanggan baru, rata-rata pesanan, dan pertumbuhan.\n4. Scroll ke bawah untuk lihat grafik tren pendapatan dan pendapatan per layanan.\n5. Cek Completion Rate untuk lihat persentase pesanan yang sudah selesai.\n6. Ketuk \"Cetak Laporan\" kalau mau ekspor ke PDF.'**
  String get chatBotTopicReportAnswer;

  /// No description provided for @chatBotTopicLanguageQuestion.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana cara mengganti bahasa aplikasi?'**
  String get chatBotTopicLanguageQuestion;

  /// No description provided for @chatBotTopicLanguageAnswer.
  ///
  /// In id, this message translates to:
  /// **'Caranya:\n1. Buka menu Pengaturan.\n2. Ketuk menu Bahasa.\n3. Pilih bahasa yang diinginkan (Indonesia/English).\n4. Perubahan langsung diterapkan ke seluruh aplikasi.'**
  String get chatBotTopicLanguageAnswer;

  /// No description provided for @orderDetailStatusPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get orderDetailStatusPending;

  /// No description provided for @orderDetailStatusConfirmed.
  ///
  /// In id, this message translates to:
  /// **'Dikonfirmasi'**
  String get orderDetailStatusConfirmed;

  /// No description provided for @orderDetailStatusInProgress.
  ///
  /// In id, this message translates to:
  /// **'Diproses'**
  String get orderDetailStatusInProgress;

  /// No description provided for @orderDetailStatusWashing.
  ///
  /// In id, this message translates to:
  /// **'Washing (Pencucian)'**
  String get orderDetailStatusWashing;

  /// No description provided for @orderDetailStatusDrying.
  ///
  /// In id, this message translates to:
  /// **'Drying (Pengeringan)'**
  String get orderDetailStatusDrying;

  /// No description provided for @orderDetailStatusIroning.
  ///
  /// In id, this message translates to:
  /// **'Ironing (Penyetrikaan)'**
  String get orderDetailStatusIroning;

  /// No description provided for @orderDetailStatusQualityCheck.
  ///
  /// In id, this message translates to:
  /// **'Quality Check'**
  String get orderDetailStatusQualityCheck;

  /// No description provided for @orderDetailStatusReady.
  ///
  /// In id, this message translates to:
  /// **'Siap Diambil/Kirim'**
  String get orderDetailStatusReady;

  /// No description provided for @orderDetailStatusCompleted.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get orderDetailStatusCompleted;

  /// No description provided for @orderDetailStatusCancelled.
  ///
  /// In id, this message translates to:
  /// **'Dibatalkan'**
  String get orderDetailStatusCancelled;

  /// No description provided for @orderDetailNotePending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu konfirmasi'**
  String get orderDetailNotePending;

  /// No description provided for @orderDetailNoteConfirmed.
  ///
  /// In id, this message translates to:
  /// **'Pesanan sudah dikonfirmasi'**
  String get orderDetailNoteConfirmed;

  /// No description provided for @orderDetailNoteInProgress.
  ///
  /// In id, this message translates to:
  /// **'Sedang diproses'**
  String get orderDetailNoteInProgress;

  /// No description provided for @orderDetailNoteWashing.
  ///
  /// In id, this message translates to:
  /// **'Sedang dalam mesin cuci'**
  String get orderDetailNoteWashing;

  /// No description provided for @orderDetailNoteDrying.
  ///
  /// In id, this message translates to:
  /// **'Sedang dikeringkan'**
  String get orderDetailNoteDrying;

  /// No description provided for @orderDetailNoteIroning.
  ///
  /// In id, this message translates to:
  /// **'Sedang disetrika'**
  String get orderDetailNoteIroning;

  /// No description provided for @orderDetailNoteQualityCheck.
  ///
  /// In id, this message translates to:
  /// **'Sedang dicek kualitasnya'**
  String get orderDetailNoteQualityCheck;

  /// No description provided for @orderDetailNoteReady.
  ///
  /// In id, this message translates to:
  /// **'Siap diambil / diantar'**
  String get orderDetailNoteReady;

  /// No description provided for @orderDetailNoteCompleted.
  ///
  /// In id, this message translates to:
  /// **'Pesanan sudah selesai'**
  String get orderDetailNoteCompleted;

  /// No description provided for @paymentMethodCash.
  ///
  /// In id, this message translates to:
  /// **'Tunai'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodTransfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer Bank'**
  String get paymentMethodTransfer;

  /// No description provided for @paymentMethodDebit.
  ///
  /// In id, this message translates to:
  /// **'Kartu Debit'**
  String get paymentMethodDebit;

  /// No description provided for @paymentMethodEwallet.
  ///
  /// In id, this message translates to:
  /// **'E-Wallet'**
  String get paymentMethodEwallet;

  /// No description provided for @orderDetailPaymentStatusPaid.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get orderDetailPaymentStatusPaid;

  /// No description provided for @orderDetailPaymentStatusPartial.
  ///
  /// In id, this message translates to:
  /// **'DP Sebagian'**
  String get orderDetailPaymentStatusPartial;

  /// No description provided for @orderDetailPaymentStatusRefunded.
  ///
  /// In id, this message translates to:
  /// **'Refund'**
  String get orderDetailPaymentStatusRefunded;

  /// No description provided for @orderDetailPaymentStatusPending.
  ///
  /// In id, this message translates to:
  /// **'Belum Dibayar'**
  String get orderDetailPaymentStatusPending;

  /// No description provided for @statusUpdateSuccess.
  ///
  /// In id, this message translates to:
  /// **'Status berhasil diubah menjadi {status}'**
  String statusUpdateSuccess(String status);

  /// No description provided for @statusUpdateError.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengupdate status: {error}'**
  String statusUpdateError(String error);

  /// No description provided for @paymentRecordSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran berhasil dicatat'**
  String get paymentRecordSuccess;

  /// No description provided for @customerPhoneUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Nomor telepon pelanggan tidak tersedia'**
  String get customerPhoneUnavailable;

  /// No description provided for @whatsappOpenError.
  ///
  /// In id, this message translates to:
  /// **'Tidak bisa membuka WhatsApp'**
  String get whatsappOpenError;

  /// No description provided for @amountMustBePositiveError.
  ///
  /// In id, this message translates to:
  /// **'Nominal harus lebih dari Rp0'**
  String get amountMustBePositiveError;

  /// No description provided for @receiptDownloadWebUnsupported.
  ///
  /// In id, this message translates to:
  /// **'Download struk cuma didukung di aplikasi HP, bukan di web'**
  String get receiptDownloadWebUnsupported;

  /// No description provided for @receiptImageGenerationError.
  ///
  /// In id, this message translates to:
  /// **'Gagal membuat gambar struk'**
  String get receiptImageGenerationError;

  /// No description provided for @receiptSavedToGallery.
  ///
  /// In id, this message translates to:
  /// **'Struk tersimpan di galeri'**
  String get receiptSavedToGallery;

  /// No description provided for @receiptDownloadError.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengunduh struk: {error}'**
  String receiptDownloadError(String error);

  /// No description provided for @cancellationReasonRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Alasan pembatalan wajib diisi'**
  String get cancellationReasonRequiredError;

  /// No description provided for @cancelOrderError.
  ///
  /// In id, this message translates to:
  /// **'Gagal membatalkan pesanan: {error}'**
  String cancelOrderError(String error);

  /// No description provided for @cancellationRequestSubmitted.
  ///
  /// In id, this message translates to:
  /// **'Pengajuan pembatalan terkirim, menunggu persetujuan'**
  String get cancellationRequestSubmitted;

  /// No description provided for @cancellationRequestSubmitError.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengirim pengajuan: {error}'**
  String cancellationRequestSubmitError(String error);

  /// No description provided for @cancellationRequestApproved.
  ///
  /// In id, this message translates to:
  /// **'Pengajuan pembatalan disetujui, pesanan dibatalkan'**
  String get cancellationRequestApproved;

  /// No description provided for @cancellationRequestApproveError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyetujui pengajuan: {error}'**
  String cancellationRequestApproveError(String error);

  /// No description provided for @cancellationRequestRejected.
  ///
  /// In id, this message translates to:
  /// **'Pengajuan pembatalan ditolak'**
  String get cancellationRequestRejected;

  /// No description provided for @cancellationRequestRejectError.
  ///
  /// In id, this message translates to:
  /// **'Gagal menolak pengajuan: {error}'**
  String cancellationRequestRejectError(String error);

  /// No description provided for @deliveryScheduleSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pengantaran berhasil dijadwalkan'**
  String get deliveryScheduleSuccess;

  /// No description provided for @statusChangedNoteTemplate.
  ///
  /// In id, this message translates to:
  /// **'Status diubah ke {status}'**
  String statusChangedNoteTemplate(String status);

  /// No description provided for @assignOperatorDialogTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Operator'**
  String get assignOperatorDialogTitle;

  /// No description provided for @assignOperatorDialogSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Siapa yang akan mengerjakan tahap {stage}?'**
  String assignOperatorDialogSubtitle(String stage);

  /// No description provided for @assignOperatorFieldLabel.
  ///
  /// In id, this message translates to:
  /// **'Operator'**
  String get assignOperatorFieldLabel;

  /// No description provided for @assignOperatorEmptyState.
  ///
  /// In id, this message translates to:
  /// **'Belum ada karyawan aktif yang bisa ditugaskan'**
  String get assignOperatorEmptyState;

  /// No description provided for @assignOperatorConfirmButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Tugaskan & Lanjut'**
  String get assignOperatorConfirmButtonLabel;

  /// No description provided for @currentOperatorLabel.
  ///
  /// In id, this message translates to:
  /// **'Sedang dikerjakan oleh {name}'**
  String currentOperatorLabel(String name);

  /// No description provided for @activityLogByOperatorLabel.
  ///
  /// In id, this message translates to:
  /// **'oleh {name}'**
  String activityLogByOperatorLabel(String name);

  /// No description provided for @orderCancelledNoteTemplate.
  ///
  /// In id, this message translates to:
  /// **'Pesanan dibatalkan: {reason}'**
  String orderCancelledNoteTemplate(String reason);

  /// No description provided for @cancellationRequestedNoteTemplate.
  ///
  /// In id, this message translates to:
  /// **'Pengajuan pembatalan oleh {name}: {reason}'**
  String cancellationRequestedNoteTemplate(String name, String reason);

  /// No description provided for @cancellationApprovedNoteTemplate.
  ///
  /// In id, this message translates to:
  /// **'Pengajuan pembatalan disetujui oleh {name}'**
  String cancellationApprovedNoteTemplate(String name);

  /// No description provided for @cancellationRejectedNoteTemplate.
  ///
  /// In id, this message translates to:
  /// **'Pengajuan pembatalan ditolak oleh {name}'**
  String cancellationRejectedNoteTemplate(String name);

  /// No description provided for @whatsappOrderReadyDeliveryMessage.
  ///
  /// In id, this message translates to:
  /// **'Halo kak {name}!, ini Netwash 😊 . Pesanan kamu ({orderNumber}) sudah selesai dan akan segera kami antar ke alamat kakak ya. Ditunggu ya kak 🙏'**
  String whatsappOrderReadyDeliveryMessage(String name, String orderNumber);

  /// No description provided for @whatsappOrderReadyPickupMessage.
  ///
  /// In id, this message translates to:
  /// **'Halo kak {name}!, ini Netwash 😊 . Pesanan kamu ({orderNumber}) sudah selesai dan siap diambil oleh kakak, mau diambil jam berapa ya kak?. Ditunggu ya 🙏'**
  String whatsappOrderReadyPickupMessage(String name, String orderNumber);

  /// No description provided for @whatsappContactMessage.
  ///
  /// In id, this message translates to:
  /// **'Halo kak {name}, ini dari Netwash terkait pesanan {orderNumber}.'**
  String whatsappContactMessage(String name, String orderNumber);

  /// No description provided for @receiptWhatsappTitle.
  ///
  /// In id, this message translates to:
  /// **'Struk Pesanan - Netwash'**
  String get receiptWhatsappTitle;

  /// No description provided for @receiptOrderNumberLabel.
  ///
  /// In id, this message translates to:
  /// **'No. Pesanan'**
  String get receiptOrderNumberLabel;

  /// No description provided for @receiptDateLabel.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get receiptDateLabel;

  /// No description provided for @receiptCustomerLabel.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get receiptCustomerLabel;

  /// No description provided for @receiptItemsLabel.
  ///
  /// In id, this message translates to:
  /// **'Item'**
  String get receiptItemsLabel;

  /// No description provided for @receiptTotalLabel.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get receiptTotalLabel;

  /// No description provided for @receiptPaymentMethodLabel.
  ///
  /// In id, this message translates to:
  /// **'Metode Bayar'**
  String get receiptPaymentMethodLabel;

  /// No description provided for @receiptPaymentStatusLabel.
  ///
  /// In id, this message translates to:
  /// **'Status Bayar'**
  String get receiptPaymentStatusLabel;

  /// No description provided for @receiptThankYouMessage.
  ///
  /// In id, this message translates to:
  /// **'Terima kasih sudah pakai Netwash 🙏'**
  String get receiptThankYouMessage;

  /// No description provided for @receiptFallbackSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Struk Pesanan'**
  String get receiptFallbackSubtitle;

  /// No description provided for @confirmPaymentDialogTitle.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Pembayaran'**
  String get confirmPaymentDialogTitle;

  /// No description provided for @remainingBillDialogLabel.
  ///
  /// In id, this message translates to:
  /// **'Sisa tagihan: {amount}'**
  String remainingBillDialogLabel(String amount);

  /// No description provided for @amountPaidFieldLabel.
  ///
  /// In id, this message translates to:
  /// **'Nominal Dibayar'**
  String get amountPaidFieldLabel;

  /// No description provided for @methodFieldLabel.
  ///
  /// In id, this message translates to:
  /// **'Metode'**
  String get methodFieldLabel;

  /// No description provided for @saveButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get saveButtonLabel;

  /// No description provided for @cancelOrderDialogTitle.
  ///
  /// In id, this message translates to:
  /// **'Batalkan Pesanan?'**
  String get cancelOrderDialogTitle;

  /// No description provided for @requestCancellationDialogTitle.
  ///
  /// In id, this message translates to:
  /// **'Ajukan Pembatalan?'**
  String get requestCancellationDialogTitle;

  /// No description provided for @cancelOrderDialogContent.
  ///
  /// In id, this message translates to:
  /// **'Tindakan ini akan mengubah status pesanan menjadi Dibatalkan.'**
  String get cancelOrderDialogContent;

  /// No description provided for @requestCancellationDialogContent.
  ///
  /// In id, this message translates to:
  /// **'Pengajuan ini perlu disetujui Admin/Owner/Manager sebelum status pesanan berubah jadi Dibatalkan.'**
  String get requestCancellationDialogContent;

  /// No description provided for @cancellationReasonFieldLabel.
  ///
  /// In id, this message translates to:
  /// **'Alasan pembatalan'**
  String get cancellationReasonFieldLabel;

  /// No description provided for @noButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Tidak'**
  String get noButtonLabel;

  /// No description provided for @yesCancelButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Ya, Batalkan'**
  String get yesCancelButtonLabel;

  /// No description provided for @submitCancellationRequestButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Ajukan Pembatalan'**
  String get submitCancellationRequestButtonLabel;

  /// No description provided for @orderDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Pesanan'**
  String get orderDetailTitle;

  /// No description provided for @orderStatusSectionLabel.
  ///
  /// In id, this message translates to:
  /// **'Status Pesanan'**
  String get orderStatusSectionLabel;

  /// No description provided for @orderCancelledTitle.
  ///
  /// In id, this message translates to:
  /// **'Pesanan Dibatalkan'**
  String get orderCancelledTitle;

  /// No description provided for @trackProgressTitle.
  ///
  /// In id, this message translates to:
  /// **'Lacak Progress'**
  String get trackProgressTitle;

  /// No description provided for @customerInfoSectionLabel.
  ///
  /// In id, this message translates to:
  /// **'Informasi Pelanggan'**
  String get customerInfoSectionLabel;

  /// No description provided for @registeredBranchLabel.
  ///
  /// In id, this message translates to:
  /// **'Cabang Terdaftar'**
  String get registeredBranchLabel;

  /// No description provided for @itemCountLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah Item'**
  String get itemCountLabel;

  /// No description provided for @itemCountValueTemplate.
  ///
  /// In id, this message translates to:
  /// **'{count} item'**
  String itemCountValueTemplate(int count);

  /// No description provided for @serviceLabel.
  ///
  /// In id, this message translates to:
  /// **'Layanan'**
  String get serviceLabel;

  /// No description provided for @costBreakdownSectionLabel.
  ///
  /// In id, this message translates to:
  /// **'Rincian Biaya'**
  String get costBreakdownSectionLabel;

  /// No description provided for @totalBillLabel.
  ///
  /// In id, this message translates to:
  /// **'Total Tagihan'**
  String get totalBillLabel;

  /// No description provided for @paymentSectionLabel.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get paymentSectionLabel;

  /// No description provided for @paidAmountLabel.
  ///
  /// In id, this message translates to:
  /// **'Sudah Dibayar'**
  String get paidAmountLabel;

  /// No description provided for @remainingBillLabel.
  ///
  /// In id, this message translates to:
  /// **'Sisa Tagihan'**
  String get remainingBillLabel;

  /// No description provided for @orderStatusPendingPayment.
  ///
  /// In id, this message translates to:
  /// **'Belum Lunas'**
  String get orderStatusPendingPayment;

  /// No description provided for @confirmPaymentButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Pembayaran'**
  String get confirmPaymentButtonLabel;

  /// No description provided for @downloadReceiptButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Download Struk'**
  String get downloadReceiptButtonLabel;

  /// No description provided for @sendReceiptWhatsappButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Kirim Struk via WA'**
  String get sendReceiptWhatsappButtonLabel;

  /// No description provided for @paymentHistorySectionLabel.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Pembayaran'**
  String get paymentHistorySectionLabel;

  /// No description provided for @notesSectionLabel.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get notesSectionLabel;

  /// No description provided for @cancelOrderButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Batalkan Pesanan'**
  String get cancelOrderButtonLabel;

  /// No description provided for @pendingCancellationApprovalTitle.
  ///
  /// In id, this message translates to:
  /// **'Menunggu Persetujuan Pembatalan'**
  String get pendingCancellationApprovalTitle;

  /// No description provided for @requestedByLabel.
  ///
  /// In id, this message translates to:
  /// **'Diajukan oleh {name}'**
  String requestedByLabel(String name);

  /// No description provided for @reasonLabel.
  ///
  /// In id, this message translates to:
  /// **'Alasan: {reason}'**
  String reasonLabel(String reason);

  /// No description provided for @employeeFallbackLabel.
  ///
  /// In id, this message translates to:
  /// **'Karyawan'**
  String get employeeFallbackLabel;

  /// No description provided for @rejectButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Tolak'**
  String get rejectButtonLabel;

  /// No description provided for @approveButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Setujui'**
  String get approveButtonLabel;

  /// No description provided for @notifyReadyForDeliveryButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Kabari Siap Diantar'**
  String get notifyReadyForDeliveryButtonLabel;

  /// No description provided for @notifyViaWhatsappButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Kabari via WhatsApp'**
  String get notifyViaWhatsappButtonLabel;

  /// No description provided for @scheduleDeliveryButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Jadwalkan Pengantaran'**
  String get scheduleDeliveryButtonLabel;

  /// No description provided for @editDeliveryScheduleButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Ubah Jadwal Pengantaran'**
  String get editDeliveryScheduleButtonLabel;

  /// No description provided for @branchFollowsSelectedOrderHint.
  ///
  /// In id, this message translates to:
  /// **'Cabang mengikuti pesanan yang dipilih'**
  String get branchFollowsSelectedOrderHint;

  /// No description provided for @addressAutoFilledFromCustomerHint.
  ///
  /// In id, this message translates to:
  /// **'Alamat otomatis dari data pelanggan - ganti kalau perlu'**
  String get addressAutoFilledFromCustomerHint;

  /// No description provided for @noActiveCourierInBranchHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kurir aktif di cabang {branchName}'**
  String noActiveCourierInBranchHint(String branchName);

  /// No description provided for @courierMatchesScheduleHint.
  ///
  /// In id, this message translates to:
  /// **'Sesuai jadwal yang sudah dibuat - ganti kalau perlu'**
  String get courierMatchesScheduleHint;

  /// No description provided for @deliveryScheduleUpdateSuccess.
  ///
  /// In id, this message translates to:
  /// **'Jadwal pengantaran berhasil diperbarui'**
  String get deliveryScheduleUpdateSuccess;

  /// No description provided for @contactCustomerButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Hubungi Pelanggan'**
  String get contactCustomerButtonLabel;

  /// No description provided for @confirmOrderButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Pesanan'**
  String get confirmOrderButtonLabel;

  /// No description provided for @startProcessButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Mulai Proses'**
  String get startProcessButtonLabel;

  /// No description provided for @startWashingButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Mulai Mencuci'**
  String get startWashingButtonLabel;

  /// No description provided for @finishWashingButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Selesai Dicuci'**
  String get finishWashingButtonLabel;

  /// No description provided for @finishDryingButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Selesai Dikeringkan'**
  String get finishDryingButtonLabel;

  /// No description provided for @finishIroningButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Selesai Disetrika'**
  String get finishIroningButtonLabel;

  /// No description provided for @passQualityCheckButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Lolos Cek Kualitas'**
  String get passQualityCheckButtonLabel;

  /// No description provided for @markCompletedButtonLabel.
  ///
  /// In id, this message translates to:
  /// **'Tandai Selesai'**
  String get markCompletedButtonLabel;

  /// No description provided for @createOrderSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Buat dan kelola pesanan laundry baru'**
  String get createOrderSubtitle;

  /// No description provided for @noBranchesForOrderError.
  ///
  /// In id, this message translates to:
  /// **'Belum ada cabang laundry. Tambahkan cabang dulu sebelum membuat pesanan.'**
  String get noBranchesForOrderError;

  /// No description provided for @fillWeightForItemError.
  ///
  /// In id, this message translates to:
  /// **'Isi berat (kg) untuk \"{itemName}\" terlebih dahulu'**
  String fillWeightForItemError(String itemName);

  /// No description provided for @businessContextNotReadyError.
  ///
  /// In id, this message translates to:
  /// **'Data perusahaan/cabang belum siap. Coba lagi sebentar.'**
  String get businessContextNotReadyError;

  /// No description provided for @selectedCustomerNotFoundError.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan yang dipilih tidak ditemukan, coba pilih ulang.'**
  String get selectedCustomerNotFoundError;

  /// No description provided for @orderCreatedSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pesanan berhasil dibuat!'**
  String get orderCreatedSuccess;

  /// No description provided for @genericErrorTemplate.
  ///
  /// In id, this message translates to:
  /// **'Error: {error}'**
  String genericErrorTemplate(String error);

  /// No description provided for @orderTypeSelfDropoffLabel.
  ///
  /// In id, this message translates to:
  /// **'Antar Sendiri'**
  String get orderTypeSelfDropoffLabel;

  /// No description provided for @orderDataSectionLabel.
  ///
  /// In id, this message translates to:
  /// **'Data Pesanan'**
  String get orderDataSectionLabel;

  /// No description provided for @incomingLaundryLabel.
  ///
  /// In id, this message translates to:
  /// **'Baju Masuk *'**
  String get incomingLaundryLabel;

  /// No description provided for @outgoingLaundryLabel.
  ///
  /// In id, this message translates to:
  /// **'Baju Keluar *'**
  String get outgoingLaundryLabel;

  /// No description provided for @remainingBillPayLaterNotice.
  ///
  /// In id, this message translates to:
  /// **'Sisa tagihan bisa dilunasi nanti lewat halaman detail pesanan.'**
  String get remainingBillPayLaterNotice;

  /// No description provided for @orderNotesFieldLabel.
  ///
  /// In id, this message translates to:
  /// **'Catatan (Opsional)'**
  String get orderNotesFieldLabel;

  /// No description provided for @orderNotesFieldHint.
  ///
  /// In id, this message translates to:
  /// **'Tulis catatan khusus untuk pesanan ini'**
  String get orderNotesFieldHint;

  /// No description provided for @pickupPaymentPendingNotice.
  ///
  /// In id, this message translates to:
  /// **'Metode & status pembayaran akan dikonfirmasi lagi setelah berat/jumlah cucian diketahui.'**
  String get pickupPaymentPendingNotice;

  /// No description provided for @branchFieldLabel.
  ///
  /// In id, this message translates to:
  /// **'Cabang *'**
  String get branchFieldLabel;

  /// No description provided for @selectBranchForOrderHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih cabang untuk pesanan ini'**
  String get selectBranchForOrderHint;

  /// No description provided for @selectBranchRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Pilih cabang terlebih dahulu'**
  String get selectBranchRequiredError;

  /// No description provided for @customerFieldLabel.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan *'**
  String get customerFieldLabel;

  /// No description provided for @selectCustomerRequiredError.
  ///
  /// In id, this message translates to:
  /// **'Pilih pelanggan terlebih dahulu'**
  String get selectCustomerRequiredError;

  /// No description provided for @noCustomersForOrderHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pelanggan. Tambahkan pelanggan dulu sebelum membuat pesanan.'**
  String get noCustomersForOrderHint;

  /// No description provided for @noCustomersInBranchHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pelanggan yang terdaftar di cabang ini. Tambahkan pelanggan baru, atau cek penempatan cabang pelanggan yang sudah ada.'**
  String get noCustomersInBranchHint;

  /// No description provided for @orderItemsSectionLabel.
  ///
  /// In id, this message translates to:
  /// **'Item Pesanan'**
  String get orderItemsSectionLabel;

  /// No description provided for @noItemsTapServiceHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada item. Ketuk salah satu layanan di atas untuk menambahkannya.'**
  String get noItemsTapServiceHint;

  /// No description provided for @noActiveServicesForOrderHint.
  ///
  /// In id, this message translates to:
  /// **'Belum ada layanan aktif. Tambahkan layanan dulu di menu Layanan sebelum membuat pesanan.'**
  String get noActiveServicesForOrderHint;

  /// No description provided for @pickupScheduleLabel.
  ///
  /// In id, this message translates to:
  /// **'Jadwal Jemput (Opsional)'**
  String get pickupScheduleLabel;

  /// No description provided for @pickupScheduleOptionalHint.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan kalau belum tau jamnya - bisa dijadwalkan belakangan di menu Antar Jemput.'**
  String get pickupScheduleOptionalHint;

  /// No description provided for @itemsFilledAtPickupConfirmationHint.
  ///
  /// In id, this message translates to:
  /// **'Item akan diisi saat konfirmasi jemput'**
  String get itemsFilledAtPickupConfirmationHint;

  /// No description provided for @savingLabel.
  ///
  /// In id, this message translates to:
  /// **'Sedang Menyimpan...'**
  String get savingLabel;

  /// No description provided for @dateFieldFallbackLabel.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get dateFieldFallbackLabel;

  /// No description provided for @timeFieldFallbackLabel.
  ///
  /// In id, this message translates to:
  /// **'Jam'**
  String get timeFieldFallbackLabel;

  /// No description provided for @perKgUnitSuffix.
  ///
  /// In id, this message translates to:
  /// **'/kg'**
  String get perKgUnitSuffix;
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
