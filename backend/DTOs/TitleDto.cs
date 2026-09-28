using Neizlesem.Api.Models;

namespace Neizlesem.Api.DTOs;

public record TitleDto(
    int TmdbId,
    MediaType MediaType,
    string Name,
    string? Overview,
    string? PosterUrl,
    string? BackdropUrl,
    double VoteAverage,
    string? ReleaseDate,
    List<int> GenreIds);

public record GenreDto(int Id, string Name);

public record TrailerDto(string Key, string Name, string Site, string Type);

public record PersonDto(int TmdbId, string Name, string? ProfileUrl, string? KnownForDepartment);

public record CastMemberDto(int PersonId, string Name, string? ProfileUrl, string? Character);

public record SeasonDto(int SeasonNumber, string Name, int EpisodeCount);
