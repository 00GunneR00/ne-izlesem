using Microsoft.AspNetCore.Mvc;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Controllers;

[ApiController]
[Route("api/people")]
public class PeopleController(ITmdbService tmdb, TitleMapper mapper) : ControllerBase
{
    [HttpGet("search")]
    public async Task<ActionResult<List<PersonDto>>> Search([FromQuery] string query, [FromQuery] int page = 1, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return new List<PersonDto>();
        }
        var result = await tmdb.SearchPeopleAsync(query, page, ct);
        return result.Results.Select(mapper.ToDto).ToList();
    }

    [HttpGet("popular")]
    public async Task<ActionResult<List<PersonDto>>> Popular([FromQuery] int page = 1, CancellationToken ct = default)
    {
        var result = await tmdb.GetPopularPeopleAsync(page, ct);
        return result.Results.Select(mapper.ToDto).ToList();
    }

    [HttpGet("{personId:int}/credits")]
    public async Task<ActionResult<List<TitleDto>>> GetCredits(int personId, CancellationToken ct)
    {
        // combined_credits counts a single guest cameo (a talk-show visit, a
        // one-off sitcom walk-on) as a "cast" credit exactly like a real
        // role, which drowns out an actor's actual filmography. Talk/news/
        // reality genres catch most recurring talk-show appearances; a low
        // episode count catches the rest (single cameos in otherwise
        // unrelated shows, which don't carry one of those genres).
        var nonRoleTvGenres = new HashSet<int> { 10767, 10763, 10764 };

        var credits = await tmdb.GetPersonCombinedCreditsAsync(personId, ct);
        return credits
            .Where(c => c.MediaType is "movie" or "tv")
            .Where(c => c.MediaType != "tv" || (c.EpisodeCount >= 2 && !c.GenreIds.Any(nonRoleTvGenres.Contains)))
            .DistinctBy(c => (c.MediaType, c.Id))
            .OrderByDescending(c => c.Popularity)
            .Select(c => mapper.ToDto(c, c.MediaType == "movie" ? MediaType.Movie : MediaType.Show))
            .ToList();
    }
}
