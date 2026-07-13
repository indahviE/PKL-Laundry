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