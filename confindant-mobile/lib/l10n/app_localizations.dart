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

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Confindant'**
  String get appName;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning!'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon!'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening!'**
  String get greetingEvening;

  /// No description provided for @authTokenUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Token is not available from server'**
  String get authTokenUnavailable;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get authLoginFailed;

  /// No description provided for @authRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get authRegisterFailed;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitlePrefix.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to '**
  String get loginSubtitlePrefix;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get loginEmailHint;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordHint;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignIn;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get loginNoAccount;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginSignUp;

  /// No description provided for @registerCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerCreateAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start managing your finances today'**
  String get registerSubtitle;

  /// No description provided for @registerFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get registerFullName;

  /// No description provided for @registerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get registerNameHint;

  /// No description provided for @registerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get registerEmail;

  /// No description provided for @registerEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get registerEmailHint;

  /// No description provided for @registerPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPassword;

  /// No description provided for @registerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get registerPasswordHint;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get registerHaveAccount;

  /// No description provided for @onboardingTrackMoneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Your Money'**
  String get onboardingTrackMoneyTitle;

  /// No description provided for @onboardingTrackMoneySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep track of all your income and expenses in one place'**
  String get onboardingTrackMoneySubtitle;

  /// No description provided for @onboardingFinancialInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Insights'**
  String get onboardingFinancialInsightsTitle;

  /// No description provided for @onboardingFinancialInsightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get detailed reports and insights about your spending habits'**
  String get onboardingFinancialInsightsSubtitle;

  /// No description provided for @onboardingBudgetManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Management'**
  String get onboardingBudgetManagementTitle;

  /// No description provided for @onboardingBudgetManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set budgets and monitor your spending across categories'**
  String get onboardingBudgetManagementSubtitle;

  /// No description provided for @onboardingSecureTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure & Private'**
  String get onboardingSecureTitle;

  /// No description provided for @onboardingSecureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your financial data is encrypted and stored securely'**
  String get onboardingSecureSubtitle;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @homeNoTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get homeNoTransactionsYet;

  /// No description provided for @homeQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActionsTitle;

  /// No description provided for @homeQuickActionAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get homeQuickActionAddExpense;

  /// No description provided for @homeQuickActionAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get homeQuickActionAddIncome;

  /// No description provided for @homeQuickActionAddWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Wallet'**
  String get homeQuickActionAddWallet;

  /// No description provided for @homeQuickActionVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Voice Input'**
  String get homeQuickActionVoiceInput;

  /// No description provided for @homeQuickActionVoiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get homeQuickActionVoiceListening;

  /// No description provided for @homeVoiceQuickActionListening.
  ///
  /// In en, this message translates to:
  /// **'Listening... speak transaction details, then wait a moment.'**
  String get homeVoiceQuickActionListening;

  /// No description provided for @homeVoiceQuickActionSaved.
  ///
  /// In en, this message translates to:
  /// **'Transaction created from voice input.'**
  String get homeVoiceQuickActionSaved;

  /// No description provided for @homeStartAddingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Start adding transactions to make your Home dashboard more informative.'**
  String get homeStartAddingTransactions;

  /// No description provided for @homeUnableLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Unable to load dashboard.'**
  String get homeUnableLoadDashboard;

  /// No description provided for @homePleaseCreateWalletFirst.
  ///
  /// In en, this message translates to:
  /// **'Please create wallet first.'**
  String get homePleaseCreateWalletFirst;

  /// No description provided for @homeIncomeAdded.
  ///
  /// In en, this message translates to:
  /// **'Income added.'**
  String get homeIncomeAdded;

  /// No description provided for @homeExpenseAdded.
  ///
  /// In en, this message translates to:
  /// **'Expense added.'**
  String get homeExpenseAdded;

  /// No description provided for @homeTransactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted.'**
  String get homeTransactionDeleted;

  /// No description provided for @homeTransactionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated.'**
  String get homeTransactionUpdated;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTitle;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalance;

  /// No description provided for @walletManageCategoryLimits.
  ///
  /// In en, this message translates to:
  /// **'Manage Category Limits'**
  String get walletManageCategoryLimits;

  /// No description provided for @walletRecurringPlans.
  ///
  /// In en, this message translates to:
  /// **'Recurring Plans'**
  String get walletRecurringPlans;

  /// No description provided for @walletTransferBetweenWallets.
  ///
  /// In en, this message translates to:
  /// **'Transfer Between Wallets'**
  String get walletTransferBetweenWallets;

  /// No description provided for @walletTransferFrom.
  ///
  /// In en, this message translates to:
  /// **'From Wallet'**
  String get walletTransferFrom;

  /// No description provided for @walletTransferTo.
  ///
  /// In en, this message translates to:
  /// **'To Wallet'**
  String get walletTransferTo;

  /// No description provided for @walletTransferSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet transfer successful.'**
  String get walletTransferSuccess;

  /// No description provided for @walletTransferFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to transfer wallet balance'**
  String get walletTransferFailed;

  /// No description provided for @walletTransferInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid transfer input.'**
  String get walletTransferInvalidInput;

  /// No description provided for @walletNeedTwoWalletsForTransfer.
  ///
  /// In en, this message translates to:
  /// **'Please create at least two wallets to transfer.'**
  String get walletNeedTwoWalletsForTransfer;

  /// No description provided for @walletAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get walletAddIncome;

  /// No description provided for @walletActiveLimits.
  ///
  /// In en, this message translates to:
  /// **'Active Limits:'**
  String get walletActiveLimits;

  /// No description provided for @walletLimitsAllWallets.
  ///
  /// In en, this message translates to:
  /// **'Category limits apply to expenses from all wallets.'**
  String get walletLimitsAllWallets;

  /// No description provided for @walletNoBudgetLimits.
  ///
  /// In en, this message translates to:
  /// **'No budget limits set yet.'**
  String get walletNoBudgetLimits;

  /// No description provided for @walletYourWallets.
  ///
  /// In en, this message translates to:
  /// **'Your Wallets'**
  String get walletYourWallets;

  /// No description provided for @walletRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get walletRecentTransactions;

  /// No description provided for @walletNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get walletNoTransactions;

  /// No description provided for @walletAddNewWallet.
  ///
  /// In en, this message translates to:
  /// **'Add New Wallet'**
  String get walletAddNewWallet;

  /// No description provided for @walletIncomeAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Income added successfully.'**
  String get walletIncomeAddedSuccess;

  /// No description provided for @walletIncomeAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add income'**
  String get walletIncomeAddFailed;

  /// No description provided for @walletTransactionUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated successfully.'**
  String get walletTransactionUpdatedSuccess;

  /// No description provided for @walletTransactionUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update transaction'**
  String get walletTransactionUpdateFailed;

  /// No description provided for @walletEditWallet.
  ///
  /// In en, this message translates to:
  /// **'Edit Wallet'**
  String get walletEditWallet;

  /// No description provided for @walletDeleteWallet.
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet'**
  String get walletDeleteWallet;

  /// No description provided for @analyticsExpenseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Expense Breakdown'**
  String get analyticsExpenseBreakdown;

  /// No description provided for @analyticsIncomeSources.
  ///
  /// In en, this message translates to:
  /// **'Income Sources'**
  String get analyticsIncomeSources;

  /// No description provided for @analyticsExpenseOnly.
  ///
  /// In en, this message translates to:
  /// **'Expense Only'**
  String get analyticsExpenseOnly;

  /// No description provided for @analyticsNetFlow.
  ///
  /// In en, this message translates to:
  /// **'Net Flow'**
  String get analyticsNetFlow;

  /// No description provided for @analyticsCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get analyticsCompare;

  /// No description provided for @analyticsMonthOverMonth.
  ///
  /// In en, this message translates to:
  /// **'Month over Month'**
  String get analyticsMonthOverMonth;

  /// No description provided for @analyticsWeekOverWeek.
  ///
  /// In en, this message translates to:
  /// **'Week over Week'**
  String get analyticsWeekOverWeek;

  /// No description provided for @analyticsVsPreviousPeriod.
  ///
  /// In en, this message translates to:
  /// **'vs previous period'**
  String get analyticsVsPreviousPeriod;

  /// No description provided for @analyticsAnomalyInsight.
  ///
  /// In en, this message translates to:
  /// **'Anomaly Insight'**
  String get analyticsAnomalyInsight;

  /// No description provided for @analyticsNoDataYet.
  ///
  /// In en, this message translates to:
  /// **'No analytics data yet'**
  String get analyticsNoDataYet;

  /// No description provided for @analyticsStartAddingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Start adding transactions so analytics insights can be displayed.'**
  String get analyticsStartAddingTransactions;

  /// No description provided for @analyticsUnableLoadData.
  ///
  /// In en, this message translates to:
  /// **'Unable to load analytics data.'**
  String get analyticsUnableLoadData;

  /// No description provided for @profileAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get profileAccountSettings;

  /// No description provided for @profilePersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get profilePersonalInformation;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profileChangePassword;

  /// No description provided for @profileSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get profileSupport;

  /// No description provided for @profileHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get profileHelpCenter;

  /// No description provided for @profileAboutConfindant.
  ///
  /// In en, this message translates to:
  /// **'About Confindant'**
  String get profileAboutConfindant;

  /// No description provided for @profileAiOcrHealth.
  ///
  /// In en, this message translates to:
  /// **'AI/OCR Health'**
  String get profileAiOcrHealth;

  /// No description provided for @profileAiFinanceChat.
  ///
  /// In en, this message translates to:
  /// **'AI Finance Chat'**
  String get profileAiFinanceChat;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileBuildFooter.
  ///
  /// In en, this message translates to:
  /// **'Build {build} (c) 2026 All rights reserved'**
  String profileBuildFooter(Object build);

  /// No description provided for @addWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Wallet'**
  String get addWalletTitle;

  /// No description provided for @addWalletWalletName.
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get addWalletWalletName;

  /// No description provided for @addWalletWalletNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Savings, Business'**
  String get addWalletWalletNameHint;

  /// No description provided for @addWalletColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get addWalletColor;

  /// No description provided for @addWalletCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Wallet'**
  String get addWalletCreateButton;

  /// No description provided for @addWalletCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create wallet.'**
  String get addWalletCreateFailed;

  /// No description provided for @scanUploadFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Upload from Gallery'**
  String get scanUploadFromGallery;

  /// No description provided for @scanInputManual.
  ///
  /// In en, this message translates to:
  /// **'Input Manual'**
  String get scanInputManual;

  /// No description provided for @scanInputManualShort.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get scanInputManualShort;

  /// No description provided for @scanUploadShort.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get scanUploadShort;

  /// No description provided for @scanTapToTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to take photo'**
  String get scanTapToTakePhoto;

  /// No description provided for @scanTipText.
  ///
  /// In en, this message translates to:
  /// **'Tip: Tap scan area to capture receipt. Ensure receipt is clear and well-lit for best OCR results.'**
  String get scanTipText;

  /// No description provided for @scanCameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied. Open Settings and allow camera access.'**
  String get scanCameraPermissionDenied;

  /// No description provided for @scanCameraPermissionDeniedPermanently.
  ///
  /// In en, this message translates to:
  /// **'Camera access denied permanently. Enable camera permission in Settings.'**
  String get scanCameraPermissionDeniedPermanently;

  /// No description provided for @scanCameraRestricted.
  ///
  /// In en, this message translates to:
  /// **'Camera access is restricted on this device.'**
  String get scanCameraRestricted;

  /// No description provided for @scanAudioAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Audio access denied, but camera can still be used without audio.'**
  String get scanAudioAccessDenied;

  /// No description provided for @scanCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera is unavailable on this device.'**
  String get scanCameraUnavailable;

  /// No description provided for @scanFailedToOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Failed to open camera'**
  String get scanFailedToOpenCamera;

  /// No description provided for @scanTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get scanTapToRetry;

  /// No description provided for @scanPreparingCamera.
  ///
  /// In en, this message translates to:
  /// **'Preparing camera...'**
  String get scanPreparingCamera;

  /// No description provided for @scanFlashUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Flash is unavailable'**
  String get scanFlashUnavailable;

  /// No description provided for @scanReceiptReview.
  ///
  /// In en, this message translates to:
  /// **'Receipt Review'**
  String get scanReceiptReview;

  /// No description provided for @scanMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get scanMerchant;

  /// No description provided for @scanType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get scanType;

  /// No description provided for @scanIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get scanIncome;

  /// No description provided for @scanExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get scanExpense;

  /// No description provided for @scanCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get scanCategory;

  /// No description provided for @scanTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get scanTotalAmount;

  /// No description provided for @scanTaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Tax Amount'**
  String get scanTaxAmount;

  /// No description provided for @scanServiceAmount.
  ///
  /// In en, this message translates to:
  /// **'Service Amount'**
  String get scanServiceAmount;

  /// No description provided for @scanNeedType.
  ///
  /// In en, this message translates to:
  /// **'Need Type'**
  String get scanNeedType;

  /// No description provided for @scanNeedTypeNeeds.
  ///
  /// In en, this message translates to:
  /// **'Needs'**
  String get scanNeedTypeNeeds;

  /// No description provided for @scanNeedTypeWants.
  ///
  /// In en, this message translates to:
  /// **'Wants'**
  String get scanNeedTypeWants;

  /// No description provided for @scanNeedTypeMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get scanNeedTypeMixed;

  /// No description provided for @scanNeedTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get scanNeedTypeUnknown;

  /// No description provided for @scanDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get scanDate;

  /// No description provided for @scanNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get scanNotes;

  /// No description provided for @scanItemsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) detected by OCR'**
  String scanItemsFound(int count);

  /// No description provided for @scanDetectedTransactions.
  ///
  /// In en, this message translates to:
  /// **'{count} transaction(s) detected'**
  String scanDetectedTransactions(int count);

  /// No description provided for @scanSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get scanSelectAll;

  /// No description provided for @scanUseFirstOnly.
  ///
  /// In en, this message translates to:
  /// **'Use First Only'**
  String get scanUseFirstOnly;

  /// No description provided for @scanSelectAtLeastOneTransaction.
  ///
  /// In en, this message translates to:
  /// **'Select at least one transaction.'**
  String get scanSelectAtLeastOneTransaction;

  /// No description provided for @scanLowConfidenceHint.
  ///
  /// In en, this message translates to:
  /// **'Low OCR confidence. Please verify this field.'**
  String get scanLowConfidenceHint;

  /// No description provided for @scanInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount.'**
  String get scanInvalidAmount;

  /// No description provided for @scanFailedStartOcr.
  ///
  /// In en, this message translates to:
  /// **'Failed to start OCR, continue manually.'**
  String get scanFailedStartOcr;

  /// No description provided for @scanOcrFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'OCR failed. You can continue by entering data manually.'**
  String get scanOcrFailedGeneric;

  /// No description provided for @scanOcrStatusPrefix.
  ///
  /// In en, this message translates to:
  /// **'OCR status'**
  String get scanOcrStatusPrefix;

  /// No description provided for @scanOcrStatusPending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get scanOcrStatusPending;

  /// No description provided for @scanOcrStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'processing'**
  String get scanOcrStatusProcessing;

  /// No description provided for @scanOcrStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'success'**
  String get scanOcrStatusSuccess;

  /// No description provided for @scanOcrStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get scanOcrStatusFailed;

  /// No description provided for @scanContinueManual.
  ///
  /// In en, this message translates to:
  /// **'Continue Manually'**
  String get scanContinueManual;

  /// No description provided for @scanRetryOcr.
  ///
  /// In en, this message translates to:
  /// **'Retry OCR'**
  String get scanRetryOcr;

  /// No description provided for @scanManualModeHint.
  ///
  /// In en, this message translates to:
  /// **'Continue filling the form manually, then tap Save.'**
  String get scanManualModeHint;

  /// No description provided for @scanOcrQuotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'OCR quota is exhausted. Please try again later or enable billing in Gemini project.'**
  String get scanOcrQuotaExceeded;

  /// No description provided for @scanOcrAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'OCR authentication failed. Check Gemini API key and restrictions.'**
  String get scanOcrAuthFailed;

  /// No description provided for @scanOcrTimeout.
  ///
  /// In en, this message translates to:
  /// **'OCR request timed out. Please retry with a clearer/smaller image.'**
  String get scanOcrTimeout;

  /// No description provided for @scanOcrInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'OCR response format is invalid. Please retry or fill manually.'**
  String get scanOcrInvalidResponse;

  /// No description provided for @scanOcrProviderError.
  ///
  /// In en, this message translates to:
  /// **'OCR provider error occurred. Please try again later.'**
  String get scanOcrProviderError;

  /// No description provided for @scanFailedSaveReceipt.
  ///
  /// In en, this message translates to:
  /// **'Failed to save receipt.'**
  String get scanFailedSaveReceipt;

  /// No description provided for @scanReceiptSaved.
  ///
  /// In en, this message translates to:
  /// **'Receipt saved to backend.'**
  String get scanReceiptSaved;

  /// No description provided for @scanManualSaved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved from manual input.'**
  String get scanManualSaved;

  /// No description provided for @scanManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get scanManualEntry;

  /// No description provided for @scanNoReceiptImage.
  ///
  /// In en, this message translates to:
  /// **'No receipt image'**
  String get scanNoReceiptImage;

  /// No description provided for @transactionFormAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get transactionFormAddIncome;

  /// No description provided for @transactionFormAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get transactionFormAddExpense;

  /// No description provided for @transactionFormWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get transactionFormWallet;

  /// No description provided for @transactionFormType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get transactionFormType;

  /// No description provided for @transactionFormAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionFormAmount;

  /// No description provided for @transactionFormSource.
  ///
  /// In en, this message translates to:
  /// **'Source (income)'**
  String get transactionFormSource;

  /// No description provided for @transactionFormTags.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma-separated)'**
  String get transactionFormTags;

  /// No description provided for @transactionFormMerchantRef.
  ///
  /// In en, this message translates to:
  /// **'Merchant/Reference'**
  String get transactionFormMerchantRef;

  /// No description provided for @transactionFormVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get transactionFormVerified;

  /// No description provided for @transactionFormDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionFormDate;

  /// No description provided for @transactionFormInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid transaction input.'**
  String get transactionFormInvalidInput;

  /// No description provided for @transactionFormVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Voice Input (AI)'**
  String get transactionFormVoiceInput;

  /// No description provided for @transactionFormListening.
  ///
  /// In en, this message translates to:
  /// **'Listening... tap again to stop'**
  String get transactionFormListening;

  /// No description provided for @transactionFormVoiceNoSpeech.
  ///
  /// In en, this message translates to:
  /// **'No voice detected. Please try again.'**
  String get transactionFormVoiceNoSpeech;

  /// No description provided for @transactionFormVoiceApplySuccess.
  ///
  /// In en, this message translates to:
  /// **'Voice input applied to form.'**
  String get transactionFormVoiceApplySuccess;

  /// No description provided for @transactionFormVoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input is unavailable on this device.'**
  String get transactionFormVoiceUnavailable;

  /// No description provided for @transactionFormVoicePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied. Please enable it in Settings.'**
  String get transactionFormVoicePermissionDenied;

  /// No description provided for @transactionFormVoiceParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse voice input. Please fill manually.'**
  String get transactionFormVoiceParseFailed;

  /// No description provided for @notificationsPermissionMissing.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is not granted. Enable it in Settings.'**
  String get notificationsPermissionMissing;

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Finance Chat'**
  String get aiChatTitle;

  /// No description provided for @aiChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask financial insight from your real data'**
  String get aiChatSubtitle;

  /// No description provided for @aiChatQuickAsk1.
  ///
  /// In en, this message translates to:
  /// **'Where did I spend the most this month?'**
  String get aiChatQuickAsk1;

  /// No description provided for @aiChatQuickAsk2.
  ///
  /// In en, this message translates to:
  /// **'How much did I spend on food in the last 2 weeks?'**
  String get aiChatQuickAsk2;

  /// No description provided for @aiChatQuickAsk3.
  ///
  /// In en, this message translates to:
  /// **'How is my cashflow in the last 30 days?'**
  String get aiChatQuickAsk3;

  /// No description provided for @aiChatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No questions yet. Try quick ask or type your own question.'**
  String get aiChatEmpty;

  /// No description provided for @aiChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type your finance question...'**
  String get aiChatInputHint;

  /// No description provided for @aiChatClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get aiChatClear;

  /// No description provided for @aiChatClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get aiChatClearHistory;

  /// No description provided for @aiChatAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get aiChatAsk;

  /// No description provided for @aiChatNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer from AI yet.'**
  String get aiChatNoAnswer;

  /// No description provided for @aiChatInsightPrefix.
  ///
  /// In en, this message translates to:
  /// **'Insight'**
  String get aiChatInsightPrefix;

  /// No description provided for @aiChatError.
  ///
  /// In en, this message translates to:
  /// **'AI cannot process your query right now. Please try again.'**
  String get aiChatError;

  /// No description provided for @aiChatHistoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading conversation history...'**
  String get aiChatHistoryLoading;

  /// No description provided for @aiChatHistoryLoaded.
  ///
  /// In en, this message translates to:
  /// **'Conversation history loaded.'**
  String get aiChatHistoryLoaded;

  /// No description provided for @aiChatHistoryClearSuccess.
  ///
  /// In en, this message translates to:
  /// **'Conversation history cleared.'**
  String get aiChatHistoryClearSuccess;

  /// No description provided for @aiChatRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get aiChatRename;

  /// No description provided for @aiChatDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get aiChatDelete;

  /// No description provided for @aiChatDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete History Item?'**
  String get aiChatDeleteConfirmTitle;

  /// No description provided for @aiChatDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove this Q&A pair from your history.'**
  String get aiChatDeleteConfirmMessage;

  /// No description provided for @aiChatDeleteConfirmTarget.
  ///
  /// In en, this message translates to:
  /// **'Question: {query}'**
  String aiChatDeleteConfirmTarget(Object query);

  /// No description provided for @aiChatRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Query'**
  String get aiChatRenameTitle;

  /// No description provided for @aiChatRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Update question title'**
  String get aiChatRenameHint;

  /// No description provided for @aiChatRenameSuccess.
  ///
  /// In en, this message translates to:
  /// **'History item renamed.'**
  String get aiChatRenameSuccess;

  /// No description provided for @aiChatDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'History item deleted.'**
  String get aiChatDeleteSuccess;

  /// No description provided for @aiChatUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get aiChatUndo;

  /// No description provided for @aiChatDeleteQueued.
  ///
  /// In en, this message translates to:
  /// **'History item removed. Undo within 5 seconds.'**
  String get aiChatDeleteQueued;

  /// No description provided for @aiChatDeleteUndone.
  ///
  /// In en, this message translates to:
  /// **'Delete canceled.'**
  String get aiChatDeleteUndone;

  /// No description provided for @aiOcrHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Internal quality metrics'**
  String get aiOcrHealthSubtitle;

  /// No description provided for @aiOcrHealthWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get aiOcrHealthWindow;

  /// No description provided for @aiOcrHealthLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get aiOcrHealthLast7Days;

  /// No description provided for @aiOcrHealthLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get aiOcrHealthLast30Days;

  /// No description provided for @aiOcrHealthLast90Days.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get aiOcrHealthLast90Days;

  /// No description provided for @aiOcrHealthRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get aiOcrHealthRefresh;

  /// No description provided for @aiOcrHealthErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get aiOcrHealthErrorTitle;

  /// No description provided for @aiOcrHealthJobs.
  ///
  /// In en, this message translates to:
  /// **'OCR Jobs'**
  String get aiOcrHealthJobs;

  /// No description provided for @aiOcrHealthTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get aiOcrHealthTotal;

  /// No description provided for @aiOcrHealthSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get aiOcrHealthSuccess;

  /// No description provided for @aiOcrHealthFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get aiOcrHealthFailed;

  /// No description provided for @aiOcrHealthPendingProcessing.
  ///
  /// In en, this message translates to:
  /// **'Pending/Processing'**
  String get aiOcrHealthPendingProcessing;

  /// No description provided for @aiOcrHealthSuccessRate.
  ///
  /// In en, this message translates to:
  /// **'Success Rate'**
  String get aiOcrHealthSuccessRate;

  /// No description provided for @aiOcrHealthAvgConfidence.
  ///
  /// In en, this message translates to:
  /// **'Avg Confidence'**
  String get aiOcrHealthAvgConfidence;

  /// No description provided for @aiOcrHealthUserFeedback.
  ///
  /// In en, this message translates to:
  /// **'User Feedback'**
  String get aiOcrHealthUserFeedback;

  /// No description provided for @aiOcrHealthTotalFeedback.
  ///
  /// In en, this message translates to:
  /// **'Total Feedback'**
  String get aiOcrHealthTotalFeedback;

  /// No description provided for @aiOcrHealthAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get aiOcrHealthAccepted;

  /// No description provided for @aiOcrHealthAcceptanceRate.
  ///
  /// In en, this message translates to:
  /// **'Acceptance Rate'**
  String get aiOcrHealthAcceptanceRate;

  /// No description provided for @aiOcrHealthTopEditedFields.
  ///
  /// In en, this message translates to:
  /// **'Top Edited Fields'**
  String get aiOcrHealthTopEditedFields;

  /// No description provided for @aiOcrHealthNoFeedbackData.
  ///
  /// In en, this message translates to:
  /// **'No feedback data yet.'**
  String get aiOcrHealthNoFeedbackData;

  /// No description provided for @aiOcrHealthErrorBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Error Breakdown'**
  String get aiOcrHealthErrorBreakdown;

  /// No description provided for @aiOcrHealthNoErrorsWindow.
  ///
  /// In en, this message translates to:
  /// **'No OCR errors in this window.'**
  String get aiOcrHealthNoErrorsWindow;
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
