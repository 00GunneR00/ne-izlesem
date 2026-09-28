namespace Neizlesem.Api.DTOs;

/// <summary>A batch of swipe cards plus the TMDB page to ask for next.</summary>
public record SwipeDeckDto(List<TitleDto> Items, int NextPage);
