namespace Neizlesem.Api.Services.Tmdb;

public class TmdbOptions
{
    public const string SectionName = "Tmdb";

    public string BaseUrl { get; set; } = "https://api.themoviedb.org/3/";
    public string ReadAccessToken { get; set; } = string.Empty;
    public string ApiKey { get; set; } = string.Empty;
    public string ImageBaseUrl { get; set; } = "https://image.tmdb.org/t/p/";

    /// <summary>Titles, overviews and genre names are requested in this language.</summary>
    public string Language { get; set; } = "tr-TR";

    /// <summary>Used for overviews TMDB has no translation for in <see cref="Language"/>.</summary>
    public string FallbackLanguage { get; set; } = "en-US";
}
