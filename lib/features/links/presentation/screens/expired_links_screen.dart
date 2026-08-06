import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/formatters.dart';
import '../../../../core/utils/theme.dart';
import '../../../../providers/file_provider.dart';

/// Pantalla con la lista de enlaces expirados o revocados.
///
/// Muestra información básica para no saturar al usuario:
/// nombre del archivo, tamaño y fecha de expiración.
class ExpiredLinksScreen extends ConsumerWidget {
  const ExpiredLinksScreen({super.key});

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('dd/MM/yyyy HH:mm', locale).format(date.toLocal());
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(expiredLinksProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final expiredAsync = ref.watch(expiredLinksProvider);

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: Text(l10n.expiredLinksTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        color: KriptonTheme.electricLime,
        backgroundColor: KriptonTheme.inkDeep,
        child: expiredAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const _EmptyBody();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KriptonTheme.ink,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: KriptonTheme.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: KriptonTheme.alertRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.timer_off,
                          color: KriptonTheme.alertRed,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.fileName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: KriptonTheme.platinum,
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.sizeExpiredOn(
                                formatBytes(context, item.fileSizeBytes),
                                _formatDate(context, item.expiredAt),
                              ),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: KriptonTheme.silver,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
            ),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: KriptonTheme.alertRed, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n.errorWithMessage(error.toString()),
                  style: const TextStyle(color: KriptonTheme.alertRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _refresh(ref),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: KriptonTheme.cryptoGreen,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noExpiredLinks,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.allDataRoomsActive,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KriptonTheme.silver,
                ),
          ),
        ],
      ),
    );
  }
}
