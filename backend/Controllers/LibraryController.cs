using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Controllers;

[ApiController]
[Route("api/library")]
public class LibraryController(AppDbContext db, TitleCacheService titleCache, TitleMapper mapper, ITmdbService tmdb) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<LibraryEntryDto>>> GetForUser(
        [FromQuery] int userId, [FromQuery] LibraryStatus? status, [FromQuery] MediaType? mediaType,
        [FromQuery] int page = 1, [FromQuery] int pageSize = 24, CancellationToken ct = default)
    {
        var query = db.LibraryEntries.Include(e => e.Title).Where(e => e.UserId == userId);

        if (status.HasValue)
        {
            query = query.Where(e => e.Status == status.Value);
        }

        if (mediaType.HasValue)
        {
            query = query.Where(e => e.Title!.MediaType == mediaType.Value);
        }

        var entries = await query
            .OrderByDescending(e => e.AddedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);
        return entries.Select(ToDto).ToList();
    }

    [HttpGet("count")]
    public async Task<ActionResult<int>> GetCount([FromQuery] int userId, [FromQuery] LibraryStatus? status, CancellationToken ct)
    {
        var query = db.LibraryEntries.Where(e => e.UserId == userId);
        if (status.HasValue)
        {
            query = query.Where(e => e.Status == status.Value);
        }
        return await query.CountAsync(ct);
    }

    /// <summary>The user's entry for one title, so the detail screen can show (and undo) its current status. 204 when absent.</summary>
    [HttpGet("entry")]
    public async Task<ActionResult<LibraryEntryDto>> GetEntry(
        [FromQuery] int userId, [FromQuery] int tmdbId, [FromQuery] MediaType mediaType, CancellationToken ct)
    {
        var entry = await db.LibraryEntries
            .Include(e => e.Title)
            .FirstOrDefaultAsync(e => e.UserId == userId && e.Title!.TmdbId == tmdbId && e.Title.MediaType == mediaType, ct);
        return entry is null ? NoContent() : ToDto(entry);
    }

    [HttpPost]
    public async Task<ActionResult<LibraryEntryDto>> Add(CreateLibraryEntryRequest request, CancellationToken ct)
    {
        var title = await titleCache.GetOrCacheAsync(request.TmdbId, request.MediaType, ct);
        if (title is null)
        {
            return NotFound("Title not found on TMDB.");
        }

        var existing = await db.LibraryEntries
            .Include(e => e.Title)
            .FirstOrDefaultAsync(e => e.UserId == request.UserId && e.TitleId == title.Id, ct);
        if (existing is not null)
        {
            SetStatus(existing, request.Status);
            await db.SaveChangesAsync(ct);
            return ToDto(existing);
        }

        var entry = new LibraryEntry
        {
            UserId = request.UserId,
            TitleId = title.Id,
            Title = title,
            Status = request.Status,
        };
        db.LibraryEntries.Add(entry);
        await db.SaveChangesAsync(ct);
        return CreatedAtAction(nameof(GetForUser), new { userId = request.UserId }, ToDto(entry));
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<LibraryEntryDto>> UpdateStatus(int id, UpdateLibraryEntryRequest request, CancellationToken ct)
    {
        var entry = await db.LibraryEntries.Include(e => e.Title).FirstOrDefaultAsync(e => e.Id == id, ct);
        if (entry is null)
        {
            return NotFound();
        }

        SetStatus(entry, request.Status);
        await db.SaveChangesAsync(ct);
        return ToDto(entry);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Remove(int id, CancellationToken ct)
    {
        var entry = await db.LibraryEntries.FirstOrDefaultAsync(e => e.Id == id, ct);
        if (entry is null)
        {
            return NotFound();
        }

        db.LibraryEntries.Remove(entry);
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpPut("{id:int}/rating")]
    public async Task<ActionResult<LibraryEntryDto>> SetRating(int id, SetRatingRequest request, CancellationToken ct)
    {
        if (request.Rating is < 1 or > 5)
        {
            return BadRequest("Puan 1 ile 5 arasında olmalı.");
        }

        var entry = await db.LibraryEntries.Include(e => e.Title)
            .FirstOrDefaultAsync(e => e.Id == id && e.UserId == request.UserId, ct);
        if (entry is null)
        {
            return NotFound();
        }
        if (request.Rating is not null && entry.Status != LibraryStatus.Watched)
        {
            return BadRequest("Sadece izlediğin içerikleri puanlayabilirsin.");
        }

        entry.Rating = request.Rating;
        entry.RatedAt = request.Rating is null ? null : DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return ToDto(entry);
    }

    /// <summary>
    /// Records the last watched episode of a show. Anything not finished yet
    /// becomes "İzliyorum"; an already-watched show keeps its status (e.g.
    /// a rewatch).
    /// </summary>
    [HttpPut("{id:int}/progress")]
    public async Task<ActionResult<LibraryEntryDto>> SetProgress(int id, SetProgressRequest request, CancellationToken ct)
    {
        if (request.Season < 1 || request.Episode < 0)
        {
            return BadRequest("Geçersiz sezon/bölüm.");
        }

        var entry = await db.LibraryEntries.Include(e => e.Title)
            .FirstOrDefaultAsync(e => e.Id == id && e.UserId == request.UserId, ct);
        if (entry is null)
        {
            return NotFound();
        }
        if (entry.Title!.MediaType != MediaType.Show)
        {
            return BadRequest("Bölüm takibi sadece diziler için.");
        }

        entry.CurrentSeason = request.Season;
        entry.CurrentEpisode = request.Episode;
        if (entry.Status == LibraryStatus.ToWatch)
        {
            SetStatus(entry, LibraryStatus.Watching);
        }
        await db.SaveChangesAsync(ct);
        return ToDto(entry);
    }

    /// <summary>
    /// "▶ Sonraki bölüm" from the Listem strip: logs the episode after the
    /// current one, rolling over into the next aired season. Season/episode
    /// counts come from TMDB so the client doesn't need them.
    /// </summary>
    [HttpPost("{id:int}/next-episode")]
    public async Task<ActionResult<NextEpisodeResultDto>> NextEpisode(int id, [FromQuery] int userId, CancellationToken ct)
    {
        var entry = await db.LibraryEntries.Include(e => e.Title)
            .FirstOrDefaultAsync(e => e.Id == id && e.UserId == userId, ct);
        if (entry is null)
        {
            return NotFound();
        }
        if (entry.Title!.MediaType != MediaType.Show)
        {
            return BadRequest("Bölüm takibi sadece diziler için.");
        }

        var show = await tmdb.GetDetailsAsync(MediaType.Show, entry.Title.TmdbId, ct);
        var seasons = (show?.Seasons ?? [])
            .Where(s => s.SeasonNumber > 0 && s.EpisodeCount > 0)
            .OrderBy(s => s.SeasonNumber)
            .ToList();
        if (seasons.Count == 0)
        {
            return BadRequest("Bu dizinin bölüm bilgisi yok.");
        }

        (int Season, int Episode)? next;
        if (entry.CurrentSeason is not { } season)
        {
            next = (seasons[0].SeasonNumber, 1);
        }
        else
        {
            var episode = entry.CurrentEpisode ?? 0;
            var count = seasons.FirstOrDefault(s => s.SeasonNumber == season)?.EpisodeCount ?? 0;
            var following = seasons.FirstOrDefault(s => s.SeasonNumber > season);
            next = episode < count ? (season, episode + 1)
                : following is not null ? (following.SeasonNumber, 1)
                : null;
        }
        if (next is null)
        {
            return Conflict("Yayınlanan tüm bölümleri izledin.");
        }

        entry.CurrentSeason = next.Value.Season;
        entry.CurrentEpisode = next.Value.Episode;
        if (entry.Status == LibraryStatus.ToWatch)
        {
            SetStatus(entry, LibraryStatus.Watching);
        }
        await db.SaveChangesAsync(ct);

        var last = seasons[^1];
        var finished = next.Value.Season == last.SeasonNumber && next.Value.Episode >= last.EpisodeCount;
        return new NextEpisodeResultDto(ToDto(entry), finished);
    }

    /// <summary>
    /// A rating only makes sense for something watched, and episode progress
    /// only once started — moving back to "İzleyeceğim" drops both.
    /// </summary>
    private static void SetStatus(LibraryEntry entry, LibraryStatus status)
    {
        entry.Status = status;
        if (status != LibraryStatus.Watched)
        {
            entry.Rating = null;
            entry.RatedAt = null;
        }
        if (status == LibraryStatus.ToWatch)
        {
            entry.CurrentSeason = null;
            entry.CurrentEpisode = null;
        }
    }

    private LibraryEntryDto ToDto(LibraryEntry e) =>
        new(e.Id, e.UserId, mapper.ToDto(e.Title!), e.Status, e.AddedAt, e.Rating, e.CurrentSeason, e.CurrentEpisode);
}
