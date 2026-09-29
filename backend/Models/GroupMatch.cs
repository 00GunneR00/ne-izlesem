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
    public List<GroupMatchVote> Votes { get; set; } = new();
}

/// <summary>A member's vote to watch a matched title — ranks the group's matches.</summary>
public class GroupMatchVote
{
    public int Id { get; set; }
    public int GroupMatchId { get; set; }
    public GroupMatch? GroupMatch { get; set; }
    public int UserId { get; set; }
    public AppUser? User { get; set; }
    public DateTime VotedAt { get; set; } = DateTime.UtcNow;
}
