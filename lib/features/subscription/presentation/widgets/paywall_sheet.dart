import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:kriptonshare/utils/theme.dart';
import 'package:kriptonshare/providers/auth_provider.dart';
import 'package:kriptonshare/models/user_model.dart';
import 'package:kriptonshare/core/localization/formatters.dart';
import 'package:kriptonshare/features/analytics/services/funnel_metrics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Paywall contextual mostrado en el momento exacto de la fricción (§10.1).
/// `trigger` es uno de: `file_size`, `monthly_quota`, `active_links`,
/// `link_duration`, `storage` o `general`.
class PaywallSheet {
  static Future<void> show(BuildContext context, {required String trigger}) {
    final l10n = AppLocalizations.of(context);

    FunnelMetricsService().logEvent('paywall_shown', trigger: trigger);

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: KriptonTheme.inkDeep,
      barrierColor: Colors.black.withOpacity(0.6),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _PaywallSheetContent(
          trigger: trigger,
          l10n: l10n,
        );
      },
    );
  }
}

class _PaywallSheetContent extends ConsumerWidget {
  final String trigger;
  final AppLocalizations l10n;

  const _PaywallSheetContent({
    required this.trigger,
    required this.l10n,
  });

  String? get _titleKey => switch (trigger) {
        'file_size' => 'paywallFileSizeTitle',
        'active_links' => 'paywallActiveLinksTitle',
        'monthly_quota' => 'paywallMonthlyQuotaTitle',
        'link_duration' => 'paywallDurationTitle',
        'storage' => 'paywallStorageTitle',
        _ => null,
      };

  String? _titleFor(AppLocalizations l) => switch (_titleKey) {
        'paywallFileSizeTitle' => l.paywallFileSizeTitle,
        'paywallActiveLinksTitle' => l.paywallActiveLinksTitle,
        'paywallMonthlyQuotaTitle' => l.paywallMonthlyQuotaTitle,
        'paywallDurationTitle' => l.paywallDurationTitle,
        'paywallStorageTitle' => l.paywallStorageTitle,
        _ => null,
      };

  IconData _iconForTrigger() {
    switch (trigger) {
      case 'file_size':
        return Icons.file_upload_outlined;
      case 'monthly_quota':
        return Icons.link_outlined;
      case 'active_links':
        return Icons.link;
      case 'storage':
        return Icons.storage;
      case 'link_duration':
        return Icons.schedule_outlined;
      default:
        return Icons.lock_outline;
    }
  }

  bool _isStorageBusinessCase(KriptonUser? user) =>
      trigger == 'storage' && user?.effectiveTier == 'business';

  String _bodyText(BuildContext context, AppLocalizations l, KriptonUser? user) {
    switch (trigger) {
      case 'file_size':
        final maxSize = formatBytes(context, user?.maxFileSizeBytes ?? 0);
        return l.paywallFileSizeBody(maxSize);
      case 'active_links':
        return l.paywallActiveLinksBody;
      case 'monthly_quota':
        return l.paywallMonthlyQuotaBody;
      case 'link_duration':
        return l.paywallDurationBody;
      case 'storage':
        if (_isStorageBusinessCase(user)) {
          return l.paywallStorageBodyBusiness;
        }
        final quota = formatBytes(context, user?.maxStorageBytes ?? 0);
        return l.paywallStorageBody(quota);
      default:
        return l.paywallBody;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final l = l10n;
    final businessStorageCase = _isStorageBusinessCase(user);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handleBar(),
            const SizedBox(height: 16),
            _header(context),
            const SizedBox(height: 16),
            _body(context, l, user),
            if (!businessStorageCase) ...[
              const SizedBox(height: 24),
              _featureList(),
              const SizedBox(height: 28),
            ] else ...[
              const SizedBox(height: 24),
            ],
            _actions(context, businessStorageCase),
          ],
        ),
      ),
    );
  }

  Widget _handleBar() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: KriptonTheme.cardBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _titleFor(l10n) ?? l10n.unlockPremiumTitle;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: KriptonTheme.electricLime.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _iconForTrigger(),
            color: KriptonTheme.electricLime,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: KriptonTheme.platinum,
              letterSpacing: -0.02,
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, KriptonUser? user) {
    return Text(
      _bodyText(context, l, user),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: KriptonTheme.platinumGrey,
        height: 1.5,
      ),
    );
  }

  Widget _featureList() {
    final List<String> features = [
      l10n.featureFileSize(100),
      l10n.featureStorage(l10n.unlimited),
      l10n.featureLinkDuration(30),
      l10n.featureNoAds,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map<Widget>((String feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                size: 18,
                color: KriptonTheme.electricLime,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  feature,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: KriptonTheme.platinumGrey,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _actions(BuildContext context, bool businessStorageCase) {
    return Column(
      children: [
        if (!businessStorageCase)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                FunnelMetricsService().logEvent('paywall_cta_clicked', trigger: trigger);
                Navigator.of(context).pop();
                context.go('/plans');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KriptonTheme.electricLime,
                foregroundColor: KriptonTheme.charcoalBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              child: Text(l10n.paywallViewPlans),
            ),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            FunnelMetricsService().logEvent('paywall_dismissed', trigger: trigger);
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            foregroundColor: KriptonTheme.silver,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Text(
            l10n.paywallNotNow,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
