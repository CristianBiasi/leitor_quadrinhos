import 'dart:io';
import 'package:flutter/material.dart';
import '../models/comic.dart';
import '../utils/app_theme.dart';

class ComicCard extends StatelessWidget {
  final Comic comic;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ComicCard({
    super.key,
    required this.comic,
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
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildCover(),
              ),
            ),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (comic.coverPath != null) {
      final file = File(comic.coverPath!);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholderCover(),
      );
    }
    return _placeholderCover();
  }

  Widget _placeholderCover() {
    return Container(
      color: AppTheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: AppTheme.accent,
            size: 48,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              comic.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comic.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          if (comic.pageCount != null)
            Text(
              '${comic.pageCount} páginas',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
              ),
            ),
          if (comic.lastReadPage > 0 && comic.pageCount != null) ...[
            const SizedBox(height: 4),
            _buildProgressBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = comic.readProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          comic.isRead
              ? '✓ Lido'
              : 'Pág. ${comic.lastReadPage + 1}/${comic.pageCount}',
          style: TextStyle(
            color: comic.isRead ? Colors.green : AppTheme.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}