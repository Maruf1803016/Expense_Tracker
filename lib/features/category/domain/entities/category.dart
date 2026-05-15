import 'package:equatable/equatable.dart';

enum CategoryType { income, expense }

class Category extends Equatable {
  final String id;
  final String name;
  final CategoryType type;

  const Category({
    required this.id,
    required this.name,
    required this.type,
  });

  @override
  List<Object?> get props => [id, name, type];
}
