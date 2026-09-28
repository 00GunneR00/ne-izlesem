import 'user_model.dart';

class GroupModel {
  final int id;
  final String name;
  final int ownerId;
  final List<UserSummaryModel> members;

  GroupModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as int,
        name: json['name'] as String,
        ownerId: json['ownerId'] as int,
        members: (json['members'] as List).map((e) => UserSummaryModel.fromJson(e)).toList(),
      );
}
