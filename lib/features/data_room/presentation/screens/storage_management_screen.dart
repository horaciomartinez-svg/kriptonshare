import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../../core/services/revenue_cat_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/theme.dart';
import '../notifiers/storage_upsell_notifier.dart';

final storageUpsellNotifierProvider =
    StateNotifierProvider<StorageUpsellNotifier, StorageUpsellState>((ref) {
  return StorageUpsellNotifier(RevenueCatServiceImpl());
});

class StorageManagementScreen extends ConsumerStatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  ConsumerState<StorageManagementScreen> createState() =>
      _StorageManagementScreenState();
}

class _StorageManagementScreenState
    extends ConsumerState<StorageManagementScreen> {
  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      ref.read(storageUpsellNotifierProvider.notifier).loadOfferings();
    }
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    }
    if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final upsell = ref.watch(storageUpsellNotifierProvider);

    final used = user?.totalStorageUsedBytes ?? 0;
    final max = user?.maxStorageBytes ?? 0;
    final ratio = max > 0 ? (used / max).clamp(0.0, 1.0) : 0.0;
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: const Text('Bóveda y Almacenamiento Data Room'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPremium
                      ? KriptonTheme.electricLime.withOpacity(0.15)
                      : KriptonTheme.ink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPremium ? 'PREMIUM ACTIVO' : 'PLAN GRATUITO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isPremium ? KriptonTheme.electricLime : KriptonTheme.silver,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Capacidad del Data Room',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatBytes(used)} / ${_formatBytes(max)} Usados',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 12,
                  backgroundColor: KriptonTheme.ink,
                  valueColor: AlwaysStoppedAnimation(
                    ratio > 0.9 ? KriptonTheme.alertRed : KriptonTheme.kryptonGreen,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 32),
              if (isPremium) ...[
                ElevatedButton(
                  onPressed: upsell.isLoading
                      ? null
                      : () => _buyAddon(upsell.offerings),
                  child: const Text('Expandir Data Room (+1 GB por \$5/mes)'),
                ),
                const SizedBox(height: 32),
              ],
              if (!isPremium) ...[
                Text(
                  'Opciones de Suscripción',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _PricingCard(
                  title: 'Mensual',
                  price: '\$19.00 / mes',
                  selected: true,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _PricingCard(
                  title: 'Anual',
                  price: '\$189.00 / año',
                  subtitle: 'Ahorras \$39 USD/año',
                  selected: false,
                  onTap: () {},
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: upsell.isLoading
                      ? null
                      : () => _buySubscription(upsell.offerings),
                  child: const Text('Suscribirse a Premium'),
                ),
                const SizedBox(height: 32),
              ],
              if (upsell.error != null) ...[
                Text(
                  upsell.error!,
                  style: const TextStyle(color: KriptonTheme.alertRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              TextButton(
                onPressed: upsell.isLoading
                    ? null
                    : () => ref
                        .read(storageUpsellNotifierProvider.notifier)
                        .restorePurchases(),
                child: const Text('Restaurar Compras'),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 32),
                const Divider(color: KriptonTheme.cardBorder),
                const SizedBox(height: 16),
                Text(
                  'MODO PRUEBA (debug)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KriptonTheme.amber,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Activa Premium sin RevenueCat ni Google Cloud para evaluar la interfaz.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _togglePremiumSimulation(!isPremium),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPremium
                        ? KriptonTheme.alertRed
                        : KriptonTheme.electricLime,
                    foregroundColor: KriptonTheme.charcoalBlack,
                  ),
                  child: Text(
                    isPremium
                        ? 'Desactivar Premium de prueba'
                        : 'Activar Premium de prueba',
                  ),
                ),
              ],
              if (upsell.isLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePremiumSimulation(bool enable) async {
    await ref.read(authStateProvider.notifier).setPremiumSimulation(enable);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enable
                ? 'Premium de prueba activado'
                : 'Premium de prueba desactivado',
          ),
        ),
      );
    }
  }

  Future<void> _buySubscription(Offerings? offerings) async {
    final package = offerings?.current?.availablePackages.firstOrNull;
    if (package == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ofertas disponibles')),
      );
      return;
    }
    final ok = await ref
        .read(storageUpsellNotifierProvider.notifier)
        .purchasePackage(package);
    if (ok) {
      await ref.read(authStateProvider.notifier).refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suscripción activada')),
      );
    }
  }

  Future<void> _buyAddon(Offerings? offerings) async {
    // Buscar un offering de add-ons si existe; de lo contrario usar el primero.
    final packages = offerings?.all.entries
        .expand((e) => e.value.availablePackages)
        .toList();
    final package = packages?.firstOrNull;
    if (package == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay add-ons disponibles')),
      );
      return;
    }
    final ok = await ref
        .read(storageUpsellNotifierProvider.notifier)
        .purchaseAddon(package);
    if (ok) {
      await ref.read(authStateProvider.notifier).refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Almacenamiento ampliado')),
      );
    }
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PricingCard({
    required this.title,
    required this.price,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KriptonTheme.ink,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? KriptonTheme.electricLime : KriptonTheme.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? KriptonTheme.electricLime : KriptonTheme.silver,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  Text(price, style: Theme.of(context).textTheme.bodyMedium),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
