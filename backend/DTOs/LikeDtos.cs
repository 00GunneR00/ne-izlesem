using Neizlesem.Api.Models;

namespace Neizlesem.Api.DTOs;

public record LikeRequest(int UserId, int TmdbId, MediaType MediaType);

public record LikeToggleResultDto(bool Liked);

public record LikedTitleDto(int TmdbId, MediaType MediaType);

public record LikeCountDto(int TmdbId, int Count);
