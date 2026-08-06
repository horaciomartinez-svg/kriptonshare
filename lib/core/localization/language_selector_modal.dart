import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';

import '../../utils/theme.dart';
import 'locale_provider.dart';
import 'supported_locales.dart';

/// Bottom sheet de selección de idioma. Se invoca idénticamente desde
/// Login (AuthScreen), Dashboard (AppBar) y Perfil (ListTile).
class LanguageSelectorModal extends ConsumerWidget {
  const LanguageSelectorModal({super.key});

  /// Helper estático de presentación.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: KriptonTheme.charcoalBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const LanguageSelectorModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            // Handle de arrastre
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KriptonTheme.ink,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.selectLanguage,
              style: const TextStyle(
                color: KriptonTheme.platinum,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: KriptonTheme.ink, height: 1),
          ...kSupportedLocales.map((supported) {
            final isSelected =
                currentLocale.languageCode == supported.locale.languageCode;
            return ListTile(
              leading: Text(
                supported.flagEmoji,
                style: const TextStyle(fontSize: 22),
              ),
              title: Text(
                supported.nativeName,
                style: TextStyle(
                  color: isSelected
                      ? KriptonTheme.electricLime
                      : KriptonTheme.platinum,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      color: KriptonTheme.electricLime,
                    )
                  : null,
              onTap: () {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(supported.locale.languageCode);
                Navigator.of(context).pop();
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
