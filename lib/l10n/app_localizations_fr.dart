// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'KRIPTONSHARE';

  @override
  String get cancel => 'Annuler';

  @override
  String get accept => 'Accepter';

  @override
  String get retry => 'Réessayer';

  @override
  String get delete => 'Supprimer';

  @override
  String get share => 'Partager';

  @override
  String get revoke => 'Révoquer';

  @override
  String get dataRoom => 'Data Room';

  @override
  String get premium => 'Premium';

  @override
  String get premiumBadge => 'PREMIUM';

  @override
  String get free => 'Gratuit';

  @override
  String get enabled => 'Activé';

  @override
  String get disabled => 'Désactivé';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String errorWithMessage(String message) {
    return 'Erreur : $message';
  }

  @override
  String get splashTagline => 'Data Room éphémère';

  @override
  String get onboardingTitle1 => 'Chiffrement Zero-Knowledge';

  @override
  String get onboardingBody1 =>
      'Vos fichiers sont chiffrés localement avec AES-256 avant leur envoi vers le cloud. Personne d\'autre que vous ne détient les clés.';

  @override
  String get onboardingTitle2 => 'Liens éphémères';

  @override
  String get onboardingBody2 =>
      'Configurez l\'autodestruction physique de vos documents. Choisissez la durée de validité exacte du lien d\'accès sécurisé.';

  @override
  String get onboardingTitle3 => 'Sécurité forensique';

  @override
  String get onboardingBody3 =>
      'Atténuez l\'espionnage industriel et les fuites physiques grâce aux filigranes dynamiques et au blocage des captures d\'écran.';

  @override
  String get onboardingSkip => 'IGNORER';

  @override
  String get onboardingStart => 'COMMENCER';

  @override
  String get onboardingNext => 'SUIVANT';

  @override
  String get authTagline => 'Votre appareil est l\'unique gardien';

  @override
  String get loginTab => 'Se connecter';

  @override
  String get registerTab => 'Créer un compte';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get emailHint => 'vous@email.com';

  @override
  String get emailRequired => 'E-mail requis';

  @override
  String get emailInvalid => 'E-mail invalide';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get passwordRequired => 'Mot de passe requis';

  @override
  String passwordMinLength(int min) {
    return 'Minimum $min caractères';
  }

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get confirmPasswordRequired => 'Confirmation requise';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get registerButton => 'Créer un compte gratuit';

  @override
  String get loginInvalidCredentials =>
      'Identifiants invalides. Veuillez réessayer.';

  @override
  String get registerError =>
      'Impossible de créer le compte. Essayez un autre e-mail.';

  @override
  String get biometricLoginReason =>
      'Vérifiez votre identité pour terminer la connexion';

  @override
  String get biometricAuthCancelled => 'Authentification biométrique annulée.';

  @override
  String freePlanInfo(int maxMB, int maxLinks, int maxHours) {
    return 'Plan gratuit : $maxMB Mo max · $maxLinks liens/mois · $maxHours h de durée';
  }

  @override
  String get termsNotice =>
      'En vous inscrivant, vous acceptez les conditions de souveraineté des données. KRIPTONSHARE ne stocke jamais vos fichiers en clair.';

  @override
  String get lockTitle => 'KRIPTONSHARE verrouillé';

  @override
  String get lockSubtitle =>
      'Utilisez votre empreinte ou votre visage pour déverrouiller l\'application.';

  @override
  String get lockVerifying => 'Vérification...';

  @override
  String get unlockWithBiometrics => 'Déverrouiller avec la biométrie';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get authCancelled => 'Authentification annulée.';

  @override
  String get noSavedCredentials =>
      'Aucun identifiant enregistré. Connectez-vous manuellement.';

  @override
  String get invalidSavedCredentials =>
      'Les identifiants enregistrés ne sont plus valides. Connectez-vous manuellement.';

  @override
  String get biometricSettingsTitle => 'Configuration de la biométrie';

  @override
  String get biometricIntro =>
      'Protégez l\'accès à vos Data Rooms avec votre identité biométrique.';

  @override
  String get biometricNotAvailableTitle => 'Biométrie non disponible';

  @override
  String get biometricNoSensorsBody =>
      'Cet appareil ne dispose d\'aucun capteur biométrique configuré.';

  @override
  String get testNow => 'Tester maintenant';

  @override
  String get verifyAgain => 'Revérifier';

  @override
  String get biometricUnlock => 'Déverrouillage biométrique';

  @override
  String get dataSovereigntyTitle => 'Souveraineté des données';

  @override
  String get dataSovereigntyBody =>
      'Votre empreinte ou votre visage ne quitte jamais l\'appareil. Nous ne stockons aucune donnée biométrique.';

  @override
  String get quickAccessTitle => 'Accès rapide';

  @override
  String get quickAccessBody =>
      'Déverrouillez KRIPTONSHARE sans saisir votre mot de passe à chaque fois.';

  @override
  String get extraProtectionTitle => 'Protection supplémentaire';

  @override
  String get extraProtectionBody =>
      'La biométrie complète votre mot de passe ; elle ne le remplace pas.';

  @override
  String get securityTitle => 'Sécurité';

  @override
  String get faceId => 'Face ID';

  @override
  String get iris => 'Iris';

  @override
  String get fingerprint => 'Empreinte digitale';

  @override
  String get faceIdDescription =>
      'Utilisez Face ID pour déverrouiller KRIPTONSHARE en toute sécurité.';

  @override
  String get irisDescription =>
      'Utilisez la reconnaissance de l\'iris pour accéder.';

  @override
  String get fingerprintDescription =>
      'Utilisez votre empreinte digitale pour déverrouiller rapidement l\'application.';

  @override
  String get biometricEnableReason =>
      'Confirmez votre empreinte ou votre visage pour activer le déverrouillage biométrique';

  @override
  String get biometricAuthSuccess => 'Authentification biométrique réussie.';

  @override
  String get biometricEnableCancelled =>
      'Activation impossible : authentification annulée.';

  @override
  String get biometricUnlockEnabledMsg =>
      'Déverrouillage biométrique activé. Il sera demandé après la connexion.';

  @override
  String get biometricUnlockDisabledMsg =>
      'Déverrouillage biométrique désactivé.';

  @override
  String biometricQueryError(String message) {
    return 'Erreur lors de la vérification de la biométrie : $message';
  }

  @override
  String get dashboardTab => 'Tableau de bord';

  @override
  String get linksTab => 'Liens';

  @override
  String get profileTab => 'Profil';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get capacity => 'Capacité';

  @override
  String get duration => 'Durée';

  @override
  String get plan => 'Plan';

  @override
  String get receivedFiles => 'Fichiers reçus';

  @override
  String get noReceivedFiles => 'Vous n\'avez reçu aucun fichier';

  @override
  String get receivedFilesHint =>
      'Les liens envoyés à votre e-mail apparaîtront ici';

  @override
  String get activeLinks => 'Liens actifs';

  @override
  String get viewAll => 'Tout voir';

  @override
  String get noActiveLinks => 'Aucun lien actif';

  @override
  String get createFirstDataRoom => 'Créez votre premier Data Room sécurisé';

  @override
  String get expiresLabel => 'Expire';

  @override
  String expiresInMinutes(int minutes) {
    return 'dans $minutes min';
  }

  @override
  String expiresInHours(int hours) {
    return 'dans $hours h';
  }

  @override
  String expiresInDays(int days) {
    return 'dans $days j';
  }

  @override
  String get analyticsTooltip => 'Analytique';

  @override
  String get newDataRoom => 'Nouveau Data Room';

  @override
  String get attachFile => 'Joindre un fichier';

  @override
  String get cameraToVault => 'Caméra vers le coffre';

  @override
  String get noPublicGallery => 'Aucune galerie publique';

  @override
  String get encryptionPasswordLabel => 'Mot de passe de chiffrement';

  @override
  String get passwordNotStoredHint => 'Non stocké dans le cloud';

  @override
  String get recipientEmailOptional => 'E-mail du destinataire (facultatif)';

  @override
  String get encryptAndGenerateLink => 'Chiffrer et générer le lien';

  @override
  String get dataRoomReadyBanner => 'Data Room prêt sur Cloudflare';

  @override
  String get protectingFiles => 'Protection de vos fichiers...';

  @override
  String get encryptingAesStep => '> Chiffrement avec AES-256...';

  @override
  String get syncingR2Step => '> Synchronisation vers R2...';

  @override
  String fileExceedsPlanLimit(String maxSize) {
    return 'Le fichier dépasse la limite de $maxSize de votre plan';
  }

  @override
  String captureExceedsPlanLimit(String maxSize) {
    return 'La capture dépasse la limite de $maxSize de votre plan';
  }

  @override
  String get cameraAccessCancelled => 'Accès à la caméra annulé ou refusé';

  @override
  String get enterEncryptionPassword =>
      'Saisissez un mot de passe de chiffrement';

  @override
  String get sessionExpired => 'Session expirée';

  @override
  String get filePickError => 'Erreur lors de la sélection du fichier';

  @override
  String get shareDataRoomTitle => 'Data Room confidentiel partagé';

  @override
  String get expirationLabel => 'Expiration :';

  @override
  String get oneHour => '1 heure';

  @override
  String get default24h => '24 h (par défaut)';

  @override
  String get max48Hours => '48 heures (max)';

  @override
  String get max30Days => 'Max 30 jours';

  @override
  String daysUnit(int count) {
    return '$count jours';
  }

  @override
  String hoursUnit(int count) {
    return '$count heures';
  }

  @override
  String linkExpiresNotice(int hours) {
    return 'Ce lien expire dans $hours h.';
  }

  @override
  String get searchByIdOrEmail => 'Rechercher par ID ou e-mail';

  @override
  String get createLink => 'Créer un lien';

  @override
  String get noSearchResults => 'Aucun résultat trouvé';

  @override
  String get createFirstFromDashboard =>
      'Créez votre premier Data Room depuis le tableau de bord';

  @override
  String get deleteDocumentTitle => 'Supprimer le document';

  @override
  String get deleteDocumentWarning =>
      'Cette action est irréversible. Le document sera définitivement supprimé.';

  @override
  String get linkRevoked => 'Lien révoqué';

  @override
  String get documentDeleted => 'Document supprimé';

  @override
  String shareMessageTemplate(String url, String appUrl, int hours) {
    return 'Document sécurisé via KRIPTONSHARE\n\n$url\n\nSi le lien n\'ouvre pas l\'application, utilisez :\n$appUrl\n\nCe lien expire dans $hours h.';
  }

  @override
  String hoursRemaining(int hours) {
    return '$hours h restantes';
  }

  @override
  String daysRemaining(int days) {
    return '$days j restants';
  }

  @override
  String viewsCount(int count) {
    return '$count vues';
  }

  @override
  String get activeTag => 'ACTIF';

  @override
  String get expiredTag => 'EXPIRÉ';

  @override
  String expiresOn(String date) {
    return 'Expire : $date';
  }

  @override
  String get expiredLinksTitle => 'Liens expirés';

  @override
  String get noExpiredLinks => 'Aucun lien expiré';

  @override
  String get allDataRoomsActive => 'Tous vos Data Rooms sont actifs';

  @override
  String sizeExpiredOn(String size, String date) {
    return '$size · Expiré le $date';
  }

  @override
  String get linkIdMissing => 'ID de lien non fourni';

  @override
  String get linkInvalidExpiredRevoked => 'Lien invalide, expiré ou révoqué';

  @override
  String recipientOnlyNotice(String recipient) {
    return 'Ce fichier a été envoyé à $recipient. Connectez-vous avec ce compte pour y accéder.';
  }

  @override
  String documentLoadError(String error) {
    return 'Erreur lors du chargement du document : $error';
  }

  @override
  String get invalidDecryptedFile =>
      'Le fichier déchiffré n\'est pas valide. Vérifiez le mot de passe.';

  @override
  String get incompleteFileData =>
      'Données de fichier incomplètes ou corrompues.';

  @override
  String get wrongPasswordOrCorrupt =>
      'Mot de passe incorrect ou fichier corrompu';

  @override
  String get secureDocument => 'Document sécurisé';

  @override
  String get encryptedFileReceived => 'Vous avez reçu un fichier chiffré';

  @override
  String get senderPasswordPrompt =>
      'Saisissez le mot de passe fourni par l\'expéditeur pour le déchiffrer';

  @override
  String get decryptionPasswordLabel => 'Mot de passe de déchiffrement';

  @override
  String get decryptAndView => 'Déchiffrer et afficher';

  @override
  String get selfDestructNotice =>
      'Ce document s\'autodétruit après expiration. Il n\'est pas stocké sur votre appareil.';

  @override
  String get decryptingDocument => 'Déchiffrement du document...';

  @override
  String get unexpectedError => 'Erreur inattendue';

  @override
  String pdfOpenError(String error) {
    return 'Impossible d\'ouvrir le PDF :\n$error';
  }

  @override
  String get pdfViewerFallback =>
      'Le lecteur natif n\'a pas pu afficher ce PDF. Pour des raisons de sécurité, son ouverture hors de l\'application n\'est pas autorisée.';

  @override
  String get decryptedVideo => 'Vidéo déchiffrée';

  @override
  String get playVideo => 'Lire la vidéo';

  @override
  String get protectedFormat => 'Format protégé';

  @override
  String get officeNotViewable =>
      'Les documents Microsoft Office et autres formats ne peuvent pas être visualisés directement dans l\'application pour des raisons de sécurité.';

  @override
  String get convertToPdfAdvice =>
      'Pour partager ce contenu en toute sécurité, convertissez-le en PDF avant de le téléverser.';

  @override
  String get confidentialBanner => 'KRIPTONSHARE | CONFIDENTIEL';

  @override
  String get secureMode => 'MODE SÉCURISÉ';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get unknownError => 'Erreur inconnue';

  @override
  String videoPlaybackError(String error) {
    return 'Impossible de lire la vidéo : $error';
  }

  @override
  String fileSizeAndType(String size, String mimeType) {
    return '$size · $mimeType';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String get yourCurrentPlan => 'Votre plan actuel';

  @override
  String get maxFileSize => 'Taille maximale par fichier';

  @override
  String get dataRoomStorage => 'Stockage Data Room';

  @override
  String get notAvailable => 'Non disponible';

  @override
  String get monthlyLinks => 'Liens mensuels';

  @override
  String get maxDuration => 'Durée maximale';

  @override
  String hoursValue(int count) {
    return '$count heures';
  }

  @override
  String daysValue(int count) {
    return '$count jours';
  }

  @override
  String get unlimited => 'Illimité';

  @override
  String get encryptionLabel => 'Chiffrement';

  @override
  String get watermarkLabel => 'Filigrane';

  @override
  String get institutionalPassiveWatermark => 'Institutionnel passif';

  @override
  String get biometricsLabel => 'Biométrie';

  @override
  String get configureBiometrics => 'Configurez l\'empreinte ou Face ID';

  @override
  String get unlockFullCapacity => 'Débloquez la capacité totale';

  @override
  String get premiumBenefits =>
      '100 Mo par fichier • liens illimités • jusqu’à 30 jours • 1 Go de stockage éphémère • filigrane dynamique';

  @override
  String get managePremiumVault => 'Gérer le coffre Premium';

  @override
  String get analyticsTitle => 'Analytique';

  @override
  String get noDataAvailable => 'Aucune donnée disponible';

  @override
  String get dataRoomsMetrics => 'Métriques de vos Data Rooms';

  @override
  String get topLinks => 'Top liens';

  @override
  String get linkEvents => 'Événements du lien';

  @override
  String get viewExpiredLinks => 'Voir les liens expirés';

  @override
  String get totalLinks => 'Liens totaux';

  @override
  String get activeLabel => 'Actifs';

  @override
  String get expiredLabel => 'Expirés';

  @override
  String get totalViews => 'Vues totales';

  @override
  String get downloadsLabel => 'Téléchargements';

  @override
  String get avgDuration => 'Durée moyenne';

  @override
  String get events24h => 'Événements 24 h';

  @override
  String get storageLabel => 'Stockage';

  @override
  String get noActivityYet => 'Aucune activité pour le moment';

  @override
  String get topLinksEmptyHint =>
      'Vos liens les plus consultés apparaîtront ici';

  @override
  String get unnamedDocument => 'Document sans nom';

  @override
  String viewsDownloadsSummary(int views, int downloads) {
    return '$views vues · $downloads téléchargements';
  }

  @override
  String get noEventsForLink => 'Aucun événement enregistré pour ce lien';

  @override
  String pageN(int number) {
    return 'Page $number';
  }

  @override
  String get eventPageView => 'Vue de page';

  @override
  String get eventDownloadComplete => 'Téléchargement terminé';

  @override
  String get eventDownloadStart => 'Début du téléchargement';

  @override
  String get eventScreenshotBlocked => 'Capture d\'écran bloquée';

  @override
  String aes256Encrypted(String size) {
    return '$size · Chiffré AES-256';
  }

  @override
  String confidentialUserWatermark(String email) {
    return '$email • CONFIDENTIEL';
  }

  @override
  String get premiumActive => 'PREMIUM ACTIF';

  @override
  String get freePlanBadge => 'PLAN GRATUIT';

  @override
  String storageUsedOf(String used, String max) {
    return '$used / $max utilisés';
  }

  @override
  String get subscriptionOptions => 'Options d\'abonnement';

  @override
  String get monthlyPlan => 'Mensuel';

  @override
  String get monthlyPrice => '19,00 \$ / mois';

  @override
  String get annualPlan => 'Annuel';

  @override
  String get annualPrice => '189,00 \$ / an';

  @override
  String get annualSavings => 'Économisez 39 \$ USD/an';

  @override
  String get subscribeToPremium => 'S\'abonner à Premium';

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get testModeLabel => 'MODE TEST (debug)';

  @override
  String get testModeDescription =>
      'Activez Premium sans RevenueCat ni Google Cloud pour évaluer l\'interface.';

  @override
  String get deactivateTestPremium => 'Désactiver le Premium de test';

  @override
  String get activateTestPremium => 'Activer le Premium de test';

  @override
  String get testPremiumActivated => 'Premium de test activé';

  @override
  String get testPremiumDeactivated => 'Premium de test désactivé';

  @override
  String get noOfferingsAvailable => 'Aucune offre disponible';

  @override
  String get subscriptionActivated => 'Abonnement activé';

  @override
  String remainingLinks(int remaining) {
    return '$remaining restants';
  }

  @override
  String get freePlanLabel => 'Plan gratuit';

  @override
  String get premiumPlanLabel => 'Plan Premium';

  @override
  String get errorUserNotAuthenticated => 'Utilisateur non authentifié';

  @override
  String get errorQuotaExceeded => 'Limite de quota dépassée';

  @override
  String get errorUploadNotAllowed =>
      'Le téléversement ne peut pas être terminé. Vérifiez les limites de votre plan.';

  @override
  String get errorSignInFailed => 'Connexion impossible';

  @override
  String get errorUserRecordMissing =>
      'Utilisateur authentifié introuvable dans la table users.';

  @override
  String get errorCreateRoomFailed => 'Impossible de créer le Data Room';

  @override
  String get errorInvalidLinkFragment => 'Lien invalide : fragment manquant';

  @override
  String get errorInvalidKey => 'Clé invalide';

  @override
  String get errorDecryptionFailed => 'Erreur de déchiffrement';

  @override
  String errorDecryptionWithDetail(String error) {
    return 'Erreur de déchiffrement : $error';
  }

  @override
  String get uploadFileMax => 'Téléverser un fichier (≤ 100 Mo)';

  @override
  String get sendAction => 'Envoyer';

  @override
  String get sortByName => 'Nom';

  @override
  String get sortByLastModified => 'Dernière modification';

  @override
  String get sortBySize => 'Taille';

  @override
  String get gridView => 'Vue en grille';

  @override
  String get listView => 'Vue en liste';

  @override
  String linkExpiresInLabel(int days) {
    return 'Le lien expire dans : $days jours';
  }

  @override
  String get recipientEmailRequiredTitle =>
      'Saisissez votre e-mail pour accéder aux documents';

  @override
  String get dataRoomAccessAuditNotice =>
      'Saisissez votre e-mail pour continuer. L\'accès fera l\'objet d\'un audit.';

  @override
  String get accessAction => 'Accéder';

  @override
  String get encryptedAtOrigin => 'Chiffré à la source';

  @override
  String get shareSingleFile => 'Fichier unique';

  @override
  String get requireRecipientEmailLabel => 'E-mail du destinataire obligatoire';

  @override
  String get requireRecipientEmailSubtitle =>
      'Le destinataire devra saisir son e-mail avant d\'accéder';

  @override
  String get enableWatermarkLabel => 'Filigrane dynamique';

  @override
  String get enableWatermarkSubtitle =>
      'Superpose l\'e-mail, l\'IP et la date du destinataire sur le document';

  @override
  String get expirationPremiumNotice =>
      'Premium : les liens peuvent durer jusqu\'à 30 jours';

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get shareQrCode => 'Partager le code QR';

  @override
  String get errorExpirationMustBeFuture =>
      'La date d\'expiration doit être future.';

  @override
  String get errorExpirationPremiumMax =>
      'Premium : la durée d\'expiration maximale d\'un lien est de 30 jours.';

  @override
  String get errorExpirationFreemiumMax =>
      'Plan gratuit : la durée d\'expiration maximale d\'un lien est de 48 heures.';

  @override
  String get expirationPremiumValid =>
      'Expiration Premium valide (≤ 30 jours).';

  @override
  String get expirationFreemiumValid => 'Expiration gratuite valide (≤ 48 h).';

  @override
  String get unlockPremiumTitle => 'Débloquez Premium';

  @override
  String get paywallBody =>
      'Envoyez des fichiers plus volumineux, créez des liens illimités et conservez vos fichiers plus longtemps.';

  @override
  String get close => 'Fermer';

  @override
  String get popular => 'POPULAIRE';

  @override
  String get premiumPlanName => 'Premium';

  @override
  String get businessPlanName => 'Business';

  @override
  String get monthlyLabel => 'Mensuel';

  @override
  String get yearlyLabel => 'Annuel';

  @override
  String yearlySaveLabel(int percent) {
    return 'Économisez $percent %';
  }

  @override
  String get subscribeToBusiness => 'S\'abonner à Business';

  @override
  String get trialBannerTitle => 'Démarrez votre essai gratuit';

  @override
  String get trialBannerBody =>
      'Essayez Premium gratuitement pendant 14 jours. Annulez à tout moment.';

  @override
  String featureFileSize(int size) {
    return 'Jusqu’à $size Mo par fichier';
  }

  @override
  String featureStorage(String storage) {
    return '$storage de stockage';
  }

  @override
  String featureLinkDuration(int days) {
    return 'Liens valables jusqu’à $days jours';
  }

  @override
  String featureActiveLinks(int count) {
    return 'Jusqu\'à $count liens actifs';
  }

  @override
  String get featureActiveLinksUnlimited => 'Liens actifs illimités';

  @override
  String get featureNoAds => 'Sans publicité';

  @override
  String get unsupportedFormatTitle => 'Format non pris en charge';

  @override
  String unsupportedFormatBody(String formats) {
    return 'Pour des raisons de sécurité, KRIPTONSHARE n’accepte que les fichiers dans ces formats : $formats. Convertissez votre document en PDF avant de le partager.';
  }

  @override
  String unsupportedViewerBody(String formats) {
    return 'Ce format ne peut pas être consulté en toute sécurité dans l’application. Formats acceptés : $formats.';
  }

  @override
  String get plansTitle => 'Formules et stockage';

  @override
  String trialBanner(int days) {
    return 'Essayez Premium : $days jours restants';
  }

  @override
  String get trialPromo =>
      '14 jours de Premium gratuits. Aucune carte requise.';

  @override
  String get trialExpiredTitle => 'Votre essai Premium est terminé';

  @override
  String get trialExpiredBody =>
      'Vous êtes revenu au plan gratuit : 20 Mo par fichier, 20 liens par mois et expiration sous 7 jours. Conservez 100 Mo, des liens illimités et 30 jours avec Premium.';

  @override
  String get businessBenefits =>
      '200 Mo par fichier • 5 Go au total • liens jusqu’à 60 jours • tout Premium • assistance prioritaire • marque personnalisée dans la visionneuse (bientôt)';

  @override
  String get premiumPriceMonthly => '\$12.99/mois';

  @override
  String get premiumPriceAnnual => '\$103.99/an';

  @override
  String get premiumAnnualSavings => '4 mois offerts (économie de 33 %)';

  @override
  String get businessPriceMonthly => '\$29.99/mois';

  @override
  String get businessPriceAnnual => '\$239.99/an';

  @override
  String get businessAnnualSavings => 'Économisez 33 %';

  @override
  String get paywallFileSizeTitle => 'Fichier trop volumineux';

  @override
  String paywallFileSizeBody(String maxSize) {
    return 'Votre plan autorise $maxSize par fichier. Avec Premium, vous pouvez partager jusqu’à 100 Mo.';
  }

  @override
  String get paywallActiveLinksTitle => 'Limite de liens actifs';

  @override
  String get paywallActiveLinksBody =>
      'Le plan gratuit autorise 3 liens actifs à la fois. Avec Premium, ils sont illimités.';

  @override
  String get paywallMonthlyQuotaTitle => 'Quota mensuel atteint';

  @override
  String get paywallMonthlyQuotaBody =>
      'Vous avez créé 20 liens ce mois-ci. Avec Premium, ils sont illimités.';

  @override
  String get paywallDurationTitle => 'Durée maximale du plan gratuit';

  @override
  String get paywallDurationBody =>
      'Les liens gratuits durent jusqu’à 7 jours. Avec Premium, jusqu’à 30.';

  @override
  String get paywallStorageTitle => 'Stockage plein';

  @override
  String paywallStorageBody(String quota) {
    return 'Vous avez utilisé $quota de stockage. Supprimez des liens actifs pour libérer de l’espace ou améliorez votre formule.';
  }

  @override
  String get paywallStorageBodyBusiness =>
      'Vous avez utilisé les 5 Go. Supprimez ou expirez des liens actifs pour libérer de l’espace.';

  @override
  String get paywallViewPlans => 'Voir les formules';

  @override
  String get paywallNotNow => 'Pas maintenant';

  @override
  String get max7Days => '7 jours (max.)';

  @override
  String get max60Days => '60 jours (max.)';

  @override
  String get ephemeralStorageLabel => 'Stockage éphémère total';

  @override
  String get businessBadge => 'BUSINESS';

  @override
  String get businessPlanLabel => 'Formule Business';
}
