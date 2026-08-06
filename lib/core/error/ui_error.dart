import '../../l10n/app_localizations.dart';

/// Códigos de error visibles para capas sin acceso a BuildContext
/// (notifiers, providers). La UI los traduce con AppLocalizations.
enum UiErrorCode {
  createRoomFailed,
  invalidLinkFragment,
  invalidKey,
  decryptionFailed,
  userNotAuthenticated,
  quotaExceeded,
  uploadNotAllowed,
  signInFailed,
  userRecordMissing,
  // v2.1 — validación de expiración de enlaces (VDR 29Jul26)
  expirationMustBeFuture,
  expirationPremiumMax,
  expirationFreemiumMax,
  // Fallback para errores no categorizados
  unknown,
}

extension UiErrorCodeL10n on UiErrorCode {
  String message(AppLocalizations l10n) => switch (this) {
        UiErrorCode.createRoomFailed => l10n.errorCreateRoomFailed,
        UiErrorCode.invalidLinkFragment => l10n.errorInvalidLinkFragment,
        UiErrorCode.invalidKey => l10n.errorInvalidKey,
        UiErrorCode.decryptionFailed => l10n.errorDecryptionFailed,
        UiErrorCode.userNotAuthenticated => l10n.errorUserNotAuthenticated,
        UiErrorCode.quotaExceeded => l10n.errorQuotaExceeded,
        UiErrorCode.uploadNotAllowed => l10n.errorUploadNotAllowed,
        UiErrorCode.signInFailed => l10n.errorSignInFailed,
        UiErrorCode.userRecordMissing => l10n.errorUserRecordMissing,
        UiErrorCode.expirationMustBeFuture => l10n.errorExpirationMustBeFuture,
        UiErrorCode.expirationPremiumMax => l10n.errorExpirationPremiumMax,
        UiErrorCode.expirationFreemiumMax => l10n.errorExpirationFreemiumMax,
        UiErrorCode.unknown => l10n.unknownError,
      };
}
