using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Controllers;

/// <summary>
/// User-made collections (Sosyal → Listem). Owners see and edit their own
/// lists; friends can view lists the owner marked as shared.
/// </summary>
[ApiController]
[Route("api/lists")]
public class ListsController(AppDbContext db, TitleCacheService titleCache, TitleMapper mapper) : ControllerBase
{
    private const int MaxNameLength = 60;
    private const int MaxDescriptionLength = 200;
    private const int PreviewCount = 4;

    [HttpGet("mine")]
    public async Task<ActionResult<List<UserListSummaryDto>>> GetMine([FromQuery] int userId, CancellationToken ct)
    {
        var lists = await ListsQuery()
            .Where(l => l.OwnerId == userId)
            .OrderByDescending(l => l.UpdatedAt)
            .ToListAsync(ct);
        return lists.Select(ToSummary).ToList();
    }

    /// <summary>Lists friends chose to share, most recently updated first.</summary>
    [HttpGet("friends")]
    public async Task<ActionResult<List<UserListSummaryDto>>> GetFriends([FromQuery] int userId, CancellationToken ct)
    {
        var friendIds = await FriendsController.GetFriendIdsAsync(db, userId, ct);
        var lists = await ListsQuery()
            .Where(l => l.IsShared && friendIds.Contains(l.OwnerId))
            .OrderByDescending(l => l.UpdatedAt)
            .Take(50)
            .ToListAsync(ct);
        return lists.Select(ToSummary).ToList();
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<UserListDetailDto>> Get(int id, [FromQuery] int userId, CancellationToken ct)
    {
        var list = await ListsQuery().FirstOrDefaultAsync(l => l.Id == id, ct);
        if (list is null || !await CanViewAsync(list, userId, ct))
        {
            return NotFound();
        }
        return new UserListDetailDto(
            ToSummary(list),
            list.Items
                .OrderByDescending(i => i.AddedAt)
                .Select(i => new UserListItemDto(mapper.ToDto(i.Title!), i.AddedAt))
                .ToList());
    }

    /// <summary>Ids of the user's own lists that contain this title (for the "Listeye Ekle" sheet).</summary>
    [HttpGet("containing")]
    public async Task<ActionResult<List<int>>> GetContaining(
        [FromQuery] int userId, [FromQuery] int tmdbId, [FromQuery] MediaType mediaType, CancellationToken ct)
    {
        return await db.UserListItems
            .Where(i => i.List!.OwnerId == userId && i.Title!.TmdbId == tmdbId && i.Title.MediaType == mediaType)
            .Select(i => i.ListId)
            .ToListAsync(ct);
    }

    [HttpPost]
    public async Task<ActionResult<UserListSummaryDto>> Create(SaveUserListRequest request, CancellationToken ct)
    {
        if (Validate(request) is { } error)
        {
            return BadRequest(error);
        }
        if (!await db.Users.AnyAsync(u => u.Id == request.UserId, ct))
        {
            return NotFound("User not found.");
        }

        var list = new UserList
        {
            OwnerId = request.UserId,
            Name = request.Name.Trim(),
            Description = Clean(request.Description),
            IsShared = request.IsShared,
        };
        db.UserLists.Add(list);
        await db.SaveChangesAsync(ct);
        return ToSummary(await ListsQuery().FirstAsync(l => l.Id == list.Id, ct));
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<UserListSummaryDto>> Update(int id, SaveUserListRequest request, CancellationToken ct)
    {
        if (Validate(request) is { } error)
        {
            return BadRequest(error);
        }
        var list = await ListsQuery().FirstOrDefaultAsync(l => l.Id == id && l.OwnerId == request.UserId, ct);
        if (list is null)
        {
            return NotFound();
        }

        list.Name = request.Name.Trim();
        list.Description = Clean(request.Description);
        list.IsShared = request.IsShared;
        list.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return ToSummary(list);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, [FromQuery] int userId, CancellationToken ct)
    {
        var deleted = await db.UserLists
            .Where(l => l.Id == id && l.OwnerId == userId)
            .ExecuteDeleteAsync(ct);
        return deleted == 0 ? NotFound() : NoContent();
    }

    [HttpPost("{id:int}/items")]
    public async Task<ActionResult<UserListSummaryDto>> AddItem(int id, AddListItemRequest request, CancellationToken ct)
    {
        var list = await db.UserLists.FirstOrDefaultAsync(l => l.Id == id && l.OwnerId == request.UserId, ct);
        if (list is null)
        {
            return NotFound();
        }
        var title = await titleCache.GetOrCacheAsync(request.TmdbId, request.MediaType, ct);
        if (title is null)
        {
            return NotFound("Title not found on TMDB.");
        }

        // Adding something already in the list is a no-op, not an error.
        if (!await db.UserListItems.AnyAsync(i => i.ListId == id && i.TitleId == title.Id, ct))
        {
            db.UserListItems.Add(new UserListItem { ListId = id, TitleId = title.Id });
            list.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
        }
        return ToSummary(await ListsQuery().FirstAsync(l => l.Id == id, ct));
    }

    [HttpDelete("{id:int}/items/{tmdbId:int}")]
    public async Task<IActionResult> RemoveItem(
        int id, int tmdbId, [FromQuery] MediaType mediaType, [FromQuery] int userId, CancellationToken ct)
    {
        var list = await db.UserLists.FirstOrDefaultAsync(l => l.Id == id && l.OwnerId == userId, ct);
        if (list is null)
        {
            return NotFound();
        }
        await db.UserListItems
            .Where(i => i.ListId == id && i.Title!.TmdbId == tmdbId && i.Title.MediaType == mediaType)
            .ExecuteDeleteAsync(ct);
        list.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    private IQueryable<UserList> ListsQuery() => db.UserLists
        .Include(l => l.Owner)
        .Include(l => l.Items).ThenInclude(i => i.Title);

    private async Task<bool> CanViewAsync(UserList list, int userId, CancellationToken ct)
    {
        if (list.OwnerId == userId)
        {
            return true;
        }
        return list.IsShared
               && (await FriendsController.GetFriendIdsAsync(db, userId, ct)).Contains(list.OwnerId);
    }

    private static string? Validate(SaveUserListRequest request)
    {
        var name = request.Name?.Trim() ?? string.Empty;
        if (name.Length == 0)
        {
            return "Liste adı boş olamaz.";
        }
        if (name.Length > MaxNameLength)
        {
            return $"Liste adı en fazla {MaxNameLength} karakter olabilir.";
        }
        if ((request.Description?.Trim().Length ?? 0) > MaxDescriptionLength)
        {
            return $"Açıklama en fazla {MaxDescriptionLength} karakter olabilir.";
        }
        return null;
    }

    private static string? Clean(string? text) =>
        string.IsNullOrWhiteSpace(text) ? null : text.Trim();

    private UserListSummaryDto ToSummary(UserList l) => new(
        l.Id,
        l.OwnerId,
        l.Owner!.DisplayName,
        l.Name,
        l.Description,
        l.IsShared,
        l.Items.Count,
        l.Items
            .OrderByDescending(i => i.AddedAt)
            .Select(i => mapper.ToDto(i.Title!).PosterUrl)
            .OfType<string>()
            .Take(PreviewCount)
            .ToList(),
        l.UpdatedAt);
}
