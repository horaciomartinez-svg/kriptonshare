import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/theme.dart';
import '../../../../utils/constants.dart';
import '../../../../core/services/purchase_service.dart';
import '../../../../features/analytics/services/funnel_metrics_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../widgets/premium_storage_gauge.dart';

final _purchaseServiceProvider = Provider<IPurchaseService>((ref) {
  return createPurchaseService(ref);
});

enum _BillingPeriod { monthly, yearly }

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  _BillingPeriod _period = _BillingPeriod.yearly;
  bool _isProcessing = false;

  void _togglePeriod(_BillingPeriod period) {
    if (_period != period) {
      setState(() => _period = period);
    }
  }

  Future<void> _handleSubscribe(String packageId) async {
    if (_isProcessing) return;

    FunnelMetricsService().logEvent('checkout_started');
    final l10n = AppLocalizations.of(context);
    final purchaseService = ref.read(_purchaseServiceProvider);
    final offerings = await purchaseService.getOfferings();
    final purchasePkg = offerings.packages.firstWhere(
      (p) => p.identifier == packageId,
      orElse: () => PurchasePackage(identifier: packageId),
    );

    setState(() => _isProcessing = true);

    try {
      final success = await purchaseService.purchase(purchasePkg);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.subscriptionActivated),
            backgroundColor: KriptonTheme.kryptonGreen,
          ),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.unknownError),
            backgroundColor: KriptonTheme.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: Text(l10n.plansTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TrialBanner(),
            const SizedBox(height: 24),
            _BillingToggle(
              selectedPeriod: _period,
              onChanged: _togglePeriod,
            ),
            const SizedBox(height: 24),
            _PremiumPlanCard(
              isYearly: _period == _BillingPeriod.yearly,
              onSubscribe: () => _handleSubscribe(
                _period == _BillingPeriod.yearly
                    ? 'premium_yearly_v2'
                    : 'premium_monthly_v2',
              ),
              isProcessing: _isProcessing,
            ),
            const SizedBox(height: 16),
            _BusinessPlanCard(
              isYearly: _period == _BillingPeriod.yearly,
              onSubscribe: () => _handleSubscribe(
                _period == _BillingPeriod.yearly
                    ? 'business_yearly_v2'
                    : 'business_monthly_v2',
              ),
              isProcessing: _isProcessing,
            ),
            if (user != null) ...[
              const SizedBox(height: 24),
              PremiumStorageGauge(
                usedBytes: user.totalStorageUsedBytes,
                maxBytes: user.maxStorageBytes,
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TrialBanner extends StatelessWidget {
  const _TrialBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KriptonTheme.electricLime.withOpacity(0.12),
            KriptonTheme.kryptonGreen.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KriptonTheme.electricLime.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star_outline,
            color: KriptonTheme.electricLime,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.trialPromo,
                  style: const TextStyle(
                    color: KriptonTheme.electricLime,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingToggle extends StatelessWidget {
  final _BillingPeriod selectedPeriod;
  final ValueChanged<_BillingPeriod> onChanged;

  const _BillingToggle({
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KriptonTheme.inkDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KriptonTheme.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: l10n.monthlyLabel,
              isSelected: selectedPeriod == _BillingPeriod.monthly,
              onTap: () => onChanged(_BillingPeriod.monthly),
            ),
          ),
          Expanded(
            child: _ToggleOption(
              label: l10n.yearlyLabel,
              isSelected: selectedPeriod == _BillingPeriod.yearly,
              onTap: () => onChanged(_BillingPeriod.yearly),
              badge: l10n.yearlySaveLabel(33),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  const _ToggleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? KriptonTheme.electricLime.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: KriptonTheme.electricLime, width: 1)
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? KriptonTheme.electricLime
                    : KriptonTheme.silver,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: KriptonTheme.electricLime,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: KriptonTheme.charcoalBlack,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: KriptonTheme.electricLime),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: KriptonTheme.platinumGrey,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class Pricing {
  static const double premiumMonthlyUsd = 12.99;
  static const double premiumYearlyUsd = 103.99;
  static const double businessMonthlyUsd = 29.99;
  static const double businessYearlyUsd = 239.99;
  static const String dollar = '\$';
}

class _PremiumPlanCard extends StatelessWidget {
  final bool isYearly;
  final VoidCallback onSubscribe;
  final bool isProcessing;

  const _PremiumPlanCard({
    required this.isYearly,
    required this.onSubscribe,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const monthlyPrice = Pricing.premiumMonthlyUsd;
    const yearlyPrice = Pricing.premiumYearlyUsd;
    final displayPrice = isYearly ? yearlyPrice : monthlyPrice;
    final periodLabel = isYearly
        ? l10n.yearlyLabel.toLowerCase()
        : l10n.monthlyLabel.toLowerCase();

    return Container(
      decoration: BoxDecoration(
        color: KriptonTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KriptonTheme.electricLime.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: KriptonTheme.electricLime.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.diamond_outlined,
                  color: KriptonTheme.electricLime,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.premiumPlanName,
                  style: const TextStyle(
                    color: KriptonTheme.platinum,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KriptonTheme.electricLime.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: KriptonTheme.electricLime.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    l10n.popular,
                    style: const TextStyle(
                      color: KriptonTheme.electricLime,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  Pricing.dollar + displayPrice.toStringAsFixed(2),
                  style: const TextStyle(
                    color: KriptonTheme.platinum,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ $periodLabel',
                  style: const TextStyle(
                    color: KriptonTheme.silver,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            if (isYearly) ...[
              const SizedBox(height: 4),
              Text(
                l10n.premiumAnnualSavings,
                style: const TextStyle(
                  color: KriptonTheme.cyanTelemetry,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(color: KriptonTheme.cardBorder),
            const SizedBox(height: 12),
            _FeatureItem(
              icon: Icons.upload_file_outlined,
              label: l10n.featureFileSize(
                AppConstants.premiumMaxFileSizeBytes ~/ (1024 * 1024),
              ),
            ),
            _FeatureItem(
              icon: Icons.storage_outlined,
              label: l10n.featureStorage('1 GB'),
            ),
            _FeatureItem(
              icon: Icons.schedule_outlined,
              label: l10n.featureLinkDuration(
                AppConstants.premiumMaxDurationHours ~/ 24,
              ),
            ),
            _FeatureItem(
              icon: Icons.link_outlined,
              label: l10n.featureActiveLinksUnlimited,
            ),
            _FeatureItem(
              icon: Icons.ads_click_outlined,
              label: l10n.featureNoAds,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : onSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KriptonTheme.electricLime,
                  foregroundColor: KriptonTheme.charcoalBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(
                              KriptonTheme.charcoalBlack),
                        ),
                      )
                    : Text(l10n.subscribeToPremium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessPlanCard extends StatelessWidget {
  final bool isYearly;
  final VoidCallback onSubscribe;
  final bool isProcessing;

  const _BusinessPlanCard({
    required this.isYearly,
    required this.onSubscribe,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const monthlyPrice = Pricing.businessMonthlyUsd;
    const yearlyPrice = Pricing.businessYearlyUsd;
    final displayPrice = isYearly ? yearlyPrice : monthlyPrice;
    final periodLabel = isYearly
        ? l10n.yearlyLabel.toLowerCase()
        : l10n.monthlyLabel.toLowerCase();

    return Container(
      decoration: BoxDecoration(
        color: KriptonTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KriptonTheme.cyanTelemetry.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: KriptonTheme.cyanTelemetry.withOpacity(0.06),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.business_center_outlined,
                  color: KriptonTheme.cyanTelemetry,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.businessPlanName,
                  style: const TextStyle(
                    color: KriptonTheme.platinum,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  Pricing.dollar + displayPrice.toStringAsFixed(2),
                  style: const TextStyle(
                    color: KriptonTheme.platinum,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ $periodLabel',
                  style: const TextStyle(
                    color: KriptonTheme.silver,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            if (isYearly) ...[
              const SizedBox(height: 4),
              Text(
                l10n.businessAnnualSavings,
                style: const TextStyle(
                  color: KriptonTheme.cyanTelemetry,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(color: KriptonTheme.cardBorder),
            const SizedBox(height: 12),
            _FeatureItem(
              icon: Icons.upload_file_outlined,
              label: l10n.featureFileSize(
                AppConstants.businessMaxFileSizeBytes ~/ (1024 * 1024),
              ),
            ),
            _FeatureItem(
              icon: Icons.storage_outlined,
              label: l10n.featureStorage('5 GB'),
            ),
            _FeatureItem(
              icon: Icons.schedule_outlined,
              label: l10n.featureLinkDuration(
                AppConstants.businessMaxDurationHours ~/ 24,
              ),
            ),
            _FeatureItem(
              icon: Icons.link_outlined,
              label: l10n.featureActiveLinks(100),
            ),
            _FeatureItem(
              icon: Icons.ads_click_outlined,
              label: l10n.featureNoAds,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : onSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KriptonTheme.cyanTelemetry,
                  foregroundColor: KriptonTheme.charcoalBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(
                              KriptonTheme.charcoalBlack),
                        ),
                      )
                    : Text(l10n.subscribeToBusiness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
