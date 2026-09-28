using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Controllers;

/// <summary>
/// The Takip tab: shows in progress, new/upcoming episodes of followed
/// shows, unreleased titles on the watchlist, and recent group matches.
/// </summary>
[ApiController]
[Route("api/tracking")]
public class TrackingController(AppDbContext db, ITmdbService tmdb, TitleMapper mapper) : ControllerBase
{
    /// <summary>Episodes that aired this recently still count as "new".</summary>
    private const int RecentDays = 7;

    /// <summary>How far ahead upcoming episodes are listed.</summary>
    private const int AheadDays = 30;

    /// <summary>Cap on TMDB lookups per request (one per followed show).</summary>
    private const int MaxShowLookups = 30;

    [HttpGet]
    public async Task<ActionResult<TrackingDto>> Get([FromQuery] int userId, CancellationToken ct)
    {
        if (!await db.Users.AnyAsync(u => u.Id == userId, ct))
        {
            return NotFound();
        }

        var entries = await db.LibraryEntries
            .Include(e => e.Title)
            .Where(e => e.UserId == userId)
            .ToListAsync(ct);

        var continueWatching = entries
            .Where(e => e.Status == LibraryStatus.Watching)
            .OrderByDescending(e => e.AddedAt)
            .Select(ToEntryDto)
            .ToList();

        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        // Followed shows = in progress, finished (waiting for new seasons),
        // or on the watchlist.
        var shows = entries
            .Where(e => e.Title!.MediaType == MediaType.Show)
            .OrderBy(e => e.Status == LibraryStatus.Watching ? 0 : 1)
            .Take(MaxShowLookups)
            .ToList();
        var newEpisodes = (await Task.WhenAll(shows.Select(e => NewEpisodeForAsync(e.Title!, today, ct))))
            .OfType<NewEpisodeDto>()
            // Just-aired first (newest first), then upcoming (soonest first).
            .OrderBy(n => n.Aired ? 0 : 1)
            .ThenBy(n => n.Aired ? today.DayNumber - n.AirDate.DayNumber : n.AirDate.DayNumber)
            .ToList();

        var upcoming = entries
            .Where(e => e.Status == LibraryStatus.ToWatch && e.Title!.ReleaseDate > today)
            .OrderBy(e => e.Title!.ReleaseDate)
            .Select(e => new UpcomingReleaseDto(mapper.ToDto(e.Title!), e.Title!.ReleaseDate!.Value))
            .ToList();

        var matches = await db.GroupMatches
            .Include(m => m.Title)
            .Include(m => m.Group)
            .Join(db.GroupMembers.Where(gm => gm.UserId == userId),
                m => m.GroupId, gm => gm.GroupId,
                (m, gm) => new { Match = m, gm.MatchesSeenAt })
            .OrderByDescending(x => x.Match.MatchedAt)
            .Take(10)
            .ToListAsync(ct);
        var groupMatches = matches.Select(x => new GroupMatchNotificationDto(
            x.Match.Id,
            x.Match.GroupId,
            x.Match.Group!.Name,
            mapper.ToDto(x.Match.Title!),
            x.Match.MatchedAt,
            x.MatchesSeenAt.HasValue && x.Match.MatchedAt <= x.MatchesSeenAt.Value)).ToList();

        return new TrackingDto(continueWatching, newEpisodes, upcoming, groupMatches);
    }

    /// <summary>
    /// The show's next episode if it airs within <see cref="AheadDays"/>,
    /// else its latest one if that aired within <see cref="RecentDays"/>.
    /// A TMDB failure just leaves the show out.
    /// </summary>
    private async Task<NewEpisodeDto?> NewEpisodeForAsync(Title show, DateOnly today, CancellationToken ct)
    {
        TmdbTitle? details;
        try
        {
            details = await tmdb.GetDetailsAsync(MediaType.Show, show.TmdbId, ct);
        }
        catch (HttpRequestException)
        {
            return null;
        }
        if (details is null)
        {
            return null;
        }

        if (details.NextEpisodeToAir is { } next
            && DateOnly.TryParse(next.AirDate, out var nextDate)
            && nextDate.DayNumber - today.DayNumber <= AheadDays)
        {
            return new NewEpisodeDto(mapper.ToDto(show), next.SeasonNumber, next.EpisodeNumber,
                next.Name, nextDate, Aired: nextDate <= today);
        }
        if (details.LastEpisodeToAir is { } last
            && DateOnly.TryParse(last.AirDate, out var lastDate)
            && today.DayNumber - lastDate.DayNumber is >= 0 and <= RecentDays)
        {
            return new NewEpisodeDto(mapper.ToDto(show), last.SeasonNumber, last.EpisodeNumber,
                last.Name, lastDate, Aired: true);
        }
        return null;
    }

    private LibraryEntryDto ToEntryDto(LibraryEntry e) =>
        new(e.Id, e.UserId, mapper.ToDto(e.Title!), e.Status, e.AddedAt, e.Rating, e.CurrentSeason, e.CurrentEpisode);
}
