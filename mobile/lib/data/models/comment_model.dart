import 'title_model.dart';

class CommentModel {
  final int id;
  final int userId;
  final String userDisplayName;
  final TitleModel title;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.title,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] as int,
        userId: json['userId'] as int,
        userDisplayName: json['userDisplayName'] as String,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
