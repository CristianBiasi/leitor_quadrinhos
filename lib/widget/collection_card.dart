import 'dart:io';
import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../utils/app_theme.dart';

class CollectionCard extends StatelessWidget {
  final Collection collection;
  final int comicCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.comicCount,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surface.withValues(alpha: 0.8),
              AppTheme.cardBg,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildCover()),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (collection.coverPath != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(collection.coverPath!),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholderCover(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$comicCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return _placeholderCover();
  }

  Widget _placeholderCover() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.surface, AppTheme.cardBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.collections_bookmark_rounded,
                color: AppTheme.accent,
                size: 40,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$comicCount quadrinhos',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_special_rounded,
                color: AppTheme.gold,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  collection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (collection.description != null && collection.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                collection.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          const SizedBox(height: 2),
          Text(
            '$comicCount ${comicCount == 1 ? "livro" : "livros"}',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}