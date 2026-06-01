import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/comic.dart';
import '../models/collection.dart';
import '../utils/cbr_extractor.dart';

class LibraryProvider extends ChangeNotifier {
  static const String _comicsKey = 'comics';
  static const String _collectionsKey = 'collections';

  List<Comic> _comics = [];
  List<Collection> _collections = [];
  bool _isLoading = false;
  String? _error;

  final _uuid = const Uuid();

  List<Comic> get comics => List.unmodifiable(_comics);
  List<Collection> get collections => List.unmodifiable(_collections);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Comic> get unassignedComics =>
      _comics.where((c) => c.collectionId == null).toList();

  List<Comic> comicsInCollection(String collectionId) =>
      _comics.where((c) => c.collectionId == collectionId).toList();

  Comic? getComic(String id) {
    try {
      return _comics.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Collection? getCollection(String id) {
    try {
      return _collections.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadLibrary() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      final comicsJson = prefs.getStringList(_comicsKey) ?? [];
      _comics = comicsJson
          .map((j) => Comic.fromMap(jsonDecode(j)))
          .toList();

      final collectionsJson = prefs.getStringList(_collectionsKey) ?? [];
      _collections = collectionsJson
          .map((j) => Collection.fromMap(jsonDecode(j)))
          .toList();

      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar biblioteca: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Comic?> addComic(String filePath, {String? title}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = _uuid.v4();
      final comicTitle = title ?? _titleFromPath(filePath);

      // Extrai capa
      final coverPath = await CbrExtractor.extractCover(filePath, comicId: id);

      // Conta páginas
      final pageCount = await CbrExtractor.countPages(filePath);

      final comic = Comic(
        id: id,
        title: comicTitle,
        filePath: filePath,
        coverPath: coverPath,
        pageCount: pageCount,
        addedAt: DateTime.now(),
      );

      _comics.add(comic);
      await _saveComics();
      _error = null;
      return comic;
    } catch (e) {
      _error = 'Erro ao adicionar quadrinho: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateComicProgress(String comicId, int page) async {
    final index = _comics.indexWhere((c) => c.id == comicId);
    if (index == -1) return false;

    _comics[index] = _comics[index].copyWith(
      lastReadPage: page,
      lastReadAt: DateTime.now(),
    );
    await _saveComics();
    notifyListeners();
    return true;
  }

  Future<bool> updateComicTitle(String comicId, String title) async {
    final index = _comics.indexWhere((c) => c.id == comicId);
    if (index == -1) return false;

    _comics[index] = _comics[index].copyWith(title: title);
    await _saveComics();
    notifyListeners();
    return true;
  }

  Future<bool> deleteComic(String comicId) async {
    final comic = getComic(comicId);
    if (comic == null) return false;

    // Remove de coleções
    if (comic.collectionId != null) {
      final colIndex = _collections.indexWhere((c) => c.id == comic.collectionId);
      if (colIndex != -1) {
        final updated = _collections[colIndex].copyWith(
          comicIds: List.from(_collections[colIndex].comicIds)..remove(comicId),
        );
        _collections[colIndex] = updated;
        await _saveCollections();
      }
    }

    _comics.removeWhere((c) => c.id == comicId);
    await CbrExtractor.clearCache(comicId);
    await _saveComics();
    notifyListeners();
    return true;
  }

  Future<Collection?> createCollection(String name, {String? description}) async {
    try {
      final collection = Collection(
        id: _uuid.v4(),
        name: name,
        description: description,
        createdAt: DateTime.now(),
      );

      _collections.add(collection);
      await _saveCollections();
      notifyListeners();
      return collection;
    } catch (e) {
      _error = 'Erro ao criar coleção: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateCollection(String collectionId, {String? name, String? description}) async {
    final index = _collections.indexWhere((c) => c.id == collectionId);
    if (index == -1) return false;

    _collections[index] = _collections[index].copyWith(
      name: name ?? _collections[index].name,
      description: description,
    );
    await _saveCollections();
    notifyListeners();
    return true;
  }

  Future<bool> deleteCollection(String collectionId, {bool deleteComics = false}) async {
    final colIndex = _collections.indexWhere((c) => c.id == collectionId);
    if (colIndex == -1) return false;

    if (deleteComics) {
      final comicsToDelete = _comics
          .where((c) => c.collectionId == collectionId)
          .map((c) => c.id)
          .toList();
      for (final id in comicsToDelete) {
        await deleteComic(id);
      }
    } else {
      // Desvincula os quadrinhos da coleção
      for (int i = 0; i < _comics.length; i++) {
        if (_comics[i].collectionId == collectionId) {
          _comics[i] = _comics[i].copyWith(clearCollection: true);
        }
      }
      await _saveComics();
    }

    _collections.removeAt(colIndex);
    await _saveCollections();
    notifyListeners();
    return true;
  }

  Future<bool> addComicToCollection(String comicId, String collectionId) async {
    final comicIndex = _comics.indexWhere((c) => c.id == comicId);
    final colIndex = _collections.indexWhere((c) => c.id == collectionId);

    if (comicIndex == -1 || colIndex == -1) return false;

    // Remove da coleção anterior, se houver
    final oldColId = _comics[comicIndex].collectionId;
    if (oldColId != null && oldColId != collectionId) {
      final oldColIndex = _collections.indexWhere((c) => c.id == oldColId);
      if (oldColIndex != -1) {
        _collections[oldColIndex] = _collections[oldColIndex].copyWith(
          comicIds: List.from(_collections[oldColIndex].comicIds)..remove(comicId),
        );
      }
    }

    // Adiciona à nova coleção
    _comics[comicIndex] = _comics[comicIndex].copyWith(collectionId: collectionId);

    if (!_collections[colIndex].comicIds.contains(comicId)) {
      _collections[colIndex] = _collections[colIndex].copyWith(
        comicIds: List.from(_collections[colIndex].comicIds)..add(comicId),
      );
    }

    // Usa a capa do primeiro quadrinho como capa da coleção, se não tiver
    if (_collections[colIndex].coverPath == null && _comics[comicIndex].coverPath != null) {
      _collections[colIndex] = _collections[colIndex].copyWith(
        coverPath: _comics[comicIndex].coverPath,
      );
    }

    await _saveComics();
    await _saveCollections();
    notifyListeners();
    return true;
  }

  Future<bool> removeComicFromCollection(String comicId) async {
    final comicIndex = _comics.indexWhere((c) => c.id == comicId);
    if (comicIndex == -1) return false;

    final collectionId = _comics[comicIndex].collectionId;
    if (collectionId == null) return false;

    final colIndex = _collections.indexWhere((c) => c.id == collectionId);
    if (colIndex != -1) {
      _collections[colIndex] = _collections[colIndex].copyWith(
        comicIds: List.from(_collections[colIndex].comicIds)..remove(comicId),
      );
      await _saveCollections();
    }

    _comics[comicIndex] = _comics[comicIndex].copyWith(clearCollection: true);
    await _saveComics();
    notifyListeners();
    return true;
  }

  Future<void> _saveComics() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _comics.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList(_comicsKey, jsonList);
  }

  Future<void> _saveCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _collections.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList(_collectionsKey, jsonList);
  }

  String _titleFromPath(String path) {
    final name = path.split('/').last;
    return name
        .replaceAll(RegExp(r'\.(cbr|cbz|zip|rar)$', caseSensitive: false), '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
  }
}