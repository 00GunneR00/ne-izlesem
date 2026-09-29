namespace Neizlesem.Api.Models;

public class GroupMember
{
    public int Id { get; set; }
    public int GroupId { get; set; }
    public Group? Group { get; set; }
    public int UserId { get; set; }
    public AppUser? User { get; set; }
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

    /// <summary>Matches newer than this are unread notifications for this member.</summary>
    public DateTime? MatchesSeenAt { get; set; }

    /// <summary>
    /// "Temizle": match notifications up to this point (the read ones at the
    /// time) are hidden from this member's notifications page.
    /// </summary>
    public DateTime? MatchesClearedAt { get; set; }
}
