// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'KRIPTONSHARE';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get delete => 'Löschen';

  @override
  String get share => 'Teilen';

  @override
  String get revoke => 'Widerrufen';

  @override
  String get dataRoom => 'Data Room';

  @override
  String get premium => 'Premium';

  @override
  String get premiumBadge => 'PREMIUM';

  @override
  String get free => 'Kostenlos';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get language => 'Sprache';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String errorWithMessage(String message) {
    return 'Fehler: $message';
  }

  @override
  String get splashTagline => 'Ephemerer Data Room';

  @override
  String get onboardingTitle1 => 'Zero-Knowledge-Verschlüsselung';

  @override
  String get onboardingBody1 =>
      'Ihre Dateien werden lokal mit AES-256 verschlüsselt, bevor sie in die Cloud hochgeladen werden. Niemand außer Ihnen besitzt die Schlüssel.';

  @override
  String get onboardingTitle2 => 'Ephemere Links';

  @override
  String get onboardingBody2 =>
      'Konfigurieren Sie die physische Selbstzerstörung Ihrer Dokumente. Wählen Sie die genaue Gültigkeitsdauer des sicheren Zugangslinks.';

  @override
  String get onboardingTitle3 => 'Forensische Sicherheit';

  @override
  String get onboardingBody3 =>
      'Mindern Sie Wirtschaftsspionage und physische Datenlecks mit dynamischen Wasserzeichen und Screenshot-Sperre.';

  @override
  String get onboardingSkip => 'ÜBERSPRINGEN';

  @override
  String get onboardingStart => 'STARTEN';

  @override
  String get onboardingNext => 'WEITER';

  @override
  String get authTagline => 'Ihr Gerät ist der einzige Verwahrer';

  @override
  String get loginTab => 'Anmelden';

  @override
  String get registerTab => 'Konto erstellen';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get emailHint => 'sie@email.com';

  @override
  String get emailRequired => 'E-Mail erforderlich';

  @override
  String get emailInvalid => 'Ungültige E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get passwordRequired => 'Passwort erforderlich';

  @override
  String passwordMinLength(int min) {
    return 'Mindestens $min Zeichen';
  }

  @override
  String get confirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get confirmPasswordRequired => 'Bestätigung erforderlich';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get loginButton => 'Anmelden';

  @override
  String get registerButton => 'Kostenloses Konto erstellen';

  @override
  String get loginInvalidCredentials =>
      'Ungültige Anmeldedaten. Bitte erneut versuchen.';

  @override
  String get registerError =>
      'Konto konnte nicht erstellt werden. Versuchen Sie eine andere E-Mail.';

  @override
  String get biometricLoginReason =>
      'Bestätigen Sie Ihre Identität, um die Anmeldung abzuschließen';

  @override
  String get biometricAuthCancelled =>
      'Biometrische Authentifizierung abgebrochen.';

  @override
  String freePlanInfo(int maxMB, int maxLinks, int maxHours) {
    return 'Kostenloser Plan: max. $maxMB MB · $maxLinks Links/Monat · $maxHours Std. Laufzeit';
  }

  @override
  String get termsNotice =>
      'Mit der Registrierung akzeptieren Sie die Bedingungen zur Datensouveränität. KRIPTONSHARE speichert Ihre Dateien niemals im Klartext.';

  @override
  String get lockTitle => 'KRIPTONSHARE gesperrt';

  @override
  String get lockSubtitle =>
      'Nutzen Sie Ihren Fingerabdruck oder Ihr Gesicht, um die App zu entsperren.';

  @override
  String get lockVerifying => 'Überprüfung...';

  @override
  String get unlockWithBiometrics => 'Mit Biometrie entsperren';

  @override
  String get signOut => 'Abmelden';

  @override
  String get authCancelled => 'Authentifizierung abgebrochen.';

  @override
  String get noSavedCredentials =>
      'Keine gespeicherten Anmeldedaten. Bitte melden Sie sich manuell an.';

  @override
  String get invalidSavedCredentials =>
      'Die gespeicherten Anmeldedaten sind nicht mehr gültig. Bitte melden Sie sich manuell an.';

  @override
  String get biometricSettingsTitle => 'Biometrie-Einstellungen';

  @override
  String get biometricIntro =>
      'Schützen Sie den Zugriff auf Ihre Data Rooms mit Ihrer biometrischen Identität.';

  @override
  String get biometricNotAvailableTitle => 'Biometrie nicht verfügbar';

  @override
  String get biometricNoSensorsBody =>
      'Auf diesem Gerät sind keine biometrischen Sensoren konfiguriert.';

  @override
  String get testNow => 'Jetzt testen';

  @override
  String get verifyAgain => 'Erneut prüfen';

  @override
  String get biometricUnlock => 'Biometrische Entsperrung';

  @override
  String get dataSovereigntyTitle => 'Datensouveränität';

  @override
  String get dataSovereigntyBody =>
      'Ihr Fingerabdruck oder Ihr Gesicht verlässt das Gerät niemals. Wir speichern keine biometrischen Daten.';

  @override
  String get quickAccessTitle => 'Schnellzugriff';

  @override
  String get quickAccessBody =>
      'Entsperren Sie KRIPTONSHARE, ohne jedes Mal Ihr Passwort einzugeben.';

  @override
  String get extraProtectionTitle => 'Zusätzlicher Schutz';

  @override
  String get extraProtectionBody =>
      'Biometrie ergänzt Ihr Passwort; sie ersetzt es nicht.';

  @override
  String get securityTitle => 'Sicherheit';

  @override
  String get faceId => 'Face ID';

  @override
  String get iris => 'Iris';

  @override
  String get fingerprint => 'Fingerabdruck';

  @override
  String get faceIdDescription =>
      'Nutzen Sie Face ID, um KRIPTONSHARE sicher zu entsperren.';

  @override
  String get irisDescription => 'Nutzen Sie die Iriserkennung für den Zugriff.';

  @override
  String get fingerprintDescription =>
      'Nutzen Sie Ihren Fingerabdruck, um die App schnell zu entsperren.';

  @override
  String get biometricEnableReason =>
      'Bestätigen Sie Ihren Fingerabdruck oder Ihr Gesicht, um die biometrische Entsperrung zu aktivieren';

  @override
  String get biometricAuthSuccess =>
      'Biometrische Authentifizierung erfolgreich.';

  @override
  String get biometricEnableCancelled =>
      'Aktivierung fehlgeschlagen: Authentifizierung abgebrochen.';

  @override
  String get biometricUnlockEnabledMsg =>
      'Biometrische Entsperrung aktiviert. Sie wird nach der Anmeldung abgefragt.';

  @override
  String get biometricUnlockDisabledMsg =>
      'Biometrische Entsperrung deaktiviert.';

  @override
  String biometricQueryError(String message) {
    return 'Fehler beim Prüfen der Biometrie: $message';
  }

  @override
  String get dashboardTab => 'Dashboard';

  @override
  String get linksTab => 'Links';

  @override
  String get profileTab => 'Profil';

  @override
  String get welcome => 'Willkommen';

  @override
  String get capacity => 'Kapazität';

  @override
  String get duration => 'Laufzeit';

  @override
  String get plan => 'Plan';

  @override
  String get receivedFiles => 'Empfangene Dateien';

  @override
  String get noReceivedFiles => 'Sie haben keine Dateien erhalten';

  @override
  String get receivedFilesHint =>
      'An Ihre E-Mail gesendete Links erscheinen hier';

  @override
  String get activeLinks => 'Aktive Links';

  @override
  String get viewAll => 'Alle anzeigen';

  @override
  String get noActiveLinks => 'Keine aktiven Links';

  @override
  String get createFirstDataRoom =>
      'Erstellen Sie Ihren ersten sicheren Data Room';

  @override
  String get expiresLabel => 'Läuft ab';

  @override
  String expiresInMinutes(int minutes) {
    return 'in $minutes Min.';
  }

  @override
  String expiresInHours(int hours) {
    return 'in $hours Std.';
  }

  @override
  String expiresInDays(int days) {
    return 'in $days T.';
  }

  @override
  String get analyticsTooltip => 'Analytik';

  @override
  String get newDataRoom => 'Neuer Data Room';

  @override
  String get attachFile => 'Datei anhängen';

  @override
  String get cameraToVault => 'Kamera zum Tresor';

  @override
  String get noPublicGallery => 'Keine öffentliche Galerie';

  @override
  String get encryptionPasswordLabel => 'Verschlüsselungspasswort';

  @override
  String get passwordNotStoredHint => 'Wird nicht in der Cloud gespeichert';

  @override
  String get recipientEmailOptional => 'E-Mail des Empfängers (optional)';

  @override
  String get encryptAndGenerateLink => 'Verschlüsseln und Link generieren';

  @override
  String get pdfPreviewGeneratedNotice =>
      'Eine sichere PDF-Vorschau wird für den Empfänger erstellt';

  @override
  String get dataRoomReadyBanner => 'Data Room bereit auf Cloudflare';

  @override
  String get previewGenerationFailedNotice =>
      'Die Datei wurde geteilt, aber die Vorschau konnte nicht erstellt werden. Der Empfänger kann sie herunterladen, wenn Sie es erlauben.';

  @override
  String get protectingFiles => 'Ihre Dateien werden geschützt...';

  @override
  String get encryptingAesStep => '> Verschlüsselung mit AES-256...';

  @override
  String get generatingPreviewStep => '> Sichere Vorschau wird erstellt...';

  @override
  String get syncingR2Step => '> Synchronisierung mit R2...';

  @override
  String fileExceedsPlanLimit(String maxSize) {
    return 'Die Datei überschreitet das Limit von $maxSize Ihres Plans';
  }

  @override
  String captureExceedsPlanLimit(String maxSize) {
    return 'Die Aufnahme überschreitet das Limit von $maxSize Ihres Plans';
  }

  @override
  String get cameraAccessCancelled =>
      'Kamerazugriff abgebrochen oder verweigert';

  @override
  String get enterEncryptionPassword =>
      'Geben Sie ein Verschlüsselungspasswort ein';

  @override
  String get sessionExpired => 'Sitzung abgelaufen';

  @override
  String get filePickError => 'Fehler bei der Dateiauswahl';

  @override
  String get shareDataRoomTitle => 'Vertraulicher geteilter Data Room';

  @override
  String get expirationLabel => 'Ablauf:';

  @override
  String get oneHour => '1 Stunde';

  @override
  String get default24h => '24 Std. (Standard)';

  @override
  String get max48Hours => '48 Stunden (max.)';

  @override
  String get max30Days => 'Max. 30 Tage';

  @override
  String daysUnit(int count) {
    return '$count Tage';
  }

  @override
  String hoursUnit(int count) {
    return '$count Stunden';
  }

  @override
  String get upsellTitle => 'Senden ohne Pausen?';

  @override
  String get upsellCta => '> Zu Premium wechseln';

  @override
  String linkExpiresNotice(int hours) {
    return 'Dieser Link läuft in $hours Std. ab.';
  }

  @override
  String get adSampleTitle => 'IBM Cloud Security';

  @override
  String get adSampleBody =>
      'Schützen Sie die Infrastruktur Ihres Unternehmens.';

  @override
  String get adSampleCta => 'MEHR ERFAHREN';

  @override
  String get searchByIdOrEmail => 'Nach ID oder E-Mail suchen';

  @override
  String get createLink => 'Link erstellen';

  @override
  String get noSearchResults => 'Keine Ergebnisse gefunden';

  @override
  String get createFirstFromDashboard =>
      'Erstellen Sie Ihren ersten Data Room über das Dashboard';

  @override
  String get deleteDocumentTitle => 'Dokument löschen';

  @override
  String get deleteDocumentWarning =>
      'Diese Aktion ist unwiderruflich. Das Dokument wird dauerhaft gelöscht.';

  @override
  String get linkRevoked => 'Link wurde widerrufen';

  @override
  String get documentDeleted => 'Dokument gelöscht';

  @override
  String shareMessageTemplate(String url, String appUrl, int hours) {
    return 'Sicheres Dokument via KRIPTONSHARE\n\n$url\n\nFalls der Link die App nicht öffnet, verwenden Sie:\n$appUrl\n\nDieser Link läuft in $hours Std. ab.';
  }

  @override
  String hoursRemaining(int hours) {
    return 'noch $hours Std.';
  }

  @override
  String daysRemaining(int days) {
    return 'noch $days T.';
  }

  @override
  String viewsCount(int count) {
    return '$count Aufrufe';
  }

  @override
  String get activeTag => 'AKTIV';

  @override
  String get expiredTag => 'ABGELAUFEN';

  @override
  String expiresOn(String date) {
    return 'Läuft ab: $date';
  }

  @override
  String get expiredLinksTitle => 'Abgelaufene Links';

  @override
  String get noExpiredLinks => 'Keine abgelaufenen Links';

  @override
  String get allDataRoomsActive => 'Alle Ihre Data Rooms sind aktiv';

  @override
  String sizeExpiredOn(String size, String date) {
    return '$size · Abgelaufen am $date';
  }

  @override
  String get linkIdMissing => 'Link-ID nicht angegeben';

  @override
  String get linkInvalidExpiredRevoked =>
      'Ungültiger, abgelaufener oder widerrufener Link';

  @override
  String recipientOnlyNotice(String recipient) {
    return 'Diese Datei wurde an $recipient gesendet. Melden Sie sich mit diesem Konto an, um darauf zuzugreifen.';
  }

  @override
  String documentLoadError(String error) {
    return 'Fehler beim Laden des Dokuments: $error';
  }

  @override
  String get invalidDecryptedFile =>
      'Die entschlüsselte Datei ist ungültig. Überprüfen Sie das Passwort.';

  @override
  String get incompleteFileData =>
      'Unvollständige oder beschädigte Dateidaten.';

  @override
  String get wrongPasswordOrCorrupt =>
      'Falsches Passwort oder beschädigte Datei';

  @override
  String get secureDocument => 'Sicheres Dokument';

  @override
  String get encryptedFileReceived =>
      'Sie haben eine verschlüsselte Datei erhalten';

  @override
  String get senderPasswordPrompt =>
      'Geben Sie das vom Absender bereitgestellte Passwort ein, um sie zu entschlüsseln';

  @override
  String get decryptionPasswordLabel => 'Entschlüsselungspasswort';

  @override
  String get decryptAndView => 'Entschlüsseln und anzeigen';

  @override
  String get selfDestructNotice =>
      'Dieses Dokument zerstört sich nach Ablauf selbst. Es wird nicht auf Ihrem Gerät gespeichert.';

  @override
  String get decryptingDocument => 'Dokument wird entschlüsselt...';

  @override
  String get unexpectedError => 'Unerwarteter Fehler';

  @override
  String pdfOpenError(String error) {
    return 'PDF konnte nicht geöffnet werden:\n$error';
  }

  @override
  String get pdfViewerFallback =>
      'Der native Viewer konnte dieses PDF nicht anzeigen. Aus Sicherheitsgründen darf es nicht außerhalb der App geöffnet werden.';

  @override
  String get decryptedVideo => 'Entschlüsseltes Video';

  @override
  String get playVideo => 'Video abspielen';

  @override
  String get protectedFormat => 'Geschütztes Format';

  @override
  String get officeNotViewable =>
      'Microsoft-Office-Dokumente und andere Formate können aus Sicherheitsgründen nicht direkt in der App angezeigt werden.';

  @override
  String get convertToPdfAdvice =>
      'Um diesen Inhalt sicher zu teilen, konvertieren Sie ihn vor dem Hochladen in PDF.';

  @override
  String get confidentialBanner => 'KRIPTONSHARE | VERTRAULICH';

  @override
  String get secureMode => 'SICHERER MODUS';

  @override
  String get backToHome => 'Zurück zur Startseite';

  @override
  String get unknownError => 'Unbekannter Fehler';

  @override
  String videoPlaybackError(String error) {
    return 'Video konnte nicht abgespielt werden: $error';
  }

  @override
  String fileSizeAndType(String size, String mimeType) {
    return '$size · $mimeType';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String get yourCurrentPlan => 'Ihr aktueller Plan';

  @override
  String get maxFileSize => 'Maximale Dateigröße';

  @override
  String get dataRoomStorage => 'Data-Room-Speicher';

  @override
  String get notAvailable => 'Nicht verfügbar';

  @override
  String get monthlyLinks => 'Monatliche Links';

  @override
  String get maxDuration => 'Maximale Laufzeit';

  @override
  String hoursValue(int count) {
    return '$count Stunden';
  }

  @override
  String get encryptionLabel => 'Verschlüsselung';

  @override
  String get watermarkLabel => 'Wasserzeichen';

  @override
  String get institutionalPassiveWatermark => 'Institutionell passiv';

  @override
  String get biometricsLabel => 'Biometrie';

  @override
  String get configureBiometrics => 'Fingerabdruck oder Face ID einrichten';

  @override
  String get unlockFullCapacity => 'Volle Kapazität freischalten';

  @override
  String get premiumBenefits =>
      '100 MB pro Datei, unbegrenzte Links, individueller Ablauf, dynamisches forensisches Wasserzeichen.';

  @override
  String get managePremiumVault => 'Premium-Tresor verwalten';

  @override
  String get analyticsTitle => 'Analytik';

  @override
  String get noDataAvailable => 'Keine Daten verfügbar';

  @override
  String get dataRoomsMetrics => 'Metriken Ihrer Data Rooms';

  @override
  String get topLinks => 'Top-Links';

  @override
  String get linkEvents => 'Link-Ereignisse';

  @override
  String get viewExpiredLinks => 'Abgelaufene Links anzeigen';

  @override
  String get totalLinks => 'Links gesamt';

  @override
  String get activeLabel => 'Aktiv';

  @override
  String get expiredLabel => 'Abgelaufen';

  @override
  String get totalViews => 'Aufrufe gesamt';

  @override
  String get downloadsLabel => 'Downloads';

  @override
  String get avgDuration => 'Durchschnittliche Dauer';

  @override
  String get events24h => 'Ereignisse 24 Std.';

  @override
  String get storageLabel => 'Speicher';

  @override
  String get noActivityYet => 'Noch keine Aktivität';

  @override
  String get topLinksEmptyHint => 'Ihre meistgesehenen Links erscheinen hier';

  @override
  String get unnamedDocument => 'Unbenanntes Dokument';

  @override
  String viewsDownloadsSummary(int views, int downloads) {
    return '$views Aufrufe · $downloads Downloads';
  }

  @override
  String get noEventsForLink =>
      'Für diesen Link wurden keine Ereignisse erfasst';

  @override
  String pageN(int number) {
    return 'Seite $number';
  }

  @override
  String get eventPageView => 'Seitenaufruf';

  @override
  String get eventDownloadComplete => 'Download abgeschlossen';

  @override
  String get eventDownloadStart => 'Download gestartet';

  @override
  String get eventScreenshotBlocked => 'Screenshot blockiert';

  @override
  String get enterDataRoomPassword =>
      'Geben Sie das Passwort des Data Rooms ein';

  @override
  String get dataRoomNotFound => 'Data Room nicht gefunden';

  @override
  String get dataRoomPasswordLabel => 'Data-Room-Passwort';

  @override
  String get selectFileToDecrypt =>
      'Wählen Sie eine Datei, um sie im RAM zu entschlüsseln';

  @override
  String encryptedFilesCount(int count, String size) {
    return '$count verschlüsselte Dateien · $size';
  }

  @override
  String aes256Encrypted(String size) {
    return '$size · AES-256-verschlüsselt';
  }

  @override
  String get officeDocsNotViewable =>
      'Office-Dokumente können aus Sicherheitsgründen nicht direkt angezeigt werden.';

  @override
  String confidentialUserWatermark(String email) {
    return '$email • VERTRAULICH';
  }

  @override
  String get storageManagementTitle => 'Tresor & Data-Room-Speicher';

  @override
  String get premiumActive => 'PREMIUM AKTIV';

  @override
  String get freePlanBadge => 'KOSTENLOSER PLAN';

  @override
  String get dataRoomCapacity => 'Kapazität des Data Rooms';

  @override
  String storageUsedOf(String used, String max) {
    return '$used / $max belegt';
  }

  @override
  String get expandDataRoomAddon =>
      'Data Room erweitern (+1 GB für 5 \$/Monat)';

  @override
  String get subscriptionOptions => 'Abonnement-Optionen';

  @override
  String get monthlyPlan => 'Monatlich';

  @override
  String get monthlyPrice => '19,00 \$ / Monat';

  @override
  String get annualPlan => 'Jährlich';

  @override
  String get annualPrice => '189,00 \$ / Jahr';

  @override
  String get annualSavings => 'Sie sparen 39 \$ USD/Jahr';

  @override
  String get subscribeToPremium => 'Premium abonnieren';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get testModeLabel => 'TESTMODUS (Debug)';

  @override
  String get testModeDescription =>
      'Aktivieren Sie Premium ohne RevenueCat oder Google Cloud, um die Oberfläche zu evaluieren.';

  @override
  String get deactivateTestPremium => 'Test-Premium deaktivieren';

  @override
  String get activateTestPremium => 'Test-Premium aktivieren';

  @override
  String get testPremiumActivated => 'Test-Premium aktiviert';

  @override
  String get testPremiumDeactivated => 'Test-Premium deaktiviert';

  @override
  String get noOfferingsAvailable => 'Keine Angebote verfügbar';

  @override
  String get subscriptionActivated => 'Abonnement aktiviert';

  @override
  String get noAddonsAvailable => 'Keine Add-ons verfügbar';

  @override
  String get storageExpanded => 'Speicher erweitert';

  @override
  String remainingLinks(int remaining) {
    return '$remaining verbleibend';
  }

  @override
  String get freePlanLabel => 'Kostenloser Plan';

  @override
  String get errorUserNotAuthenticated => 'Benutzer nicht authentifiziert';

  @override
  String get errorQuotaExceeded => 'Kontingentlimit überschritten';

  @override
  String get errorUploadNotAllowed =>
      'Der Upload kann nicht abgeschlossen werden. Prüfen Sie die Limits Ihres Plans.';

  @override
  String get errorSignInFailed => 'Anmeldung fehlgeschlagen';

  @override
  String get errorUserRecordMissing =>
      'Authentifizierter Benutzer nicht in der Tabelle users gefunden.';

  @override
  String get errorCreateRoomFailed => 'Data Room konnte nicht erstellt werden';

  @override
  String get errorInvalidLinkFragment => 'Ungültiger Link: Fragment fehlt';

  @override
  String get errorInvalidKey => 'Ungültiger Schlüssel';

  @override
  String get errorDecryptionFailed => 'Fehler bei der Entschlüsselung';

  @override
  String errorDecryptionWithDetail(String error) {
    return 'Fehler beim Entschlüsseln: $error';
  }

  @override
  String get dataRoomExplorerTitle => 'Mein Data-Room-Tresor';

  @override
  String get premiumCapacityLabel => 'PREMIUM-DATA-ROOM-KAPAZITÄT';

  @override
  String storageUsedSummary(String used, String max, int percent) {
    return '$used von $max belegt ($percent %)';
  }

  @override
  String get expandVaultAddon => 'Tresor erweitern (+1 GB für 5 \$/Monat)';

  @override
  String get uploadFileMax => 'Datei hochladen (≤ 100 MB)';

  @override
  String get newVirtualFolder => 'Neuer virtueller Ordner';

  @override
  String get batchUploadAction => 'Stapel-Upload in Ordner';

  @override
  String get batchUploadHint => 'Mehrfachauswahl';

  @override
  String get virtualFoldersSection => 'Virtuelle Ordner';

  @override
  String get unfiledFilesSection => 'Einzelne Dateien im Tresor';

  @override
  String folderCardSummary(int count, String size) {
    return '$count Dateien · $size';
  }

  @override
  String linkStatusActiveExpires(int days) {
    return 'Link: Aktiv (läuft in $days Tagen ab)';
  }

  @override
  String get sendAction => 'Senden';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByLastModified => 'Zuletzt geändert';

  @override
  String get sortBySize => 'Größe';

  @override
  String get gridView => 'Rasteransicht';

  @override
  String get listView => 'Listenansicht';

  @override
  String get emptyDataRoomTitle => 'Ihr Data Room ist leer';

  @override
  String get emptyDataRoomHint =>
      'Laden Sie verschlüsselte Dateien hoch oder erstellen Sie Ihren ersten virtuellen Ordner';

  @override
  String get folderNameLabel => 'Ordnername';

  @override
  String get folderDescriptionLabel => 'Beschreibung (optional)';

  @override
  String get createFolder => 'Ordner erstellen';

  @override
  String get folderCreated => 'Ordner erstellt';

  @override
  String get batchUploadTitle => 'Stapel-Upload';

  @override
  String batchProgressSummary(int completed, int total) {
    return '$completed von $total Dateien hochgeladen';
  }

  @override
  String batchCompletedMessage(int count) {
    return '$count Dateien im Data Room verschlüsselt';
  }

  @override
  String batchFileSkippedTooLarge(String filename) {
    return '$filename überschreitet 100 MB und wurde übersprungen';
  }

  @override
  String get selectDestinationFolder => 'Zielordner auswählen';

  @override
  String filesSelected(int count) {
    return '$count Dateien ausgewählt';
  }

  @override
  String dataRoomLobbyTitle(String name) {
    return 'DATA ROOM: $name';
  }

  @override
  String linkExpiresInLabel(int days) {
    return 'Link läuft ab in: $days Tagen';
  }

  @override
  String get recipientEmailRequiredTitle =>
      'Geben Sie Ihre E-Mail ein, um auf die Dokumente zuzugreifen';

  @override
  String get dataRoomAccessAuditNotice =>
      'Geben Sie Ihre E-Mail ein, um fortzufahren. Der Zugriff wird geprüft.';

  @override
  String get accessAction => 'Zugreifen';

  @override
  String get availableDocumentsSection => 'Im Ordner verfügbare Dokumente';

  @override
  String get encryptedAtOrigin => 'An der Quelle verschlüsselt';

  @override
  String get openAndDecryptInRam => 'Im RAM öffnen und entschlüsseln';

  @override
  String get ramDecryptionNotice =>
      'Dokumente werden ausschließlich im flüchtigen RAM entschlüsselt und unterliegen einer aktiven Leseprotokollierung.';

  @override
  String get shareSheetTitle => 'Sicher teilen';

  @override
  String get shareSingleFile => 'Einzelne Datei';

  @override
  String get shareFullFolder => 'Gesamter Ordner';

  @override
  String get requireRecipientEmailLabel => 'Empfänger-E-Mail erforderlich';

  @override
  String get requireRecipientEmailSubtitle =>
      'Der Empfänger muss vor dem Zugriff seine E-Mail eingeben';

  @override
  String get enableWatermarkLabel => 'Dynamisches Wasserzeichen';

  @override
  String get enableWatermarkSubtitle =>
      'Blendet E-Mail, IP und Datum des Empfängers über dem Dokument ein';

  @override
  String get expirationPremiumNotice =>
      'Premium: Links können bis zu 30 Tage gültig sein';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get shareQrCode => 'QR-Code teilen';

  @override
  String get errorExpirationMustBeFuture =>
      'Das Ablaufdatum muss in der Zukunft liegen.';

  @override
  String get errorExpirationPremiumMax =>
      'Premium: Die maximale Link-Laufzeit beträgt 30 Tage.';

  @override
  String get errorExpirationFreemiumMax =>
      'Kostenloser Plan: Die maximale Link-Laufzeit beträgt 48 Stunden.';

  @override
  String get expirationPremiumValid => 'Gültiger Premium-Ablauf (≤ 30 Tage).';

  @override
  String get expirationFreemiumValid =>
      'Gültiger kostenloser Ablauf (≤ 48 Std.).';

  @override
  String get eventLobbyEnter => 'Lobby betreten';

  @override
  String get eventFileOpen => 'Datei geöffnet';

  @override
  String get eventLobbyExit => 'Lobby verlassen';
}
