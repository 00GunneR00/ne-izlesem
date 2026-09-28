namespace Neizlesem.Api.Models;

/// <summary>A user's persistent "like" on a title, independent of watch status. Shown to friends.</summary>
public class TitleLike
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public AppUser? User { get; set; }
    public int TitleId { get; set; }
    public Title? Title { get; set; }
    public DateTime LikedAt { get; set; } = DateTime.UtcNow;
}
