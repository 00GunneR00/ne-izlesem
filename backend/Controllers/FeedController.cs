using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Controllers;

[ApiController]
[Route("api/feed")]
public class FeedController(AppDbContext db, TitleMapper mapper) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<FeedItemDto>>> GetFeed([FromQuery] int userId, [FromQuery] int take, CancellationToken ct)
    {
        var limit = take is > 0 and <= 100 ? take : 30;
        var friendIds = await FriendsController.GetFriendIdsAsync(db, userId, ct);
        if (friendIds.Count == 0)
        {
            return new List<FeedItemDto>();
        }

        var likeEntities = await db.TitleLikes
            .Include(l => l.User)
            .Include(l => l.Title)
            .Where(l => friendIds.Contains(l.UserId))
            .OrderByDescending(l => l.LikedAt)
            .Take(limit)
            .ToListAsync(ct);

        var commentEntities = await db.Comments
            .Include(c => c.User)
            .Include(c => c.Title)
            .Where(c => friendIds.Contains(c.UserId))
            .OrderByDescending(c => c.CreatedAt)
            .Take(limit)
            .ToListAsync(ct);

        var ratingEntities = await db.LibraryEntries
            .Include(e => e.User)
            .Include(e => e.Title)
            .Where(e => friendIds.Contains(e.UserId) && e.Rating != null && e.RatedAt != null)
            .OrderByDescending(e => e.RatedAt)
            .Take(limit)
            .ToListAsync(ct);

        var likes = likeEntities.Select(l => new FeedItemDto("Like", l.UserId, l.User!.DisplayName, mapper.ToDto(l.Title!), null, l.LikedAt));
        var comments = commentEntities.Select(c => new FeedItemDto("Comment", c.UserId, c.User!.DisplayName, mapper.ToDto(c.Title!), c.Text, c.CreatedAt));
        var ratings = ratingEntities.Select(e => new FeedItemDto("Rating", e.UserId, e.User!.DisplayName, mapper.ToDto(e.Title!), null, e.RatedAt!.Value, e.Rating));

        return likes.Concat(comments).Concat(ratings)
            .OrderByDescending(f => f.CreatedAt)
            .Take(limit)
            .ToList();
    }
}
