using Neizlesem.Api.Models;

namespace Neizlesem.Api.Services.Tmdb;

public class TmdbService(HttpClient httpClient, TmdbOptions options) : ITmdbService
{
    private static string MediaSegment(MediaType mediaType) => mediaType == MediaType.Movie ? "movie" : "tv";

    private string WithFallbackLanguage(string url) =>
        $"{url}{(url.Contains('?') ? '&' : '?')}language={options.FallbackLanguage}";

    private async Task<TmdbPagedResult<TmdbTitle>> GetTitlePageAsync(string url, CancellationToken ct)
    {
        var result = await httpClient.GetFromJsonAsync<TmdbPagedResult<TmdbTitle>>(url, ct)
            ?? new TmdbPagedResult<TmdbTitle>();
        await FillMissingTranslationsAsync(result.Results, async () =>
            (await httpClient.GetFromJsonAsync<TmdbPagedResult<TmdbTitle>>(WithFallbackLanguage(url), ct))?.Results, ct);
        return result;
    }

    /// <summary>
    /// When a title has no Turkish translation, TMDB returns an empty overview
    /// and the original-language name (e.g. Japanese script). Re-fetch the
    /// same list in the fallback language (English) — one extra request, only
    /// when needed — and fill both gaps by id.
    /// </summary>
    private static async Task FillMissingTranslationsAsync<T>(List<T> items, Func<Task<List<T>?>> fetchFallback, CancellationToken ct)
        where T : TmdbTitle
    {
        if (!items.Any(i => string.IsNullOrWhiteSpace(i.Overview) || i.HasUntranslatedName))
        {
            return;
        }

        static string Key(TmdbTitle t) => t is TmdbCombinedCredit c ? $"{c.MediaType}-{t.Id}" : t.Id.ToString();

        List<T>? fallback;
        try
        {
            fallback = await fetchFallback();
        }
        catch (HttpRequestException)
        {
            return; // a missing overview isn't worth failing the whole list over
        }

        var byKey = (fallback ?? [])
            .GroupBy(Key)
            .ToDictionary(g => g.Key, g => g.First());
        foreach (var item in items)
        {
            if (!byKey.TryGetValue(Key(item), out var english))
            {
                continue;
            }
            if (string.IsNullOrWhiteSpace(item.Overview) && !string.IsNullOrWhiteSpace(english.Overview))
            {
                item.Overview = english.Overview;
            }
            if (item.HasUntranslatedName && !string.IsNullOrWhiteSpace(english.DisplayName))
            {
                item.SetDisplayName(english.DisplayName);
            }
        }
    }

    public async Task<List<TmdbGenre>> GetGenresAsync(MediaType mediaType, CancellationToken ct = default)
    {
        var result = await httpClient.GetFromJsonAsync<TmdbGenreList>(
            $"genre/{MediaSegment(mediaType)}/list", ct);
        return result?.Genres ?? [];
    }

    public Task<TmdbPagedResult<TmdbTitle>> GetTrendingAsync(MediaType mediaType, int page = 1, CancellationToken ct = default) =>
        GetTitlePageAsync($"trending/{MediaSegment(mediaType)}/week?page={page}", ct);

    public async Task<TmdbPagedResult<TmdbTitle>> DiscoverAsync(MediaType mediaType, int? genreId, int page = 1, int? providerId = null, CancellationToken ct = default)
    {
        string BuildUrl(int p)
        {
            var url = $"discover/{MediaSegment(mediaType)}?page={p}&sort_by=popularity.desc";
            if (genreId.HasValue)
            {
                url += $"&with_genres={genreId.Value}";
            }
            if (providerId.HasValue)
            {
                url += $"&with_watch_providers={providerId.Value}&watch_region=TR";
            }
            // Never surface pre-1993 titles in Discover/Swipe recommendations.
            url += mediaType == MediaType.Movie
                ? "&primary_release_date.gte=1993-01-01"
                : "&first_air_date.gte=1993-01-01";
            if (mediaType == MediaType.Show)
            {
                // TMDB's TV "popularity" ranks a lot of near-zero-vote local/daily
                // content (regional talk shows, news programs, etc.) surprisingly
                // high, which movies don't suffer from anywhere near as much. A
                // minimum vote count filters that noise out while still leaving a
                // large enough pool (thousands of shows) for real discovery.
                url += "&vote_count.gte=100";
            }
            return url;
        }

        // TMDB's discover endpoint returns internal-error 500s in bursts —
        // observed failing on several consecutive pages at a time, not just
        // a single flaky one. Skip ahead through a run of bad pages instead
        // of surfacing a crash to the client; if every attempt in the run
        // fails too, degrade to an empty page rather than letting the
        // exception propagate as a 500 of our own.
        for (var attempt = 0; attempt < 8; attempt++)
        {
            try
            {
                return await GetTitlePageAsync(BuildUrl(page + attempt), ct);
            }
            catch (HttpRequestException)
            {
            }
        }
        return new TmdbPagedResult<TmdbTitle>();
    }

    public async Task<TmdbTitle?> GetDetailsAsync(MediaType mediaType, int tmdbId, CancellationToken ct = default)
    {
        var url = $"{MediaSegment(mediaType)}/{tmdbId}";
        var result = await httpClient.GetFromJsonAsync<TmdbTitle>(url, ct);
        if (result is not null)
        {
            await FillMissingTranslationsAsync([result], async () =>
                await httpClient.GetFromJsonAsync<TmdbTitle>(WithFallbackLanguage(url), ct) is { } f ? [f] : null, ct);
        }
        return result;
    }

    public async Task<List<TmdbVideo>> GetVideosAsync(MediaType mediaType, int tmdbId, CancellationToken ct = default)
    {
        // With a language set, TMDB only returns videos in that language —
        // which would hide most trailers. Ask for Turkish + English +
        // language-less videos, and put Turkish ones first.
        var result = await httpClient.GetFromJsonAsync<TmdbVideoResults>(
            $"{MediaSegment(mediaType)}/{tmdbId}/videos?include_video_language=tr,en,null", ct);
        return (result?.Results ?? [])
            .OrderBy(v => v.Language == "tr" ? 0 : 1)
            .ToList();
    }

    public Task<TmdbPagedResult<TmdbTitle>> SearchTitlesAsync(MediaType mediaType, string query, int page = 1, CancellationToken ct = default) =>
        GetTitlePageAsync($"search/{MediaSegment(mediaType)}?query={Uri.EscapeDataString(query)}&page={page}", ct);

    public async Task<TmdbPagedResult<TmdbPerson>> SearchPeopleAsync(string query, int page = 1, CancellationToken ct = default)
    {
        var url = $"search/person?query={Uri.EscapeDataString(query)}&page={page}";
        var result = await httpClient.GetFromJsonAsync<TmdbPagedResult<TmdbPerson>>(url, ct);
        return result ?? new TmdbPagedResult<TmdbPerson>();
    }

    public async Task<List<TmdbCastMember>> GetCreditsAsync(MediaType mediaType, int tmdbId, CancellationToken ct = default)
    {
        var result = await httpClient.GetFromJsonAsync<TmdbCreditsResponse>(
            $"{MediaSegment(mediaType)}/{tmdbId}/credits", ct);
        return result?.Cast ?? [];
    }

    public async Task<TmdbPagedResult<TmdbPerson>> GetPopularPeopleAsync(int page = 1, CancellationToken ct = default)
    {
        var result = await httpClient.GetFromJsonAsync<TmdbPagedResult<TmdbPerson>>($"person/popular?page={page}", ct);
        return result ?? new TmdbPagedResult<TmdbPerson>();
    }

    public async Task<List<TmdbCombinedCredit>> GetPersonCombinedCreditsAsync(int personId, CancellationToken ct = default)
    {
        var url = $"person/{personId}/combined_credits";
        var cast = (await httpClient.GetFromJsonAsync<TmdbCombinedCreditsResponse>(url, ct))?.Cast ?? [];
        await FillMissingTranslationsAsync(cast, async () =>
            (await httpClient.GetFromJsonAsync<TmdbCombinedCreditsResponse>(WithFallbackLanguage(url), ct))?.Cast, ct);
        return cast;
    }
}
