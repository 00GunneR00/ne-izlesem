import 'title_model.dart';

/// A user-made collection, as shown on cards (Sosyal → Listem).
class UserListSummary {
  final int id;
  final int ownerId;
  final String ownerDisplayName;
  final String name;
  final String? description;

  /// Visible to the owner's friends; otherwise private.
  final bool isShared;
  final int itemCount;

  /// Posters of the most recently added items, for the card collage.
  final List<String> previewPosters;
  final DateTime updatedAt;

  UserListSummary({
    required this.id,
    required this.ownerId,
    required this.ownerDisplayName,
    required this.name,
    this.description,
    required this.isShared,
    required this.itemCount,
    required this.previewPosters,
    required this.updatedAt,
  });

  factory UserListSummary.fromJson(Map<String, dynamic> json) => UserListSummary(
        id: json['id'] as int,
        ownerId: json['ownerId'] as int,
        ownerDisplayName: json['ownerDisplayName'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        isShared: json['isShared'] as bool,
        itemCount: json['itemCount'] as int,
        previewPosters: (json['previewPosters'] as List).cast<String>(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class UserListDetail {
  final UserListSummary list;
  final List<TitleModel> items;

  UserListDetail({required this.list, required this.items});

  factory UserListDetail.fromJson(Map<String, dynamic> json) => UserListDetail(
        list: UserListSummary.fromJson(json['list'] as Map<String, dynamic>),
        items: (json['items'] as List)
            .map((e) => TitleModel.fromJson(e['title'] as Map<String, dynamic>))
            .toList(),
      );
}
