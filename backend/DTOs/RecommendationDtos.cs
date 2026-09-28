namespace Neizlesem.Api.DTOs;

/// <summary><see cref="BasedOn"/> names the seed titles; empty when it fell back to preferred genres.</summary>
public record RecommendationsDto(List<TitleDto> Items, List<string> BasedOn);
