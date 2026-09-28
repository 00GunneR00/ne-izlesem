namespace Neizlesem.Api.Models;

public class Comment
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public AppUser? User { get; set; }
    public int TitleId { get; set; }
    public Title? Title { get; set; }
    public string Text { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>Hidden behind a tap-to-reveal until the reader opts in.</summary>
    public bool IsSpoiler { get; set; }
    public DateTime? EditedAt { get; set; }
}
