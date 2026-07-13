// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAccount => 'Account';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfileSubtitle => 'Change name & profile photo';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get changePasswordSubtitle => 'Update account password';

  @override
  String get sectionPreference => 'Preferences';

  @override
  String get notificationTitle => 'Notifications';

  @override
  String get notificationSubtitle => 'Manage app notifications';

  @override
  String get languageTitle => 'Language';

  @override
  String get sectionOther => 'Others';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpSubtitle => 'FAQ & support';

  @override
  String get aboutTitle => 'About App';

  @override
  String get logoutButton => 'Log Out';

  @override
  String get logoutDialogTitle => 'Log Out?';

  @override
  String get logoutDialogContent =>
      'You\'ll need to log in again to access this account.';

  @override
  String get cancel => 'Cancel';

  @override
  String get logout => 'Log Out';

  @override
  String get roleOwner => 'Owner';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get nameEmptyError => 'Name cannot be empty';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String galleryOpenError(String error) {
    return 'Failed to open gallery: $error';
  }

  @override
  String get uploadTimeoutError => 'Upload timed out, check your connection';

  @override
  String uploadFailedError(String code, String body) {
    return 'Upload failed ($code): $body';
  }

  @override
  String get profileUpdateSuccess => 'Profile updated successfully';

  @override
  String profileUpdateError(String error) {
    return 'Failed to update profile: $error';
  }

  @override
  String get oldPasswordLabel => 'Old Password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmPasswordLabel => 'Confirm New Password';

  @override
  String get oldPasswordRequiredError => 'Old password is required';

  @override
  String get newPasswordRequiredError => 'New password is required';

  @override
  String get passwordMinLengthError => 'Minimum 6 characters';

  @override
  String get newPasswordSameAsOldError =>
      'New password cannot be the same as the old one';

  @override
  String get confirmPasswordRequiredError =>
      'Password confirmation is required';

  @override
  String get confirmPasswordMismatchError =>
      'Confirmation does not match the new password';

  @override
  String get savePasswordButton => 'Save New Password';

  @override
  String get passwordChangeSuccess => 'Password changed successfully';

  @override
  String get wrongOldPasswordError => 'Old password is incorrect';

  @override
  String get weakPasswordError =>
      'New password is too weak, minimum 6 characters';

  @override
  String get requiresRecentLoginError =>
      'Your session has expired, please log in again';

  @override
  String get tooManyRequestsError => 'Too many attempts, try again later';

  @override
  String passwordChangeGenericError(String error) {
    return 'Failed to change password: $error';
  }

  @override
  String get otherProviderNotice =>
      'Your account is signed in with another provider (e.g. Google), so there\'s no password to change here.';
}
