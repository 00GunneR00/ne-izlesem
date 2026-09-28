using Neizlesem.Api.Models;

namespace Neizlesem.Api.Services;

/// <summary>
/// Onboarding only offers TMDB *movie* genres, and TMDB's TV genres use a
/// partly different id space. Maps preferred movie genres onto their TV
/// equivalents so taste applies to shows too.
/// </summary>
public static class GenreMap
{
    private static readonly Dictionary<int, int> MovieToTv = new()
    {
        [28] = 10759,    // Aksiyon            → Action & Adventure
        [12] = 10759,    // Macera             → Action & Adventure
        [16] = 16,       // Animasyon
        [35] = 35,       // Komedi
        [80] = 80,       // Suç
        [99] = 99,       // Belgesel
        [18] = 18,       // Dram
        [10751] = 10751, // Aile
        [14] = 10765,    // Fantastik          → Sci-Fi & Fantasy
        [878] = 10765,   // Bilim Kurgu        → Sci-Fi & Fantasy
        [9648] = 9648,   // Gizem
        [10752] = 10768, // Savaş              → War & Politics
        [37] = 37,       // Vahşi Batı
        // Korku, Romantik, Gerilim, Müzik, Tarih, TV Filmi have no TV genre.
    };

    public static List<int> For(MediaType mediaType, IEnumerable<int> preferredMovieGenreIds) =>
        mediaType == MediaType.Movie
            ? preferredMovieGenreIds.Distinct().ToList()
            : preferredMovieGenreIds
                .Where(MovieToTv.ContainsKey)
                .Select(id => MovieToTv[id])
                .Distinct()
                .ToList();
}
