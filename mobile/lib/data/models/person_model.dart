class PersonModel {
  final int tmdbId;
  final String name;
  final String? profileUrl;
  final String? knownForDepartment;

  PersonModel({
    required this.tmdbId,
    required this.name,
    this.profileUrl,
    this.knownForDepartment,
  });

  factory PersonModel.fromJson(Map<String, dynamic> json) => PersonModel(
    tmdbId: json['tmdbId'] as int,
    name: json['name'] as String,
    profileUrl: json['profileUrl'] as String?,
    knownForDepartment: json['knownForDepartment'] as String?,
  );
}
