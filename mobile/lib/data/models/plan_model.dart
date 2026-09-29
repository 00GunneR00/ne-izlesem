import 'title_model.dart';

/// Katılıyorum / Belki / Gelemem (Pending = not answered yet).
enum PlanResponse {
  pending,
  going,
  maybe,
  notGoing;

  String get apiValue => switch (this) {
        PlanResponse.pending => 'Pending',
        PlanResponse.going => 'Going',
        PlanResponse.maybe => 'Maybe',
        PlanResponse.notGoing => 'NotGoing',
      };

  static PlanResponse fromApi(String value) => switch (value) {
        'Going' => PlanResponse.going,
        'Maybe' => PlanResponse.maybe,
        'NotGoing' => PlanResponse.notGoing,
        _ => PlanResponse.pending,
      };
}

/// "Nasıldı?" answer after the plan's time.
enum PlanOutcome {
  watched,
  skipped;

  String get apiValue => this == PlanOutcome.watched ? 'Watched' : 'Skipped';

  static PlanOutcome? fromApi(String? value) => switch (value) {
        'Watched' => PlanOutcome.watched,
        'Skipped' => PlanOutcome.skipped,
        _ => null,
      };
}

class PlanAttendee {
  final int userId;
  final String displayName;
  final PlanResponse response;
  final PlanOutcome? outcome;

  PlanAttendee({
    required this.userId,
    required this.displayName,
    required this.response,
    this.outcome,
  });

  factory PlanAttendee.fromJson(Map<String, dynamic> json) => PlanAttendee(
        userId: json['userId'] as int,
        displayName: json['displayName'] as String,
        response: PlanResponse.fromApi(json['response'] as String),
        outcome: PlanOutcome.fromApi(json['outcome'] as String?),
      );
}

/// A watch plan as seen by the current user ([myResponse]/[myOutcome]).
class PlanModel {
  final int id;
  final TitleModel title;
  final DateTime scheduledAt;
  final String? note;
  final int creatorId;
  final String creatorDisplayName;
  final int? groupId;
  final String? groupName;

  /// Includes the creator (always going), creator first.
  final List<PlanAttendee> attendees;
  final PlanResponse myResponse;
  final PlanOutcome? myOutcome;

  PlanModel({
    required this.id,
    required this.title,
    required this.scheduledAt,
    this.note,
    required this.creatorId,
    required this.creatorDisplayName,
    this.groupId,
    this.groupName,
    required this.attendees,
    required this.myResponse,
    this.myOutcome,
  });

  bool get isSolo => attendees.length <= 1;
  bool get hasStarted => !scheduledAt.isAfter(DateTime.now());

  factory PlanModel.fromJson(Map<String, dynamic> json) => PlanModel(
        id: json['id'] as int,
        title: TitleModel.fromJson(json['title'] as Map<String, dynamic>),
        scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
        note: json['note'] as String?,
        creatorId: json['creatorId'] as int,
        creatorDisplayName: json['creatorDisplayName'] as String,
        groupId: json['groupId'] as int?,
        groupName: json['groupName'] as String?,
        attendees: (json['attendees'] as List)
            .map((e) => PlanAttendee.fromJson(e))
            .toList(),
        myResponse: PlanResponse.fromApi(json['myResponse'] as String),
        myOutcome: PlanOutcome.fromApi(json['myOutcome'] as String?),
      );
}
