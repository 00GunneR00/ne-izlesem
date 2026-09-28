namespace Neizlesem.Api.DTOs;

/// <summary>Type is "Like", "Comment" or "Rating" (then <see cref="Rating"/> is set).</summary>
public record FeedItemDto(string Type, int UserId, string UserDisplayName, TitleDto Title, string? Text, DateTime CreatedAt, int? Rating = null, bool IsSpoiler = false);
