import 'title_model.dart';

class FeedItemModel {
  final String type; // "Like" | "Comment"
  final int userId;
  final String userDisplayName;
  final TitleModel title;
  final String? text;
  final DateTime createdAt;

  FeedItemModel({
    required this.type,
    required this.userId,
    required this.userDisplayName,
    required this.title,
    this.text,
    required this.createdAt,
  });

  bool get isComment => type == 'Comment';

  factory FeedItemModel.fromJson(Map<String, dynamic> json) => FeedItemModel(
        type: json['type'] as String,
        userId: json['userId'] as int,
        userDisplayName: json['userDisplayName'] as String,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        text: json['text'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
