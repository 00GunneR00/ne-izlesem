using Neizlesem.Api.Models;

namespace Neizlesem.Api.DTOs;

public record CreateCommentRequest(int UserId, int TmdbId, MediaType MediaType, string Text);

public record CommentDto(int Id, int UserId, string UserDisplayName, TitleDto Title, string Text, DateTime CreatedAt);
