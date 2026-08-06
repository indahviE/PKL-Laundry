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
  String get notifPrefOrderStatusTitle => 'Order status';

  @override
  String get notifPrefOrderStatusSubtitle =>
      'Laundry updates, ready for pickup, etc.';

  @override
  String get notifPrefPromoTitle => 'Promos and discounts';

  @override
  String get notifPrefPromoSubtitle => 'Special offers for you';

  @override
  String get notifPrefReminderTitle => 'Reminders';

  @override
  String get notifPrefReminderSubtitle => 'Pickup and delivery schedule';

  @override
  String get notifPrefChatCsTitle => 'Chat and CS';

  @override
  String get notifPrefChatCsSubtitle => 'Replies from customer service';

  @override
  String notifPrefSaveError(String error) {
    return 'Failed to save preference: $error';
  }

  @override
  String get notificationsPanelTitle => 'New Orders';

  @override
  String pendingOrdersNotifSubtitle(int count) {
    return '$count orders waiting to be processed';
  }

  @override
  String get noNewNotifications => 'No new notifications';

  @override
  String get noNewNotificationsSubtitle =>
      'New pending orders will show up here';

  @override
  String get languageTitle => 'Language';

  @override
  String get sectionCsTeam => 'CS Team';

  @override
  String get manageCsChatTitle => 'Manage CS Chat';

  @override
  String get manageCsChatSubtitle => 'Reply to conversations from all users';

  @override
  String get sectionOther => 'Others';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpSubtitle => 'FAQ & support';

  @override
  String get helpSectionGeneralTitle => 'General Questions';

  @override
  String get helpSectionAppGuideTitle => 'App Guide';

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
  String get activeBranchLabel => 'ACTIVE BRANCH';

  @override
  String get allBranchesLabel => 'All Branches';

  @override
  String get selectBranchTitle => 'Select Branch';

  @override
  String get searchBranchHint => 'Search branch name...';

  @override
  String get noBranchesRegistered => 'No branches registered yet';

  @override
  String get branchNotFoundSearch => 'Branch not found';

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
  String get reportsTitle => 'Reports';

  @override
  String get reportsSubtitle => 'Monitor your laundry business performance';

  @override
  String get periodToday => 'Today';

  @override
  String get periodThisWeek => 'This Week';

  @override
  String weekNumberLabel(int index) {
    return 'Week $index';
  }

  @override
  String weekNumberRangeLabel(int index, String start, String end) {
    return 'Week $index ($start - $end)';
  }

  @override
  String get periodThisMonth => 'This Month';

  @override
  String get periodThisYear => 'This Year';

  @override
  String get printButtonShort => 'Print';

  @override
  String get printReportButton => 'Print Report';

  @override
  String get generatingPdfButton => 'Generating PDF...';

  @override
  String get growthThisPeriodLabel => 'This Period\'s Growth';

  @override
  String get growthUpLabel => 'Up';

  @override
  String get growthDownLabel => 'Down';

  @override
  String get fromPreviousPeriodLabel => 'from previous period';

  @override
  String get revenueTrendTitle => 'Revenue Trend';

  @override
  String get last7DaysLabel => 'Last 7 days';

  @override
  String get revenuePerServiceTitle => 'Revenue per Service';

  @override
  String get noOrdersThisPeriod => 'No order data for this period yet.';

  @override
  String get completionRateLabel => 'Completion Rate';

  @override
  String get ofAllOrdersLabel => 'of all orders';

  @override
  String exportPdfError(String error) {
    return 'Failed to generate PDF: $error';
  }

  @override
  String get pdfReportTitle => 'Laundry Business Report';

  @override
  String pdfHeaderInfo(String period, String branch, String date) {
    return 'Period: $period   |   Branch: $branch   |   Generated: $date';
  }

  @override
  String get pdfSummaryTitle => 'Summary';

  @override
  String get totalRevenueLabel => 'Total Revenue';

  @override
  String get newCustomersLabel => 'New Customers';

  @override
  String get avgOrderLabel => 'Average Order';

  @override
  String get growthLabel => 'Growth';

  @override
  String growthValueTemplate(String rate) {
    return '+$rate% from previous period';
  }

  @override
  String get pdfWeeklyTrendTitle => 'Revenue Trend (Last 7 days)';

  @override
  String get pdfServiceColumn => 'Service';

  @override
  String get pdfOrdersColumn => 'Orders';

  @override
  String get pdfRevenueColumn => 'Revenue';

  @override
  String get pdfPercentageColumn => 'Percentage';

  @override
  String pdfPageOfPages(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get unnamedBranchLabel => 'Unnamed Branch';

  @override
  String get otherServiceLabel => 'Other';

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
  String get manageBranchAction => 'Manage\nBranch';

  @override
  String get manageEmployeesAction => 'Manage\nEmployees';

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
  String get serviceTypeSectionLabel => 'Service Type';

  @override
  String get pricingTypeKgChipLabel => 'By Weight';

  @override
  String get pricingTypeItemChipLabel => 'By Item';

  @override
  String get pricingTypeExpressLabel => 'Express';

  @override
  String get pricePerKgFieldLabel => 'Price per Kg';

  @override
  String get pricePerItemFieldLabel => 'Price per Item';

  @override
  String get baseFeeLabel => 'Base Price';

  @override
  String get expressFeeLabel => 'Extra Express Fee';

  @override
  String get minWeightLabel => 'Minimum Weight (Kg)';

  @override
  String get estimatedDurationSectionLabel => 'Estimated Duration';

  @override
  String get durationUnitHours => 'Hours';

  @override
  String get durationUnitDays => 'Days';

  @override
  String durationChipHoursLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Hours',
      one: '$count Hour',
    );
    return '$_temp0';
  }

  @override
  String durationChipDaysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Days',
      one: '$count Day',
    );
    return '$_temp0';
  }

  @override
  String get availableAtBranchesLabel => 'Available at Branches';

  @override
  String get noBranchesForServiceHint =>
      'No branches yet. Add a branch first from the Branches menu.';

  @override
  String get noBranchSelectedLabel => 'No branch selected yet';

  @override
  String branchesSelectedCountLabel(int count, int total) {
    return '$count of $total branches selected';
  }

  @override
  String get selectAllLabel => 'Select All';

  @override
  String get deselectAllLabel => 'Deselect All';

  @override
  String get loadBranchesFailedLabel => 'Failed to load branches.';

  @override
  String get searchServiceHint => 'Search service name...';

  @override
  String get noMatchingServicesTitle => 'No matching services';

  @override
  String get tryDifferentKeywordFilterHint =>
      'Try a different keyword or filter';

  @override
  String get emptyBranchSelectionMeansAllHint =>
      'Leave empty to be available at all branches.';

  @override
  String get sessionNotFoundError =>
      'User session not found. Please log in again.';

  @override
  String get companyNotSetupError =>
      'Company not set up yet. Please complete onboarding first.';

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
  String get unitPerKgSuffix => '/kg';

  @override
  String get unitPerItemSuffix => '/item';

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
  String get phoneLabel => 'Phone Number';

  @override
  String get customerAddressLabel => 'Full Address';

  @override
  String get orderHistoryTitle => 'Order History';

  @override
  String get notifyReadyForPickupButtonLabel => 'Notify Customer It\'s Ready';

  @override
  String get viewAllOrdersComingSoon =>
      'Navigate to full order history will be added';

  @override
  String get noOrderHistoryLabel => 'No order history yet';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get customerOrderStatusConfirmed => 'Confirmed';

  @override
  String get orderStatusInProgress => 'In Progress';

  @override
  String get customerOrderStatusProcessing => 'Processing';

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
  String get customerPhoneNumberLabel => 'Phone Number';

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

  @override
  String get laundriesTitle => 'Branches';

  @override
  String get laundriesSubtitle => 'Manage your laundry branches';

  @override
  String get searchLaundryHint => 'Search by branch name, code, or city...';

  @override
  String get filterAllLaundries => 'All';

  @override
  String get filterActiveLaundries => 'Active';

  @override
  String get filterInactiveLaundries => 'Inactive';

  @override
  String get totalLaundriesLabel => 'Total Branches';

  @override
  String get activeLaundriesLabel => 'Active Branches';

  @override
  String get emptyLaundriesTitle => 'No branches yet';

  @override
  String get emptyLaundriesSubtitle => 'Add a new branch to get started';

  @override
  String get newBranchButton => 'New Branch';

  @override
  String get addBranchButton => 'Add Branch';

  @override
  String get loadLaundriesError => 'Failed to load branch data';

  @override
  String get addBranchTitle => 'Add New Branch';

  @override
  String get editBranchTitle => 'Edit Branch Data';

  @override
  String get addBranchInfo =>
      'The system will automatically validate branch quota limits according to your subscription plan.';

  @override
  String get editBranchInfo =>
      'Changes will be saved directly. Subscription limits do not apply to editing existing branches.';

  @override
  String get ownerCompanyLabel => 'Owner Company';

  @override
  String get registerCompanyFirst => '+ Register Company First';

  @override
  String get branchNameLabel => 'Branch Name';

  @override
  String get branchCodeLabel => 'Branch Code';

  @override
  String get branchFullAddressLabel => 'Alamat Lengkap';

  @override
  String get cityLabel => 'City';

  @override
  String get provinceLabel => 'Province';

  @override
  String get branchContactPhoneLabel => 'Nomor Telepon';

  @override
  String get branchEmailOptionalLabel => 'Branch Email (Optional)';

  @override
  String get managerOptionalLabel => 'Branch Manager (Optional)';

  @override
  String get noEmployeeDataInfo =>
      'No employee data yet. Manager can be assigned later.';

  @override
  String get dailyCapacityLabel => 'Daily Capacity (Orders Count)';

  @override
  String get mapLocationLabel => 'Map Location Point (Optional)';

  @override
  String get operatingHoursLabel => 'Operating Hours';

  @override
  String get useSameHoursLabel => 'Use same hours for all days';

  @override
  String get everyDayLabel => 'Every Day';

  @override
  String get activeStatusLabel => 'Active Branch Status';

  @override
  String get saveBranchButton => 'Save Branch Data';

  @override
  String get updateBranchButton => 'Save Changes';

  @override
  String get branchNameEmpty => 'Branch name cannot be empty';

  @override
  String get branchCodeEmpty => 'Branch code cannot be empty';

  @override
  String get addressEmpty => 'Address is required';

  @override
  String get fieldRequired => 'Required';

  @override
  String get phoneEmpty => 'Phone number is required';

  @override
  String get capacityEmpty => 'Capacity is required';

  @override
  String get quotaReachedTitle => 'Quota Limit Reached';

  @override
  String get quotaReachedContent =>
      'You have reached the maximum branch limit for your current subscription plan.';

  @override
  String get upgradePlanButton => 'Upgrade Plan';

  @override
  String get branchAddSuccess => 'Laundry branch added successfully!';

  @override
  String get branchUpdateSuccess => 'Branch changes saved successfully!';

  @override
  String get deleteBranchTitle => 'Delete Branch?';

  @override
  String deleteBranchConfirm(Object name) {
    return 'Branch \"$name\" will be permanently deleted. This action cannot be undone.';
  }

  @override
  String get contactInfoSection => 'Contact Information';

  @override
  String get capacityLocationSection => 'Capacity & Location';

  @override
  String get createdLabel => 'Created';

  @override
  String get updatedLabel => 'Updated';

  @override
  String get todayLabel => 'Today';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String cardCapacityLabel(Object capacity) {
    return 'Capacity $capacity';
  }

  @override
  String get selectCompanyHint => 'Select company';

  @override
  String get branchNameHint => 'e.g. Merdeka Branch';

  @override
  String get branchCodeHint => 'e.g. JKT001';

  @override
  String get branchAddressHint => 'e.g. Jl. Merdeka No. 123';

  @override
  String get cityHint => 'Jakarta';

  @override
  String get provinceHint => 'DKI Jakarta';

  @override
  String get branchPhoneLabel => 'Branch Phone Number';

  @override
  String get branchPhoneHint => 'e.g. +6281234567890';

  @override
  String get branchEmailHint => 'e.g. branch@laundry.com';

  @override
  String get selectManagerHint => 'Select branch manager';

  @override
  String get capacityHint => 'e.g. 100';

  @override
  String get latitudeHint => 'Latitude';

  @override
  String get longitudeHint => 'Longitude';

  @override
  String get companyRequiredValidator => 'Company must be selected';

  @override
  String get defaultCompanyName => 'Unnamed Company';

  @override
  String get defaultEmployeeName => 'Employee';

  @override
  String get branchDataNotFoundError => 'Branch data not found.';

  @override
  String loadBranchDataError(String error) {
    return 'Failed to load branch data: $error';
  }

  @override
  String get companyNotSelectedWarning =>
      'Company not selected or not created yet!';

  @override
  String get userSessionExpiredError => 'User session expired.';

  @override
  String saveBranchError(String error) {
    return 'Failed to save branch data: $error';
  }

  @override
  String get branchDetailTitle => 'Branch Detail';

  @override
  String deleteBranchConfirmDetail(String name, String code) {
    return 'Branch \"$name\" ($code) will be permanently deleted. This action cannot be undone.';
  }

  @override
  String branchDeleteSuccess(String name) {
    return 'Branch \"$name\" deleted successfully.';
  }

  @override
  String deleteBranchError(String error) {
    return 'Failed to delete branch: $error';
  }

  @override
  String get addressShortLabel => 'Address';

  @override
  String get phoneShortLabel => 'Phone';

  @override
  String get capacityShortLabel => 'Capacity';

  @override
  String get coordinatesLabel => 'Coordinates';

  @override
  String get notSetLabel => 'Not set';

  @override
  String get branchNotFoundTitle => 'Branch not found';

  @override
  String get branchNotFoundSubtitle =>
      'The branch may have been deleted or the id is invalid';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String branchListTitle(int count) {
    return 'Branch List ($count)';
  }

  @override
  String get hideLabel => 'Hide';

  @override
  String openTodayStatus(String open, String close) {
    return 'Open • $open - $close';
  }

  @override
  String get closedTemporarilyLabel => 'Temporarily Closed';

  @override
  String get dayOffLabel => 'Day Off';

  @override
  String get totalStaffLabel => 'Total Staff';

  @override
  String get openTodayLabel => 'Open Today';

  @override
  String staffAtThisBranchLabel(int count) {
    return 'Staff at This Branch ($count)';
  }

  @override
  String get noStaffAtBranch => 'No employees assigned to this branch yet.';

  @override
  String get resignedLabel => 'Resigned';

  @override
  String get deactivateBranchTitle => 'Deactivate Branch?';

  @override
  String get deactivateBranchContent =>
      'This branch will be marked as temporarily closed and will not accept new orders.';

  @override
  String get activeStatusSubtitle => 'Turn off to mark as temporarily closed';

  @override
  String get generalInfoSection => 'General Information';

  @override
  String get deactivateBranchButton => 'Deactivate Branch';

  @override
  String get ordersListSubtitle => 'Kelola semua pesanan laundry Anda';

  @override
  String get newOrderButtonLabel => 'New';

  @override
  String get searchOrderHint => 'Search order...';

  @override
  String get orderWaitingStatus => 'Menunggu';

  @override
  String get orderProcessingStatus => 'Diproses';

  @override
  String get orderRetryButtonLabel => 'Try Again';

  @override
  String get orderSessionNotFoundError =>
      'User session not found. Please log in again.';

  @override
  String get createOrderAppBarTitle => 'Create New Order';

  @override
  String get createOrderSectionTitle => 'Detail Pesanan';

  @override
  String get createOrderSectionSubtitle => 'Isi informasi pesanan';

  @override
  String get selectCustomerLabel => 'Pelanggan';

  @override
  String get selectCustomerHint => 'Select customer';

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
  String get taxLabel => 'Tax';

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
  String get saveOrderButton => 'Save Order';

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
  String get closeButton => 'Close';

  @override
  String get selectOrderTitle => 'Select Order';

  @override
  String get noOrdersWaitingPickupHint => 'No orders waiting to be picked up.';

  @override
  String get noOrdersReadyDeliveryHint => 'No orders ready to be delivered.';

  @override
  String get customerFallbackLabel => 'Customer';

  @override
  String get orderNotFoundError => 'Order not found';

  @override
  String loadOrderError(String error) {
    return 'Failed to load order: $error';
  }

  @override
  String get loadingOrderLabel => 'Loading order...';

  @override
  String get schedulingDeliveryBadgeLabel => 'Scheduling Delivery';

  @override
  String get scheduleDeliveryScreenTitle => 'Schedule Pickup/Delivery';

  @override
  String get pickupModeLabel => 'Pickup';

  @override
  String get deliveryModeLabel => 'Delivery';

  @override
  String get newCustomerButtonShort => 'New';

  @override
  String get autoFilledScheduleHint =>
      'Date & time auto-filled from when the order was created';

  @override
  String get selectBranchLabel => 'Select Branch';

  @override
  String get noActiveBranchesScheduleHint =>
      'No active branches yet. Add a branch first from the Branches menu.';

  @override
  String get createOrderSelectBranchHint => 'Select branch';

  @override
  String get useMapLocationButton => 'Use map location';

  @override
  String get mapLocationComingSoon => 'Map location picker is coming soon';

  @override
  String get addressFieldExampleHint => 'e.g. 123 Main St, South Jakarta...';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get selectCourierLabel => 'Select Courier';

  @override
  String get noCourierEmployeeScheduleHint =>
      'No employees with the \"Courier\" position yet. You can still save the schedule without picking a courier.';

  @override
  String get searchCourierHint => 'Search nearest courier...';

  @override
  String get courierListHint =>
      'Active employees with the \"Courier\" position are shown in this list.';

  @override
  String get additionalNotesLabel => 'Additional Notes (Optional)';

  @override
  String get notesExampleHint => 'Example: Leave with security, black gate...';

  @override
  String get scheduleSummaryTitle => 'SCHEDULE SUMMARY';

  @override
  String get selectOrSearchOrderLabel => 'Select or Search Order';

  @override
  String get addressNotSetLabel => 'Address not set';

  @override
  String get notScheduledLabel => 'Not scheduled';

  @override
  String modeWithBranchLabel(String mode, String branch) {
    return 'Mode: $mode • $branch';
  }

  @override
  String modeOnlyLabel(String mode) {
    return 'Mode: $mode';
  }

  @override
  String get saveScheduleButton => 'Save Schedule';

  @override
  String get selectOrderRequiredError => 'Please select an order first';

  @override
  String get addressRequiredError => 'Address is required';

  @override
  String get dateTimeRequiredError => 'Date and time must be selected';

  @override
  String get scheduleSaveSuccess => 'Schedule saved successfully';

  @override
  String scheduleSaveError(String error) {
    return 'Failed to save schedule: $error';
  }

  @override
  String get waitingPickupStatus => 'Waiting for pickup';

  @override
  String get readyDeliveryStatus => 'Ready for delivery';

  @override
  String get readyPickupStatus => 'Ready for pickup';

  @override
  String get waitingConfirmationStatus => 'Awaiting confirmation';

  @override
  String get confirmedStatus => 'Confirmed';

  @override
  String get inProgressStatus => 'In progress';

  @override
  String markedPickedUpSnackbar(String orderNumber) {
    return '$orderNumber marked as picked up';
  }

  @override
  String markedDeliveredSnackbar(String orderNumber) {
    return '$orderNumber marked as delivered';
  }

  @override
  String markedDeliveredCompletedSnackbar(String orderNumber) {
    return '$orderNumber marked as delivered & completed';
  }

  @override
  String genericUpdateError(String error) {
    return 'Failed to update: $error';
  }

  @override
  String get addScheduleButton => 'Add Schedule';

  @override
  String get pickupDeliveryTitle => 'Pickup & Delivery';

  @override
  String get pickupDeliverySubtitle => 'Manage pickup, delivery & self-service';

  @override
  String get searchOrderCustomerHint => 'Search customer name or order no...';

  @override
  String get filterNeedsPickup => 'Needs pickup';

  @override
  String get filterNeedsDelivery => 'Needs delivery';

  @override
  String get filterSelfService => 'Self-service';

  @override
  String get filterOthers => 'Others';

  @override
  String get statNeedsPickupTitle => 'Needs Pickup';

  @override
  String get statReadyDeliveryTitle => 'Ready to Deliver';

  @override
  String get statSelfServiceTitle => 'Self-Service';

  @override
  String get noOrdersTitle => 'No orders';

  @override
  String get noOrdersFilterSubtitle => 'No orders match this filter yet';

  @override
  String get selectScheduleModeSubtitle => 'Choose which schedule to create';

  @override
  String get schedulePickupTileTitle => 'Schedule Pickup';

  @override
  String get schedulePickupTileSubtitle => 'For orders waiting to be picked up';

  @override
  String get scheduleDeliveryTileTitle => 'Schedule Delivery';

  @override
  String get scheduleDeliveryTileSubtitle => 'For orders ready to be delivered';

  @override
  String get selectServiceTitle => 'Select Service';

  @override
  String get noActiveServicesHint => 'No active services yet.';

  @override
  String get dpAmountRequiredError =>
      'Please enter a down payment amount first';

  @override
  String get dpAmountTooLargeError =>
      'Down payment must be less than the total. Choose \"Paid in Full\" if paying the full amount.';

  @override
  String get minOneItemError => 'Add at least 1 item';

  @override
  String weightRequiredError(String itemName) {
    return 'Enter the weight (kg) for \"$itemName\"';
  }

  @override
  String confirmFailedError(String error) {
    return 'Failed to confirm: $error';
  }

  @override
  String get cashPaymentLabel => 'Cash';

  @override
  String get bankTransferLabel => 'Bank Transfer';

  @override
  String get debitCardLabel => 'Debit Card';

  @override
  String get eWalletLabel => 'E-Wallet';

  @override
  String get paymentMethodLabel => 'Payment Method';

  @override
  String get transferPaymentPendingNotice =>
      'Payment status will be \"Unpaid\" until manually confirmed on the order detail page.';

  @override
  String get instantPaymentNotice =>
      'This method is considered paid immediately.';

  @override
  String get fullPaymentLabel => 'Paid in Full';

  @override
  String get partialPaymentLabel => 'Down Payment (Partial)';

  @override
  String get dpAmountLabel => 'Down Payment Amount';

  @override
  String get dpAmountHint => 'Example: 20000';

  @override
  String get remainingBalanceHint =>
      'The remaining balance can be settled later from the order detail page.';

  @override
  String get confirmPickupTitle => 'Confirm Pickup';

  @override
  String confirmPickupSubtitle(String customerName, String orderNumber) {
    return 'Record the laundry items & weight for $customerName ($orderNumber)';
  }

  @override
  String get laundryItemsLabel => 'Laundry Items';

  @override
  String get addButtonLabel => 'Add';

  @override
  String get noItemsAddHint => 'No items yet. Tap \"Add\" to pick a service.';

  @override
  String get confirmPickedUpButton => 'Confirm Picked Up';

  @override
  String get confirmDeliveryTitle => 'Confirm Delivery';

  @override
  String confirmDeliverySubtitle(String customerName, String orderNumber) {
    return 'Deliver laundry for $customerName ($orderNumber)';
  }

  @override
  String get assignedCourierLabel => 'Assigned Courier (Optional)';

  @override
  String get noCourierEmployeeDeliverHint =>
      'No employees with the \"Courier\" position yet. You can still mark this order as delivered.';

  @override
  String get selectCourierHint => 'Select courier';

  @override
  String get confirmDeliveredButton => 'Confirm Delivered';

  @override
  String get pickupTypeLabel => 'Pickup';

  @override
  String get walkInTypeLabel => 'Walk-in';

  @override
  String get deliveryTypeLabel => 'Delivery';

  @override
  String get selfPickupTypeLabel => 'Self-Pickup';

  @override
  String get genericCourierLabel => 'Courier';

  @override
  String get courierNotAssignedLabel => 'Courier not assigned';

  @override
  String plannedPickupLabel(String date) {
    return 'Pickup planned: $date';
  }

  @override
  String selfServicePickedUpLabel(String date) {
    return 'Picked up by customer: $date';
  }

  @override
  String deliveredAtLabel(String date) {
    return 'Delivered: $date';
  }

  @override
  String pickedUpFromCustomerLabel(String date) {
    return 'Picked up: $date';
  }

  @override
  String get markPickedUpButton => 'Mark as Picked Up';

  @override
  String get markSelfPickedUpButton => 'Mark as Collected';

  @override
  String get markDeliveredButton => 'Mark as Delivered';

  @override
  String get employeeNotFoundError => 'Employee data not found.';

  @override
  String employeeLoadError(String error) {
    return 'Failed to load employee data: $error';
  }

  @override
  String employeeGenericError(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get branchNotSelectedWarning =>
      'Branch not selected or not yet created!';

  @override
  String get sessionExpiredError => 'Session has expired.';

  @override
  String get branchNotLinkedWarning =>
      'Selected branch is not linked to company data. Please check the branch data again.';

  @override
  String get quotaLimitReachedTitle => 'Quota Limit Reached';

  @override
  String get quotaLimitReachedContent =>
      'The number of employees has reached the maximum quota of your current subscription plan. Please upgrade your plan.';

  @override
  String get employeeUpdateSuccess => 'Employee data updated successfully!';

  @override
  String get employeeAddSuccess => 'Employee added successfully!';

  @override
  String employeeSaveError(String error) {
    return 'Failed to save employee data: $error';
  }

  @override
  String get deactivateEmployeeTitle => 'Deactivate Employee';

  @override
  String get deactivateEmployeeConfirm =>
      'Are you sure you want to deactivate this employee? Past transaction history will remain safe.';

  @override
  String get deactivateEmployeeConfirmAlt =>
      'Are you sure you want to deactivate this employee\'s active status? Past transaction history will remain safe.';

  @override
  String get yesDeactivateButton => 'Yes, Deactivate';

  @override
  String get employeeDeactivatedSuccess => 'Employee has been deactivated.';

  @override
  String employeeDeactivateError(String error) {
    return 'Failed to deactivate employee: $error';
  }

  @override
  String get editEmployeeTitle => 'Edit Employee Data';

  @override
  String get addEmployeeTitle => 'Add Employee';

  @override
  String get additionalDetailsDivider => 'ADDITIONAL DETAILS';

  @override
  String get editEmployeeInfoBanner =>
      'Changes will be saved immediately to this employee\'s data.';

  @override
  String get addEmployeeInfoBanner =>
      'The system will automatically validate your subscription plan quota before saving the employee data.';

  @override
  String get fullNameHint => 'e.g. Siti Aminah';

  @override
  String get employeeNameRequiredError => 'Employee name is required';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get phoneNumberRequiredError => 'Phone number is required';

  @override
  String get emailOptionalLabel => 'Email (Optional)';

  @override
  String get invalidEmailFormatError => 'Invalid email format';

  @override
  String get addressLabel => 'Address';

  @override
  String get addressHint => 'Enter complete home address';

  @override
  String get roleLabel => 'Role / Position';

  @override
  String get selectPositionHint => 'Select Position';

  @override
  String get positionRequiredError => 'Position must be selected';

  @override
  String get assignedBranchLabel => 'Assigned Branch';

  @override
  String get registerNewBranchFirstButton => '+ Register a New Branch First';

  @override
  String get selectBranchHint => 'Select Branch';

  @override
  String get branchRequiredError => 'Assigned branch must be selected';

  @override
  String get hireDateLabel => 'Hire Date';

  @override
  String get appAccessTitle => 'App Access';

  @override
  String get appAccessSubtitle => 'Grant app login access';

  @override
  String get employeeStatusTitle => 'Employee Status';

  @override
  String employeeStatusCurrent(String status) {
    return 'Current status: $status';
  }

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get employeeCodeLabel => 'Employee Code';

  @override
  String get employeeCodeHint => 'e.g. EMP01, KSR02';

  @override
  String get employeeCodeRequiredError => 'Employee code cannot be empty';

  @override
  String get baseSalaryLabel => 'Base Salary (IDR)';

  @override
  String get baseSalaryRequiredError => 'Base salary is required';

  @override
  String get commissionPerTransactionLabel => 'Commission per Transaction (%)';

  @override
  String get commissionHint => 'e.g. 5.0';

  @override
  String get employeePermissionsTitle => 'Employee Feature Permissions';

  @override
  String get employeePermissionsSubtitle =>
      'Set which features this employee can access';

  @override
  String get canCreateOrderPermission => 'Can Create Orders';

  @override
  String get canManageCustomerPermission => 'Can Manage Customer Data';

  @override
  String get canViewReportPermission => 'Can View Financial Reports';

  @override
  String get savingButton => 'Saving...';

  @override
  String get saveEmployeeButton => 'Save Employee';

  @override
  String get completeRequiredFieldsWarning =>
      'Please fill in all required fields';

  @override
  String get employeeDetailTitle => 'Employee Detail';

  @override
  String employeeCodeFallback(String code) {
    return 'Employee $code';
  }

  @override
  String get laundryStaffFallback => 'Laundry Staff';

  @override
  String get addressFullLabel => 'Full Address';

  @override
  String get employmentInfoTitle => 'Employment Information';

  @override
  String get documentIdLabel => 'Document ID';

  @override
  String get positionLabel => 'Position';

  @override
  String get baseSalaryShortLabel => 'Base Salary';

  @override
  String get commissionLabel => 'Commission';

  @override
  String get systemAccessTitle => 'System Access Rights';

  @override
  String get createOrdersPermissionShort => 'Create Orders';

  @override
  String get manageCustomersPermissionShort => 'Manage Customers';

  @override
  String get viewReportsPermissionShort => 'View Reports';

  @override
  String get activityHistoryLabel => 'Activity History';

  @override
  String activityLogEntryLabel(String stage, String orderNumber) {
    return '$stage · $orderNumber';
  }

  @override
  String get activityHistoryUnavailable =>
      'Activity history is not available yet.';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get loggedInActivityLabel => 'Logged in';

  @override
  String get loggedOutActivityLabel => 'Logged out';

  @override
  String get latestActivityBadge => 'Latest';

  @override
  String get noActivityYet => 'No activity yet.';

  @override
  String get viewAllActivityLabel => 'View all activity';

  @override
  String get resetPasswordLabel => 'Reset Password';

  @override
  String get resetPasswordUnavailable => 'Password reset is not available yet.';

  @override
  String get manageEmployeesTitle => 'Manage Employees';

  @override
  String get searchEmployeeHint => 'Search employee name or phone number...';

  @override
  String get filterAllLabel => 'All';

  @override
  String get allRolesLabel => 'All Roles';

  @override
  String get totalEmployeesLabel => 'Total Employees';

  @override
  String get noEmployeesFoundTitle => 'No employee data found';

  @override
  String get noEmployeesFoundSubtitle =>
      'Try changing filters or add a new employee';

  @override
  String get newEmployeeButton => 'New Employee';

  @override
  String get noNameFallback => 'No Name';

  @override
  String get terminateEmployeeTitle => 'Terminate Employee';

  @override
  String terminateEmployeeConfirm(String name, String position) {
    return 'Are you sure you want to deactivate $name ($position)?';
  }

  @override
  String employeeDeactivatedWithCodeSuccess(String code) {
    return 'Employee $code has been deactivated';
  }

  @override
  String deleteEmployeeConfirmContent(String name) {
    return 'Employee \"$name\" will be permanently deleted from the database and CANNOT be recovered.\n\nIf this employee is or has been recorded in transaction history, it\'s recommended to use the \"Deactivate\" option instead so old history still displays correctly.';
  }

  @override
  String deleteEmployeeSuccess(String name) {
    return 'Employee \"$name\" permanently deleted';
  }

  @override
  String deleteEmployeeError(String error) {
    return 'Failed to delete employee: $error';
  }

  @override
  String get unnamedBranchFallback => 'Unnamed Branch';

  @override
  String get ordersListTitle => 'Orders';

  @override
  String get orderCompletedStatus => 'Completed';

  @override
  String get orderCancelledStatus => 'Cancelled';

  @override
  String get orderNoOrdersLabel => 'No orders yet';

  @override
  String get orderCreateOrderButtonLabel => 'Create your first order now';

  @override
  String get orderNoOrdersInBranch => 'No orders in this branch';

  @override
  String get orderSuggestNewOrChangeBranch =>
      'Please add a new order or try selecting a different branch filter.';

  @override
  String get orderStatusWaiting => 'Waiting';

  @override
  String get orderStatusConfirmed => 'Confirmed';

  @override
  String get orderStatusProcessing => 'Processing';

  @override
  String get orderStatusWashing => 'Washing';

  @override
  String get orderStatusDrying => 'Drying';

  @override
  String get orderStatusIroning => 'Ironing';

  @override
  String get orderStatusQualityCheck => 'Quality Check';

  @override
  String get orderStatusReady => 'Ready to Pick Up';

  @override
  String get orderTypePickup => 'Pickup';

  @override
  String get orderTypeWalkIn => 'Walk-in';

  @override
  String get orderDeliveryDelivery => 'Delivery';

  @override
  String get orderDeliverySelfPickup => 'Self-Pickup';

  @override
  String get orderServiceMoreSuffix => 'others';

  @override
  String get orderTotalPaymentLabel => 'Total Payment';

  @override
  String get orderItemsLabel => 'items';

  @override
  String get linkOpenError => 'Couldn\'t open the link';

  @override
  String appVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get aboutAppDescription =>
      'NetWash is an on-demand laundry app that makes it easy for you to pick up, wash, and deliver laundry hassle-free.';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get termsConditionsLabel => 'Terms and Conditions';

  @override
  String get rateAppLabel => 'Rate the App';

  @override
  String get copyrightNotice => '© 2026 NetWash. All rights reserved.';

  @override
  String get searchFaqHint => 'Search questions...';

  @override
  String get notAnsweredContactUs => 'Not answered yet? Contact us';

  @override
  String get faqOrderQuestion => 'How do I place a laundry order?';

  @override
  String get faqOrderAnswer =>
      'Open the Order menu, choose a service, set the pickup address, then confirm your order. A courier will arrive as scheduled.';

  @override
  String get faqDurationQuestion => 'How long does the laundry process take?';

  @override
  String get faqDurationAnswer =>
      'Regular wash takes 1-2 business days, express is finished within 6 hours of pickup.';

  @override
  String get faqPaymentQuestion => 'What payment methods are available?';

  @override
  String get faqPaymentAnswer =>
      'We accept bank transfer, e-wallet, and cash payment directly to the courier.';

  @override
  String get faqTrackQuestion => 'How do I track my order status?';

  @override
  String get faqTrackAnswer =>
      'Open the Orders menu, select the active order, and the status will update automatically as it progresses.';

  @override
  String get chatBotTopicBranchQuestion => 'How do I add a new branch?';

  @override
  String get chatBotTopicBranchAnswer =>
      'Here\'s how:\n1. From the dashboard, open the Branches menu.\n2. Tap \"New Branch\".\n3. Fill in the branch name, code, city, province, and full address.\n4. Optionally add the branch phone number, email, and map location.\n5. Set the daily capacity (max orders per day).\n6. Set operating hours per day, or check \"Use same hours for all days\".\n7. Tap \"Save Branch Data\".';

  @override
  String get chatBotTopicEmployeeQuestion => 'How do I add a new employee?';

  @override
  String get chatBotTopicEmployeeAnswer =>
      'Here\'s how:\n1. From the dashboard, open Manage Employees.\n2. Tap \"New Employee\".\n3. Fill in their full name, phone number, and optionally email & address.\n4. Fill in the employee code, position, and assigned branch.\n5. Set the hire date, base salary, and commission per transaction (optional).\n6. Choose which features they can access (create orders, manage customers, view reports).\n7. Turn on \"App Access\" if they should be able to log in to the app.\n8. Tap \"Save Employee\".';

  @override
  String get chatBotTopicServiceQuestion =>
      'How do I add a wash service and set its price?';

  @override
  String get chatBotTopicServiceAnswer =>
      'Here\'s how:\n1. From the dashboard, open the Services menu.\n2. Tap \"New Service\".\n3. Fill in the service name and description (optional).\n4. Choose the service type: By Weight, By Item, or Express.\n5. Fill in the price (per Kg/Item, or base price + express fee) and minimum weight if any.\n6. Set the estimated turnaround time (hours or days).\n7. Choose which branches offer this service, or leave it empty to make it available at all branches.\n8. Tap \"Save Service\".';

  @override
  String get chatBotTopicOrderQuestion => 'How do I create a new order?';

  @override
  String get chatBotTopicOrderAnswer =>
      'Here\'s how:\n1. From the dashboard, tap \"New Order\".\n2. Select the branch and customer (add a new customer first if needed).\n3. Tap a service to add it to the order, then enter the weight/quantity for each item.\n4. Optionally set a pickup schedule, or leave it blank and schedule it later from Pickup & Delivery.\n5. Choose the payment method and whether it\'s paid in full or a down payment (DP).\n6. If DP, enter the amount paid up front.\n7. Tap \"Save Order\".';

  @override
  String get chatBotTopicReportQuestion => 'How do I view my business reports?';

  @override
  String get chatBotTopicReportAnswer =>
      'Here\'s how:\n1. From the dashboard, open the Reports menu.\n2. Choose a period: Today, This Week, This Month, or This Year.\n3. View the summary: revenue, new customers, average order, and growth.\n4. Scroll down for the revenue trend chart and revenue per service.\n5. Check the Completion Rate to see the percentage of finished orders.\n6. Tap \"Print Report\" if you want to export it as a PDF.';

  @override
  String get chatBotTopicLanguageQuestion =>
      'How do I change the app language?';

  @override
  String get chatBotTopicLanguageAnswer =>
      'Here\'s how:\n1. Open the Settings menu.\n2. Tap the Language menu.\n3. Choose the language you want (Indonesian/English).\n4. The change applies to the whole app immediately.';

  @override
  String get orderDetailStatusPending => 'Waiting';

  @override
  String get orderDetailStatusConfirmed => 'Confirmed';

  @override
  String get orderDetailStatusInProgress => 'Processing';

  @override
  String get orderDetailStatusWashing => 'Washing';

  @override
  String get orderDetailStatusDrying => 'Drying';

  @override
  String get orderDetailStatusIroning => 'Ironing';

  @override
  String get orderDetailStatusQualityCheck => 'Quality Check';

  @override
  String get orderDetailStatusReady => 'Ready to Pick Up/Deliver';

  @override
  String get orderDetailStatusCompleted => 'Completed';

  @override
  String get orderDetailStatusCancelled => 'Cancelled';

  @override
  String get orderDetailNotePending => 'Waiting for confirmation';

  @override
  String get orderDetailNoteConfirmed => 'Order has been confirmed';

  @override
  String get orderDetailNoteInProgress => 'Being processed';

  @override
  String get orderDetailNoteWashing => 'In the washing machine';

  @override
  String get orderDetailNoteDrying => 'Being dried';

  @override
  String get orderDetailNoteIroning => 'Being ironed';

  @override
  String get orderDetailNoteQualityCheck => 'Quality is being checked';

  @override
  String get orderDetailNoteReady => 'Ready for pickup / delivery';

  @override
  String get orderDetailNoteCompleted => 'Order is complete';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodTransfer => 'Bank Transfer';

  @override
  String get paymentMethodDebit => 'Debit Card';

  @override
  String get paymentMethodEwallet => 'E-Wallet';

  @override
  String get orderDetailPaymentStatusPaid => 'Paid';

  @override
  String get orderDetailPaymentStatusPartial => 'Partially Paid';

  @override
  String get orderDetailPaymentStatusRefunded => 'Refunded';

  @override
  String get orderDetailPaymentStatusPending => 'Unpaid';

  @override
  String statusUpdateSuccess(String status) {
    return 'Status successfully changed to $status';
  }

  @override
  String statusUpdateError(String error) {
    return 'Failed to update status: $error';
  }

  @override
  String get paymentRecordSuccess => 'Payment recorded successfully';

  @override
  String get customerPhoneUnavailable =>
      'Customer phone number is not available';

  @override
  String get whatsappOpenError => 'Couldn\'t open WhatsApp';

  @override
  String get amountMustBePositiveError => 'Amount must be greater than Rp0';

  @override
  String get receiptDownloadWebUnsupported =>
      'Receipt download is only supported on the mobile app, not on web';

  @override
  String get receiptImageGenerationError => 'Failed to generate receipt image';

  @override
  String get receiptSavedToGallery => 'Receipt saved to gallery';

  @override
  String receiptDownloadError(String error) {
    return 'Failed to download receipt: $error';
  }

  @override
  String get cancellationReasonRequiredError =>
      'Cancellation reason is required';

  @override
  String cancelOrderError(String error) {
    return 'Failed to cancel order: $error';
  }

  @override
  String get cancellationRequestSubmitted =>
      'Cancellation request submitted, awaiting approval';

  @override
  String cancellationRequestSubmitError(String error) {
    return 'Failed to submit request: $error';
  }

  @override
  String get cancellationRequestApproved =>
      'Cancellation request approved, order cancelled';

  @override
  String cancellationRequestApproveError(String error) {
    return 'Failed to approve request: $error';
  }

  @override
  String get cancellationRequestRejected => 'Cancellation request rejected';

  @override
  String cancellationRequestRejectError(String error) {
    return 'Failed to reject request: $error';
  }

  @override
  String get deliveryScheduleSuccess => 'Delivery scheduled successfully';

  @override
  String statusChangedNoteTemplate(String status) {
    return 'Status changed to $status';
  }

  @override
  String get assignOperatorDialogTitle => 'Select Operator';

  @override
  String assignOperatorDialogSubtitle(String stage) {
    return 'Who will handle the $stage stage?';
  }

  @override
  String get assignOperatorFieldLabel => 'Operator';

  @override
  String get assignOperatorEmptyState =>
      'No active employees available to assign';

  @override
  String get assignOperatorConfirmButtonLabel => 'Assign & Continue';

  @override
  String currentOperatorLabel(String name) {
    return 'Currently handled by $name';
  }

  @override
  String activityLogByOperatorLabel(String name) {
    return 'by $name';
  }

  @override
  String orderCancelledNoteTemplate(String reason) {
    return 'Order cancelled: $reason';
  }

  @override
  String cancellationRequestedNoteTemplate(String name, String reason) {
    return 'Cancellation requested by $name: $reason';
  }

  @override
  String cancellationApprovedNoteTemplate(String name) {
    return 'Cancellation request approved by $name';
  }

  @override
  String cancellationRejectedNoteTemplate(String name) {
    return 'Cancellation request rejected by $name';
  }

  @override
  String whatsappOrderReadyDeliveryMessage(String name, String orderNumber) {
    return 'Hi $name, this is Netwash 😊. Your order ($orderNumber) is complete and will be delivered to your address shortly. Thanks for waiting 🙏';
  }

  @override
  String whatsappOrderReadyPickupMessage(String name, String orderNumber) {
    return 'Hi $name! This is Netwash 😊. Your order ($orderNumber) is complete and ready for pickup, what time would you like to pick it up? We\'ll be waiting 🙏';
  }

  @override
  String whatsappContactMessage(String name, String orderNumber) {
    return 'Hi $name, this is Netwash regarding order $orderNumber.';
  }

  @override
  String get receiptWhatsappTitle => 'Netwash Order Receipt';

  @override
  String get receiptOrderNumberLabel => 'Order No.';

  @override
  String get receiptDateLabel => 'Date';

  @override
  String get receiptCustomerLabel => 'Customer';

  @override
  String get receiptItemsLabel => 'Items';

  @override
  String get receiptTotalLabel => 'Total';

  @override
  String get receiptPaymentMethodLabel => 'Payment Method';

  @override
  String get receiptPaymentStatusLabel => 'Payment Status';

  @override
  String get receiptThankYouMessage => 'Thank you for using Netwash 🙏';

  @override
  String get receiptFallbackSubtitle => 'Order Receipt';

  @override
  String get confirmPaymentDialogTitle => 'Confirm Payment';

  @override
  String remainingBillDialogLabel(String amount) {
    return 'Remaining bill: $amount';
  }

  @override
  String get amountPaidFieldLabel => 'Amount Paid';

  @override
  String get methodFieldLabel => 'Method';

  @override
  String get saveButtonLabel => 'Save';

  @override
  String get cancelOrderDialogTitle => 'Cancel Order?';

  @override
  String get requestCancellationDialogTitle => 'Request Cancellation?';

  @override
  String get cancelOrderDialogContent =>
      'This action will change the order status to Cancelled.';

  @override
  String get requestCancellationDialogContent =>
      'This request needs to be approved by an Admin/Owner/Manager before the order status changes to Cancelled.';

  @override
  String get cancellationReasonFieldLabel => 'Cancellation reason';

  @override
  String get noButtonLabel => 'No';

  @override
  String get yesCancelButtonLabel => 'Yes, Cancel';

  @override
  String get submitCancellationRequestButtonLabel => 'Request Cancellation';

  @override
  String get orderDetailTitle => 'Order Detail';

  @override
  String get orderStatusSectionLabel => 'Order Status';

  @override
  String get orderCancelledTitle => 'Order Cancelled';

  @override
  String get trackProgressTitle => 'Track Progress';

  @override
  String get customerInfoSectionLabel => 'Customer Information';

  @override
  String get registeredBranchLabel => 'Registered Branch';

  @override
  String get itemCountLabel => 'Item Count';

  @override
  String itemCountValueTemplate(int count) {
    return '$count items';
  }

  @override
  String get serviceLabel => 'Service';

  @override
  String get costBreakdownSectionLabel => 'Cost Breakdown';

  @override
  String get totalBillLabel => 'Total Bill';

  @override
  String get paymentSectionLabel => 'Payment';

  @override
  String get paidAmountLabel => 'Amount Paid';

  @override
  String get remainingBillLabel => 'Remaining Bill';

  @override
  String get orderStatusPendingPayment => 'Unpaid';

  @override
  String get confirmPaymentButtonLabel => 'Confirm Payment';

  @override
  String get downloadReceiptButtonLabel => 'Download Receipt';

  @override
  String get sendReceiptWhatsappButtonLabel => 'Send Receipt via WA';

  @override
  String get paymentHistorySectionLabel => 'Payment History';

  @override
  String get notesSectionLabel => 'Notes';

  @override
  String get cancelOrderButtonLabel => 'Cancel Order';

  @override
  String get pendingCancellationApprovalTitle =>
      'Awaiting Cancellation Approval';

  @override
  String requestedByLabel(String name) {
    return 'Requested by $name';
  }

  @override
  String reasonLabel(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get employeeFallbackLabel => 'Employee';

  @override
  String get rejectButtonLabel => 'Reject';

  @override
  String get approveButtonLabel => 'Approve';

  @override
  String get notifyReadyForDeliveryButtonLabel => 'Notify Ready for Delivery';

  @override
  String get notifyViaWhatsappButtonLabel => 'Notify via WhatsApp';

  @override
  String get scheduleDeliveryButtonLabel => 'Schedule Delivery';

  @override
  String get editDeliveryScheduleButtonLabel => 'Change Delivery Schedule';

  @override
  String get branchFollowsSelectedOrderHint =>
      'Branch follows the selected order';

  @override
  String get addressAutoFilledFromCustomerHint =>
      'Address auto-filled from customer data - change if needed';

  @override
  String noActiveCourierInBranchHint(String branchName) {
    return 'No active couriers at $branchName branch yet';
  }

  @override
  String get courierMatchesScheduleHint =>
      'Matches the schedule already set - change if needed';

  @override
  String get deliveryScheduleUpdateSuccess =>
      'Delivery schedule updated successfully';

  @override
  String get contactCustomerButtonLabel => 'Contact Customer';

  @override
  String get confirmOrderButtonLabel => 'Confirm Order';

  @override
  String get startProcessButtonLabel => 'Start Processing';

  @override
  String get startWashingButtonLabel => 'Start Washing';

  @override
  String get finishWashingButtonLabel => 'Finish Washing';

  @override
  String get finishDryingButtonLabel => 'Finish Drying';

  @override
  String get finishIroningButtonLabel => 'Finish Ironing';

  @override
  String get passQualityCheckButtonLabel => 'Pass Quality Check';

  @override
  String get markCompletedButtonLabel => 'Mark as Completed';

  @override
  String get createOrderSubtitle => 'Create and manage a new laundry order';

  @override
  String get noBranchesForOrderError =>
      'No laundry branches yet. Add a branch first before creating an order.';

  @override
  String fillWeightForItemError(String itemName) {
    return 'Please enter the weight (kg) for \"$itemName\" first';
  }

  @override
  String get businessContextNotReadyError =>
      'Company/branch data is not ready yet. Please try again shortly.';

  @override
  String get selectedCustomerNotFoundError =>
      'Selected customer not found, please choose again.';

  @override
  String get orderCreatedSuccess => 'Order created successfully!';

  @override
  String genericErrorTemplate(String error) {
    return 'Error: $error';
  }

  @override
  String get orderTypeSelfDropoffLabel => 'Self Drop-off';

  @override
  String get orderDataSectionLabel => 'Order Data';

  @override
  String get incomingLaundryLabel => 'Incoming Laundry *';

  @override
  String get outgoingLaundryLabel => 'Outgoing Laundry *';

  @override
  String get remainingBillPayLaterNotice =>
      'The remaining balance can be settled later from the order detail page.';

  @override
  String get orderNotesFieldLabel => 'Notes (Optional)';

  @override
  String get orderNotesFieldHint => 'Write any special notes for this order';

  @override
  String get pickupPaymentPendingNotice =>
      'Payment method & status will be confirmed again once the laundry weight/quantity is known.';

  @override
  String get branchFieldLabel => 'Branch *';

  @override
  String get selectBranchForOrderHint => 'Select a branch for this order';

  @override
  String get selectBranchRequiredError => 'Please select a branch first';

  @override
  String get customerFieldLabel => 'Customer *';

  @override
  String get selectCustomerRequiredError => 'Please select a customer first';

  @override
  String get noCustomersForOrderHint =>
      'No customers yet. Add a customer first before creating an order.';

  @override
  String get noCustomersInBranchHint =>
      'No customers are registered at this branch yet. Add a new customer, or check the branch assignment of existing customers.';

  @override
  String get orderItemsSectionLabel => 'Order Items';

  @override
  String get noItemsTapServiceHint =>
      'No items yet. Tap one of the services above to add it.';

  @override
  String get noActiveServicesForOrderHint =>
      'No active services yet. Add a service first from the Services menu before creating an order.';

  @override
  String get pickupScheduleLabel => 'Pickup Schedule (Optional)';

  @override
  String get pickupScheduleOptionalHint =>
      'Leave blank if you don\'t know the time yet — it can be scheduled later from the Pickup & Delivery menu.';

  @override
  String get itemsFilledAtPickupConfirmationHint =>
      'Items will be filled in when confirming pickup';

  @override
  String get savingLabel => 'Saving...';

  @override
  String get dateFieldFallbackLabel => 'Date';

  @override
  String get timeFieldFallbackLabel => 'Time';

  @override
  String get perKgUnitSuffix => '/kg';
}
