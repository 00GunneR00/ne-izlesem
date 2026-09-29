using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Controllers;

[ApiController]
[Route("api/suggestions")]
public class SuggestionsController(
    AppDbContext db, TitleCacheService titleCache, TitleMapper mapper, GroupSuggestionMatcher matcher) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Send(SendSuggestionRequest request, CancellationToken ct)
    {
        var title = await titleCache.GetOrCacheAsync(request.TmdbId, request.MediaType, ct);
        if (title is null)
        {
            return NotFound("Title not found on TMDB.");
        }

        var recipientIds = new HashSet<int>(request.RecipientUserIds ?? []);
        if (request.GroupId.HasValue)
        {
            var groupMemberIds = await db.GroupMembers
                .Where(m => m.GroupId == request.GroupId.Value)
                .Select(m => m.UserId)
                .ToListAsync(ct);
            recipientIds.UnionWith(groupMemberIds);
        }
        recipientIds.Remove(request.SenderId);

        if (recipientIds.Count == 0)
        {
            return BadRequest("En az bir alıcı seçmelisin.");
        }

        var suggestion = new Suggestion
        {
            SenderId = request.SenderId,
            TitleId = title.Id,
            Note = string.IsNullOrWhiteSpace(request.Note) ? null : request.Note.Trim(),
            GroupId = request.GroupId,
        };
        db.Suggestions.Add(suggestion);
        await db.SaveChangesAsync(ct);

        foreach (var recipientId in recipientIds)
        {
            db.SuggestionRecipients.Add(new SuggestionRecipient { SuggestionId = suggestion.Id, RecipientId = recipientId });
        }
        await db.SaveChangesAsync(ct);

        return NoContent();
    }

    [HttpGet("inbox")]
    public async Task<ActionResult<List<SuggestionInboxItemDto>>> GetInbox([FromQuery] int userId, CancellationToken ct)
    {
        var rows = await db.SuggestionRecipients
            .Include(r => r.Suggestion)!.ThenInclude(s => s!.Sender)
            .Include(r => r.Suggestion)!.ThenInclude(s => s!.Title)
            .Include(r => r.Suggestion)!.ThenInclude(s => s!.Group)
            .Where(r => r.RecipientId == userId && r.Status == SuggestionStatus.Pending)
            .OrderByDescending(r => r.Suggestion!.CreatedAt)
            .ToListAsync(ct);

        return rows.Select(r => new SuggestionInboxItemDto(
            r.Id,
            r.Suggestion!.SenderId,
            r.Suggestion.Sender!.DisplayName,
            mapper.ToDto(r.Suggestion.Title!),
            r.Suggestion.Note,
            r.Suggestion.Group?.Name,
            r.Suggestion.CreatedAt)).ToList();
    }

    [HttpPost("{recipientRowId:int}/accept")]
    public async Task<ActionResult<SuggestionAcceptResultDto>> Accept(int recipientRowId, [FromQuery] int userId, CancellationToken ct)
    {
        var row = await db.SuggestionRecipients
            .Include(r => r.Suggestion)
            .FirstOrDefaultAsync(r => r.Id == recipientRowId && r.RecipientId == userId, ct);
        if (row is null)
        {
            return NotFound();
        }

        row.Status = SuggestionStatus.Accepted;
        row.RespondedAt = DateTime.UtcNow;

        // A group suggestion's accepted state is already visible on the
        // group's watchlist screen, so it doesn't also need a personal
        // library entry. A direct (non-group) suggestion has no such view,
        // so it still lands in the recipient's "İzleyeceğim" list.
        if (row.Suggestion!.GroupId is null)
        {
            var existingEntry = await db.LibraryEntries
                .FirstOrDefaultAsync(e => e.UserId == userId && e.TitleId == row.Suggestion.TitleId, ct);
            if (existingEntry is null)
            {
                db.LibraryEntries.Add(new LibraryEntry
                {
                    UserId = userId,
                    TitleId = row.Suggestion.TitleId,
                    Status = LibraryStatus.ToWatch,
                });
            }
        }

        await db.SaveChangesAsync(ct);

        // Everyone in the group now on board → it's a group match.
        var matched = row.Suggestion.GroupId is { } groupId
                      && await matcher.TryMatchAsync(groupId, row.Suggestion.TitleId, ct);
        return new SuggestionAcceptResultDto(matched);
    }

    [HttpPost("{recipientRowId:int}/pass")]
    public async Task<IActionResult> Pass(int recipientRowId, [FromQuery] int userId, CancellationToken ct)
    {
        var row = await db.SuggestionRecipients.FirstOrDefaultAsync(r => r.Id == recipientRowId && r.RecipientId == userId, ct);
        if (row is null)
        {
            return NotFound();
        }

        row.Status = SuggestionStatus.Passed;
        row.RespondedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpGet("notifications")]
    public async Task<ActionResult<List<SuggestionNotificationDto>>> GetNotifications([FromQuery] int userId, CancellationToken ct)
    {
        var rows = await db.SuggestionRecipients
            .Include(r => r.Recipient)
            .Include(r => r.Suggestion)!.ThenInclude(s => s!.Title)
            .Where(r => r.Suggestion!.SenderId == userId && r.Status != SuggestionStatus.Pending)
            .OrderByDescending(r => r.RespondedAt)
            .Take(30)
            .ToListAsync(ct);

        return rows.Select(r => new SuggestionNotificationDto(
            r.Id,
            r.Recipient!.DisplayName,
            mapper.ToDto(r.Suggestion!.Title!),
            r.Status,
            r.RespondedAt!.Value,
            r.SeenBySender)).ToList();
    }

    [HttpPost("notifications/mark-seen")]
    public async Task<IActionResult> MarkNotificationsSeen([FromQuery] int userId, CancellationToken ct)
    {
        var rows = await db.SuggestionRecipients
            .Include(r => r.Suggestion)
            .Where(r => r.Suggestion!.SenderId == userId && r.Status != SuggestionStatus.Pending && !r.SeenBySender)
            .ToListAsync(ct);
        foreach (var row in rows)
        {
            row.SeenBySender = true;
        }
        await db.SaveChangesAsync(ct);
        return NoContent();
    }
}
