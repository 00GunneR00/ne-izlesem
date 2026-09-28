namespace Neizlesem.Api.DTOs;

/// <summary>Everything the Takip tab shows, in one round trip.</summary>
public record TrackingDto(
    List<LibraryEntryDto> ContinueWatching,
    List<NewEpisodeDto> NewEpisodes,
    List<UpcomingReleaseDto> Upcoming,
    List<GroupMatchNotificationDto> GroupMatches);

/// <summary>An episode of a followed show that just aired (<see cref="Aired"/>) or airs soon.</summary>
public record NewEpisodeDto(TitleDto Title, int Season, int Episode, string? EpisodeName, DateOnly AirDate, bool Aired);

/// <summary>A title on the user's İzleyeceğim list that isn't out yet.</summary>
public record UpcomingReleaseDto(TitleDto Title, DateOnly ReleaseDate);
