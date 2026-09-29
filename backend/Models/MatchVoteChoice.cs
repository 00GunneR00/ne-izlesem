namespace Neizlesem.Api.Models;

/// <summary>A member's stance on a group match. Yes = 0 so pre-existing (thumbs-up) votes read as "İzleyelim".</summary>
public enum MatchVoteChoice
{
    Yes = 0,   // İzleyelim  (+1)
    Maybe = 1, // Kararsız   (0)
    No = 2,    // İzlemeyelim (−1)
}
