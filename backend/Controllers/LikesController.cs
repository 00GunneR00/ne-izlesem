using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services;

namespace Neizlesem.Api.Controllers;

[ApiController]
[Route("api/likes")]
public class LikesController(AppDbContext db, TitleCacheService titleCache) : ControllerBase
{
    [HttpPost("toggle")]
    public async Task<ActionResult<LikeToggleResultDto>> Toggle(LikeRequest request, CancellationToken ct)
    {
        var title = await titleCache.GetOrCacheAsync(request.TmdbId, request.MediaType, ct);
        if (title is null)
        {
            return NotFound("Title not found on TMDB.");
        }

        var existing = await db.TitleLikes
            .FirstOrDefaultAsync(l => l.UserId == request.UserId && l.TitleId == title.Id, ct);

        if (existing is not null)
        {
            db.TitleLikes.Remove(existing);
            await db.SaveChangesAsync(ct);
            return new LikeToggleResultDto(false);
        }

        db.TitleLikes.Add(new TitleLike { UserId = request.UserId, TitleId = title.Id });
        await db.SaveChangesAsync(ct);
        return new LikeToggleResultDto(true);
    }

    [HttpGet]
    public async Task<ActionResult<List<LikedTitleDto>>> GetForUser([FromQuery] int userId, CancellationToken ct)
    {
        var likes = await db.TitleLikes
            .Include(l => l.Title)
            .Where(l => l.UserId == userId)
            .Select(l => new LikedTitleDto(l.Title!.TmdbId, l.Title.MediaType))
            .ToListAsync(ct);
        return likes;
    }

    /// <summary>Total (all-user) like counts for a batch of titles — used by the trending list.</summary>
    [HttpGet("counts")]
    public async Task<ActionResult<List<LikeCountDto>>> GetCounts([FromQuery] string tmdbIds, [FromQuery] MediaType mediaType, CancellationToken ct)
    {
        var ids = tmdbIds.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(int.Parse)
            .ToList();
        if (ids.Count == 0)
        {
            return new List<LikeCountDto>();
        }

        var counts = await db.TitleLikes
            .Include(l => l.Title)
            .Where(l => l.Title!.MediaType == mediaType && ids.Contains(l.Title.TmdbId))
            .GroupBy(l => l.Title!.TmdbId)
            .Select(g => new LikeCountDto(g.Key, g.Count()))
            .ToListAsync(ct);
        return counts;
    }
}
