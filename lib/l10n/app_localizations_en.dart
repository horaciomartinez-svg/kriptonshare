// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'KRIPTONSHARE';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get delete => 'Delete';

  @override
  String get share => 'Share';

  @override
  String get revoke => 'Revoke';

  @override
  String get dataRoom => 'Data Room';

  @override
  String get premium => 'Premium';

  @override
  String get premiumBadge => 'PREMIUM';

  @override
  String get free => 'Free';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select language';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get splashTagline => 'Ephemeral Data Room';

  @override
  String get onboardingTitle1 => 'Zero-Knowledge Encryption';

  @override
  String get onboardingBody1 =>
      'Your files are encrypted locally with AES-256 before uploading to the cloud. No one but you holds the keys.';

  @override
  String get onboardingTitle2 => 'Ephemeral Links';

  @override
  String get onboardingBody2 =>
      'Configure the physical self-destruction of your documents. Choose the exact validity duration of the secure access link.';

  @override
  String get onboardingTitle3 => 'Forensic Security';

  @override
  String get onboardingBody3 =>
      'Mitigate corporate espionage and physical leaks with dynamic watermarks and screenshot blocking.';

  @override
  String get onboardingSkip => 'SKIP';

  @override
  String get onboardingStart => 'START';

  @override
  String get onboardingNext => 'NEXT';

  @override
  String get authTagline => 'Your device is the sole custodian';

  @override
  String get loginTab => 'Sign In';

  @override
  String get registerTab => 'Create Account';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'you@email.com';

  @override
  String get emailRequired => 'Email required';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordRequired => 'Password required';

  @override
  String passwordMinLength(int min) {
    return 'Minimum $min characters';
  }

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get confirmPasswordRequired => 'Confirmation required';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get loginButton => 'Sign In';

  @override
  String get registerButton => 'Create free account';

  @override
  String get loginInvalidCredentials =>
      'Invalid credentials. Please try again.';

  @override
  String get registerError => 'Could not create account. Try another email.';

  @override
  String get biometricLoginReason => 'Verify your identity to complete sign-in';

  @override
  String get biometricAuthCancelled => 'Biometric authentication cancelled.';

  @override
  String freePlanInfo(int maxMB, int maxLinks, int maxHours) {
    return 'Free plan: $maxMB MB max · $maxLinks links/month · ${maxHours}h duration';
  }

  @override
  String get termsNotice =>
      'By signing up, you accept the data sovereignty terms. KRIPTONSHARE never stores your files in plain text.';

  @override
  String get lockTitle => 'KRIPTONSHARE locked';

  @override
  String get lockSubtitle => 'Use your fingerprint or face to unlock the app.';

  @override
  String get lockVerifying => 'Verifying...';

  @override
  String get unlockWithBiometrics => 'Unlock with biometrics';

  @override
  String get signOut => 'Sign Out';

  @override
  String get authCancelled => 'Authentication cancelled.';

  @override
  String get noSavedCredentials =>
      'No saved credentials. Please sign in manually.';

  @override
  String get invalidSavedCredentials =>
      'Saved credentials are no longer valid. Please sign in manually.';

  @override
  String get biometricSettingsTitle => 'Biometrics Settings';

  @override
  String get biometricIntro =>
      'Protect access to your Data Rooms with your biometric identity.';

  @override
  String get biometricNotAvailableTitle => 'Biometrics not available';

  @override
  String get biometricNoSensorsBody =>
      'This device has no biometric sensors configured.';

  @override
  String get testNow => 'Test now';

  @override
  String get verifyAgain => 'Verify again';

  @override
  String get biometricUnlock => 'Biometric unlock';

  @override
  String get dataSovereigntyTitle => 'Data sovereignty';

  @override
  String get dataSovereigntyBody =>
      'Your fingerprint or face never leaves the device. We do not store biometric data.';

  @override
  String get quickAccessTitle => 'Quick access';

  @override
  String get quickAccessBody =>
      'Unlock KRIPTONSHARE without typing your password every time.';

  @override
  String get extraProtectionTitle => 'Additional protection';

  @override
  String get extraProtectionBody =>
      'Biometrics complements your password; it does not replace it.';

  @override
  String get securityTitle => 'Security';

  @override
  String get faceId => 'Face ID';

  @override
  String get iris => 'Iris';

  @override
  String get fingerprint => 'Fingerprint';

  @override
  String get faceIdDescription =>
      'Use Face ID to unlock KRIPTONSHARE securely.';

  @override
  String get irisDescription => 'Use iris recognition to sign in.';

  @override
  String get fingerprintDescription =>
      'Use your fingerprint to unlock the app quickly.';

  @override
  String get biometricEnableReason =>
      'Confirm your fingerprint or face to enable biometric unlock';

  @override
  String get biometricAuthSuccess => 'Biometric authentication successful.';

  @override
  String get biometricEnableCancelled =>
      'Could not enable: authentication cancelled.';

  @override
  String get biometricUnlockEnabledMsg =>
      'Biometric unlock enabled. It will be requested after sign-in.';

  @override
  String get biometricUnlockDisabledMsg => 'Biometric unlock disabled.';

  @override
  String biometricQueryError(String message) {
    return 'Error checking biometrics: $message';
  }

  @override
  String get dashboardTab => 'Dashboard';

  @override
  String get linksTab => 'Links';

  @override
  String get profileTab => 'Profile';

  @override
  String get welcome => 'Welcome';

  @override
  String get capacity => 'Capacity';

  @override
  String get duration => 'Duration';

  @override
  String get plan => 'Plan';

  @override
  String get receivedFiles => 'Received files';

  @override
  String get noReceivedFiles => 'You have not received any files';

  @override
  String get receivedFilesHint => 'Links sent to your email will appear here';

  @override
  String get activeLinks => 'Active links';

  @override
  String get viewAll => 'View all';

  @override
  String get noActiveLinks => 'No active links';

  @override
  String get createFirstDataRoom => 'Create your first secure Data Room';

  @override
  String get expiresLabel => 'Expires';

  @override
  String expiresInMinutes(int minutes) {
    return 'in ${minutes}m';
  }

  @override
  String expiresInHours(int hours) {
    return 'in ${hours}h';
  }

  @override
  String expiresInDays(int days) {
    return 'in ${days}d';
  }

  @override
  String get analyticsTooltip => 'Analytics';

  @override
  String get newDataRoom => 'New Data Room';

  @override
  String get attachFile => 'Attach File';

  @override
  String get cameraToVault => 'Camera to Vault';

  @override
  String get noPublicGallery => 'No public gallery';

  @override
  String get encryptionPasswordLabel => 'Encryption password';

  @override
  String get passwordNotStoredHint => 'Not stored in the cloud';

  @override
  String get recipientEmailOptional => 'Recipient email (optional)';

  @override
  String get encryptAndGenerateLink => 'Encrypt and generate link';

  @override
  String get pdfPreviewGeneratedNotice =>
      'A secure PDF preview will be generated for the recipient';

  @override
  String get dataRoomReadyBanner => 'Data Room ready on Cloudflare';

  @override
  String get previewGenerationFailedNotice =>
      'The file was shared, but the preview could not be generated. The recipient will be able to download it if you allow it.';

  @override
  String get protectingFiles => 'Protecting your files...';

  @override
  String get encryptingAesStep => '> Encrypting with AES-256...';

  @override
  String get generatingPreviewStep => '> Generating secure preview...';

  @override
  String get syncingR2Step => '> Syncing to R2...';

  @override
  String fileExceedsPlanLimit(String maxSize) {
    return 'The file exceeds the $maxSize limit of your plan';
  }

  @override
  String captureExceedsPlanLimit(String maxSize) {
    return 'The capture exceeds the $maxSize limit of your plan';
  }

  @override
  String get cameraAccessCancelled => 'Camera access cancelled or denied';

  @override
  String get enterEncryptionPassword => 'Enter an encryption password';

  @override
  String get sessionExpired => 'Session expired';

  @override
  String get filePickError => 'Error selecting file';

  @override
  String get shareDataRoomTitle => 'Confidential Shared Data Room';

  @override
  String get expirationLabel => 'Expiration:';

  @override
  String get oneHour => '1 hour';

  @override
  String get default24h => '24h (Default)';

  @override
  String get max48Hours => '48 hours (Max)';

  @override
  String get max30Days => 'Max 30 days';

  @override
  String daysUnit(int count) {
    return '$count Days';
  }

  @override
  String hoursUnit(int count) {
    return '$count Hours';
  }

  @override
  String get upsellTitle => 'Sending without pauses?';

  @override
  String get upsellCta => '> Go Premium';

  @override
  String linkExpiresNotice(int hours) {
    return 'This link expires in ${hours}h.';
  }

  @override
  String get adSampleTitle => 'IBM Cloud Security';

  @override
  String get adSampleBody => 'Protect your company\'s infrastructure.';

  @override
  String get adSampleCta => 'LEARN MORE';

  @override
  String get searchByIdOrEmail => 'Search by ID or email';

  @override
  String get createLink => 'Create link';

  @override
  String get noSearchResults => 'No results found';

  @override
  String get createFirstFromDashboard =>
      'Create your first Data Room from the dashboard';

  @override
  String get deleteDocumentTitle => 'Delete document';

  @override
  String get deleteDocumentWarning =>
      'This action is irreversible. The document will be permanently deleted.';

  @override
  String get linkRevoked => 'Link revoked';

  @override
  String get documentDeleted => 'Document deleted';

  @override
  String shareMessageTemplate(String url, String appUrl, int hours) {
    return 'Secure document via KRIPTONSHARE\n\n$url\n\nIf the link does not open the app, use:\n$appUrl\n\nThis link expires in ${hours}h.';
  }

  @override
  String hoursRemaining(int hours) {
    return '${hours}h remaining';
  }

  @override
  String daysRemaining(int days) {
    return '${days}d remaining';
  }

  @override
  String viewsCount(int count) {
    return '$count views';
  }

  @override
  String get activeTag => 'ACTIVE';

  @override
  String get expiredTag => 'EXPIRED';

  @override
  String expiresOn(String date) {
    return 'Expires: $date';
  }

  @override
  String get expiredLinksTitle => 'Expired links';

  @override
  String get noExpiredLinks => 'No expired links';

  @override
  String get allDataRoomsActive => 'All your Data Rooms are active';

  @override
  String sizeExpiredOn(String size, String date) {
    return '$size · Expired on $date';
  }

  @override
  String get linkIdMissing => 'Link ID not provided';

  @override
  String get linkInvalidExpiredRevoked => 'Invalid, expired or revoked link';

  @override
  String recipientOnlyNotice(String recipient) {
    return 'This file was sent to $recipient. Sign in with that account to access it.';
  }

  @override
  String documentLoadError(String error) {
    return 'Error loading document: $error';
  }

  @override
  String get invalidDecryptedFile =>
      'The decrypted file is not valid. Check the password.';

  @override
  String get incompleteFileData => 'Incomplete or corrupt file data.';

  @override
  String get wrongPasswordOrCorrupt => 'Wrong password or corrupt file';

  @override
  String get secureDocument => 'Secure document';

  @override
  String get encryptedFileReceived => 'You have received an encrypted file';

  @override
  String get senderPasswordPrompt =>
      'Enter the password provided by the sender to decrypt it';

  @override
  String get decryptionPasswordLabel => 'Decryption password';

  @override
  String get decryptAndView => 'Decrypt and view';

  @override
  String get selfDestructNotice =>
      'This document self-destructs after expiry. It is not stored on your device.';

  @override
  String get decryptingDocument => 'Decrypting document...';

  @override
  String get unexpectedError => 'Unexpected error';

  @override
  String pdfOpenError(String error) {
    return 'Could not open the PDF:\n$error';
  }

  @override
  String get pdfViewerFallback =>
      'The native viewer could not display this PDF. For security reasons it cannot be opened outside the app.';

  @override
  String get decryptedVideo => 'Decrypted video';

  @override
  String get playVideo => 'Play video';

  @override
  String get protectedFormat => 'Protected format';

  @override
  String get officeNotViewable =>
      'Microsoft Office documents and other formats cannot be viewed directly inside the app for security reasons.';

  @override
  String get convertToPdfAdvice =>
      'To share this content securely, convert it to PDF before uploading.';

  @override
  String get confidentialBanner => 'KRIPTONSHARE | CONFIDENTIAL';

  @override
  String get secureMode => 'SECURE MODE';

  @override
  String get backToHome => 'Back to home';

  @override
  String get unknownError => 'Unknown error';

  @override
  String videoPlaybackError(String error) {
    return 'Could not play the video: $error';
  }

  @override
  String fileSizeAndType(String size, String mimeType) {
    return '$size · $mimeType';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get yourCurrentPlan => 'Your current plan';

  @override
  String get maxFileSize => 'Maximum file size';

  @override
  String get dataRoomStorage => 'Data Room storage';

  @override
  String get notAvailable => 'Not available';

  @override
  String get monthlyLinks => 'Monthly links';

  @override
  String get maxDuration => 'Maximum duration';

  @override
  String hoursValue(int count) {
    return '$count hours';
  }

  @override
  String get encryptionLabel => 'Encryption';

  @override
  String get watermarkLabel => 'Watermark';

  @override
  String get institutionalPassiveWatermark => 'Institutional passive';

  @override
  String get biometricsLabel => 'Biometrics';

  @override
  String get configureBiometrics => 'Set up fingerprint or Face ID';

  @override
  String get unlockFullCapacity => 'Unlock full capacity';

  @override
  String get premiumBenefits =>
      '100 MB per file, unlimited links, custom expiration, dynamic forensic watermark.';

  @override
  String get managePremiumVault => 'Manage Premium Vault';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get dataRoomsMetrics => 'Your Data Rooms metrics';

  @override
  String get topLinks => 'Top Links';

  @override
  String get linkEvents => 'Link events';

  @override
  String get viewExpiredLinks => 'View expired links';

  @override
  String get totalLinks => 'Total links';

  @override
  String get activeLabel => 'Active';

  @override
  String get expiredLabel => 'Expired';

  @override
  String get totalViews => 'Total views';

  @override
  String get downloadsLabel => 'Downloads';

  @override
  String get avgDuration => 'Average duration';

  @override
  String get events24h => '24h events';

  @override
  String get storageLabel => 'Storage';

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get topLinksEmptyHint => 'Your most viewed links will appear here';

  @override
  String get unnamedDocument => 'Unnamed document';

  @override
  String viewsDownloadsSummary(int views, int downloads) {
    return '$views views · $downloads downloads';
  }

  @override
  String get noEventsForLink => 'No events recorded for this link';

  @override
  String pageN(int number) {
    return 'Page $number';
  }

  @override
  String get eventPageView => 'Page view';

  @override
  String get eventDownloadComplete => 'Download completed';

  @override
  String get eventDownloadStart => 'Download started';

  @override
  String get eventScreenshotBlocked => 'Screenshot blocked';

  @override
  String get enterDataRoomPassword => 'Enter the Data Room password';

  @override
  String get dataRoomNotFound => 'Data Room not found';

  @override
  String get dataRoomPasswordLabel => 'Data Room password';

  @override
  String get selectFileToDecrypt => 'Select a file to decrypt it in RAM';

  @override
  String encryptedFilesCount(int count, String size) {
    return '$count Encrypted Files · $size';
  }

  @override
  String aes256Encrypted(String size) {
    return '$size · AES-256 encrypted';
  }

  @override
  String get officeDocsNotViewable =>
      'Office documents cannot be viewed directly for security reasons.';

  @override
  String confidentialUserWatermark(String email) {
    return '$email • CONFIDENTIAL';
  }

  @override
  String get storageManagementTitle => 'Vault & Data Room Storage';

  @override
  String get premiumActive => 'PREMIUM ACTIVE';

  @override
  String get freePlanBadge => 'FREE PLAN';

  @override
  String get dataRoomCapacity => 'Data Room capacity';

  @override
  String storageUsedOf(String used, String max) {
    return '$used / $max Used';
  }

  @override
  String get expandDataRoomAddon => 'Expand Data Room (+1 GB for \$5/month)';

  @override
  String get subscriptionOptions => 'Subscription Options';

  @override
  String get monthlyPlan => 'Monthly';

  @override
  String get monthlyPrice => '\$19.00 / month';

  @override
  String get annualPlan => 'Annual';

  @override
  String get annualPrice => '\$189.00 / year';

  @override
  String get annualSavings => 'You save \$39 USD/year';

  @override
  String get subscribeToPremium => 'Subscribe to Premium';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get testModeLabel => 'TEST MODE (debug)';

  @override
  String get testModeDescription =>
      'Enable Premium without RevenueCat or Google Cloud to evaluate the interface.';

  @override
  String get deactivateTestPremium => 'Deactivate test Premium';

  @override
  String get activateTestPremium => 'Activate test Premium';

  @override
  String get testPremiumActivated => 'Test Premium activated';

  @override
  String get testPremiumDeactivated => 'Test Premium deactivated';

  @override
  String get noOfferingsAvailable => 'No offerings available';

  @override
  String get subscriptionActivated => 'Subscription activated';

  @override
  String get noAddonsAvailable => 'No add-ons available';

  @override
  String get storageExpanded => 'Storage expanded';

  @override
  String remainingLinks(int remaining) {
    return '$remaining remaining';
  }

  @override
  String get freePlanLabel => 'Free plan';

  @override
  String get errorUserNotAuthenticated => 'User not authenticated';

  @override
  String get errorQuotaExceeded => 'Quota limit exceeded';

  @override
  String get errorUploadNotAllowed =>
      'Upload cannot be completed. Check your plan limits.';

  @override
  String get errorSignInFailed => 'Could not sign in';

  @override
  String get errorUserRecordMissing =>
      'Authenticated user not found in the users table.';

  @override
  String get errorCreateRoomFailed => 'Could not create the Data Room';

  @override
  String get errorInvalidLinkFragment => 'Invalid link: missing fragment';

  @override
  String get errorInvalidKey => 'Invalid key';

  @override
  String get errorDecryptionFailed => 'Decryption error';

  @override
  String errorDecryptionWithDetail(String error) {
    return 'Decryption error: $error';
  }

  @override
  String get dataRoomExplorerTitle => 'My Data Room Vault';

  @override
  String get premiumCapacityLabel => 'PREMIUM DATA ROOM CAPACITY';

  @override
  String storageUsedSummary(String used, String max, int percent) {
    return '$used of $max used ($percent%)';
  }

  @override
  String get expandVaultAddon => 'Expand Vault (+1 GB for \$5/month)';

  @override
  String get uploadFileMax => 'Upload file (≤ 100 MB)';

  @override
  String get newVirtualFolder => 'New virtual folder';

  @override
  String get batchUploadAction => 'Batch upload to folder';

  @override
  String get batchUploadHint => 'Multiple selection';

  @override
  String get virtualFoldersSection => 'Virtual folders';

  @override
  String get unfiledFilesSection => 'Individual files in vault';

  @override
  String folderCardSummary(int count, String size) {
    return '$count files · $size';
  }

  @override
  String linkStatusActiveExpires(int days) {
    return 'Link: Active (expires in $days days)';
  }

  @override
  String get sendAction => 'Send';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByLastModified => 'Last modified';

  @override
  String get sortBySize => 'Size';

  @override
  String get gridView => 'Grid view';

  @override
  String get listView => 'List view';

  @override
  String get emptyDataRoomTitle => 'Your Data Room is empty';

  @override
  String get emptyDataRoomHint =>
      'Upload encrypted files or create your first virtual folder';

  @override
  String get folderNameLabel => 'Folder name';

  @override
  String get folderDescriptionLabel => 'Description (optional)';

  @override
  String get createFolder => 'Create folder';

  @override
  String get folderCreated => 'Folder created';

  @override
  String get batchUploadTitle => 'Batch upload';

  @override
  String batchProgressSummary(int completed, int total) {
    return '$completed of $total files uploaded';
  }

  @override
  String batchCompletedMessage(int count) {
    return '$count files encrypted in Data Room';
  }

  @override
  String batchFileSkippedTooLarge(String filename) {
    return '$filename exceeds 100 MB and was skipped';
  }

  @override
  String get selectDestinationFolder => 'Select destination folder';

  @override
  String filesSelected(int count) {
    return '$count files selected';
  }

  @override
  String dataRoomLobbyTitle(String name) {
    return 'DATA ROOM: $name';
  }

  @override
  String linkExpiresInLabel(int days) {
    return 'Link expires in: $days days';
  }

  @override
  String get recipientEmailRequiredTitle =>
      'Enter your email to access the documents';

  @override
  String get dataRoomAccessAuditNotice =>
      'Enter your email to continue. Access will be audited.';

  @override
  String get accessAction => 'Access';

  @override
  String get availableDocumentsSection => 'Documents available in the folder';

  @override
  String get encryptedAtOrigin => 'Encrypted at source';

  @override
  String get openAndDecryptInRam => 'Open and decrypt in RAM';

  @override
  String get ramDecryptionNotice =>
      'Documents are decrypted exclusively in volatile RAM and are covered by active read auditing.';

  @override
  String get shareSheetTitle => 'Share securely';

  @override
  String get shareSingleFile => 'Single file';

  @override
  String get shareFullFolder => 'Full folder';

  @override
  String get requireRecipientEmailLabel => 'Require recipient email';

  @override
  String get requireRecipientEmailSubtitle =>
      'The recipient must enter their email before accessing';

  @override
  String get enableWatermarkLabel => 'Dynamic watermark';

  @override
  String get enableWatermarkSubtitle =>
      'Overlays recipient email, IP and date on the document';

  @override
  String get expirationPremiumNotice => 'Premium: links can last up to 30 days';

  @override
  String get copyLink => 'Copy link';

  @override
  String get shareQrCode => 'Share QR code';

  @override
  String get errorExpirationMustBeFuture =>
      'The expiration date must be in the future.';

  @override
  String get errorExpirationPremiumMax =>
      'Premium: the maximum link expiration is 30 days.';

  @override
  String get errorExpirationFreemiumMax =>
      'Free plan: the maximum link expiration is 48 hours.';

  @override
  String get expirationPremiumValid => 'Valid Premium expiration (≤ 30 days).';

  @override
  String get expirationFreemiumValid => 'Valid Free expiration (≤ 48 h).';

  @override
  String get eventLobbyEnter => 'Lobby entered';

  @override
  String get eventFileOpen => 'File opened';

  @override
  String get eventLobbyExit => 'Lobby exited';
}
