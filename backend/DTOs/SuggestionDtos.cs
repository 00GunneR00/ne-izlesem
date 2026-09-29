using Neizlesem.Api.Models;

namespace Neizlesem.Api.DTOs;

public record SendSuggestionRequest(
    int SenderId,
    int TmdbId,
    MediaType MediaType,
    string? Note,
    List<int>? RecipientUserIds,
    int? GroupId);

public record SuggestionInboxItemDto(
    int RecipientRowId,
    int SenderId,
    string SenderDisplayName,
    TitleDto Title,
    string? Note,
    string? GroupName,
    DateTime CreatedAt);

public record SuggestionNotificationDto(
    int RecipientRowId,
    string RecipientDisplayName,
    TitleDto Title,
    SuggestionStatus Status,
    DateTime RespondedAt,
    bool Seen);

/// <summary>
/// One card per title suggested to a group ("Grubun Önerileri"), however
/// many times it was suggested or accepted. <see cref="SupportCount"/> =
/// members who suggested or accepted it; all of them → <see cref="IsMatch"/>.
/// </summary>
public record GroupSuggestionDto(
    TitleDto Title,
    List<string> SuggestedBy,
    string? Note,
    List<string> AcceptedBy,
    List<string> PassedBy,
    int SupportCount,
    int MemberCount,
    bool IsMatch,
    DateTime LastActivityAt);

/// <summary><see cref="Matched"/>: this accept made everyone agree — a new group match.</summary>
public record SuggestionAcceptResultDto(bool Matched);
