class UserModel {
  final int id;
  final String email;
  final String displayName;
  final String username;
  final String friendCode;
  final List<int> preferredGenreIds;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.username,
    required this.friendCode,
    this.preferredGenreIds = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        username: json['username'] as String,
        friendCode: json['friendCode'] as String,
        preferredGenreIds: (json['preferredGenreIds'] as List<dynamic>? ?? [])
            .map((e) => e as int)
            .toList(),
      );
}

class UserSummaryModel {
  final int id;
  final String displayName;
  final String username;

  UserSummaryModel({required this.id, required this.displayName, required this.username});

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) => UserSummaryModel(
        id: json['id'] as int,
        displayName: json['displayName'] as String,
        username: json['username'] as String,
      );
}
