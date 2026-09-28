import 'title_model.dart';

class FeedItemModel {
  final String type; // "Like" | "Comment" | "Rating"
  final int userId;
  final String userDisplayName;
  final TitleModel title;
  final String? text;
  final DateTime createdAt;
  final int? rating;
  final bool isSpoiler;

  FeedItemModel({
    required this.type,
    required this.userId,
    required this.userDisplayName,
    required this.title,
    this.text,
    required this.createdAt,
    this.rating,
    this.isSpoiler = false,
  });

  bool get isComment => type == 'Comment';
  bool get isRating => type == 'Rating';

  factory FeedItemModel.fromJson(Map<String, dynamic> json) => FeedItemModel(
        type: json['type'] as String,
        userId: json['userId'] as int,
        userDisplayName: json['userDisplayName'] as String,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        text: json['text'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        rating: json['rating'] as int?,
        isSpoiler: json['isSpoiler'] as bool? ?? false,
      );
}
