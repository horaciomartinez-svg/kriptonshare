import 'package:flutter/material.dart';
import '../../../../../app/config/theme/app_theme.dart';
import '../../../domain/entities/file_entity.dart';
import '../../../domain/entities/folder_entity.dart';
import '../molecules/file_list_tile.dart';
import '../molecules/folder_grid_card.dart';

enum ExplorerViewMode { grid, list }

class DriveExplorerView extends StatelessWidget {
  final List<FolderEntity> folders;
  final List<FileEntity> unfiledDocuments;
  final ExplorerViewMode viewMode;
  final void Function(FolderEntity folder)? onFolderTap;
  final void Function(FolderEntity folder)? onFolderShare;
  final void Function(FileEntity file)? onFileTap;
  final void Function(FileEntity file)? onFileShare;

  const DriveExplorerView({
    super.key,
    required this.folders,
    required this.unfiledDocuments,
    this.viewMode = ExplorerViewMode.list,
    this.onFolderTap,
    this.onFolderShare,
    this.onFileTap,
    this.onFileShare,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (folders.isNotEmpty) ...[
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'CARPETAS VIRTUALES',
                style: TextStyle(
                  color: AppTheme.silver,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          viewMode == ExplorerViewMode.grid
              ? SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => FolderGridCard(
                        folder: folders[index],
                        onTap: onFolderTap != null ? () => onFolderTap!(folders[index]) : null,
                        onShare: onFolderShare != null ? () => onFolderShare!(folders[index]) : null,
                      ),
                      childCount: folders.length,
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => FolderGridCard(
                        folder: folders[index],
                        onTap: onFolderTap != null ? () => onFolderTap!(folders[index]) : null,
                        onShare: onFolderShare != null ? () => onFolderShare!(folders[index]) : null,
                      ),
                      childCount: folders.length,
                    ),
                  ),
                ),
        ],
        if (unfiledDocuments.isNotEmpty) ...[
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'ARCHIVOS INDIVIDUALES EN BÓVEDA',
                style: TextStyle(
                  color: AppTheme.silver,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => FileListTile(
                  file: unfiledDocuments[index],
                  onTap: onFileTap != null ? () => onFileTap!(unfiledDocuments[index]) : null,
                  onShare: onFileShare != null ? () => onFileShare!(unfiledDocuments[index]) : null,
                ),
                childCount: unfiledDocuments.length,
              ),
            ),
          ),
        ],
        if (folders.isEmpty && unfiledDocuments.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'Tu Data Room está vacío',
                style: TextStyle(color: AppTheme.silver),
              ),
            ),
          ),
      ],
    );
  }
}
