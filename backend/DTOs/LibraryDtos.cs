using Neizlesem.Api.Models;

namespace Neizlesem.Api.DTOs;

public record LibraryEntryDto(
    int Id,
    int UserId,
    TitleDto Title,
    LibraryStatus Status,
    DateTime AddedAt,
    int? Rating);

public record CreateLibraryEntryRequest(
    int UserId,
    int TmdbId,
    MediaType MediaType,
    LibraryStatus Status);

public record UpdateLibraryEntryRequest(LibraryStatus Status);

public record SwipeRequest(
    int UserId,
    int TmdbId,
    MediaType MediaType,
    SwipeDirection Direction);

/// <summary><see cref="Rating"/> 1–5, or null to clear it.</summary>
public record SetRatingRequest(int UserId, int? Rating);
