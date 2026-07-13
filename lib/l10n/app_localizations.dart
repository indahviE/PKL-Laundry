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
