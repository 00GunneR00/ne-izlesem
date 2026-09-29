using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Controllers;

/// <summary>
/// "Birlikte Seç": group members swipe a shared deck; when every member
/// likes the same title it becomes a match ("Eşleşme! 🎉").
/// </summary>
[ApiController]
[Route("api/groups")]
public class GroupMatchesController(
    AppDbContext db,
    TitleCacheService titleCache,
    SwipeDeckService deck,
    TitleMapper mapper) : ControllerBase
{
    private Task<bool> IsMemberAsync(int groupId, int userId, CancellationToken ct) =>
        db.GroupMembers.AnyAsync(m => m.GroupId == groupId && m.UserId == userId, ct);

    /// <summary>
    /// Cards for this member. Titles other members already liked come first
    /// (that's what turns into matches); the rest is a deterministic TMDB
    /// list in the members' combined genres, so everyone sees the same
    /// titles in the same order.
    /// </summary>
    [HttpGet("{id:int}/deck")]
    public async Task<ActionResult<SwipeDeckDto>> GetDeck(
        int id, [FromQuery] int userId, [FromQuery] MediaType mediaType, [FromQuery] int page = 1, CancellationToken ct = default)
    {
        if (!await IsMemberAsync(id, userId, ct))
        {
            return NotFound();
        }

        var mine = (await db.GroupSwipes
            .Where(s => s.GroupId == id && s.UserId == userId && s.Title!.MediaType == mediaType)
            .Select(s => s.Title!.TmdbId)
            .ToListAsync(ct)).ToHashSet();
        var matched = await db.GroupMatches
            .Where(m => m.GroupId == id && m.Title!.MediaType == mediaType)
            .Select(m => m.Title!.TmdbId)
            .ToListAsync(ct);
        var excluded = mine.Concat(matched).ToHashSet();

        var likedByOthers = page == 1
            ? await db.GroupSwipes
                .Where(s => s.GroupId == id && s.UserId != userId && s.Direction == SwipeDirection.Like
                            && s.Title!.MediaType == mediaType)
                .Select(s => s.Title!)
                .Distinct()
                .ToListAsync(ct)
            : [];
        var priority = likedByOthers
            .Where(t => excluded.Add(t.TmdbId))
            .Select(mapper.ToDto)
            .ToList();

        var genres = await db.GroupMembers
            .Where(m => m.GroupId == id)
            .Select(m => m.User!.PreferredGenreIds)
            .ToListAsync(ct);
        var rest = await deck.BuildAsync(mediaType, genres.SelectMany(g => g), excluded, page, ct);

        return new SwipeDeckDto([.. priority, .. rest.Items], rest.NextPage);
    }

    [HttpPost("{id:int}/swipes")]
    public async Task<ActionResult<GroupSwipeResultDto>> Swipe(int id, GroupSwipeRequest request, CancellationToken ct)
    {
        if (!await IsMemberAsync(id, request.UserId, ct))
        {
            return NotFound();
        }

        var title = await titleCache.GetOrCacheAsync(request.TmdbId, request.MediaType, ct);
        if (title is null)
        {
            return NotFound("Title not found on TMDB.");
        }

        var swipe = await db.GroupSwipes.FirstOrDefaultAsync(
            s => s.GroupId == id && s.UserId == request.UserId && s.TitleId == title.Id, ct);
        if (swipe is null)
        {
            db.GroupSwipes.Add(new GroupSwipe
            {
                GroupId = id,
                UserId = request.UserId,
                TitleId = title.Id,
                Direction = request.Direction,
            });
        }
        else
        {
            swipe.Direction = request.Direction;
            swipe.SwipedAt = DateTime.UtcNow;
        }
        await db.SaveChangesAsync(ct);

        if (request.Direction != SwipeDirection.Like)
        {
            return new GroupSwipeResultDto(false, null);
        }

        var memberCount = await db.GroupMembers.CountAsync(m => m.GroupId == id, ct);
        var likeCount = await db.GroupSwipes.CountAsync(
            s => s.GroupId == id && s.TitleId == title.Id && s.Direction == SwipeDirection.Like, ct);
        // A one-person group would "match" on every like — not a match.
        if (memberCount < 2 || likeCount < memberCount)
        {
            return new GroupSwipeResultDto(false, null);
        }

        if (await db.GroupMatches.AnyAsync(m => m.GroupId == id && m.TitleId == title.Id, ct))
        {
            return new GroupSwipeResultDto(false, null);
        }

        var match = new GroupMatch { GroupId = id, TitleId = title.Id };
        db.GroupMatches.Add(match);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            // The last two members liked it at the same moment and the other
            // request recorded the match first — it's still a match.
            db.Entry(match).State = EntityState.Detached;
        }
        return new GroupSwipeResultDto(true, mapper.ToDto(title));
    }

    [HttpGet("{id:int}/matches")]
    public async Task<ActionResult<List<GroupMatchDto>>> GetMatches(int id, [FromQuery] int userId, CancellationToken ct)
    {
        if (!await IsMemberAsync(id, userId, ct))
        {
            return NotFound();
        }

        var matches = await db.GroupMatches
            .Include(m => m.Title)
            .Include(m => m.Votes).ThenInclude(v => v.User)
            .Where(m => m.GroupId == id)
            .ToListAsync(ct);
        // Highest score first ("Sıradaki film"); ties → more İzleyelim, then newer.
        return matches
            .OrderByDescending(Score)
            .ThenByDescending(m => m.Votes.Count(v => v.Choice == MatchVoteChoice.Yes))
            .ThenByDescending(m => m.MatchedAt)
            .Select(ToMatchDto(userId))
            .ToList();
    }

    /// <summary>İzleyelim +1, Kararsız 0, İzlemeyelim −1.</summary>
    private static int Score(GroupMatch m) =>
        m.Votes.Count(v => v.Choice == MatchVoteChoice.Yes) - m.Votes.Count(v => v.Choice == MatchVoteChoice.No);

    /// <summary>
    /// Sets the member's vote on a match to <paramref name="choice"/>
    /// (İzleyelim / Kararsız / İzlemeyelim); voting the same choice again
    /// clears it. Returns the match's updated vote state.
    /// </summary>
    [HttpPost("{id:int}/matches/{matchId:int}/vote")]
    public async Task<ActionResult<GroupMatchDto>> Vote(
        int id, int matchId, [FromQuery] int userId, [FromQuery] MatchVoteChoice choice, CancellationToken ct)
    {
        if (!await IsMemberAsync(id, userId, ct)
            || !await db.GroupMatches.AnyAsync(m => m.Id == matchId && m.GroupId == id, ct))
        {
            return NotFound();
        }

        var existing = await db.GroupMatchVotes
            .FirstOrDefaultAsync(v => v.GroupMatchId == matchId && v.UserId == userId, ct);
        if (existing is null)
        {
            db.GroupMatchVotes.Add(new GroupMatchVote { GroupMatchId = matchId, UserId = userId, Choice = choice });
        }
        else if (existing.Choice == choice)
        {
            db.GroupMatchVotes.Remove(existing);
        }
        else
        {
            existing.Choice = choice;
            existing.VotedAt = DateTime.UtcNow;
        }
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            // A double tap raced itself and the other request already
            // recorded a vote; the returned state below reflects it.
        }

        var match = await db.GroupMatches
            .Include(m => m.Title)
            .Include(m => m.Votes).ThenInclude(v => v.User)
            .FirstAsync(m => m.Id == matchId, ct);
        return ToMatchDto(userId)(match);
    }

    private Func<GroupMatch, GroupMatchDto> ToMatchDto(int userId) => m =>
    {
        List<string> Names(MatchVoteChoice c) => m.Votes
            .Where(v => v.Choice == c)
            .OrderBy(v => v.VotedAt)
            .Select(v => v.User!.DisplayName)
            .ToList();
        return new GroupMatchDto(
            m.Id,
            mapper.ToDto(m.Title!),
            m.MatchedAt,
            Score(m),
            Names(MatchVoteChoice.Yes),
            Names(MatchVoteChoice.Maybe),
            Names(MatchVoteChoice.No),
            m.Votes.FirstOrDefault(v => v.UserId == userId)?.Choice);
    };

    /// <summary>Recent matches across all of the user's groups, for the notifications page.</summary>
    [HttpGet("matches/notifications")]
    public async Task<ActionResult<List<GroupMatchNotificationDto>>> GetNotifications([FromQuery] int userId, CancellationToken ct)
    {
        var rows = await db.GroupMatches
            .Include(m => m.Title)
            .Include(m => m.Group)
            .Join(db.GroupMembers.Where(gm => gm.UserId == userId),
                m => m.GroupId, gm => gm.GroupId,
                (m, gm) => new { Match = m, gm.MatchesSeenAt, gm.MatchesClearedAt })
            // Hide what "Temizle" cleared.
            .Where(x => x.MatchesClearedAt == null || x.Match.MatchedAt > x.MatchesClearedAt)
            .OrderByDescending(x => x.Match.MatchedAt)
            .Take(30)
            .ToListAsync(ct);

        return rows.Select(x => new GroupMatchNotificationDto(
            x.Match.Id,
            x.Match.GroupId,
            x.Match.Group!.Name,
            mapper.ToDto(x.Match.Title!),
            x.Match.MatchedAt,
            x.MatchesSeenAt.HasValue && x.Match.MatchedAt <= x.MatchesSeenAt.Value)).ToList();
    }

    [HttpPost("matches/mark-seen")]
    public async Task<IActionResult> MarkNotificationsSeen([FromQuery] int userId, CancellationToken ct)
    {
        var now = DateTime.UtcNow;
        await db.GroupMembers
            .Where(m => m.UserId == userId)
            .ExecuteUpdateAsync(s => s.SetProperty(m => m.MatchesSeenAt, now), ct);
        return NoContent();
    }

    /// <summary>
    /// "Temizle": hides the member's already-read match notifications — the
    /// cut-off is when they last read them, so newer unread ones stay.
    /// Matches themselves (group page, Takip) are untouched.
    /// </summary>
    [HttpPost("matches/clear")]
    public async Task<IActionResult> ClearReadNotifications([FromQuery] int userId, CancellationToken ct)
    {
        await db.GroupMembers
            .Where(m => m.UserId == userId && m.MatchesSeenAt != null)
            .ExecuteUpdateAsync(s => s.SetProperty(m => m.MatchesClearedAt, m => m.MatchesSeenAt), ct);
        return NoContent();
    }
}
