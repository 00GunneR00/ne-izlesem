using Neizlesem.Api.Models;

namespace Neizlesem.Api.DTOs;

public record FriendDto(int FriendshipId, int UserId, string DisplayName, string Username);

public record FriendRequestDto(int FriendshipId, int RequesterId, string RequesterDisplayName, string RequesterUsername, DateTime CreatedAt, bool Seen);

public record SendFriendRequestRequest(int RequesterId, string? Username, string? FriendCode);

public record FriendshipResultDto(int FriendshipId, FriendshipStatus Status);
