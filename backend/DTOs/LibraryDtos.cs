using Neizlesem.Api.Models;

namespace Neizlesem.Api.DTOs;

public record LibraryEntryDto(
    int Id,
    int UserId,
    TitleDto Title,
    LibraryStatus Status,
    DateTime AddedAt);

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
