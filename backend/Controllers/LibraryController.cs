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
public class LibraryController(AppDbContext db, TitleCacheService titleCache, TitleMapper mapper) : ControllerBase
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

    /// <summary>A rating only makes sense for something watched — moving back to "İzleyeceğim" drops it.</summary>
    private static void SetStatus(LibraryEntry entry, LibraryStatus status)
    {
        entry.Status = status;
        if (status != LibraryStatus.Watched)
        {
            entry.Rating = null;
            entry.RatedAt = null;
        }
    }

    private LibraryEntryDto ToDto(LibraryEntry e) => new(e.Id, e.UserId, mapper.ToDto(e.Title!), e.Status, e.AddedAt, e.Rating);
}
