using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Controllers;

/// <summary>
/// Watch plans ("Planla"): solo, group film nights, or with chosen friends.
/// Invitees answer Katılıyorum / Belki / Gelemem; after the plan's time each
/// attendee says whether they watched it ("Nasıldı?").
/// </summary>
[ApiController]
[Route("api/plans")]
public class PlansController(AppDbContext db, TitleCacheService titleCache, TitleMapper mapper) : ControllerBase
{
    /// <summary>Past plans stay listed this long (for "Nasıldı?").</summary>
    private static readonly TimeSpan PastWindow = TimeSpan.FromDays(14);

    private const int MaxNoteLength = 200;

    [HttpPost]
    public async Task<ActionResult<PlanDto>> Create(CreatePlanRequest request, CancellationToken ct)
    {
        var now = DateTime.UtcNow;
        var scheduledAt = DateTime.SpecifyKind(request.ScheduledAt, DateTimeKind.Utc);
        if (scheduledAt < now.AddMinutes(-10) || scheduledAt > now.AddYears(1))
        {
            return BadRequest("Plan zamanı şimdiden sonra ve bir yıl içinde olmalı.");
        }
        if ((request.Note?.Trim().Length ?? 0) > MaxNoteLength)
        {
            return BadRequest($"Not en fazla {MaxNoteLength} karakter olabilir.");
        }
        if (!await db.Users.AnyAsync(u => u.Id == request.UserId, ct))
        {
            return NotFound("User not found.");
        }

        HashSet<int> invitees;
        if (request.GroupId is { } groupId)
        {
            var members = await db.GroupMembers
                .Where(m => m.GroupId == groupId)
                .Select(m => m.UserId)
                .ToListAsync(ct);
            if (!members.Contains(request.UserId))
            {
                return NotFound("Group not found.");
            }
            invitees = members.ToHashSet();
        }
        else
        {
            invitees = (request.FriendIds ?? []).ToHashSet();
            var friends = await FriendsController.GetFriendIdsAsync(db, request.UserId, ct);
            if (invitees.Any(id => !friends.Contains(id)))
            {
                return BadRequest("Sadece arkadaşlarını davet edebilirsin.");
            }
        }
        invitees.Remove(request.UserId);

        var title = await titleCache.GetOrCacheAsync(request.TmdbId, request.MediaType, ct);
        if (title is null)
        {
            return NotFound("Title not found on TMDB.");
        }

        var plan = new WatchPlan
        {
            CreatorId = request.UserId,
            TitleId = title.Id,
            GroupId = request.GroupId,
            ScheduledAt = scheduledAt,
            Note = string.IsNullOrWhiteSpace(request.Note) ? null : request.Note.Trim(),
        };
        plan.Attendees.Add(new PlanAttendee { UserId = request.UserId, Response = PlanResponse.Going, RespondedAt = now });
        foreach (var id in invitees)
        {
            plan.Attendees.Add(new PlanAttendee { UserId = id });
        }
        db.WatchPlans.Add(plan);
        await db.SaveChangesAsync(ct);

        return ToDto(await PlansQuery().FirstAsync(p => p.Id == plan.Id, ct), request.UserId);
    }

    /// <summary>
    /// The user's plans (created or invited): upcoming ones plus those from
    /// the last two weeks, soonest first. The client derives "Sıradaki Plan",
    /// "Nasıldı?" and pending invites from this.
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<PlanDto>>> GetForUser([FromQuery] int userId, CancellationToken ct)
    {
        var since = DateTime.UtcNow - PastWindow;
        var plans = await PlansQuery()
            .Where(p => p.ScheduledAt >= since && p.Attendees.Any(a => a.UserId == userId))
            .OrderBy(p => p.ScheduledAt)
            .ToListAsync(ct);
        return plans.Select(p => ToDto(p, userId)).ToList();
    }

    /// <summary>Katılıyorum / Belki / Gelemem. The creator is always Going.</summary>
    [HttpPost("{id:int}/respond")]
    public async Task<ActionResult<PlanDto>> Respond(
        int id, [FromQuery] int userId, [FromQuery] PlanResponse response, CancellationToken ct)
    {
        if (response == PlanResponse.Pending)
        {
            return BadRequest("Geçersiz yanıt.");
        }
        var attendee = await db.PlanAttendees
            .Include(a => a.Plan)
            .FirstOrDefaultAsync(a => a.PlanId == id && a.UserId == userId, ct);
        if (attendee is null)
        {
            return NotFound();
        }
        if (attendee.Plan!.CreatorId == userId)
        {
            return BadRequest("Planı oluşturan zaten katılıyor.");
        }

        attendee.Response = response;
        attendee.RespondedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return ToDto(await PlansQuery().FirstAsync(p => p.Id == id, ct), userId);
    }

    /// <summary>
    /// "Nasıldı?" — after the plan's time: Watched adds the title to the
    /// user's library (films as İzledim, shows as İzliyorum unless already
    /// watched); Skipped just dismisses the prompt.
    /// </summary>
    [HttpPost("{id:int}/outcome")]
    public async Task<ActionResult<PlanDto>> SetOutcome(
        int id, [FromQuery] int userId, [FromQuery] PlanOutcome outcome, CancellationToken ct)
    {
        var attendee = await db.PlanAttendees
            .Include(a => a.Plan)!.ThenInclude(p => p!.Title)
            .FirstOrDefaultAsync(a => a.PlanId == id && a.UserId == userId, ct);
        if (attendee is null)
        {
            return NotFound();
        }
        if (attendee.Plan!.ScheduledAt > DateTime.UtcNow)
        {
            return BadRequest("Plan zamanı henüz gelmedi.");
        }

        attendee.Outcome = outcome;
        if (outcome == PlanOutcome.Watched)
        {
            var title = attendee.Plan.Title!;
            var target = title.MediaType == MediaType.Movie ? LibraryStatus.Watched : LibraryStatus.Watching;
            var entry = await db.LibraryEntries
                .FirstOrDefaultAsync(e => e.UserId == userId && e.TitleId == title.Id, ct);
            if (entry is null)
            {
                db.LibraryEntries.Add(new LibraryEntry { UserId = userId, TitleId = title.Id, Status = target });
            }
            else if (entry.Status != LibraryStatus.Watched)
            {
                entry.Status = target;
            }
        }
        await db.SaveChangesAsync(ct);
        return ToDto(await PlansQuery().FirstAsync(p => p.Id == id, ct), userId);
    }

    /// <summary>Only the creator can cancel a plan.</summary>
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Cancel(int id, [FromQuery] int userId, CancellationToken ct)
    {
        var deleted = await db.WatchPlans
            .Where(p => p.Id == id && p.CreatorId == userId)
            .ExecuteDeleteAsync(ct);
        return deleted == 0 ? NotFound() : NoContent();
    }

    private IQueryable<WatchPlan> PlansQuery() => db.WatchPlans
        .Include(p => p.Title)
        .Include(p => p.Creator)
        .Include(p => p.Group)
        .Include(p => p.Attendees).ThenInclude(a => a.User);

    private PlanDto ToDto(WatchPlan p, int userId)
    {
        var mine = p.Attendees.FirstOrDefault(a => a.UserId == userId);
        return new PlanDto(
            p.Id,
            mapper.ToDto(p.Title!),
            DateTime.SpecifyKind(p.ScheduledAt, DateTimeKind.Utc),
            p.Note,
            p.CreatorId,
            p.Creator!.DisplayName,
            p.GroupId,
            p.Group?.Name,
            p.Attendees
                .OrderBy(a => a.UserId == p.CreatorId ? 0 : 1)
                .ThenBy(a => a.User!.DisplayName)
                .Select(a => new PlanAttendeeDto(a.UserId, a.User!.DisplayName, a.Response, a.Outcome))
                .ToList(),
            mine?.Response ?? PlanResponse.Pending,
            mine?.Outcome);
    }
}
