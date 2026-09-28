class CastMemberModel {
  final int personId;
  final String name;
  final String? profileUrl;
  final String? character;

  CastMemberModel({
    required this.personId,
    required this.name,
    this.profileUrl,
    this.character,
  });

  factory CastMemberModel.fromJson(Map<String, dynamic> json) =>
      CastMemberModel(
        personId: json['personId'] as int,
        name: json['name'] as String,
        profileUrl: json['profileUrl'] as String?,
        character: json['character'] as String?,
      );
}
