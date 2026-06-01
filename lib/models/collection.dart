import 'dart:convert';

class Collection {
  final String id;
  String name;
  String? description;
  String? coverPath;
  DateTime createdAt;
  List<String> comicIds;

  Collection({
    required this.id,
    required this.name,
    this.description,
    this.coverPath,
    required this.createdAt,
    List<String>? comicIds,
  }) : comicIds = comicIds ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverPath': coverPath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'comicIds': comicIds,
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      coverPath: map['coverPath'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      comicIds: List<String>.from(map['comicIds'] ?? []),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory Collection.fromJson(String source) =>
      Collection.fromMap(jsonDecode(source));

  Collection copyWith({
    String? name,
    String? description,
    String? coverPath,
    List<String>? comicIds,
  }) {
    return Collection(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverPath: coverPath ?? this.coverPath,
      createdAt: createdAt,
      comicIds: comicIds ?? List.from(this.comicIds),
    );
  }
}