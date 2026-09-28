using Neizlesem.Api.Models;

namespace Neizlesem.Api.Services.Tmdb;

public interface ITmdbService
{
    Task<List<TmdbGenre>> GetGenresAsync(MediaType mediaType, CancellationToken ct = default);
    Task<TmdbPagedResult<TmdbTitle>> GetTrendingAsync(MediaType mediaType, int page = 1, CancellationToken ct = default);
    Task<TmdbPagedResult<TmdbTitle>> DiscoverAsync(MediaType mediaType, int? genreId, int page = 1, int? providerId = null, CancellationToken ct = default);
    Task<TmdbTitle?> GetDetailsAsync(MediaType mediaType, int tmdbId, CancellationToken ct = default);
    Task<List<TmdbVideo>> GetVideosAsync(MediaType mediaType, int tmdbId, CancellationToken ct = default);
    Task<TmdbPagedResult<TmdbTitle>> SearchTitlesAsync(MediaType mediaType, string query, int page = 1, CancellationToken ct = default);
    Task<TmdbPagedResult<TmdbPerson>> SearchPeopleAsync(string query, int page = 1, CancellationToken ct = default);
    Task<TmdbPagedResult<TmdbPerson>> GetPopularPeopleAsync(int page = 1, CancellationToken ct = default);
    Task<List<TmdbCombinedCredit>> GetPersonCombinedCreditsAsync(int personId, CancellationToken ct = default);
    Task<List<TmdbCastMember>> GetCreditsAsync(MediaType mediaType, int tmdbId, CancellationToken ct = default);
}
