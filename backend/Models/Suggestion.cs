namespace Neizlesem.Api.Models;

/// <summary>"Bunu izleyelim mi?" — a title one user sends to one or more
/// friends/group members, who each independently accept or pass.</summary>
public class Suggestion
{
    public int Id { get; set; }
    public int SenderId { get; set; }
    public AppUser? Sender { get; set; }
    public int TitleId { get; set; }
    public Title? Title { get; set; }
    public string? Note { get; set; }
    public int? GroupId { get; set; }
    public Group? Group { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public List<SuggestionRecipient> Recipients { get; set; } = new();
}
