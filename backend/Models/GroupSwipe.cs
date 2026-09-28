namespace Neizlesem.Api.Models;

/// <summary>A member's like/pass on a title inside a group's shared "Birlikte Seç" deck.</summary>
public class GroupSwipe
{
    public int Id { get; set; }
    public int GroupId { get; set; }
    public Group? Group { get; set; }
    public int UserId { get; set; }
    public AppUser? User { get; set; }
    public int TitleId { get; set; }
    public Title? Title { get; set; }
    public SwipeDirection Direction { get; set; }
    public DateTime SwipedAt { get; set; } = DateTime.UtcNow;
}
