import 'group_model.dart';
import 'library_entry_model.dart';
import 'title_model.dart';

/// An episode of a followed show that just aired ([aired]) or airs soon.
class NewEpisodeModel {
  final TitleModel title;
  final int season;
  final int episode;
  final String? episodeName;
  final DateTime airDate;
  final bool aired;

  NewEpisodeModel({
    required this.title,
    required this.season,
    required this.episode,
    this.episodeName,
    required this.airDate,
    required this.aired,
  });

  factory NewEpisodeModel.fromJson(Map<String, dynamic> json) => NewEpisodeModel(
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        season: json['season'] as int,
        episode: json['episode'] as int,
        episodeName: json['episodeName'] as String?,
        airDate: DateTime.parse(json['airDate'] as String),
        aired: json['aired'] as bool,
      );
}

/// A title on the İzleyeceğim list that isn't out yet.
class UpcomingReleaseModel {
  final TitleModel title;
  final DateTime releaseDate;

  UpcomingReleaseModel({required this.title, required this.releaseDate});

  factory UpcomingReleaseModel.fromJson(Map<String, dynamic> json) => UpcomingReleaseModel(
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        releaseDate: DateTime.parse(json['releaseDate'] as String),
      );
}

/// Everything the Takip tab shows.
class TrackingModel {
  final List<LibraryEntryModel> continueWatching;
  final List<NewEpisodeModel> newEpisodes;
  final List<UpcomingReleaseModel> upcoming;
  final List<GroupMatchNotification> groupMatches;

  TrackingModel({
    required this.continueWatching,
    required this.newEpisodes,
    required this.upcoming,
    required this.groupMatches,
  });

  bool get isEmpty =>
      continueWatching.isEmpty &&
      newEpisodes.isEmpty &&
      upcoming.isEmpty &&
      groupMatches.isEmpty;

  factory TrackingModel.fromJson(Map<String, dynamic> json) => TrackingModel(
        continueWatching: (json['continueWatching'] as List)
            .map((e) => LibraryEntryModel.fromJson(e))
            .toList(),
        newEpisodes: (json['newEpisodes'] as List)
            .map((e) => NewEpisodeModel.fromJson(e))
            .toList(),
        upcoming: (json['upcoming'] as List)
            .map((e) => UpcomingReleaseModel.fromJson(e))
            .toList(),
        groupMatches: (json['groupMatches'] as List)
            .map((e) => GroupMatchNotification.fromJson(e))
            .toList(),
      );
}
