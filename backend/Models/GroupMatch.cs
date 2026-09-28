namespace Neizlesem.Api.Models;

/// <summary>Every member of the group swiped right on this title — "Eşleşme!".</summary>
public class GroupMatch
{
    public int Id { get; set; }
    public int GroupId { get; set; }
    public Group? Group { get; set; }
    public int TitleId { get; set; }
    public Title? Title { get; set; }
    public DateTime MatchedAt { get; set; } = DateTime.UtcNow;
}
