using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Controllers;

[ApiController]
[Route("api/groups")]
public class GroupsController(AppDbContext db, TitleMapper mapper) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<GroupDto>> Create(CreateGroupRequest request, CancellationToken ct)
    {
        var name = request.Name.Trim();
        if (string.IsNullOrEmpty(name))
        {
            return BadRequest("Grup adı boş olamaz.");
        }

        var group = new Group { Name = name, OwnerId = request.OwnerId };
        db.Groups.Add(group);

        var memberIds = request.MemberUserIds.Append(request.OwnerId).Distinct().ToList();
        foreach (var userId in memberIds)
        {
            // Wire via the navigation (not group.Id, which doesn't exist yet) so
            // both inserts land in a single atomic SaveChanges call — if a member
            // id is invalid, the group insert rolls back too instead of being
            // left behind half-created.
            db.GroupMembers.Add(new GroupMember { Group = group, UserId = userId });
        }
        await db.SaveChangesAsync(ct);

        return await ToDto(group, ct);
    }

    [HttpGet]
    public async Task<ActionResult<List<GroupDto>>> GetForUser([FromQuery] int userId, CancellationToken ct)
    {
        var groupIds = await db.GroupMembers
            .Where(m => m.UserId == userId)
            .Select(m => m.GroupId)
            .ToListAsync(ct);

        var groups = await db.Groups.Where(g => groupIds.Contains(g.Id)).ToListAsync(ct);
        var result = new List<GroupDto>();
        foreach (var group in groups)
        {
            result.Add(await ToDto(group, ct));
        }
        return result;
    }

    /// <summary>
    /// "Grubun Önerileri": every title suggested to the group, one entry per
    /// title (even if suggested/accepted several times), with who suggested,
    /// accepted and passed. Only current members count toward support.
    /// </summary>
    [HttpGet("{id:int}/suggestions")]
    public async Task<ActionResult<List<GroupSuggestionDto>>> GetSuggestions(int id, [FromQuery] int userId, CancellationToken ct)
    {
        var members = await db.GroupMembers
            .Where(m => m.GroupId == id)
            .Select(m => m.UserId)
            .ToListAsync(ct);
        if (!members.Contains(userId))
        {
            return NotFound();
        }
        var memberSet = members.ToHashSet();

        var suggestions = await db.Suggestions
            .Include(s => s.Sender)
            .Include(s => s.Title)
            .Include(s => s.Recipients).ThenInclude(r => r.Recipient)
            .Where(s => s.GroupId == id)
            .ToListAsync(ct);
        var matchedTitleIds = (await db.GroupMatches
            .Where(m => m.GroupId == id)
            .Select(m => m.TitleId)
            .ToListAsync(ct)).ToHashSet();

        static List<string> Names(IEnumerable<AppUser> users) =>
            users.DistinctBy(u => u.Id).Select(u => u.DisplayName).ToList();

        return suggestions
            .GroupBy(s => s.TitleId)
            .Select(g =>
            {
                var senders = g.Select(s => s.Sender!).Where(u => memberSet.Contains(u.Id)).ToList();
                var responses = g.SelectMany(s => s.Recipients)
                    .Where(r => memberSet.Contains(r.RecipientId))
                    .ToList();
                var accepters = responses
                    .Where(r => r.Status == SuggestionStatus.Accepted)
                    .Select(r => r.Recipient!)
                    .ToList();
                // Someone who accepted any suggestion of it isn't "passed".
                var passers = responses
                    .Where(r => r.Status == SuggestionStatus.Passed)
                    .Select(r => r.Recipient!)
                    .Where(u => accepters.All(a => a.Id != u.Id) && senders.All(s => s.Id != u.Id))
                    .ToList();
                var support = senders.Select(u => u.Id).Concat(accepters.Select(u => u.Id)).ToHashSet();
                var lastActivity = g.Select(s => s.CreatedAt)
                    .Concat(responses.Where(r => r.RespondedAt.HasValue).Select(r => r.RespondedAt!.Value))
                    .Max();

                return new GroupSuggestionDto(
                    mapper.ToDto(g.First().Title!),
                    Names(senders),
                    g.OrderByDescending(s => s.CreatedAt).Select(s => s.Note).FirstOrDefault(n => n != null),
                    Names(accepters),
                    Names(passers),
                    support.Count,
                    members.Count,
                    matchedTitleIds.Contains(g.Key),
                    lastActivity);
            })
            .OrderByDescending(s => s.LastActivityAt)
            .ToList();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, [FromQuery] int userId, CancellationToken ct)
    {
        var group = await db.Groups.FirstOrDefaultAsync(g => g.Id == id && g.OwnerId == userId, ct);
        if (group is null)
        {
            return NotFound();
        }

        // The FK would only null out Suggestion.GroupId, turning the group's
        // pending suggestions into stray direct ones in members' inboxes —
        // remove them along with the group instead.
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        await db.SuggestionRecipients
            .Where(r => r.Suggestion!.GroupId == id)
            .ExecuteDeleteAsync(ct);
        await db.Suggestions
            .Where(s => s.GroupId == id)
            .ExecuteDeleteAsync(ct);
        db.Groups.Remove(group);
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return NoContent();
    }

    private async Task<GroupDto> ToDto(Group group, CancellationToken ct)
    {
        var members = await db.GroupMembers
            .Include(m => m.User)
            .Where(m => m.GroupId == group.Id)
            .Select(m => new UserSummaryDto(m.User!.Id, m.User.DisplayName, m.User.Username))
            .ToListAsync(ct);
        return new GroupDto(group.Id, group.Name, group.OwnerId, members);
    }
}
