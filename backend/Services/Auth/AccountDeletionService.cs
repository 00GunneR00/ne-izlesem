using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;

namespace Neizlesem.Api.Services.Auth;

/// <summary>
/// Permanently deletes an account and everything tied to it (Google Play's
/// account-deletion requirement). Groups the user owns are deleted with their
/// swipes, matches, votes and suggestions; plans they created are removed for
/// everyone; their votes/responses in other people's groups and plans go too.
/// Cached titles (shared) stay.
/// </summary>
public class AccountDeletionService(AppDbContext db)
{
    public async Task DeleteAsync(int userId, CancellationToken ct)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);

        // Groups the user owns: everything in them, then the groups.
        var ownedGroups = await db.Groups.Where(g => g.OwnerId == userId).Select(g => g.Id).ToListAsync(ct);
        await db.GroupMatchVotes.Where(v => ownedGroups.Contains(v.GroupMatch!.GroupId)).ExecuteDeleteAsync(ct);
        await db.GroupMatches.Where(m => ownedGroups.Contains(m.GroupId)).ExecuteDeleteAsync(ct);
        await db.GroupSwipes.Where(s => ownedGroups.Contains(s.GroupId)).ExecuteDeleteAsync(ct);
        await db.SuggestionRecipients.Where(r => r.Suggestion!.GroupId != null && ownedGroups.Contains(r.Suggestion.GroupId.Value)).ExecuteDeleteAsync(ct);
        await db.Suggestions.Where(s => s.GroupId != null && ownedGroups.Contains(s.GroupId.Value)).ExecuteDeleteAsync(ct);
        await db.GroupMembers.Where(m => ownedGroups.Contains(m.GroupId)).ExecuteDeleteAsync(ct);
        await db.WatchPlans.Where(p => p.GroupId != null && ownedGroups.Contains(p.GroupId.Value))
            .ExecuteUpdateAsync(s => s.SetProperty(p => p.GroupId, (int?)null), ct);
        await db.Groups.Where(g => g.OwnerId == userId).ExecuteDeleteAsync(ct);

        // The user's footprint in other people's groups.
        await db.GroupMatchVotes.Where(v => v.UserId == userId).ExecuteDeleteAsync(ct);
        await db.GroupSwipes.Where(s => s.UserId == userId).ExecuteDeleteAsync(ct);
        await db.GroupMembers.Where(m => m.UserId == userId).ExecuteDeleteAsync(ct);

        // Plans: ones they created (attendees go with them), then their RSVPs.
        await db.PlanAttendees.Where(a => a.Plan!.CreatorId == userId).ExecuteDeleteAsync(ct);
        await db.WatchPlans.Where(p => p.CreatorId == userId).ExecuteDeleteAsync(ct);
        await db.PlanAttendees.Where(a => a.UserId == userId).ExecuteDeleteAsync(ct);

        // Suggestions sent (with every recipient row) and received.
        await db.SuggestionRecipients.Where(r => r.Suggestion!.SenderId == userId || r.RecipientId == userId).ExecuteDeleteAsync(ct);
        await db.Suggestions.Where(s => s.SenderId == userId).ExecuteDeleteAsync(ct);

        // Personal data.
        await db.UserListItems.Where(i => i.List!.OwnerId == userId).ExecuteDeleteAsync(ct);
        await db.UserLists.Where(l => l.OwnerId == userId).ExecuteDeleteAsync(ct);
        await db.Comments.Where(c => c.UserId == userId).ExecuteDeleteAsync(ct);
        await db.TitleLikes.Where(l => l.UserId == userId).ExecuteDeleteAsync(ct);
        await db.SwipeInteractions.Where(s => s.UserId == userId).ExecuteDeleteAsync(ct);
        await db.LibraryEntries.Where(e => e.UserId == userId).ExecuteDeleteAsync(ct);
        await db.Friendships.Where(f => f.RequesterId == userId || f.AddresseeId == userId).ExecuteDeleteAsync(ct);

        await db.Users.Where(u => u.Id == userId).ExecuteDeleteAsync(ct);
        await tx.CommitAsync(ct);
    }
}
