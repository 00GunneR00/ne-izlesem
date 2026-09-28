using Microsoft.AspNetCore.Mvc;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services;

namespace Neizlesem.Api.Controllers;

[ApiController]
[Route("api/swipes")]
public class SwipesController(AppDbContext db, TitleCacheService titleCache, SwipeDeckService deck) : ControllerBase
{
    /// <summary>
    /// Next swipe cards for a user: popular titles in *any* of their
    /// preferred genres, excluding everything they already swiped or have in
    /// their library (so restarting the app doesn't replay old cards).
    /// </summary>
    [HttpGet("deck")]
    public async Task<ActionResult<SwipeDeckDto>> GetDeck(
        [FromQuery] int userId, [FromQuery] MediaType mediaType, [FromQuery] int page = 1, CancellationToken ct = default)
    {
        var user = await db.Users.FindAsync([userId], ct);
        if (user is null)
        {
            return NotFound();
        }

        var handled = await deck.GetHandledTmdbIdsAsync(userId, mediaType, ct);
        return await deck.BuildAsync(mediaType, user.PreferredGenreIds, handled, page, ct);
    }

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
