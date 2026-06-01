import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:rar/rar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CbrExtractor {
  static const List<String> supportedImageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'
  ];

  /// Extrai as páginas de um arquivo CBR/CBZ e retorna lista de caminhos de imagem.
  /// Retorna null em caso de erro.
  static Future<List<String>?> extractPages(
    String filePath, {
    String? comicId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final extension = p.extension(filePath).toLowerCase();
      final cacheDir = await _getComicCacheDir(comicId ?? p.basenameWithoutExtension(filePath));

      if (extension == '.cbr' || extension == '.rar') {
        await _extractRarToCache(filePath, cacheDir.path);
        return await _getCacheImageFiles(cacheDir.path);
      }

      if (extension != '.cbz' && extension != '.zip') return null;

      final archive = ZipDecoder().decodeBytes(bytes);
      final imageFiles = archive.files
          .where((f) => f.isFile && _isImageFile(f.name))
          .toList();
      imageFiles.sort((a, b) => _naturalSort(a.name, b.name));

      final List<String> imagePaths = [];
      final total = imageFiles.length;
      for (int i = 0; i < imageFiles.length; i++) {
        final entry = imageFiles[i];
        final data = entry.content;
        final fileName = '${i.toString().padLeft(5, '0')}_${p.basename(entry.name)}';
        final outPath = p.join(cacheDir.path, fileName);
        final outFile = File(outPath);
        if (!await outFile.exists()) {
          await outFile.writeAsBytes(data);
        }
        imagePaths.add(outPath);
        onProgress?.call((i + 1) / total);
      }
      return imagePaths;
    } catch (e) {
      debugPrint('Erro ao extrair CBR/CBZ: $e');
      return null;
    }
  }

  /// Tenta extrair apenas a capa (primeira imagem) do arquivo.
  static Future<String?> extractCover(String filePath, {String? comicId}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final extension = p.extension(filePath).toLowerCase();

      Archive? archive;

      if (extension == '.cbz' || extension == '.zip') {
        archive = ZipDecoder().decodeBytes(bytes);
      } else if (extension == '.cbr' || extension == '.rar') {
        final cacheDir = await _getComicCacheDir(comicId ?? p.basenameWithoutExtension(filePath));
        await _extractRarToCache(filePath, cacheDir.path);
        final imageFiles = await _getCacheImageFiles(cacheDir.path);
        if (imageFiles.isEmpty) return null;

        imageFiles.sort((a, b) => _naturalSort(a, b));

        final coverFile = File(imageFiles.first);
        final data = await coverFile.readAsBytes();

        final coverPath = p.join(cacheDir.path, 'cover${p.extension(coverFile.path)}');
        final outFile = File(coverPath);
        if (!await outFile.exists()) {
          await outFile.writeAsBytes(data);
        }

        return coverPath;
      }

      if (archive == null) return null;

      final imageFiles = archive.files
          .where((f) => f.isFile && _isImageFile(f.name))
          .toList();

      if (imageFiles.isEmpty) return null;

      imageFiles.sort((a, b) => _naturalSort(a.name, b.name));

      final coverFile = imageFiles.first;
      final data = coverFile.content;

      final cacheDir = await _getComicCacheDir(
        comicId ?? p.basenameWithoutExtension(filePath),
      );

      final coverPath = p.join(cacheDir.path, 'cover${p.extension(coverFile.name)}');
      final outFile = File(coverPath);
      if (!await outFile.exists()) {
        await outFile.writeAsBytes(data);
      }

      return coverPath;
    } catch (e) {
      debugPrint('Erro ao extrair capa: $e');
      return null;
    }
  }

  /// Conta o número de páginas sem extrair tudo.
  static Future<int?> countPages(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final extension = p.extension(filePath).toLowerCase();

      Archive? archive;

      if (extension == '.cbz' || extension == '.zip') {
        archive = ZipDecoder().decodeBytes(bytes);
      } else if (extension == '.cbr' || extension == '.rar') {
        final listResult = await Rar.listRarContents(rarFilePath: filePath);
        if (listResult['success'] != true) return null;
        final files = (listResult['files'] as List<dynamic>?)
            ?.whereType<String>()
            .where(_isImageFile)
            .toList();
        return files?.length;
      }

      if (archive == null) return null;

      return archive.files
          .where((f) => f.isFile && _isImageFile(f.name))
          .length;
    } catch (e) {
      return null;
    }
  }

  /// Limpa o cache de um quadrinho específico.
  static Future<void> clearCache(String comicId) async {
    final cacheDir = await _getComicCacheDir(comicId);
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }

  static Future<Directory> _getComicCacheDir(String comicId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'comics_cache', comicId));
    await dir.create(recursive: true);
    return dir;
  }

  static bool _isImageFile(String name) {
    final ext = p.extension(name).toLowerCase();
    return supportedImageExtensions.contains(ext);
  }

  /// Ordenação natural para nomes de arquivo (ex: page2 antes de page10)
  static int _naturalSort(String a, String b) {
    final RegExp numRegex = RegExp(r'(\d+)');
    
    final aName = p.basename(a).toLowerCase();
    final bName = p.basename(b).toLowerCase();

    final aParts = aName.split(numRegex);
    final bParts = bName.split(numRegex);
    final aMatches = numRegex.allMatches(aName).map((m) => int.parse(m.group(0)!)).toList();
    final bMatches = numRegex.allMatches(bName).map((m) => int.parse(m.group(0)!)).toList();

    int i = 0;
    while (i < aParts.length || i < bParts.length) {
      if (i < aMatches.length && i < bMatches.length) {
        final diff = aMatches[i].compareTo(bMatches[i]);
        if (diff != 0) return diff;
      }
      i++;
    }

    return aName.compareTo(bName);
  }

  /// Tenta decodificar como RAR. CBR é RAR, mas a lib archive tem suporte limitado.
  /// Se falhar, tenta como ZIP (alguns CBRs são na verdade ZIPs renomeados).
  static Future<void> _extractRarToCache(String rarPath, String cacheDirPath) async {
    final extractionDir = Directory(p.join(cacheDirPath, 'rar_extracted'));
    if (await extractionDir.exists()) {
      await extractionDir.delete(recursive: true);
    }
    await extractionDir.create(recursive: true);

    final result = await Rar.extractRarFile(
      rarFilePath: rarPath,
      destinationPath: extractionDir.path,
    );
    if (result['success'] != true) {
      throw Exception('Falha na extração RAR: ${result['message']}');
    }

    final extractedFiles = await extractionDir
        .list(recursive: true)
        .where((entity) => entity is File && _isImageFile(entity.path))
        .cast<File>()
        .toList();
    extractedFiles.sort((a, b) => _naturalSort(a.path, b.path));

    for (int i = 0; i < extractedFiles.length; i++) {
      final file = extractedFiles[i];
      final data = await file.readAsBytes();
      final fileName = '${i.toString().padLeft(5, '0')}_${p.basename(file.path)}';
      final outPath = p.join(cacheDirPath, fileName);
      final outFile = File(outPath);
      if (!await outFile.exists()) {
        await outFile.writeAsBytes(data);
      }
    }
  }

  static Future<List<String>> _getCacheImageFiles(String cacheDirPath) async {
    final dir = Directory(cacheDirPath);
    if (!await dir.exists()) return [];
    final imageFiles = await dir
        .list()
        .where((entity) => entity is File && _isImageFile(entity.path))
        .cast<File>()
        .map((file) => file.path)
        .toList();
    return imageFiles;
  }
}
