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

    [HttpGet("{id:int}/watchlist")]
    public async Task<ActionResult<List<GroupWatchlistItemDto>>> GetWatchlist(int id, [FromQuery] int userId, CancellationToken ct)
    {
        var isMember = await db.GroupMembers.AnyAsync(m => m.GroupId == id && m.UserId == userId, ct);
        if (!isMember)
        {
            return NotFound();
        }

        var rows = await db.SuggestionRecipients
            .Include(r => r.Recipient)
            .Include(r => r.Suggestion)!.ThenInclude(s => s!.Title)
            .Where(r => r.Suggestion!.GroupId == id && r.Status == SuggestionStatus.Accepted)
            .OrderByDescending(r => r.RespondedAt)
            .ToListAsync(ct);

        return rows.Select(r => new GroupWatchlistItemDto(
            mapper.ToDto(r.Suggestion!.Title!),
            r.Recipient!.DisplayName,
            r.RespondedAt!.Value)).ToList();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, [FromQuery] int userId, CancellationToken ct)
    {
        var group = await db.Groups.FirstOrDefaultAsync(g => g.Id == id && g.OwnerId == userId, ct);
        if (group is null)
        {
            return NotFound();
        }

        db.Groups.Remove(group);
        await db.SaveChangesAsync(ct);
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
