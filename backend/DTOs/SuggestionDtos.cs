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

public record GroupWatchlistItemDto(
    TitleDto Title,
    string AcceptedByDisplayName,
    DateTime AcceptedAt);
