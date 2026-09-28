using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Controllers;

/// <summary>"Senin İçin" — titles similar to what the user rated/liked/watched.</summary>
[ApiController]
[Route("api/recommendations")]
public class RecommendationsController(
    AppDbContext db,
    ITmdbService tmdb,
    TitleMapper mapper,
    SwipeDeckService deck) : ControllerBase
{
    private const int MaxSeeds = 5;
    private const int MaxItems = 20;

    [HttpGet]
    public async Task<ActionResult<RecommendationsDto>> Get(
        [FromQuery] int userId, [FromQuery] MediaType mediaType, CancellationToken ct)
    {
        var user = await db.Users.FindAsync([userId], ct);
        if (user is null)
        {
            return NotFound();
        }

        var seeds = await PickSeedsAsync(userId, mediaType, ct);
        var handled = await deck.GetHandledTmdbIdsAsync(userId, mediaType, ct);

        if (seeds.Count == 0)
        {
            // Nothing to go on yet — fall back to the onboarding genres.
            var fallback = await deck.BuildAsync(mediaType, user.PreferredGenreIds, handled, 1, ct);
            return new RecommendationsDto(fallback.Items.Take(MaxItems).ToList(), []);
        }

        var results = await Task.WhenAll(seeds.Select(async seed =>
        {
            try
            {
                return (seed, items: (await tmdb.GetRecommendationsAsync(mediaType, seed.Title.TmdbId, ct)).Results);
            }
            catch (HttpRequestException)
            {
                return (seed, items: new List<TmdbTitle>());
            }
        }));

        // A title recommended by several seeds — or by a highly rated one —
        // ranks higher; popularity only breaks ties.
        var scored = new Dictionary<int, (TmdbTitle Title, double Score)>();
        foreach (var (seed, items) in results)
        {
            foreach (var t in items.Where(t => !handled.Contains(t.Id)))
            {
                var previous = scored.TryGetValue(t.Id, out var s) ? s.Score : 0;
                scored[t.Id] = (t, previous + seed.Weight);
            }
        }

        var top = scored.Values
            .OrderByDescending(x => x.Score)
            .ThenByDescending(x => x.Title.Popularity)
            .Take(MaxItems)
            .Select(x => mapper.ToDto(x.Title, mediaType))
            .ToList();
        return new RecommendationsDto(top, seeds.Select(s => s.Title.Name).ToList());
    }

    private record Seed(Title Title, double Weight);

    /// <summary>Best-rated first, then hearted, then most recently watched; low ratings never seed.</summary>
    private async Task<List<Seed>> PickSeedsAsync(int userId, MediaType mediaType, CancellationToken ct)
    {
        var watched = await db.LibraryEntries
            .Include(e => e.Title)
            .Where(e => e.UserId == userId && (e.Status == LibraryStatus.Watched || e.Status == LibraryStatus.Watching)
                        && e.Title!.MediaType == mediaType && (e.Rating == null || e.Rating >= 3))
            .OrderByDescending(e => e.Rating ?? 0)
            .ThenByDescending(e => e.AddedAt)
            .Take(MaxSeeds * 2)
            .ToListAsync(ct);
        var liked = await db.TitleLikes
            .Include(l => l.Title)
            .Where(l => l.UserId == userId && l.Title!.MediaType == mediaType)
            .OrderByDescending(l => l.LikedAt)
            .Take(MaxSeeds)
            .Select(l => l.Title!)
            .ToListAsync(ct);
        var dislikedIds = (await db.LibraryEntries
            .Where(e => e.UserId == userId && e.Rating != null && e.Rating < 3)
            .Select(e => e.TitleId)
            .ToListAsync(ct)).ToHashSet();

        var seeds = new List<Seed>();
        var used = new HashSet<int>();
        void Add(Title title, double weight)
        {
            if (seeds.Count < MaxSeeds && !dislikedIds.Contains(title.Id) && used.Add(title.Id))
            {
                seeds.Add(new Seed(title, weight));
            }
        }

        foreach (var e in watched.Where(e => e.Rating >= 4))
        {
            Add(e.Title!, e.Rating == 5 ? 3 : 2);
        }
        foreach (var t in liked)
        {
            Add(t, 1.5);
        }
        foreach (var e in watched)
        {
            Add(e.Title!, 1);
        }
        return seeds;
    }
}
