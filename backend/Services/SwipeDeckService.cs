using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Services;

/// <summary>Builds swipe cards: popular titles in the preferred genres, minus anything already handled.</summary>
public class SwipeDeckService(AppDbContext db, ITmdbService tmdb, TitleMapper mapper)
{
    private const int TargetSize = 10;
    private const int MaxPagesPerRequest = 5;

    /// <summary>TMDB ids the user already swiped (either way) or has in their library.</summary>
    public async Task<HashSet<int>> GetHandledTmdbIdsAsync(int userId, MediaType mediaType, CancellationToken ct)
    {
        var swiped = db.SwipeInteractions
            .Where(s => s.UserId == userId && s.Title!.MediaType == mediaType)
            .Select(s => s.Title!.TmdbId);
        var inLibrary = db.LibraryEntries
            .Where(e => e.UserId == userId && e.Title!.MediaType == mediaType)
            .Select(e => e.Title!.TmdbId);
        return (await swiped.Union(inLibrary).ToListAsync(ct)).ToHashSet();
    }

    public async Task<SwipeDeckDto> BuildAsync(
        MediaType mediaType,
        IEnumerable<int> preferredMovieGenreIds,
        ISet<int> excludedTmdbIds,
        int page,
        CancellationToken ct)
    {
        var genres = GenreMap.For(mediaType, preferredMovieGenreIds);
        var items = new List<TitleDto>();
        var seen = new HashSet<int>();
        var wrapped = false;
        page = Math.Max(1, page);

        for (var i = 0; i < MaxPagesPerRequest && items.Count < TargetSize; i++)
        {
            var result = await tmdb.DiscoverAsync(mediaType, genres, page, ct: ct);
            if (result.Results.Count == 0)
            {
                // Ran past the last page (the client starts at a random page,
                // and a narrow genre mix can have few pages) — wrap once.
                if (wrapped || page == 1)
                {
                    break;
                }
                wrapped = true;
                page = 1;
                continue;
            }

            // DiscoverAsync may skip ahead over failing pages; continue after
            // the page it actually returned.
            page = (result.Page > 0 ? result.Page : page) + 1;
            items.AddRange(result.Results
                .Where(t => !excludedTmdbIds.Contains(t.Id) && seen.Add(t.Id))
                .Select(t => mapper.ToDto(t, mediaType)));
        }

        return new SwipeDeckDto(items, page);
    }
}
