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

  @override
  String get greetingMorning => 'Good Morning';

  @override
  String get greetingAfternoon => 'Good Afternoon';

  @override
  String get greetingEvening => 'Good Evening';

  @override
  String get dashboardSubtitle => 'Here\'s a summary of your laundry business';

  @override
  String get revenueThisMonthLabel => 'Revenue this month';

  @override
  String get autoSyncLabel => 'Auto-synced';

  @override
  String get customersLabel => 'Customers';

  @override
  String get activeOrdersLabel => 'Active orders';

  @override
  String get setupBranchTitle => 'Start Branch Setup';

  @override
  String get setupBranchSubtitle => 'Complete branch profile & address';

  @override
  String get setupEmployeeTitle => 'Add Employees';

  @override
  String get setupEmployeeSubtitle => 'Invite staff to manage orders';

  @override
  String get setupServiceTitle => 'Add Services';

  @override
  String get setupServiceSubtitle => 'Set wash types & prices';

  @override
  String get completeBranchSetupTitle => 'Complete Branch Setup';

  @override
  String setupStepsProgress(int done, int total) {
    return '$done of $total steps completed';
  }

  @override
  String get newOrderAction => 'New\nOrder';

  @override
  String get newEmployeeAction => 'New\nEmployee';

  @override
  String get manageServicesAction => 'Manage\nServices';

  @override
  String get pickupDeliveryAction => 'Pickup &\nDelivery';

  @override
  String get reportAction => 'Report';

  @override
  String get settingsAction => 'Settings';

  @override
  String quotaLimitReached(String label) {
    return 'The Starter plan quota limit for $label has been reached! Please upgrade.';
  }

  @override
  String get weeklyRevenueTitle => 'Weekly Revenue';

  @override
  String get sevenDaysLabel => '7 days';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get mainOrdersTitle => 'Main Orders';

  @override
  String get viewAllLabel => 'View All';

  @override
  String get filterAll => 'All';

  @override
  String get filterProcessing => 'Processing';

  @override
  String get filterReady => 'Ready for Pickup';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get noOrdersData => 'No order data yet.';

  @override
  String get noOrdersForStatus => 'No orders with this status.';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusProcessing => 'In Progress';

  @override
  String get defaultCustomerName => 'General Customer';

  @override
  String orderDetailSummary(String count, String amount) {
    return '$count items · Rp $amount';
  }
}
