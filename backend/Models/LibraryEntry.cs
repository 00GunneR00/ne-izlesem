namespace Neizlesem.Api.Models;

public class LibraryEntry
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public AppUser? User { get; set; }
    public int TitleId { get; set; }
    public Title? Title { get; set; }
    public LibraryStatus Status { get; set; }
    public DateTime AddedAt { get; set; } = DateTime.UtcNow;

    /// <summary>Personal 1–5 star rating; only meaningful once watched.</summary>
    public int? Rating { get; set; }
    public DateTime? RatedAt { get; set; }
}
