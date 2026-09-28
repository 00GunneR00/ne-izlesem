namespace Neizlesem.Api.Models;

/// <summary>Like/pass signal from the swipe screen. Swiped titles are left out of later swipe decks.</summary>
public class SwipeInteraction
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public AppUser? User { get; set; }
    public int TitleId { get; set; }
    public Title? Title { get; set; }
    public SwipeDirection Direction { get; set; }
    public DateTime SwipedAt { get; set; } = DateTime.UtcNow;
}
