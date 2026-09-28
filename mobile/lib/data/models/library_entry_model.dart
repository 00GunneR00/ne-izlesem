import 'enums.dart';
import 'title_model.dart';

class LibraryEntryModel {
  final int id;
  final int userId;
  final TitleModel title;
  final LibraryStatus status;
  final DateTime addedAt;

  /// Personal 1–5 stars; null when not rated.
  final int? rating;

  /// Shows only: last watched episode.
  final int? currentSeason;
  final int? currentEpisode;

  LibraryEntryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.status,
    required this.addedAt,
    this.rating,
    this.currentSeason,
    this.currentEpisode,
  });

  factory LibraryEntryModel.fromJson(Map<String, dynamic> json) => LibraryEntryModel(
        id: json['id'] as int,
        userId: json['userId'] as int,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        status: LibraryStatus.fromApi(json['status'] as String),
        addedAt: DateTime.parse(json['addedAt'] as String),
        rating: json['rating'] as int?,
        currentSeason: json['currentSeason'] as int?,
        currentEpisode: json['currentEpisode'] as int?,
      );
}

extension LibraryEntryProgress on LibraryEntryModel {
  /// "S2 · B5", or null when no episode has been logged.
  String? get progressLabel => currentSeason == null
      ? null
      : 'S$currentSeason · B${currentEpisode ?? 0}';
}
