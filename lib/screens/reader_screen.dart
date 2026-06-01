import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import '../models/comic.dart';
import '../providers/library_provider.dart';
import '../utils/app_theme.dart';
import '../utils/cbr_extractor.dart';

class ReaderScreen extends StatefulWidget {
  final Comic comic;

  const ReaderScreen({super.key, required this.comic});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  List<String>? _pages;
  bool _isLoading = true;
  String? _error;
  late PageController _pageController;
  int _currentPage = 0;
  bool _showControls = true;
  double _extractionProgress = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.comic.lastReadPage;
    _pageController = PageController(initialPage: _currentPage);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadPages();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    // Salva progresso
    final provider = context.read<LibraryProvider>();
    provider.updateComicProgress(widget.comic.id, _currentPage);
    super.dispose();
  }

  Future<void> _loadPages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pages = await CbrExtractor.extractPages(
        widget.comic.filePath,
        comicId: widget.comic.id,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _extractionProgress = progress);
          }
        },
      );

      if (pages == null || pages.isEmpty) {
        setState(() {
          _error = 'Não foi possível abrir este arquivo.\n\nVerifique se o arquivo não está corrompido.\n\nNota: CBR (RAR nativo) pode ter compatibilidade limitada. Tente converter para CBZ.';
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _pages = pages;
          _isLoading = false;
        });

        // Pula para a última página lida
        if (_currentPage > 0 && _currentPage < pages.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _pageController.jumpToPage(_currentPage);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao abrir quadrinho: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _goToPage(int page) {
    if (_pages == null) return;
    final target = page.clamp(0, _pages!.length - 1);
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading ? _buildLoadingState() : _buildReader(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, color: AppTheme.accent, size: 64),
          const SizedBox(height: 24),
          const Text(
            'Abrindo quadrinho...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 16),
          if (_extractionProgress > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: LinearProgressIndicator(
                value: _extractionProgress,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_extractionProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ] else
            const CircularProgressIndicator(color: AppTheme.accent),
        ],
      ),
    );
  }

  Widget _buildReader() {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.primary,
        appBar: AppBar(
          title: Text(widget.comic.title),
          backgroundColor: AppTheme.secondary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.accent, size: 64),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pages = _pages!;

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          // Leitor de páginas
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: pages.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: FileImage(File(pages[index])),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                initialScale: PhotoViewComputedScale.contained,
                heroAttributes: PhotoViewHeroAttributes(tag: 'comic_page_$index'),
                filterQuality: FilterQuality.high,
              );
            },
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              context.read<LibraryProvider>().updateComicProgress(
                widget.comic.id,
                index,
              );
            },
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),

          // Controles superiores
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.comic.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_currentPage + 1}/${pages.length}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Controles inferiores
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _showControls ? 0 : -120,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.navigate_before, color: Colors.white, size: 32),
                            onPressed: _currentPage > 0
                                ? () => _goToPage(_currentPage - 1)
                                : null,
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppTheme.accent,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: AppTheme.accent,
                                overlayColor: AppTheme.accent.withValues(alpha: 0.2),
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: _currentPage.toDouble(),
                                min: 0,
                                max: (pages.length - 1).toDouble(),
                                onChanged: (value) {
                                  _goToPage(value.round());
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.navigate_next, color: Colors.white, size: 32),
                            onPressed: _currentPage < pages.length - 1
                                ? () => _goToPage(_currentPage + 1)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}