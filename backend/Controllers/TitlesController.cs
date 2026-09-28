using Microsoft.AspNetCore.Mvc;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Controllers;

[ApiController]
[Route("api/titles")]
public class TitlesController(ITmdbService tmdb, TitleMapper mapper, SwipeDeckService deck) : ControllerBase
{
    [HttpGet("genres")]
    public async Task<ActionResult<List<GenreDto>>> GetGenres([FromQuery] MediaType mediaType, CancellationToken ct)
    {
        var genres = await tmdb.GetGenresAsync(mediaType, ct);
        return genres.Select(g => new GenreDto(g.Id, g.Name)).ToList();
    }

    [HttpGet("trending")]
    public async Task<ActionResult<List<TitleDto>>> GetTrending(
        [FromQuery] MediaType mediaType, [FromQuery] int page = 1, CancellationToken ct = default)
    {
        var result = await tmdb.GetTrendingAsync(mediaType, page, ct);
        return result.Results.Select(t => mapper.ToDto(t, mediaType)).ToList();
    }

    /// <summary>
    /// Popular titles. With <paramref name="userId"/>, titles that user already
    /// swiped or has in their library are left out (Keşfet feed), so they
    /// don't come back on every app open. A page may therefore come back
    /// short or empty — the client just asks for the next one.
    /// </summary>
    [HttpGet("discover")]
    public async Task<ActionResult<List<TitleDto>>> Discover(
        [FromQuery] MediaType mediaType, [FromQuery] int? genreId, [FromQuery] int page = 1,
        [FromQuery] int? providerId = null, [FromQuery] int? userId = null, CancellationToken ct = default)
    {
        var result = await tmdb.DiscoverAsync(mediaType, genreId.HasValue ? [genreId.Value] : null, page, providerId, ct);
        var handled = userId.HasValue
            ? await deck.GetHandledTmdbIdsAsync(userId.Value, mediaType, ct)
            : [];
        return result.Results
            .Where(t => !handled.Contains(t.Id))
            .Select(t => mapper.ToDto(t, mediaType))
            .ToList();
    }

    [HttpGet("search")]
    public async Task<ActionResult<List<TitleDto>>> Search(
        [FromQuery] MediaType mediaType, [FromQuery] string query, [FromQuery] int page = 1, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return new List<TitleDto>();
        }
        var result = await tmdb.SearchTitlesAsync(mediaType, query, page, ct);
        return result.Results.Select(t => mapper.ToDto(t, mediaType)).ToList();
    }

    [HttpGet("{mediaType}/{tmdbId:int}")]
    public async Task<ActionResult<TitleDto>> GetDetails(MediaType mediaType, int tmdbId, CancellationToken ct)
    {
        var title = await tmdb.GetDetailsAsync(mediaType, tmdbId, ct);
        return title is null ? NotFound() : mapper.ToDto(title, mediaType);
    }

    [HttpGet("{mediaType}/{tmdbId:int}/cast")]
    public async Task<ActionResult<List<CastMemberDto>>> GetCast(MediaType mediaType, int tmdbId, CancellationToken ct)
    {
        var cast = await tmdb.GetCreditsAsync(mediaType, tmdbId, ct);
        return cast
            .OrderBy(c => c.Order)
            .Take(8)
            .Select(mapper.ToDto)
            .ToList();
    }

    /// <summary>Aired seasons of a show (specials/"season 0" and empty future seasons left out).</summary>
    [HttpGet("Show/{tmdbId:int}/seasons")]
    public async Task<ActionResult<List<SeasonDto>>> GetSeasons(int tmdbId, CancellationToken ct)
    {
        var show = await tmdb.GetDetailsAsync(MediaType.Show, tmdbId, ct);
        if (show is null)
        {
            return NotFound();
        }
        return show.Seasons
            .Where(s => s.SeasonNumber > 0 && s.EpisodeCount > 0)
            .OrderBy(s => s.SeasonNumber)
            .Select(s => new SeasonDto(s.SeasonNumber, s.Name, s.EpisodeCount))
            .ToList();
    }

    [HttpGet("{mediaType}/{tmdbId:int}/trailers")]
    public async Task<ActionResult<List<TrailerDto>>> GetTrailers(MediaType mediaType, int tmdbId, CancellationToken ct)
    {
        var videos = await tmdb.GetVideosAsync(mediaType, tmdbId, ct);
        return videos
            .Where(v => v.Site == "YouTube" && v.Type == "Trailer")
            .Select(v => new TrailerDto(v.Key, v.Name, v.Site, v.Type))
            .ToList();
    }

    // Lets the client check trailer availability for a whole discover page in
    // one round trip (instead of one request per title) so it can deprioritize
    // titles with no trailer without hammering the API.
    [HttpGet("trailer-status")]
    public async Task<ActionResult<Dictionary<int, bool>>> GetTrailerStatus(
        [FromQuery] MediaType mediaType, [FromQuery] string tmdbIds, CancellationToken ct)
    {
        var ids = tmdbIds
            .Split(',', StringSplitOptions.RemoveEmptyEntries)
            .Select(int.Parse)
            .Distinct()
            .ToList();

        var results = await Task.WhenAll(ids.Select(async id =>
        {
            try
            {
                var videos = await tmdb.GetVideosAsync(mediaType, id, ct);
                var hasTrailer = videos.Any(v => v.Site == "YouTube" && v.Type == "Trailer");
                return (id, hasTrailer);
            }
            catch (HttpRequestException)
            {
                // One flaky TMDB lookup shouldn't fail Task.WhenAll for the
                // whole batch (which was silently stalling the discover
                // feed) — treat it as "no trailer" and move on.
                return (id, hasTrailer: false);
            }
        }));

        return results.ToDictionary(r => r.id, r => r.hasTrailer);
    }
}
