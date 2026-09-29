import 'title_model.dart';
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

/// A title every member of the group swiped right on in "Birlikte Seç".
/// A member's stance on a group match: İzleyelim (+1), Kararsız (0),
/// İzlemeyelim (−1).
enum MatchVote {
  yes,
  maybe,
  no;

  String get apiValue => switch (this) {
        MatchVote.yes => 'Yes',
        MatchVote.maybe => 'Maybe',
        MatchVote.no => 'No',
      };

  static MatchVote? fromApi(String? value) => switch (value) {
        'Yes' => MatchVote.yes,
        'Maybe' => MatchVote.maybe,
        'No' => MatchVote.no,
        _ => null,
      };
}

class GroupMatch {
  final int id;
  final TitleModel title;
  final DateTime matchedAt;

  /// İzleyelim − İzlemeyelim; the backend ranks matches by this.
  final int score;
  final List<String> yes;
  final List<String> maybe;
  final List<String> no;

  /// The current user's vote, if any.
  final MatchVote? myVote;

  GroupMatch({
    required this.id,
    required this.title,
    required this.matchedAt,
    this.score = 0,
    this.yes = const [],
    this.maybe = const [],
    this.no = const [],
    this.myVote,
  });

  factory GroupMatch.fromJson(Map<String, dynamic> json) => GroupMatch(
        id: json['id'] as int,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        matchedAt: DateTime.parse(json['matchedAt'] as String),
        score: json['score'] as int? ?? 0,
        yes: (json['yes'] as List?)?.cast<String>() ?? const [],
        maybe: (json['maybe'] as List?)?.cast<String>() ?? const [],
        no: (json['no'] as List?)?.cast<String>() ?? const [],
        myVote: MatchVote.fromApi(json['myChoice'] as String?),
      );
}

class GroupMatchNotification {
  final int matchId;
  final int groupId;
  final String groupName;
  final TitleModel title;
  final DateTime matchedAt;
  final bool seen;

  GroupMatchNotification({
    required this.matchId,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.matchedAt,
    required this.seen,
  });

  factory GroupMatchNotification.fromJson(Map<String, dynamic> json) => GroupMatchNotification(
        matchId: json['matchId'] as int,
        groupId: json['groupId'] as int,
        groupName: json['groupName'] as String,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        matchedAt: DateTime.parse(json['matchedAt'] as String),
        seen: json['seen'] as bool,
      );

  GroupMatchNotification markedSeen() => GroupMatchNotification(
        matchId: matchId,
        groupId: groupId,
        groupName: groupName,
        title: title,
        matchedAt: matchedAt,
        seen: true,
      );
}

/// Result of a group swipe; [title] is set when this swipe completed a match.
class GroupSwipeResult {
  final bool matched;
  final TitleModel? title;

  GroupSwipeResult({required this.matched, this.title});

  factory GroupSwipeResult.fromJson(Map<String, dynamic> json) => GroupSwipeResult(
        matched: json['matched'] as bool,
        title: json['title'] == null
            ? null
            : TitleModel.fromJson(json['title'] as Map<String, dynamic>),
      );
}
