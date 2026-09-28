using Neizlesem.Api.Models;

namespace Neizlesem.Api.DTOs;

/// <summary>Card data: <see cref="PreviewPosters"/> are the first few items' posters for the collage.</summary>
public record UserListSummaryDto(
    int Id,
    int OwnerId,
    string OwnerDisplayName,
    string Name,
    string? Description,
    bool IsShared,
    int ItemCount,
    List<string> PreviewPosters,
    DateTime UpdatedAt);

public record UserListItemDto(TitleDto Title, DateTime AddedAt);

public record UserListDetailDto(UserListSummaryDto List, List<UserListItemDto> Items);

public record SaveUserListRequest(int UserId, string Name, string? Description, bool IsShared);

public record AddListItemRequest(int UserId, int TmdbId, MediaType MediaType);
