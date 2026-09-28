import 'title_model.dart';

class CommentModel {
  final int id;
  final int userId;
  final String userDisplayName;
  final TitleModel title;
  final String text;
  final DateTime createdAt;

  /// Hidden behind a tap-to-reveal for everyone but the author.
  final bool isSpoiler;
  final DateTime? editedAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.title,
    required this.text,
    required this.createdAt,
    this.isSpoiler = false,
    this.editedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] as int,
        userId: json['userId'] as int,
        userDisplayName: json['userDisplayName'] as String,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isSpoiler: json['isSpoiler'] as bool? ?? false,
        editedAt: json['editedAt'] == null
            ? null
            : DateTime.parse(json['editedAt'] as String),
      );
}
