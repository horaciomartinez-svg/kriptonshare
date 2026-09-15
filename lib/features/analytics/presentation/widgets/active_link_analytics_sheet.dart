import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/formatters.dart';
import '../../../../core/utils/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/kripton_file.dart';
import '../../analytics_providers.dart';
import '../notifiers/analytics_notifier.dart';

/// Bottom sheet con el detalle analítico de un Active Link.
class ActiveLinkAnalyticsSheet extends ConsumerStatefulWidget {
  final ShareLink link;

  const ActiveLinkAnalyticsSheet({super.key, required this.link});

  /// Muestra el sheet y dispara la carga del detalle vía notifier.
  static Future<void> show(BuildContext context, ShareLink link) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: KriptonTheme.inkDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ActiveLinkAnalyticsSheet(link: link),
    );
  }

  @override
  ConsumerState<ActiveLinkAnalyticsSheet> createState() =>
      _ActiveLinkAnalyticsSheetState();
}

class _ActiveLinkAnalyticsSheetState
    extends ConsumerState<ActiveLinkAnalyticsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(analyticsNotifierProvider.notifier)
            .loadLinkAnalyticsDetail(widget.link.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(analyticsNotifierProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KriptonTheme.graphite,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.linkAnalyticsTitle,
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(fontSize: 18),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: KriptonTheme.silver),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: KriptonTheme.cardBorder),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _header(context),
                  const SizedBox(height: 20),
                  _infoSection(context, state),
                  const SizedBox(height: 20),
                  _detailSection(context, state),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: KriptonTheme.electricLime.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.link,
            color: KriptonTheme.electricLime,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.link.id.substring(0, 8).toUpperCase(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: KriptonTheme.platinum,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.linkInfo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KriptonTheme.silver,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoSection(BuildContext context, AnalyticsState state) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final fileName = state.linkDetail?.fileName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KriptonTheme.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KriptonTheme.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fileInfo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KriptonTheme.graphite,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            fileName ?? l10n.unnamedDocument,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KriptonTheme.platinum,
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _infoRow(
            l10n.createdOnLabel,
            formatExpiry(context, widget.link.createdAt),
          ),
          _infoRow(
            l10n.expiresLabel,
            formatExpiry(context, widget.link.expiresAt),
          ),
          _infoRow(
            l10n.statusLabel,
            _statusText(l10n),
            color: _isActive(now)
                ? KriptonTheme.electricLime
                : KriptonTheme.alertRed,
          ),
          const SizedBox(height: 4),
          const Divider(color: KriptonTheme.cardBorder),
          const SizedBox(height: 4),
          _infoRow(
            l10n.viewsLabel,
            l10n.viewsCount(widget.link.accessCount),
          ),
          _infoRow(
            l10n.viewTimeLabel,
            _formatMs(context, state.linkDetail?.totalViewDurationMs ?? 0),
            highlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _detailSection(
    BuildContext context,
    AnalyticsState state,
  ) {
    final l10n = AppLocalizations.of(context);

    if (state.isLoading && state.linkDetail == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
          ),
        ),
      );
    }

    if (state.error != null && state.linkDetail == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            l10n.errorWithMessage(state.error!),
            style: const TextStyle(color: KriptonTheme.alertRed),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final detail = state.linkDetail;
    if (detail == null || detail.pages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: KriptonTheme.ink,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KriptonTheme.cardBorder, width: 1),
        ),
        child: Center(
          child: Text(
            l10n.noActivityYet,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KriptonTheme.silver,
                ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.perPageBreakdownTitle,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            for (final entry in detail.pages.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KriptonTheme.ink,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: KriptonTheme.cardBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: KriptonTheme.cyanTelemetry,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.pageN(entry.key),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: KriptonTheme.platinum,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                      Text(
                        l10n.pageAnalyticsSummary(
                          entry.value.views,
                          _formatMs(context, entry.value.durationMs),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: KriptonTheme.silver,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {Color? color, bool highlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: highlighted ? KriptonTheme.electricLime : KriptonTheme.silver,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color ?? KriptonTheme.platinum,
                  fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: highlighted ? 'Inter' : null,
                ),
          ),
        ],
      ),
    );
  }

  String _formatMs(BuildContext context, int milliseconds) {
    return formatDurationCompact(context, milliseconds);
  }

  bool _isActive(DateTime now) {
    return widget.link.isActive && widget.link.expiresAt.isAfter(now);
  }

  String _statusText(AppLocalizations l10n) {
    final now = DateTime.now();
    if (_isActive(now)) return l10n.activeTag;
    return l10n.expiredTag;
  }
}