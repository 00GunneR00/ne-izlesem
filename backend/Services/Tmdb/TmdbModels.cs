using System.Text.Json.Serialization;

namespace Neizlesem.Api.Services.Tmdb;

public class TmdbPagedResult<T>
{
    public int Page { get; set; }
    public List<T> Results { get; set; } = new();

    [JsonPropertyName("total_pages")]
    public int TotalPages { get; set; }

    [JsonPropertyName("total_results")]
    public int TotalResults { get; set; }
}

public class TmdbTitle
{
    public int Id { get; set; }

    // Movies use "title"/"release_date", shows use "name"/"first_air_date".
    public string? Title { get; set; }
    public string? Name { get; set; }

    public string? Overview { get; set; }

    [JsonPropertyName("poster_path")]
    public string? PosterPath { get; set; }

    [JsonPropertyName("backdrop_path")]
    public string? BackdropPath { get; set; }

    [JsonPropertyName("vote_average")]
    public double VoteAverage { get; set; }

    public double Popularity { get; set; }

    [JsonPropertyName("release_date")]
    public string? ReleaseDate { get; set; }

    [JsonPropertyName("first_air_date")]
    public string? FirstAirDate { get; set; }

    // List endpoints (search/discover/trending) return "genre_ids"; the
    // single-title details endpoint instead returns "genres" as full
    // {id,name} objects. Keep both and fall back to Genres below.
    [JsonPropertyName("genre_ids")]
    public List<int> GenreIds { get; set; } = new();

    [JsonPropertyName("genres")]
    public List<TmdbGenre> Genres { get; set; } = new();

    // TV details only.
    public List<TmdbSeason> Seasons { get; set; } = new();

    [JsonPropertyName("original_title")]
    public string? OriginalTitle { get; set; }

    [JsonPropertyName("original_name")]
    public string? OriginalName { get; set; }

    [JsonPropertyName("original_language")]
    public string? OriginalLanguage { get; set; }

    public string DisplayName => Title ?? Name ?? string.Empty;

    /// <summary>
    /// TMDB answers with the original-language title when it has no
    /// translation for the requested language — for a non-Turkish original,
    /// an unchanged title means "no Turkish title". English originals are
    /// skipped: their original title already is the English one.
    /// </summary>
    public bool HasUntranslatedName =>
        OriginalLanguage is not ("tr" or "en") && DisplayName == (OriginalTitle ?? OriginalName);

    public void SetDisplayName(string value)
    {
        if (Title is not null)
        {
            Title = value;
        }
        else
        {
            Name = value;
        }
    }
    public string? DisplayDate => ReleaseDate ?? FirstAirDate;
    public List<int> ResolvedGenreIds => GenreIds.Count > 0 ? GenreIds : Genres.Select(g => g.Id).ToList();
}

public class TmdbGenre
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class TmdbGenreList
{
    public List<TmdbGenre> Genres { get; set; } = new();
}

public class TmdbVideo
{
    public string Id { get; set; } = string.Empty;
    public string Key { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Site { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public bool Official { get; set; }

    [JsonPropertyName("iso_639_1")]
    public string? Language { get; set; }
}

public class TmdbVideoResults
{
    public List<TmdbVideo> Results { get; set; } = new();
}

public class TmdbPerson
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("profile_path")]
    public string? ProfilePath { get; set; }

    [JsonPropertyName("known_for_department")]
    public string? KnownForDepartment { get; set; }
}

// person/{id}/combined_credits' "cast" entries are shaped like TmdbTitle plus a
// per-item "media_type" ("movie"/"tv") since one person can have both.
public class TmdbCombinedCredit : TmdbTitle
{
    [JsonPropertyName("media_type")]
    public string MediaType { get; set; } = string.Empty;

    // TV only — a low count usually means a one-off guest cameo rather than
    // an actual role.
    [JsonPropertyName("episode_count")]
    public int EpisodeCount { get; set; }
}

public class TmdbCombinedCreditsResponse
{
    public List<TmdbCombinedCredit> Cast { get; set; } = new();
}

public class TmdbCastMember
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("profile_path")]
    public string? ProfilePath { get; set; }

    public string? Character { get; set; }
    public int Order { get; set; }
}

public class TmdbCreditsResponse
{
    public List<TmdbCastMember> Cast { get; set; } = new();
}

public class TmdbSeason
{
    [JsonPropertyName("season_number")]
    public int SeasonNumber { get; set; }

    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("episode_count")]
    public int EpisodeCount { get; set; }
}
