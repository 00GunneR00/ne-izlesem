namespace Neizlesem.Api.DTOs;

public record FeedItemDto(string Type, int UserId, string UserDisplayName, TitleDto Title, string? Text, DateTime CreatedAt);
