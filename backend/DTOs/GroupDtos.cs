using Neizlesem.Api.Models;

namespace Neizlesem.Api.DTOs;

public record GroupDto(int Id, string Name, int OwnerId, List<UserSummaryDto> Members);

public record CreateGroupRequest(int OwnerId, string Name, List<int> MemberUserIds);

public record GroupSwipeRequest(int UserId, int TmdbId, MediaType MediaType, SwipeDirection Direction);

/// <summary><see cref="Matched"/> is true when this swipe completed the match (everyone liked it).</summary>
public record GroupSwipeResultDto(bool Matched, TitleDto? Title);

public record GroupMatchDto(int Id, TitleDto Title, DateTime MatchedAt);

public record GroupMatchNotificationDto(int MatchId, int GroupId, string GroupName, TitleDto Title, DateTime MatchedAt, bool Seen);
