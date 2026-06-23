import 'package:flutter/material.dart';
import '../../../../core/utils/theme.dart';
import '../../domain/entities/link_entity.dart';

/// Tarjeta visual para un link compartido.
class LinkCard extends StatelessWidget {
  final LinkEntity link;
  final VoidCallback? onShare;
  final VoidCallback? onRevoke;
  final VoidCallback? onDelete;

  const LinkCard({
    super.key,
    required this.link,
    this.onShare,
    this.onRevoke,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = link.isActiveAndNotExpired;
    final remaining = link.expiresAt.difference(DateTime.now());
    final remainingHours = remaining.inHours;

    String statusText;
    Color statusColor;

    if (!isActive) {
      statusText = 'EXPIRADO';
      statusColor = KriptonTheme.alertRed;
    } else if (remainingHours < 6) {
      statusText = '${remainingHours}h restantes';
      statusColor = KriptonTheme.alertRed;
    } else if (remainingHours < 24) {
      statusText = '${remainingHours}h restantes';
      statusColor = KriptonTheme.amber;
    } else {
      statusText = '${remainingHours ~/ 24}d restantes';
      statusColor = KriptonTheme.cryptoGreen;
    }

    return Container(
      decoration: BoxDecoration(
        color: KriptonTheme.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? KriptonTheme.cardBorder
              : KriptonTheme.alertRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? KriptonTheme.kryptonGreen.withOpacity(0.1)
                        : KriptonTheme.alertRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isActive ? Icons.insert_drive_file : Icons.block,
                    color: isActive ? KriptonTheme.kryptonGreen : KriptonTheme.alertRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Room',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        link.id.substring(0, 8).toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'SFMono',
                              color: KriptonTheme.silver,
                            ),
                      ),
                    ],
                  ),
                ),
                // Menu
                if (isActive && onRevoke != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: KriptonTheme.silver),
                    color: KriptonTheme.inkDeep,
                    onSelected: (value) {
                      switch (value) {
                        case 'share':
                          onShare?.call();
                          break;
                        case 'revoke':
                          onRevoke?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, color: KriptonTheme.electricLime, size: 18),
                            SizedBox(width: 8),
                            Text('Compartir'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'revoke',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: KriptonTheme.alertRed, size: 18),
                            SizedBox(width: 8),
                            Text('Revocar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: KriptonTheme.alertRed, size: 18),
                            SizedBox(width: 8),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? KriptonTheme.charcoalBlack
                  : KriptonTheme.alertRed.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                Text(
                  '${link.accessCount} vistas',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KriptonTheme.graphite,
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
