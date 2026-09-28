class FriendModel {
  final int friendshipId;
  final int userId;
  final String displayName;
  final String username;

  FriendModel({
    required this.friendshipId,
    required this.userId,
    required this.displayName,
    required this.username,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) => FriendModel(
        friendshipId: json['friendshipId'] as int,
        userId: json['userId'] as int,
        displayName: json['displayName'] as String,
        username: json['username'] as String,
      );
}

class FriendRequestModel {
  final int friendshipId;
  final int requesterId;
  final String requesterDisplayName;
  final String requesterUsername;
  final DateTime createdAt;
  final bool seen;

  FriendRequestModel({
    required this.friendshipId,
    required this.requesterId,
    required this.requesterDisplayName,
    required this.requesterUsername,
    required this.createdAt,
    this.seen = false,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) => FriendRequestModel(
        friendshipId: json['friendshipId'] as int,
        requesterId: json['requesterId'] as int,
        requesterDisplayName: json['requesterDisplayName'] as String,
        requesterUsername: json['requesterUsername'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        seen: json['seen'] as bool? ?? false,
      );

  FriendRequestModel markedSeen() => FriendRequestModel(
        friendshipId: friendshipId,
        requesterId: requesterId,
        requesterDisplayName: requesterDisplayName,
        requesterUsername: requesterUsername,
        createdAt: createdAt,
        seen: true,
      );
}
