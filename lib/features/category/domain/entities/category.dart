import 'package:equatable/equatable.dart';

enum CategoryType { income, expense }

class Category extends Equatable {
  final String id;
  final String name;
  final CategoryType type;
  final String? icon;
  final String? parentId;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.parentId,
  });

  @override
  List<Object?> get props => [id, name, type, icon, parentId];
}
