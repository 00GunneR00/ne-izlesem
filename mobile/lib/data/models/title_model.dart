import 'enums.dart';

class TitleModel {
  final int tmdbId;
  final MediaType mediaType;
  final String name;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final double voteAverage;
  final String? releaseDate;
  final List<int> genreIds;

  TitleModel({
    required this.tmdbId,
    required this.mediaType,
    required this.name,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    required this.voteAverage,
    this.releaseDate,
    this.genreIds = const [],
  });

  factory TitleModel.fromJson(Map<String, dynamic> json) => TitleModel(
        tmdbId: json['tmdbId'] as int,
        mediaType: MediaType.fromApi(json['mediaType'] as String),
        name: json['name'] as String,
        overview: json['overview'] as String?,
        posterUrl: json['posterUrl'] as String?,
        backdropUrl: json['backdropUrl'] as String?,
        voteAverage: (json['voteAverage'] as num).toDouble(),
        releaseDate: json['releaseDate'] as String?,
        genreIds: (json['genreIds'] as List<dynamic>? ?? [])
            .map((e) => e as int)
            .toList(),
      );
}
