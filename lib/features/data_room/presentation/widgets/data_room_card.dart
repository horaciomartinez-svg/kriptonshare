import 'package:flutter/material.dart';
import '../../domain/entities/data_room_entity.dart';
import '../../utils/theme.dart';

class DataRoomCard extends StatelessWidget {
  final DataRoomEntity room;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onRevoke;
  final VoidCallback? onDelete;

  const DataRoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.onShare,
    this.onRevoke,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = room.expiresAt.isBefore(DateTime.now());
    final isActive = room.isActive && !isExpired;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: KriptonTheme.platinum,
                      ),
                    ),
                  ),
                  _buildStatusIndicator(isActive),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Expires: ${_formatDate(room.expiresAt)}',
                style: TextStyle(
                  fontSize: 14,
                  color: KriptonTheme.platinum.withAlpha(179),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.visibility, size: 16, color: KriptonTheme.sapphire),
                  const SizedBox(width: 4),
                  Text(
                    '${room.currentViews}/${room.maxViews == 0 ? '∞' : room.maxViews}',
                    style: TextStyle(
                      fontSize: 12,
                      color: KriptonTheme.platinum.withAlpha(179),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (room.watermarkEnabled)
                    const Icon(Icons.water_drop, size: 16, color: KriptonTheme.sapphire),
                  if (room.downloadEnabled)
                    const Icon(Icons.download, size: 16, color: KriptonTheme.sapphire),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onShare != null)
                    IconButton(
                      icon: const Icon(Icons.share, color: KriptonTheme.sapphire),
                      onPressed: onShare,
                    ),
                  if (onRevoke != null && isActive)
                    IconButton(
                      icon: const Icon(Icons.block, color: KriptonTheme.ember),
                      onPressed: onRevoke,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: KriptonTheme.ember),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? KriptonTheme.sapphire.withAlpha(51) : KriptonTheme.ember.withAlpha(51),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'EXPIRED',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isActive ? KriptonTheme.sapphire : KriptonTheme.ember,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
