import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  final bool isRead;
  final String type; // 'reminder', 'budget', 'alert', 'system'

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
    this.type = 'reminder',
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? date,
    bool? isRead,
    String? type,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [id, title, body, date, isRead, type];
}
