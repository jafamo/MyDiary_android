import '../api/json.dart';

/// Esquema `Topic`.
class Topic {
  const Topic({required this.id, required this.name});

  factory Topic.fromJson(Json json) =>
      Topic(id: json.integer('id'), name: json.string('name'));

  final int id;
  final String name;
}
