using Microsoft.AspNetCore.Mvc;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services;

namespace Neizlesem.Api.Controllers;

[ApiController]
[Route("api/swipes")]
public class SwipesController(AppDbContext db, TitleCacheService titleCache) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Record(SwipeRequest request, CancellationToken ct)
    {
        var title = await titleCache.GetOrCacheAsync(request.TmdbId, request.MediaType, ct);
        if (title is null)
        {
            return NotFound("Title not found on TMDB.");
        }

        db.SwipeInteractions.Add(new SwipeInteraction
        {
            UserId = request.UserId,
            TitleId = title.Id,
            Direction = request.Direction,
        });
        await db.SaveChangesAsync(ct);
        return NoContent();
    }
}
