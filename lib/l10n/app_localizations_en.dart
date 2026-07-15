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

  @override
  String get serviceNameLabel => 'Service Name';

  @override
  String get serviceNameHint => 'Example: Regular Wash & Iron';

  @override
  String get serviceNameError => 'Service name cannot be empty';

  @override
  String get serviceDescriptionLabel => 'Description (Optional)';

  @override
  String get serviceDescriptionHint =>
      'Example: Washing, machine drying, and neat ironing.';

  @override
  String get pricingMethodLabel => 'Pricing Method';

  @override
  String get pricePerKgLabel => 'Price per Kg (Rp)';

  @override
  String get pricePerItemLabel => 'Price per Item (Rp)';

  @override
  String get priceHint => 'Example: 10000';

  @override
  String get priceEmptyError => 'Price cannot be empty';

  @override
  String get priceInvalidError => 'Enter a valid number';

  @override
  String get durationHint => 'Example: 24';

  @override
  String get createServiceAppBarTitle => 'Add New Service';

  @override
  String get createServiceSectionTitle => 'Laundry Service Details';

  @override
  String get createServiceSectionSubtitle =>
      'Enter the details of the laundry service package you offer.';

  @override
  String get pricingTypeKgFull => 'Per Kilogram (Kg)';

  @override
  String get pricingTypeItemFull => 'Per Item';

  @override
  String get durationLabelFull => 'Estimated Turnaround (In Hours)';

  @override
  String get durationEmptyErrorFull => 'Estimated turnaround cannot be empty';

  @override
  String get durationInvalidErrorFull => 'Enter a valid whole number of hours';

  @override
  String get saveServiceButton => 'Save Service';

  @override
  String get sessionNotFoundError =>
      'User session not found. Please log in again.';

  @override
  String get companyNotSetupError =>
      'Company not created yet. Please complete the onboarding (company setup) first.';

  @override
  String get addServiceSuccess => 'Service added successfully!';

  @override
  String addServiceError(String error) {
    return 'Failed to add service: $error';
  }

  @override
  String get servicesListAppBarTitle => 'Service List';

  @override
  String get servicesListSubtitle =>
      'Manage wash types, prices, and estimated durations';

  @override
  String get newServiceFab => 'New Service';

  @override
  String get emptyServicesTitle => 'No services registered yet';

  @override
  String get emptyServicesSubtitle =>
      'Tap the \"New Service\" button to\nadd your first wash type';

  @override
  String get errorStateTitle => 'An error occurred';

  @override
  String get editServiceMenuItem => 'Edit Service';

  @override
  String get deactivateMenuItem => 'Deactivate';

  @override
  String get activateMenuItem => 'Activate';

  @override
  String get deleteMenuItem => 'Delete Permanently';

  @override
  String serviceActivatedSnackbar(String name) {
    return 'Service \"$name\" reactivated';
  }

  @override
  String serviceDeactivatedSnackbar(String name) {
    return 'Service \"$name\" deactivated';
  }

  @override
  String toggleStatusError(String error) {
    return 'Failed to change status: $error';
  }

  @override
  String get deleteConfirmTitle => 'Delete Permanently?';

  @override
  String deleteConfirmContent(String name) {
    return 'Service \"$name\" will be permanently deleted from the database and CANNOT be recovered.\n\nIf this service is or has been used in an order, it\'s recommended to use the \"Deactivate\" option instead so old order history still displays correctly.';
  }

  @override
  String get deletePermanentButton => 'Delete Permanently';

  @override
  String deleteServiceSuccess(String name) {
    return 'Service \"$name\" permanently deleted';
  }

  @override
  String deleteServiceError(String error) {
    return 'Failed to delete service: $error';
  }

  @override
  String durationInHours(int hours) {
    return '$hours hrs';
  }

  @override
  String get activeStatusChip => 'Active';

  @override
  String get inactiveStatusChip => 'Inactive';

  @override
  String pricePerKgValue(String price) {
    return 'Rp $price / Kg';
  }

  @override
  String pricePerItemValue(String price) {
    return 'Rp $price / Item';
  }

  @override
  String get editServiceSheetTitle => 'Edit Service';

  @override
  String get editServiceSheetSubtitle =>
      'Update the details of this laundry service';

  @override
  String get pricingTypeKgShort => 'Per Kg';

  @override
  String get pricingTypeItemShort => 'Per Item';

  @override
  String get durationLabelShort => 'Estimated Turnaround (Hours)';

  @override
  String get durationEmptyErrorShort => 'Estimated duration cannot be empty';

  @override
  String get durationInvalidErrorShort => 'Enter a valid whole number';

  @override
  String get activeServiceSwitchTitle => 'Service Active';

  @override
  String get activeServiceSwitchSubtitle =>
      'Turn off if this service is not currently offered';

  @override
  String get savingButtonLabel => 'Saving...';

  @override
  String get saveChangesSuccess => 'Changes saved successfully';

  @override
  String saveChangesError(String error) {
    return 'Failed to save changes: $error';
  }

  @override
  String get customersTitle => 'Customers';

  @override
  String get customersSubtitle => 'Manage your laundry customer data';

  @override
  String get newCustomerButton => 'New';

  @override
  String get searchCustomerHint => 'Search by name or phone number...';

  @override
  String get customerActiveLabel => 'Active';

  @override
  String get customerInactiveLabel => 'Inactive';

  @override
  String get totalCustomersLabel => 'Total Customers';

  @override
  String get totalTransactionsLabel => 'Total Transactions';

  @override
  String get emptyCustomersTitle => 'No customers yet';

  @override
  String get emptyCustomersSubtitle => 'Add a new customer to get started';

  @override
  String get addCustomerButton => 'Add Customer';

  @override
  String ordersCountLabel(int count) {
    return '$count orders';
  }

  @override
  String get neverOrderedLabel => 'Never ordered';

  @override
  String get justNowLabel => 'Just now';

  @override
  String hoursAgoLabel(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgoLabel(int days) {
    return '${days}d ago';
  }

  @override
  String get editCustomerComingSoon =>
      'Navigate to Edit Customer will be added';

  @override
  String get editCustomerMenuItem => 'Edit Customer';

  @override
  String get deleteCustomerMenuItem => 'Delete Customer';

  @override
  String get deleteCustomerConfirmTitle => 'Delete Customer?';

  @override
  String deleteCustomerConfirmContent(String name) {
    return 'Customer data \"$name\" will be permanently deleted. This action cannot be undone.';
  }

  @override
  String get deleteButton => 'Delete';

  @override
  String get deleteCustomerSuccessTesting =>
      'Customer deleted successfully (Testing mode)';

  @override
  String get customerDetailTitle => 'Customer Detail';

  @override
  String joinedSinceLabel(String date) {
    return 'Joined since $date';
  }

  @override
  String get activeCustomerLabel => 'Active Customer';

  @override
  String get callButton => 'Call';

  @override
  String get openingPhoneApp => 'Opening phone app...';

  @override
  String get whatsappButton => 'WhatsApp';

  @override
  String get openingWhatsapp => 'Opening WhatsApp...';

  @override
  String get totalOrdersLabel => 'Total Orders';

  @override
  String get totalSpentLabel => 'Total Spent';

  @override
  String get contactInfoTitle => 'Contact Information';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get addressLabel => 'Address';

  @override
  String get orderHistoryTitle => 'Order History';

  @override
  String get viewAllOrdersComingSoon =>
      'Navigate to full order history will be added';

  @override
  String get noOrderHistoryLabel => 'No order history yet';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusProcessing => 'Processing';

  @override
  String get orderStatusCompleted => 'Completed';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String orderItemCountLabel(int count) {
    return '· $count items';
  }

  @override
  String get newCustomerHeaderTitle => 'New Customer';

  @override
  String get newCustomerHeaderSubtitle =>
      'Complete the customer data to add them to the system';

  @override
  String get customerNameHint => 'Enter customer name';

  @override
  String get customerNameEmptyError => 'Customer name cannot be empty';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get phoneNumberHint => 'Example: 081234567890';

  @override
  String get phoneNumberEmptyError => 'Phone number cannot be empty';

  @override
  String get phoneNumberInvalidError => 'Invalid phone number format';

  @override
  String get optionalFieldSuffix => ' (Optional)';

  @override
  String get customerEmailHint => 'Enter customer email';

  @override
  String get emailInvalidError => 'Invalid email format';

  @override
  String get customerAddressHint => 'Enter customer address';

  @override
  String get notesLabel => 'Notes';

  @override
  String get notesHint => 'Special notes for this customer';

  @override
  String get saveCustomerButton => 'Save Customer';

  @override
  String get addCustomerSuccessTesting => 'Customer added successfully!';

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String addCustomerError(String error) {
    return 'Failed to add customer: $error';
  }

  @override
  String loadCustomersError(Object error) {
    return 'Failed to load customers: $error';
  }
}
