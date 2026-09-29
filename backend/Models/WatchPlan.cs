namespace Neizlesem.Api.Models;

/// <summary>
/// "Planla": watch a title at a set time — alone, with a group, or with
/// chosen friends. The creator is an attendee too (always Going).
/// </summary>
public class WatchPlan
{
    public int Id { get; set; }
    public int CreatorId { get; set; }
    public AppUser? Creator { get; set; }
    public int TitleId { get; set; }
    public Title? Title { get; set; }

    /// <summary>Set for a group film night; null for solo/friends plans.</summary>
    public int? GroupId { get; set; }
    public Group? Group { get; set; }

    public DateTime ScheduledAt { get; set; }
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public List<PlanAttendee> Attendees { get; set; } = new();
}

public enum PlanResponse
{
    Pending,
    Going,    // Katılıyorum
    Maybe,    // Belki
    NotGoing, // Gelemem
}

/// <summary>After the plan's time: did this attendee actually watch it ("Nasıldı?").</summary>
public enum PlanOutcome
{
    Watched, // İzledik ✓
    Skipped, // İzlemedik
}

public class PlanAttendee
{
    public int Id { get; set; }
    public int PlanId { get; set; }
    public WatchPlan? Plan { get; set; }
    public int UserId { get; set; }
    public AppUser? User { get; set; }
    public PlanResponse Response { get; set; } = PlanResponse.Pending;
    public DateTime? RespondedAt { get; set; }
    public PlanOutcome? Outcome { get; set; }
}
