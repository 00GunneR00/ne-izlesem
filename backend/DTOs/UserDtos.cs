namespace Neizlesem.Api.DTOs;

public record UserDto(int Id, string Email, string DisplayName, string Username, string FriendCode, List<int> PreferredGenreIds);

public record CreateUserRequest(string Email, string DisplayName, string Username);

public record UpdatePreferredGenresRequest(List<int> GenreIds);

public record UserSummaryDto(int Id, string DisplayName, string Username);
