using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;

namespace Neizlesem.Api.Services.Tmdb;

public class TitleMapper(TmdbOptions options)
{
    private string? ImageUrl(string? path, string size) =>
        string.IsNullOrEmpty(path) ? null : $"{options.ImageBaseUrl}{size}{path}";

    public TitleDto ToDto(TmdbTitle t, MediaType mediaType) => new(
        t.Id,
        mediaType,
        t.DisplayName,
        t.Overview,
        ImageUrl(t.PosterPath, "w500"),
        ImageUrl(t.BackdropPath, "w780"),
        t.VoteAverage,
        t.DisplayDate,
        t.ResolvedGenreIds);

    public TitleDto ToDto(Title t) => new(
        t.TmdbId,
        t.MediaType,
        t.Name,
        t.Overview,
        ImageUrl(t.PosterPath, "w500"),
        ImageUrl(t.BackdropPath, "w780"),
        t.VoteAverage,
        t.ReleaseDate?.ToString("yyyy-MM-dd"),
        t.GenreIds);

    public PersonDto ToDto(TmdbPerson p) => new(
        p.Id,
        p.Name,
        ImageUrl(p.ProfilePath, "w500"),
        p.KnownForDepartment);

    public CastMemberDto ToDto(TmdbCastMember c) => new(
        c.Id,
        c.Name,
        ImageUrl(c.ProfilePath, "w500"),
        c.Character);

    public Title ToEntity(TmdbTitle t, MediaType mediaType)
    {
        var entity = new Title { TmdbId = t.Id, MediaType = mediaType };
        UpdateEntity(entity, t);
        return entity;
    }

    public void UpdateEntity(Title entity, TmdbTitle t)
    {
        entity.Name = t.DisplayName;
        entity.Overview = t.Overview;
        entity.PosterPath = t.PosterPath;
        entity.BackdropPath = t.BackdropPath;
        entity.VoteAverage = t.VoteAverage;
        entity.ReleaseDate = DateOnly.TryParse(t.DisplayDate, out var d) ? d : null;
        entity.GenreIds = t.ResolvedGenreIds;
        entity.CachedAt = DateTime.UtcNow;
        entity.Language = options.Language;
    }
}
