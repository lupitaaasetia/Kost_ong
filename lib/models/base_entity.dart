// models/base_entity.dart
abstract class BaseEntity {
  final String _id;
  final DateTime _createdAt;
  DateTime _updatedAt;

  BaseEntity({required String id})
    : _id = id,
      _createdAt = DateTime.now(),
      _updatedAt = DateTime.now();

  // Getters (Encapsulation)
  String get id => _id;
  DateTime get createdAt => _createdAt;
  DateTime get updatedAt => _updatedAt;

  // Protected setter for subclasses
  set updatedAt(DateTime value) => _updatedAt = value;

  // Abstract methods for Polymorphism
  Map<String, dynamic> toJson();
  String getDisplayName();

  String getBaseInfo() {
    return 'ID: $_id, Created: ${_formatDate(_createdAt)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Interfaces for additional functionality
abstract class Searchable {
  bool matchesQuery(String query);
  List<String> getSearchableFields();
}

abstract class Sortable implements Comparable<Sortable> {
  @override
  int compareTo(Sortable other);
}
