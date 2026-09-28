import 'enums.dart';
import 'title_model.dart';

class LibraryEntryModel {
  final int id;
  final int userId;
  final TitleModel title;
  final LibraryStatus status;
  final DateTime addedAt;

  LibraryEntryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.status,
    required this.addedAt,
  });

  factory LibraryEntryModel.fromJson(Map<String, dynamic> json) => LibraryEntryModel(
        id: json['id'] as int,
        userId: json['userId'] as int,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        status: LibraryStatus.fromApi(json['status'] as String),
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}
