using Neizlesem.Api.Models;

namespace Neizlesem.Api.DTOs;

public record PlanAttendeeDto(int UserId, string DisplayName, PlanResponse Response, PlanOutcome? Outcome);

/// <summary>
/// A plan as seen by one user: <see cref="MyResponse"/>/<see cref="MyOutcome"/>
/// are theirs; <see cref="Attendees"/> includes the creator (always Going).
/// </summary>
public record PlanDto(
    int Id,
    TitleDto Title,
    DateTime ScheduledAt,
    string? Note,
    int CreatorId,
    string CreatorDisplayName,
    int? GroupId,
    string? GroupName,
    List<PlanAttendeeDto> Attendees,
    PlanResponse MyResponse,
    PlanOutcome? MyOutcome);

/// <summary>
/// Solo when neither <see cref="GroupId"/> nor <see cref="FriendIds"/> is
/// given; a group plan invites every other member; otherwise the friends.
/// </summary>
public record CreatePlanRequest(
    int UserId,
    int TmdbId,
    MediaType MediaType,
    DateTime ScheduledAt,
    int? GroupId,
    List<int>? FriendIds,
    string? Note);
