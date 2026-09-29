import 'title_model.dart';

class SuggestionInboxItem {
  final int recipientRowId;
  final int senderId;
  final String senderDisplayName;
  final TitleModel title;
  final String? note;
  final String? groupName;
  final int? groupId;
  final DateTime createdAt;

  SuggestionInboxItem({
    required this.recipientRowId,
    required this.senderId,
    required this.senderDisplayName,
    required this.title,
    this.note,
    this.groupName,
    this.groupId,
    required this.createdAt,
  });

  factory SuggestionInboxItem.fromJson(Map<String, dynamic> json) =>
      SuggestionInboxItem(
        recipientRowId: json['recipientRowId'] as int,
        senderId: json['senderId'] as int,
        senderDisplayName: json['senderDisplayName'] as String,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        note: json['note'] as String?,
        groupName: json['groupName'] as String?,
        groupId: json['groupId'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

enum SuggestionStatus { pending, accepted, passed }

SuggestionStatus _statusFromApi(String value) => switch (value.toLowerCase()) {
  'accepted' => SuggestionStatus.accepted,
  'passed' => SuggestionStatus.passed,
  _ => SuggestionStatus.pending,
};

class SuggestionNotification {
  final int recipientRowId;
  final String recipientDisplayName;
  final TitleModel title;
  final SuggestionStatus status;
  final DateTime respondedAt;
  final bool seen;

  /// Set when the suggestion was made to a group.
  final int? groupId;
  final String? groupName;

  SuggestionNotification({
    required this.recipientRowId,
    required this.recipientDisplayName,
    required this.title,
    required this.status,
    required this.respondedAt,
    required this.seen,
    this.groupId,
    this.groupName,
  });

  factory SuggestionNotification.fromJson(Map<String, dynamic> json) =>
      SuggestionNotification(
        recipientRowId: json['recipientRowId'] as int,
        recipientDisplayName: json['recipientDisplayName'] as String,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        status: _statusFromApi(json['status'] as String),
        respondedAt: DateTime.parse(json['respondedAt'] as String),
        seen: json['seen'] as bool,
        groupId: json['groupId'] as int?,
        groupName: json['groupName'] as String?,
      );
}

/// "Grubun Önerileri": one card per title suggested to a group, however many
/// times it was suggested or accepted. [supportCount] = members who
/// suggested or accepted it; when that's everyone it's a match.
class GroupSuggestion {
  final TitleModel title;
  final List<String> suggestedBy;
  final String? note;
  final List<String> acceptedBy;
  final List<String> passedBy;
  final int supportCount;
  final int memberCount;
  final bool isMatch;
  final DateTime lastActivityAt;

  GroupSuggestion({
    required this.title,
    required this.suggestedBy,
    this.note,
    required this.acceptedBy,
    required this.passedBy,
    required this.supportCount,
    required this.memberCount,
    required this.isMatch,
    required this.lastActivityAt,
  });

  factory GroupSuggestion.fromJson(Map<String, dynamic> json) =>
      GroupSuggestion(
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        suggestedBy: (json['suggestedBy'] as List).cast<String>(),
        note: json['note'] as String?,
        acceptedBy: (json['acceptedBy'] as List).cast<String>(),
        passedBy: (json['passedBy'] as List).cast<String>(),
        supportCount: json['supportCount'] as int,
        memberCount: json['memberCount'] as int,
        isMatch: json['isMatch'] as bool,
        lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      );
}
