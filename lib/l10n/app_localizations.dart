import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
    Locale('en'),
    Locale('fr'),
    Locale('de'),
    Locale('pt')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'KRIPTONSHARE'**
  String get appName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @dataRoom.
  ///
  /// In en, this message translates to:
  /// **'Data Room'**
  String get dataRoom;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @premiumBadge.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM'**
  String get premiumBadge;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Ephemeral Data Room'**
  String get splashTagline;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Zero-Knowledge Encryption'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Your files are encrypted locally with AES-256 before uploading to the cloud. No one but you holds the keys.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Ephemeral Links'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Configure the physical self-destruction of your documents. Choose the exact validity duration of the secure access link.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Forensic Security'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Mitigate corporate espionage and physical leaks with dynamic watermarks and screenshot blocking.'**
  String get onboardingBody3;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get onboardingSkip;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get onboardingStart;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get onboardingNext;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Your device is the sole custodian'**
  String get authTagline;

  /// No description provided for @loginTab.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginTab;

  /// No description provided for @registerTab.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTab;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@email.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum {min} characters'**
  String passwordMinLength(int min);

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirmation required'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create free account'**
  String get registerButton;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials. Please try again.'**
  String get loginInvalidCredentials;

  /// No description provided for @registerError.
  ///
  /// In en, this message translates to:
  /// **'Could not create account. Try another email.'**
  String get registerError;

  /// No description provided for @biometricLoginReason.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to complete sign-in'**
  String get biometricLoginReason;

  /// No description provided for @biometricAuthCancelled.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication cancelled.'**
  String get biometricAuthCancelled;

  /// No description provided for @freePlanInfo.
  ///
  /// In en, this message translates to:
  /// **'Free plan: {maxMB} MB max · {maxLinks} links/month · {maxHours}h duration'**
  String freePlanInfo(int maxMB, int maxLinks, int maxHours);

  /// No description provided for @termsNotice.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you accept the data sovereignty terms. KRIPTONSHARE never stores your files in plain text.'**
  String get termsNotice;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'KRIPTONSHARE locked'**
  String get lockTitle;

  /// No description provided for @lockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint or face to unlock the app.'**
  String get lockSubtitle;

  /// No description provided for @lockVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get lockVerifying;

  /// No description provided for @unlockWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get unlockWithBiometrics;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @authCancelled.
  ///
  /// In en, this message translates to:
  /// **'Authentication cancelled.'**
  String get authCancelled;

  /// No description provided for @noSavedCredentials.
  ///
  /// In en, this message translates to:
  /// **'No saved credentials. Please sign in manually.'**
  String get noSavedCredentials;

  /// No description provided for @invalidSavedCredentials.
  ///
  /// In en, this message translates to:
  /// **'Saved credentials are no longer valid. Please sign in manually.'**
  String get invalidSavedCredentials;

  /// No description provided for @biometricSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometrics Settings'**
  String get biometricSettingsTitle;

  /// No description provided for @biometricIntro.
  ///
  /// In en, this message translates to:
  /// **'Protect access to your Data Rooms with your biometric identity.'**
  String get biometricIntro;

  /// No description provided for @biometricNotAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not available'**
  String get biometricNotAvailableTitle;

  /// No description provided for @biometricNoSensorsBody.
  ///
  /// In en, this message translates to:
  /// **'This device has no biometric sensors configured.'**
  String get biometricNoSensorsBody;

  /// No description provided for @testNow.
  ///
  /// In en, this message translates to:
  /// **'Test now'**
  String get testNow;

  /// No description provided for @verifyAgain.
  ///
  /// In en, this message translates to:
  /// **'Verify again'**
  String get verifyAgain;

  /// No description provided for @biometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get biometricUnlock;

  /// No description provided for @dataSovereigntyTitle.
  ///
  /// In en, this message translates to:
  /// **'Data sovereignty'**
  String get dataSovereigntyTitle;

  /// No description provided for @dataSovereigntyBody.
  ///
  /// In en, this message translates to:
  /// **'Your fingerprint or face never leaves the device. We do not store biometric data.'**
  String get dataSovereigntyBody;

  /// No description provided for @quickAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get quickAccessTitle;

  /// No description provided for @quickAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Unlock KRIPTONSHARE without typing your password every time.'**
  String get quickAccessBody;

  /// No description provided for @extraProtectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional protection'**
  String get extraProtectionTitle;

  /// No description provided for @extraProtectionBody.
  ///
  /// In en, this message translates to:
  /// **'Biometrics complements your password; it does not replace it.'**
  String get extraProtectionBody;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @faceId.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get faceId;

  /// No description provided for @iris.
  ///
  /// In en, this message translates to:
  /// **'Iris'**
  String get iris;

  /// No description provided for @fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get fingerprint;

  /// No description provided for @faceIdDescription.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID to unlock KRIPTONSHARE securely.'**
  String get faceIdDescription;

  /// No description provided for @irisDescription.
  ///
  /// In en, this message translates to:
  /// **'Use iris recognition to sign in.'**
  String get irisDescription;

  /// No description provided for @fingerprintDescription.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint to unlock the app quickly.'**
  String get fingerprintDescription;

  /// No description provided for @biometricEnableReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm your fingerprint or face to enable biometric unlock'**
  String get biometricEnableReason;

  /// No description provided for @biometricAuthSuccess.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication successful.'**
  String get biometricAuthSuccess;

  /// No description provided for @biometricEnableCancelled.
  ///
  /// In en, this message translates to:
  /// **'Could not enable: authentication cancelled.'**
  String get biometricEnableCancelled;

  /// No description provided for @biometricUnlockEnabledMsg.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock enabled. It will be requested after sign-in.'**
  String get biometricUnlockEnabledMsg;

  /// No description provided for @biometricUnlockDisabledMsg.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock disabled.'**
  String get biometricUnlockDisabledMsg;

  /// No description provided for @biometricQueryError.
  ///
  /// In en, this message translates to:
  /// **'Error checking biometrics: {message}'**
  String biometricQueryError(String message);

  /// No description provided for @dashboardTab.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTab;

  /// No description provided for @linksTab.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get linksTab;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @receivedFiles.
  ///
  /// In en, this message translates to:
  /// **'Received files'**
  String get receivedFiles;

  /// No description provided for @noReceivedFiles.
  ///
  /// In en, this message translates to:
  /// **'You have not received any files'**
  String get noReceivedFiles;

  /// No description provided for @receivedFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Links sent to your email will appear here'**
  String get receivedFilesHint;

  /// No description provided for @activeLinks.
  ///
  /// In en, this message translates to:
  /// **'Active links'**
  String get activeLinks;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noActiveLinks.
  ///
  /// In en, this message translates to:
  /// **'No active links'**
  String get noActiveLinks;

  /// No description provided for @createFirstDataRoom.
  ///
  /// In en, this message translates to:
  /// **'Create your first secure Data Room'**
  String get createFirstDataRoom;

  /// No description provided for @expiresLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expiresLabel;

  /// No description provided for @expiresInMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {minutes}m'**
  String expiresInMinutes(int minutes);

  /// No description provided for @expiresInHours.
  ///
  /// In en, this message translates to:
  /// **'in {hours}h'**
  String expiresInHours(int hours);

  /// No description provided for @expiresInDays.
  ///
  /// In en, this message translates to:
  /// **'in {days}d'**
  String expiresInDays(int days);

  /// No description provided for @analyticsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTooltip;

  /// No description provided for @newDataRoom.
  ///
  /// In en, this message translates to:
  /// **'New Data Room'**
  String get newDataRoom;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach File'**
  String get attachFile;

  /// No description provided for @cameraToVault.
  ///
  /// In en, this message translates to:
  /// **'Camera to Vault'**
  String get cameraToVault;

  /// No description provided for @noPublicGallery.
  ///
  /// In en, this message translates to:
  /// **'No public gallery'**
  String get noPublicGallery;

  /// No description provided for @encryptionPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Encryption password'**
  String get encryptionPasswordLabel;

  /// No description provided for @passwordNotStoredHint.
  ///
  /// In en, this message translates to:
  /// **'Not stored in the cloud'**
  String get passwordNotStoredHint;

  /// No description provided for @recipientEmailOptional.
  ///
  /// In en, this message translates to:
  /// **'Recipient email (optional)'**
  String get recipientEmailOptional;

  /// No description provided for @encryptAndGenerateLink.
  ///
  /// In en, this message translates to:
  /// **'Encrypt and generate link'**
  String get encryptAndGenerateLink;

  /// No description provided for @pdfPreviewGeneratedNotice.
  ///
  /// In en, this message translates to:
  /// **'A secure PDF preview will be generated for the recipient'**
  String get pdfPreviewGeneratedNotice;

  /// No description provided for @dataRoomReadyBanner.
  ///
  /// In en, this message translates to:
  /// **'Data Room ready on Cloudflare'**
  String get dataRoomReadyBanner;

  /// No description provided for @previewGenerationFailedNotice.
  ///
  /// In en, this message translates to:
  /// **'The file was shared, but the preview could not be generated. The recipient will be able to download it if you allow it.'**
  String get previewGenerationFailedNotice;

  /// No description provided for @protectingFiles.
  ///
  /// In en, this message translates to:
  /// **'Protecting your files...'**
  String get protectingFiles;

  /// No description provided for @encryptingAesStep.
  ///
  /// In en, this message translates to:
  /// **'> Encrypting with AES-256...'**
  String get encryptingAesStep;

  /// No description provided for @generatingPreviewStep.
  ///
  /// In en, this message translates to:
  /// **'> Generating secure preview...'**
  String get generatingPreviewStep;

  /// No description provided for @syncingR2Step.
  ///
  /// In en, this message translates to:
  /// **'> Syncing to R2...'**
  String get syncingR2Step;

  /// No description provided for @fileExceedsPlanLimit.
  ///
  /// In en, this message translates to:
  /// **'The file exceeds the {maxSize} limit of your plan'**
  String fileExceedsPlanLimit(String maxSize);

  /// No description provided for @captureExceedsPlanLimit.
  ///
  /// In en, this message translates to:
  /// **'The capture exceeds the {maxSize} limit of your plan'**
  String captureExceedsPlanLimit(String maxSize);

  /// No description provided for @cameraAccessCancelled.
  ///
  /// In en, this message translates to:
  /// **'Camera access cancelled or denied'**
  String get cameraAccessCancelled;

  /// No description provided for @enterEncryptionPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter an encryption password'**
  String get enterEncryptionPassword;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionExpired;

  /// No description provided for @filePickError.
  ///
  /// In en, this message translates to:
  /// **'Error selecting file'**
  String get filePickError;

  /// No description provided for @shareDataRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Confidential Shared Data Room'**
  String get shareDataRoomTitle;

  /// No description provided for @expirationLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiration:'**
  String get expirationLabel;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get oneHour;

  /// No description provided for @default24h.
  ///
  /// In en, this message translates to:
  /// **'24h (Default)'**
  String get default24h;

  /// No description provided for @max48Hours.
  ///
  /// In en, this message translates to:
  /// **'48 hours (Max)'**
  String get max48Hours;

  /// No description provided for @max30Days.
  ///
  /// In en, this message translates to:
  /// **'Max 30 days'**
  String get max30Days;

  /// No description provided for @daysUnit.
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String daysUnit(int count);

  /// No description provided for @hoursUnit.
  ///
  /// In en, this message translates to:
  /// **'{count} Hours'**
  String hoursUnit(int count);

  /// No description provided for @upsellTitle.
  ///
  /// In en, this message translates to:
  /// **'Sending without pauses?'**
  String get upsellTitle;

  /// No description provided for @upsellCta.
  ///
  /// In en, this message translates to:
  /// **'> Go Premium'**
  String get upsellCta;

  /// No description provided for @linkExpiresNotice.
  ///
  /// In en, this message translates to:
  /// **'This link expires in {hours}h.'**
  String linkExpiresNotice(int hours);

  /// No description provided for @adSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'IBM Cloud Security'**
  String get adSampleTitle;

  /// No description provided for @adSampleBody.
  ///
  /// In en, this message translates to:
  /// **'Protect your company\'s infrastructure.'**
  String get adSampleBody;

  /// No description provided for @adSampleCta.
  ///
  /// In en, this message translates to:
  /// **'LEARN MORE'**
  String get adSampleCta;

  /// No description provided for @searchByIdOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by ID or email'**
  String get searchByIdOrEmail;

  /// No description provided for @createLink.
  ///
  /// In en, this message translates to:
  /// **'Create link'**
  String get createLink;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noSearchResults;

  /// No description provided for @createFirstFromDashboard.
  ///
  /// In en, this message translates to:
  /// **'Create your first Data Room from the dashboard'**
  String get createFirstFromDashboard;

  /// No description provided for @deleteDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete document'**
  String get deleteDocumentTitle;

  /// No description provided for @deleteDocumentWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. The document will be permanently deleted.'**
  String get deleteDocumentWarning;

  /// No description provided for @linkRevoked.
  ///
  /// In en, this message translates to:
  /// **'Link revoked'**
  String get linkRevoked;

  /// No description provided for @documentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted'**
  String get documentDeleted;

  /// No description provided for @shareMessageTemplate.
  ///
  /// In en, this message translates to:
  /// **'Secure document via KRIPTONSHARE\n\n{url}\n\nIf the link does not open the app, use:\n{appUrl}\n\nThis link expires in {hours}h.'**
  String shareMessageTemplate(String url, String appUrl, int hours);

  /// No description provided for @hoursRemaining.
  ///
  /// In en, this message translates to:
  /// **'{hours}h remaining'**
  String hoursRemaining(int hours);

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days}d remaining'**
  String daysRemaining(int days);

  /// No description provided for @viewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String viewsCount(int count);

  /// No description provided for @activeTag.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get activeTag;

  /// No description provided for @expiredTag.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get expiredTag;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String expiresOn(String date);

  /// No description provided for @expiredLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Expired links'**
  String get expiredLinksTitle;

  /// No description provided for @noExpiredLinks.
  ///
  /// In en, this message translates to:
  /// **'No expired links'**
  String get noExpiredLinks;

  /// No description provided for @allDataRoomsActive.
  ///
  /// In en, this message translates to:
  /// **'All your Data Rooms are active'**
  String get allDataRoomsActive;

  /// No description provided for @sizeExpiredOn.
  ///
  /// In en, this message translates to:
  /// **'{size} · Expired on {date}'**
  String sizeExpiredOn(String size, String date);

  /// No description provided for @linkIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Link ID not provided'**
  String get linkIdMissing;

  /// No description provided for @linkInvalidExpiredRevoked.
  ///
  /// In en, this message translates to:
  /// **'Invalid, expired or revoked link'**
  String get linkInvalidExpiredRevoked;

  /// No description provided for @recipientOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'This file was sent to {recipient}. Sign in with that account to access it.'**
  String recipientOnlyNotice(String recipient);

  /// No description provided for @documentLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading document: {error}'**
  String documentLoadError(String error);

  /// No description provided for @invalidDecryptedFile.
  ///
  /// In en, this message translates to:
  /// **'The decrypted file is not valid. Check the password.'**
  String get invalidDecryptedFile;

  /// No description provided for @incompleteFileData.
  ///
  /// In en, this message translates to:
  /// **'Incomplete or corrupt file data.'**
  String get incompleteFileData;

  /// No description provided for @wrongPasswordOrCorrupt.
  ///
  /// In en, this message translates to:
  /// **'Wrong password or corrupt file'**
  String get wrongPasswordOrCorrupt;

  /// No description provided for @secureDocument.
  ///
  /// In en, this message translates to:
  /// **'Secure document'**
  String get secureDocument;

  /// No description provided for @encryptedFileReceived.
  ///
  /// In en, this message translates to:
  /// **'You have received an encrypted file'**
  String get encryptedFileReceived;

  /// No description provided for @senderPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the password provided by the sender to decrypt it'**
  String get senderPasswordPrompt;

  /// No description provided for @decryptionPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Decryption password'**
  String get decryptionPasswordLabel;

  /// No description provided for @decryptAndView.
  ///
  /// In en, this message translates to:
  /// **'Decrypt and view'**
  String get decryptAndView;

  /// No description provided for @selfDestructNotice.
  ///
  /// In en, this message translates to:
  /// **'This document self-destructs after expiry. It is not stored on your device.'**
  String get selfDestructNotice;

  /// No description provided for @decryptingDocument.
  ///
  /// In en, this message translates to:
  /// **'Decrypting document...'**
  String get decryptingDocument;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get unexpectedError;

  /// No description provided for @pdfOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the PDF:\n{error}'**
  String pdfOpenError(String error);

  /// No description provided for @pdfViewerFallback.
  ///
  /// In en, this message translates to:
  /// **'The native viewer could not display this PDF. For security reasons it cannot be opened outside the app.'**
  String get pdfViewerFallback;

  /// No description provided for @decryptedVideo.
  ///
  /// In en, this message translates to:
  /// **'Decrypted video'**
  String get decryptedVideo;

  /// No description provided for @playVideo.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get playVideo;

  /// No description provided for @protectedFormat.
  ///
  /// In en, this message translates to:
  /// **'Protected format'**
  String get protectedFormat;

  /// No description provided for @officeNotViewable.
  ///
  /// In en, this message translates to:
  /// **'Microsoft Office documents and other formats cannot be viewed directly inside the app for security reasons.'**
  String get officeNotViewable;

  /// No description provided for @convertToPdfAdvice.
  ///
  /// In en, this message translates to:
  /// **'To share this content securely, convert it to PDF before uploading.'**
  String get convertToPdfAdvice;

  /// No description provided for @confidentialBanner.
  ///
  /// In en, this message translates to:
  /// **'KRIPTONSHARE | CONFIDENTIAL'**
  String get confidentialBanner;

  /// No description provided for @secureMode.
  ///
  /// In en, this message translates to:
  /// **'SECURE MODE'**
  String get secureMode;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @videoPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Could not play the video: {error}'**
  String videoPlaybackError(String error);

  /// No description provided for @fileSizeAndType.
  ///
  /// In en, this message translates to:
  /// **'{size} · {mimeType}'**
  String fileSizeAndType(String size, String mimeType);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @yourCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Your current plan'**
  String get yourCurrentPlan;

  /// No description provided for @maxFileSize.
  ///
  /// In en, this message translates to:
  /// **'Maximum file size'**
  String get maxFileSize;

  /// No description provided for @dataRoomStorage.
  ///
  /// In en, this message translates to:
  /// **'Data Room storage'**
  String get dataRoomStorage;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @monthlyLinks.
  ///
  /// In en, this message translates to:
  /// **'Monthly links'**
  String get monthlyLinks;

  /// No description provided for @maxDuration.
  ///
  /// In en, this message translates to:
  /// **'Maximum duration'**
  String get maxDuration;

  /// No description provided for @hoursValue.
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String hoursValue(int count);

  /// No description provided for @encryptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get encryptionLabel;

  /// No description provided for @watermarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get watermarkLabel;

  /// No description provided for @institutionalPassiveWatermark.
  ///
  /// In en, this message translates to:
  /// **'Institutional passive'**
  String get institutionalPassiveWatermark;

  /// No description provided for @biometricsLabel.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get biometricsLabel;

  /// No description provided for @configureBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Set up fingerprint or Face ID'**
  String get configureBiometrics;

  /// No description provided for @unlockFullCapacity.
  ///
  /// In en, this message translates to:
  /// **'Unlock full capacity'**
  String get unlockFullCapacity;

  /// No description provided for @premiumBenefits.
  ///
  /// In en, this message translates to:
  /// **'100 MB per file, unlimited links, custom expiration, dynamic forensic watermark.'**
  String get premiumBenefits;

  /// No description provided for @managePremiumVault.
  ///
  /// In en, this message translates to:
  /// **'Manage Premium Vault'**
  String get managePremiumVault;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @dataRoomsMetrics.
  ///
  /// In en, this message translates to:
  /// **'Your Data Rooms metrics'**
  String get dataRoomsMetrics;

  /// No description provided for @topLinks.
  ///
  /// In en, this message translates to:
  /// **'Top Links'**
  String get topLinks;

  /// No description provided for @linkEvents.
  ///
  /// In en, this message translates to:
  /// **'Link events'**
  String get linkEvents;

  /// No description provided for @viewExpiredLinks.
  ///
  /// In en, this message translates to:
  /// **'View expired links'**
  String get viewExpiredLinks;

  /// No description provided for @totalLinks.
  ///
  /// In en, this message translates to:
  /// **'Total links'**
  String get totalLinks;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @expiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredLabel;

  /// No description provided for @totalViews.
  ///
  /// In en, this message translates to:
  /// **'Total views'**
  String get totalViews;

  /// No description provided for @downloadsLabel.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsLabel;

  /// No description provided for @avgDuration.
  ///
  /// In en, this message translates to:
  /// **'Average duration'**
  String get avgDuration;

  /// No description provided for @events24h.
  ///
  /// In en, this message translates to:
  /// **'24h events'**
  String get events24h;

  /// No description provided for @storageLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageLabel;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;

  /// No description provided for @topLinksEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Your most viewed links will appear here'**
  String get topLinksEmptyHint;

  /// No description provided for @unnamedDocument.
  ///
  /// In en, this message translates to:
  /// **'Unnamed document'**
  String get unnamedDocument;

  /// No description provided for @viewsDownloadsSummary.
  ///
  /// In en, this message translates to:
  /// **'{views} views · {downloads} downloads'**
  String viewsDownloadsSummary(int views, int downloads);

  /// No description provided for @noEventsForLink.
  ///
  /// In en, this message translates to:
  /// **'No events recorded for this link'**
  String get noEventsForLink;

  /// No description provided for @pageN.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String pageN(int number);

  /// No description provided for @eventPageView.
  ///
  /// In en, this message translates to:
  /// **'Page view'**
  String get eventPageView;

  /// No description provided for @eventDownloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download completed'**
  String get eventDownloadComplete;

  /// No description provided for @eventDownloadStart.
  ///
  /// In en, this message translates to:
  /// **'Download started'**
  String get eventDownloadStart;

  /// No description provided for @eventScreenshotBlocked.
  ///
  /// In en, this message translates to:
  /// **'Screenshot blocked'**
  String get eventScreenshotBlocked;

  /// No description provided for @enterDataRoomPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the Data Room password'**
  String get enterDataRoomPassword;

  /// No description provided for @dataRoomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Data Room not found'**
  String get dataRoomNotFound;

  /// No description provided for @dataRoomPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Data Room password'**
  String get dataRoomPasswordLabel;

  /// No description provided for @selectFileToDecrypt.
  ///
  /// In en, this message translates to:
  /// **'Select a file to decrypt it in RAM'**
  String get selectFileToDecrypt;

  /// No description provided for @encryptedFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Encrypted Files · {size}'**
  String encryptedFilesCount(int count, String size);

  /// No description provided for @aes256Encrypted.
  ///
  /// In en, this message translates to:
  /// **'{size} · AES-256 encrypted'**
  String aes256Encrypted(String size);

  /// No description provided for @officeDocsNotViewable.
  ///
  /// In en, this message translates to:
  /// **'Office documents cannot be viewed directly for security reasons.'**
  String get officeDocsNotViewable;

  /// No description provided for @confidentialUserWatermark.
  ///
  /// In en, this message translates to:
  /// **'{email} • CONFIDENTIAL'**
  String confidentialUserWatermark(String email);

  /// No description provided for @storageManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault & Data Room Storage'**
  String get storageManagementTitle;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM ACTIVE'**
  String get premiumActive;

  /// No description provided for @freePlanBadge.
  ///
  /// In en, this message translates to:
  /// **'FREE PLAN'**
  String get freePlanBadge;

  /// No description provided for @dataRoomCapacity.
  ///
  /// In en, this message translates to:
  /// **'Data Room capacity'**
  String get dataRoomCapacity;

  /// No description provided for @storageUsedOf.
  ///
  /// In en, this message translates to:
  /// **'{used} / {max} Used'**
  String storageUsedOf(String used, String max);

  /// No description provided for @expandDataRoomAddon.
  ///
  /// In en, this message translates to:
  /// **'Expand Data Room (+1 GB for \$5/month)'**
  String get expandDataRoomAddon;

  /// No description provided for @subscriptionOptions.
  ///
  /// In en, this message translates to:
  /// **'Subscription Options'**
  String get subscriptionOptions;

  /// No description provided for @monthlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyPlan;

  /// No description provided for @monthlyPrice.
  ///
  /// In en, this message translates to:
  /// **'\$19.00 / month'**
  String get monthlyPrice;

  /// No description provided for @annualPlan.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annualPlan;

  /// No description provided for @annualPrice.
  ///
  /// In en, this message translates to:
  /// **'\$189.00 / year'**
  String get annualPrice;

  /// No description provided for @annualSavings.
  ///
  /// In en, this message translates to:
  /// **'You save \$39 USD/year'**
  String get annualSavings;

  /// No description provided for @subscribeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to Premium'**
  String get subscribeToPremium;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @testModeLabel.
  ///
  /// In en, this message translates to:
  /// **'TEST MODE (debug)'**
  String get testModeLabel;

  /// No description provided for @testModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable Premium without RevenueCat or Google Cloud to evaluate the interface.'**
  String get testModeDescription;

  /// No description provided for @deactivateTestPremium.
  ///
  /// In en, this message translates to:
  /// **'Deactivate test Premium'**
  String get deactivateTestPremium;

  /// No description provided for @activateTestPremium.
  ///
  /// In en, this message translates to:
  /// **'Activate test Premium'**
  String get activateTestPremium;

  /// No description provided for @testPremiumActivated.
  ///
  /// In en, this message translates to:
  /// **'Test Premium activated'**
  String get testPremiumActivated;

  /// No description provided for @testPremiumDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Test Premium deactivated'**
  String get testPremiumDeactivated;

  /// No description provided for @noOfferingsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No offerings available'**
  String get noOfferingsAvailable;

  /// No description provided for @subscriptionActivated.
  ///
  /// In en, this message translates to:
  /// **'Subscription activated'**
  String get subscriptionActivated;

  /// No description provided for @noAddonsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No add-ons available'**
  String get noAddonsAvailable;

  /// No description provided for @storageExpanded.
  ///
  /// In en, this message translates to:
  /// **'Storage expanded'**
  String get storageExpanded;

  /// No description provided for @remainingLinks.
  ///
  /// In en, this message translates to:
  /// **'{remaining} remaining'**
  String remainingLinks(int remaining);

  /// No description provided for @freePlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get freePlanLabel;

  /// No description provided for @errorUserNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get errorUserNotAuthenticated;

  /// No description provided for @errorQuotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'Quota limit exceeded'**
  String get errorQuotaExceeded;

  /// No description provided for @errorUploadNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Upload cannot be completed. Check your plan limits.'**
  String get errorUploadNotAllowed;

  /// No description provided for @errorSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in'**
  String get errorSignInFailed;

  /// No description provided for @errorUserRecordMissing.
  ///
  /// In en, this message translates to:
  /// **'Authenticated user not found in the users table.'**
  String get errorUserRecordMissing;

  /// No description provided for @errorCreateRoomFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the Data Room'**
  String get errorCreateRoomFailed;

  /// No description provided for @errorInvalidLinkFragment.
  ///
  /// In en, this message translates to:
  /// **'Invalid link: missing fragment'**
  String get errorInvalidLinkFragment;

  /// No description provided for @errorInvalidKey.
  ///
  /// In en, this message translates to:
  /// **'Invalid key'**
  String get errorInvalidKey;

  /// No description provided for @errorDecryptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Decryption error'**
  String get errorDecryptionFailed;

  /// No description provided for @errorDecryptionWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Decryption error: {error}'**
  String errorDecryptionWithDetail(String error);

  /// No description provided for @dataRoomExplorerTitle.
  ///
  /// In en, this message translates to:
  /// **'My Data Room Vault'**
  String get dataRoomExplorerTitle;

  /// No description provided for @premiumCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM DATA ROOM CAPACITY'**
  String get premiumCapacityLabel;

  /// No description provided for @storageUsedSummary.
  ///
  /// In en, this message translates to:
  /// **'{used} of {max} used ({percent}%)'**
  String storageUsedSummary(String used, String max, int percent);

  /// No description provided for @expandVaultAddon.
  ///
  /// In en, this message translates to:
  /// **'Expand Vault (+1 GB for \$5/month)'**
  String get expandVaultAddon;

  /// No description provided for @uploadFileMax.
  ///
  /// In en, this message translates to:
  /// **'Upload file (≤ 100 MB)'**
  String get uploadFileMax;

  /// No description provided for @newVirtualFolder.
  ///
  /// In en, this message translates to:
  /// **'New virtual folder'**
  String get newVirtualFolder;

  /// No description provided for @batchUploadAction.
  ///
  /// In en, this message translates to:
  /// **'Batch upload to folder'**
  String get batchUploadAction;

  /// No description provided for @batchUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Multiple selection'**
  String get batchUploadHint;

  /// No description provided for @virtualFoldersSection.
  ///
  /// In en, this message translates to:
  /// **'Virtual folders'**
  String get virtualFoldersSection;

  /// No description provided for @unfiledFilesSection.
  ///
  /// In en, this message translates to:
  /// **'Individual files in vault'**
  String get unfiledFilesSection;

  /// No description provided for @folderCardSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} files · {size}'**
  String folderCardSummary(int count, String size);

  /// No description provided for @linkStatusActiveExpires.
  ///
  /// In en, this message translates to:
  /// **'Link: Active (expires in {days} days)'**
  String linkStatusActiveExpires(int days);

  /// No description provided for @sendAction.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendAction;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortByLastModified.
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get sortByLastModified;

  /// No description provided for @sortBySize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sortBySize;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get gridView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @emptyDataRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Data Room is empty'**
  String get emptyDataRoomTitle;

  /// No description provided for @emptyDataRoomHint.
  ///
  /// In en, this message translates to:
  /// **'Upload encrypted files or create your first virtual folder'**
  String get emptyDataRoomHint;

  /// No description provided for @folderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderNameLabel;

  /// No description provided for @folderDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get folderDescriptionLabel;

  /// No description provided for @createFolder.
  ///
  /// In en, this message translates to:
  /// **'Create folder'**
  String get createFolder;

  /// No description provided for @folderCreated.
  ///
  /// In en, this message translates to:
  /// **'Folder created'**
  String get folderCreated;

  /// No description provided for @batchUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch upload'**
  String get batchUploadTitle;

  /// No description provided for @batchProgressSummary.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} files uploaded'**
  String batchProgressSummary(int completed, int total);

  /// No description provided for @batchCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} files encrypted in Data Room'**
  String batchCompletedMessage(int count);

  /// No description provided for @batchFileSkippedTooLarge.
  ///
  /// In en, this message translates to:
  /// **'{filename} exceeds 100 MB and was skipped'**
  String batchFileSkippedTooLarge(String filename);

  /// No description provided for @selectDestinationFolder.
  ///
  /// In en, this message translates to:
  /// **'Select destination folder'**
  String get selectDestinationFolder;

  /// No description provided for @filesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} files selected'**
  String filesSelected(int count);

  /// No description provided for @dataRoomLobbyTitle.
  ///
  /// In en, this message translates to:
  /// **'DATA ROOM: {name}'**
  String dataRoomLobbyTitle(String name);

  /// No description provided for @linkExpiresInLabel.
  ///
  /// In en, this message translates to:
  /// **'Link expires in: {days} days'**
  String linkExpiresInLabel(int days);

  /// No description provided for @recipientEmailRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to access the documents'**
  String get recipientEmailRequiredTitle;

  /// No description provided for @dataRoomAccessAuditNotice.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to continue. Access will be audited.'**
  String get dataRoomAccessAuditNotice;

  /// No description provided for @accessAction.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get accessAction;

  /// No description provided for @availableDocumentsSection.
  ///
  /// In en, this message translates to:
  /// **'Documents available in the folder'**
  String get availableDocumentsSection;

  /// No description provided for @encryptedAtOrigin.
  ///
  /// In en, this message translates to:
  /// **'Encrypted at source'**
  String get encryptedAtOrigin;

  /// No description provided for @openAndDecryptInRam.
  ///
  /// In en, this message translates to:
  /// **'Open and decrypt in RAM'**
  String get openAndDecryptInRam;

  /// No description provided for @ramDecryptionNotice.
  ///
  /// In en, this message translates to:
  /// **'Documents are decrypted exclusively in volatile RAM and are covered by active read auditing.'**
  String get ramDecryptionNotice;

  /// No description provided for @shareSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Share securely'**
  String get shareSheetTitle;

  /// No description provided for @shareSingleFile.
  ///
  /// In en, this message translates to:
  /// **'Single file'**
  String get shareSingleFile;

  /// No description provided for @shareFullFolder.
  ///
  /// In en, this message translates to:
  /// **'Full folder'**
  String get shareFullFolder;

  /// No description provided for @requireRecipientEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Require recipient email'**
  String get requireRecipientEmailLabel;

  /// No description provided for @requireRecipientEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The recipient must enter their email before accessing'**
  String get requireRecipientEmailSubtitle;

  /// No description provided for @enableWatermarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Dynamic watermark'**
  String get enableWatermarkLabel;

  /// No description provided for @enableWatermarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Overlays recipient email, IP and date on the document'**
  String get enableWatermarkSubtitle;

  /// No description provided for @expirationPremiumNotice.
  ///
  /// In en, this message translates to:
  /// **'Premium: links can last up to 30 days'**
  String get expirationPremiumNotice;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @shareQrCode.
  ///
  /// In en, this message translates to:
  /// **'Share QR code'**
  String get shareQrCode;

  /// No description provided for @errorExpirationMustBeFuture.
  ///
  /// In en, this message translates to:
  /// **'The expiration date must be in the future.'**
  String get errorExpirationMustBeFuture;

  /// No description provided for @errorExpirationPremiumMax.
  ///
  /// In en, this message translates to:
  /// **'Premium: the maximum link expiration is 30 days.'**
  String get errorExpirationPremiumMax;

  /// No description provided for @errorExpirationFreemiumMax.
  ///
  /// In en, this message translates to:
  /// **'Free plan: the maximum link expiration is 48 hours.'**
  String get errorExpirationFreemiumMax;

  /// No description provided for @expirationPremiumValid.
  ///
  /// In en, this message translates to:
  /// **'Valid Premium expiration (≤ 30 days).'**
  String get expirationPremiumValid;

  /// No description provided for @expirationFreemiumValid.
  ///
  /// In en, this message translates to:
  /// **'Valid Free expiration (≤ 48 h).'**
  String get expirationFreemiumValid;

  /// No description provided for @eventLobbyEnter.
  ///
  /// In en, this message translates to:
  /// **'Lobby entered'**
  String get eventLobbyEnter;

  /// No description provided for @eventFileOpen.
  ///
  /// In en, this message translates to:
  /// **'File opened'**
  String get eventFileOpen;

  /// No description provided for @eventLobbyExit.
  ///
  /// In en, this message translates to:
  /// **'Lobby exited'**
  String get eventLobbyExit;
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
      <String>['de', 'en', 'es', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
