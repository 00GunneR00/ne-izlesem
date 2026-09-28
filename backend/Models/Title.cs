namespace Neizlesem.Api.Models;

/// <summary>Cached snapshot of a TMDB movie or show, keyed by TMDB's own id + media type.</summary>
public class Title
{
    public int Id { get; set; }
    public int TmdbId { get; set; }
    public MediaType MediaType { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Overview { get; set; }
    public string? PosterPath { get; set; }
    public string? BackdropPath { get; set; }
    public double VoteAverage { get; set; }
    public DateOnly? ReleaseDate { get; set; }
    public List<int> GenreIds { get; set; } = new();
    public DateTime CachedAt { get; set; } = DateTime.UtcNow;

    /// <summary>TMDB language the name/overview were fetched in; null for rows cached before localization.</summary>
    public string? Language { get; set; }
}
