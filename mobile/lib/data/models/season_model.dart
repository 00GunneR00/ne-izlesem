class SeasonModel {
  final int seasonNumber;
  final String name;
  final int episodeCount;

  SeasonModel({
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) => SeasonModel(
        seasonNumber: json['seasonNumber'] as int,
        name: json['name'] as String,
        episodeCount: json['episodeCount'] as int,
      );
}
