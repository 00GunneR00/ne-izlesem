import 'title_model.dart';

class SuggestionInboxItem {
  final int recipientRowId;
  final int senderId;
  final String senderDisplayName;
  final TitleModel title;
  final String? note;
  final String? groupName;
  final DateTime createdAt;

  SuggestionInboxItem({
    required this.recipientRowId,
    required this.senderId,
    required this.senderDisplayName,
    required this.title,
    this.note,
    this.groupName,
    required this.createdAt,
  });

  factory SuggestionInboxItem.fromJson(Map<String, dynamic> json) => SuggestionInboxItem(
        recipientRowId: json['recipientRowId'] as int,
        senderId: json['senderId'] as int,
        senderDisplayName: json['senderDisplayName'] as String,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        note: json['note'] as String?,
        groupName: json['groupName'] as String?,
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

  SuggestionNotification({
    required this.recipientRowId,
    required this.recipientDisplayName,
    required this.title,
    required this.status,
    required this.respondedAt,
    required this.seen,
  });

  factory SuggestionNotification.fromJson(Map<String, dynamic> json) => SuggestionNotification(
        recipientRowId: json['recipientRowId'] as int,
        recipientDisplayName: json['recipientDisplayName'] as String,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        status: _statusFromApi(json['status'] as String),
        respondedAt: DateTime.parse(json['respondedAt'] as String),
        seen: json['seen'] as bool,
      );
}

class GroupWatchlistItem {
  final TitleModel title;
  final String acceptedByDisplayName;
  final DateTime acceptedAt;

  GroupWatchlistItem({
    required this.title,
    required this.acceptedByDisplayName,
    required this.acceptedAt,
  });

  factory GroupWatchlistItem.fromJson(Map<String, dynamic> json) => GroupWatchlistItem(
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        acceptedByDisplayName: json['acceptedByDisplayName'] as String,
        acceptedAt: DateTime.parse(json['acceptedAt'] as String),
      );
}
