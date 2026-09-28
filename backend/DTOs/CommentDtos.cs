using Neizlesem.Api.Models;

namespace Neizlesem.Api.DTOs;

public record CreateCommentRequest(int UserId, int TmdbId, MediaType MediaType, string Text, bool IsSpoiler = false);

public record UpdateCommentRequest(int UserId, string Text, bool IsSpoiler);

public record CommentDto(
    int Id,
    int UserId,
    string UserDisplayName,
    TitleDto Title,
    string Text,
    DateTime CreatedAt,
    bool IsSpoiler,
    DateTime? EditedAt);
