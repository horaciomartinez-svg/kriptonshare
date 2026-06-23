import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../analytics_providers.dart';
import '../../domain/entities/dashboard_metrics_entity.dart';
import '../notifiers/analytics_notifier.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        ref
            .read(analyticsNotifierProvider.notifier)
            .loadDashboardMetrics(user.id);
      }
    });
  }

  Future<void> _refresh() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      await ref
          .read(analyticsNotifierProvider.notifier)
          .loadDashboardMetrics(user.id);
    }
  }

  String _formatDuration(double milliseconds) {
    final seconds = (milliseconds / 1000).round();
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsNotifierProvider);

    return Scaffold(
      backgroundColor: KriptonTheme.charcoalBlack,
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: KriptonTheme.electricLime,
        backgroundColor: KriptonTheme.inkDeep,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(AnalyticsState state) {
    if (state.isLoading && state.metrics == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
        ),
      );
    }

    if (state.error != null && state.metrics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: KriptonTheme.alertRed, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error}',
              style: const TextStyle(color: KriptonTheme.alertRed),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final metrics = state.metrics;
    if (metrics == null) {
      return const Center(
        child: Text(
          'No hay datos disponibles',
          style: TextStyle(color: KriptonTheme.silver),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
          )
              .animate()
              .fade(duration: 300.ms)
              .slideX(begin: -0.1, end: 0),
          const SizedBox(height: 4),
          Text(
            'Métricas de tus Data Rooms',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KriptonTheme.silver,
                ),
          ),
          const SizedBox(height: 24),

          // Metrics grid
          _buildMetricsGrid(metrics)
              .animate()
              .fade(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 32),

          // Top links
          Text(
            'Top Links',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          _buildTopLinksList(state)
              .animate()
              .fade(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 32),

          // Events section
          if (state.selectedLinkId != null) ...[
            Text(
              'Eventos del link',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            _buildEventsList(state)
                .animate()
                .fade(delay: 300.ms, duration: 400.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(DashboardMetricsEntity metrics) {
    final items = [
      _MetricItem('Links totales', metrics.totalLinks.toString(), Icons.link),
      _MetricItem('Activos', metrics.activeLinks.toString(), Icons.check_circle),
      _MetricItem('Expirados', metrics.expiredLinks.toString(), Icons.timer_off),
      _MetricItem('Vistas totales', metrics.totalViews.toString(), Icons.visibility),
      _MetricItem(
        'Descargas',
        metrics.totalDownloads.toString(),
        Icons.download,
      ),
      _MetricItem(
        'Duración promedio',
        _formatDuration(metrics.averageViewDurationMs),
        Icons.schedule,
      ),
      _MetricItem(
        'Eventos 24h',
        metrics.eventsLast24h.toString(),
        Icons.flash_on,
      ),
      _MetricItem(
        'Almacenamiento',
        _formatBytes(metrics.storageUsedBytes),
        Icons.storage,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMetricCard(item);
      },
    );
  }

  Widget _buildMetricCard(_MetricItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KriptonTheme.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KriptonTheme.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(item.icon, color: KriptonTheme.electricLime, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 20,
                      color: KriptonTheme.electricLime,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KriptonTheme.silver,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopLinksList(AnalyticsState state) {
    final topLinks = state.metrics?.topLinks ?? [];

    if (topLinks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: KriptonTheme.ink,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KriptonTheme.cardBorder, width: 1),
        ),
        child: Column(
          children: [
            const Icon(Icons.bar_chart, size: 48, color: KriptonTheme.graphite),
            const SizedBox(height: 16),
            Text(
              'Sin actividad aún',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Los links más vistos aparecerán aquí',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: KriptonTheme.silver,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topLinks.length,
      itemBuilder: (context, index) {
        final link = topLinks[index];
        final isSelected = state.selectedLinkId == link.linkId;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: KriptonTheme.ink,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? KriptonTheme.electricLime.withOpacity(0.5)
                  : KriptonTheme.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: KriptonTheme.electricLime.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.insert_drive_file,
                color: KriptonTheme.electricLime,
                size: 20,
              ),
            ),
            title: Text(
              link.fileName ?? 'Documento sin nombre',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: KriptonTheme.platinum,
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${link.views} vistas · ${link.downloads} descargas',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KriptonTheme.silver,
                  ),
            ),
            trailing: isSelected && state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
                    ),
                  )
                : const Icon(Icons.chevron_right, color: KriptonTheme.silver),
            onTap: () {
              ref.read(analyticsNotifierProvider.notifier).loadEvents(link.linkId);
            },
          ),
        );
      },
    );
  }

  Widget _buildEventsList(AnalyticsState state) {
    final events = state.events;

    if (state.isLoading && events.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(KriptonTheme.electricLime),
        ),
      );
    }

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: KriptonTheme.ink,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KriptonTheme.cardBorder, width: 1),
        ),
        child: const Center(
          child: Text(
            'No hay eventos registrados para este link',
            style: TextStyle(color: KriptonTheme.silver),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: KriptonTheme.inkDeep,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _eventColor(event.eventType),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatEventType(event.eventType),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: KriptonTheme.platinum,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (event.pageNumber != null)
                      Text(
                        'Página ${event.pageNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: KriptonTheme.silver,
                            ),
                      ),
                    Text(
                      _formatEventDate(event.createdAt ?? DateTime.fromMillisecondsSinceEpoch(event.timestampMs)),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KriptonTheme.graphite,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDuration(event.durationMs.toDouble()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KriptonTheme.cyanTelemetry,
                      fontFamily: 'SFMono',
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _eventColor(String eventType) {
    switch (eventType) {
      case 'page_view':
        return KriptonTheme.electricLime;
      case 'download_complete':
        return KriptonTheme.cryptoGreen;
      case 'download_start':
        return KriptonTheme.amber;
      case 'screenshot_blocked':
        return KriptonTheme.alertRed;
      default:
        return KriptonTheme.cyanTelemetry;
    }
  }

  String _formatEventType(String eventType) {
    switch (eventType) {
      case 'page_view':
        return 'Vista de página';
      case 'download_complete':
        return 'Descarga completada';
      case 'download_start':
        return 'Inicio de descarga';
      case 'screenshot_blocked':
        return 'Screenshot bloqueado';
      default:
        return eventType;
    }
  }

  String _formatEventDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;

  _MetricItem(this.label, this.value, this.icon);
}
