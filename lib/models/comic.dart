import 'dart:convert';

class Comic {
  final String id;
  String title;
  String filePath;
  String? coverPath; // caminho para imagem de capa extraída
  int? pageCount;
  int lastReadPage;
  DateTime addedAt;
  DateTime? lastReadAt;
  String? collectionId;

  Comic({
    required this.id,
    required this.title,
    required this.filePath,
    this.coverPath,
    this.pageCount,
    this.lastReadPage = 0,
    required this.addedAt,
    this.lastReadAt,
    this.collectionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'coverPath': coverPath,
      'pageCount': pageCount,
      'lastReadPage': lastReadPage,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'lastReadAt': lastReadAt?.millisecondsSinceEpoch,
      'collectionId': collectionId,
    };
  }

  factory Comic.fromMap(Map<String, dynamic> map) {
    return Comic(
      id: map['id'],
      title: map['title'],
      filePath: map['filePath'],
      coverPath: map['coverPath'],
      pageCount: map['pageCount'],
      lastReadPage: map['lastReadPage'] ?? 0,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt']),
      lastReadAt: map['lastReadAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastReadAt'])
          : null,
      collectionId: map['collectionId'],
    );
  }

  String toJson() => jsonEncode(toMap());
  factory Comic.fromJson(String source) => Comic.fromMap(jsonDecode(source));

  Comic copyWith({
    String? title,
    String? filePath,
    String? coverPath,
    int? pageCount,
    int? lastReadPage,
    DateTime? lastReadAt,
    String? collectionId,
    bool clearCollection = false,
  }) {
    return Comic(
      id: id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      coverPath: coverPath ?? this.coverPath,
      pageCount: pageCount ?? this.pageCount,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      addedAt: addedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      collectionId: clearCollection ? null : (collectionId ?? this.collectionId),
    );
  }

  double get readProgress {
    if (pageCount == null || pageCount == 0) return 0;
    return lastReadPage / pageCount!;
  }

  bool get isRead => pageCount != null && lastReadPage >= pageCount! - 1;
}