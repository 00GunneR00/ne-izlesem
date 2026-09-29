using Microsoft.EntityFrameworkCore;
using Npgsql;
using Neizlesem.Api.Data;
using Neizlesem.Api.Models;

namespace Neizlesem.Api.Services;

/// <summary>
/// "Grubun Önerileri": a title suggested to a group becomes a group match
/// once every current member supports it — having suggested it or accepted
/// a suggestion of it.
/// </summary>
public class GroupSuggestionMatcher(AppDbContext db)
{
    /// <summary>Member ids supporting <paramref name="titleId"/> in the group (suggesters + accepters).</summary>
    public async Task<HashSet<int>> GetSupportersAsync(int groupId, int titleId, CancellationToken ct)
    {
        var suggestions = db.Suggestions.Where(s => s.GroupId == groupId && s.TitleId == titleId);
        var senders = await suggestions.Select(s => s.SenderId).ToListAsync(ct);
        var accepters = await db.SuggestionRecipients
            .Where(r => suggestions.Select(s => s.Id).Contains(r.SuggestionId) && r.Status == SuggestionStatus.Accepted)
            .Select(r => r.RecipientId)
            .ToListAsync(ct);
        return senders.Concat(accepters).ToHashSet();
    }

    /// <summary>Creates the match if everyone now supports the title; true when this call created it.</summary>
    public async Task<bool> TryMatchAsync(int groupId, int titleId, CancellationToken ct)
    {
        var members = await db.GroupMembers
            .Where(m => m.GroupId == groupId)
            .Select(m => m.UserId)
            .ToListAsync(ct);
        // A one-person group would "match" on every suggestion — not a match.
        if (members.Count < 2)
        {
            return false;
        }

        var supporters = await GetSupportersAsync(groupId, titleId, ct);
        if (!members.All(supporters.Contains)
            || await db.GroupMatches.AnyAsync(m => m.GroupId == groupId && m.TitleId == titleId, ct))
        {
            return false;
        }

        var match = new GroupMatch { GroupId = groupId, TitleId = titleId };
        db.GroupMatches.Add(match);
        try
        {
            await db.SaveChangesAsync(ct);
            return true;
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            // Matched at the same moment through "Birlikte Seç" or another accept.
            db.Entry(match).State = EntityState.Detached;
            return false;
        }
    }
}
