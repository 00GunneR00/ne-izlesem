using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;

namespace Neizlesem.Api.Controllers;

[ApiController]
[Route("api/friends")]
public class FriendsController(AppDbContext db) : ControllerBase
{
    [HttpPost("requests")]
    public async Task<ActionResult<FriendshipResultDto>> SendRequest(SendFriendRequestRequest request, CancellationToken ct)
    {
        AppUser? target = null;
        if (!string.IsNullOrWhiteSpace(request.Username))
        {
            target = await db.Users.FirstOrDefaultAsync(u => u.Username == request.Username, ct);
        }
        else if (!string.IsNullOrWhiteSpace(request.FriendCode))
        {
            target = await db.Users.FirstOrDefaultAsync(u => u.FriendCode == request.FriendCode!.ToUpperInvariant(), ct);
        }

        if (target is null)
        {
            return NotFound("Kullanıcı bulunamadı.");
        }

        if (target.Id == request.RequesterId)
        {
            return BadRequest("Kendini arkadaş olarak ekleyemezsin.");
        }

        var existing = await db.Friendships.FirstOrDefaultAsync(
            f => (f.RequesterId == request.RequesterId && f.AddresseeId == target.Id) ||
                 (f.RequesterId == target.Id && f.AddresseeId == request.RequesterId), ct);

        if (existing is not null)
        {
            if (existing.Status == FriendshipStatus.Accepted)
            {
                return Ok(new FriendshipResultDto(existing.Id, existing.Status));
            }

            // The other side already sent a request — accept it instead of duplicating.
            if (existing.RequesterId == target.Id)
            {
                existing.Status = FriendshipStatus.Accepted;
                existing.RespondedAt = DateTime.UtcNow;
                await db.SaveChangesAsync(ct);
            }

            return Ok(new FriendshipResultDto(existing.Id, existing.Status));
        }

        var friendship = new Friendship { RequesterId = request.RequesterId, AddresseeId = target.Id };
        db.Friendships.Add(friendship);
        await db.SaveChangesAsync(ct);
        return Ok(new FriendshipResultDto(friendship.Id, friendship.Status));
    }

    [HttpGet("requests")]
    public async Task<ActionResult<List<FriendRequestDto>>> GetIncomingRequests([FromQuery] int userId, CancellationToken ct)
    {
        var requests = await db.Friendships
            .Include(f => f.Requester)
            .Where(f => f.AddresseeId == userId && f.Status == FriendshipStatus.Pending)
            .OrderByDescending(f => f.CreatedAt)
            .Select(f => new FriendRequestDto(f.Id, f.RequesterId, f.Requester!.DisplayName, f.Requester!.Username, f.CreatedAt, f.SeenByAddressee))
            .ToListAsync(ct);
        return requests;
    }

    [HttpPost("requests/mark-seen")]
    public async Task<IActionResult> MarkRequestsSeen([FromQuery] int userId, CancellationToken ct)
    {
        await db.Friendships
            .Where(f => f.AddresseeId == userId && f.Status == FriendshipStatus.Pending && !f.SeenByAddressee)
            .ExecuteUpdateAsync(s => s.SetProperty(f => f.SeenByAddressee, true), ct);
        return NoContent();
    }

    [HttpPost("requests/{id:int}/accept")]
    public async Task<IActionResult> Accept(int id, [FromQuery] int userId, CancellationToken ct)
    {
        var friendship = await db.Friendships.FirstOrDefaultAsync(f => f.Id == id && f.AddresseeId == userId, ct);
        if (friendship is null)
        {
            return NotFound();
        }

        friendship.Status = FriendshipStatus.Accepted;
        friendship.RespondedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpPost("requests/{id:int}/decline")]
    public async Task<IActionResult> Decline(int id, [FromQuery] int userId, CancellationToken ct)
    {
        var friendship = await db.Friendships.FirstOrDefaultAsync(f => f.Id == id && f.AddresseeId == userId, ct);
        if (friendship is null)
        {
            return NotFound();
        }

        db.Friendships.Remove(friendship);
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpGet]
    public async Task<ActionResult<List<FriendDto>>> GetFriends([FromQuery] int userId, CancellationToken ct)
    {
        var friendships = await db.Friendships
            .Include(f => f.Requester)
            .Include(f => f.Addressee)
            .Where(f => f.Status == FriendshipStatus.Accepted && (f.RequesterId == userId || f.AddresseeId == userId))
            .ToListAsync(ct);

        return friendships.Select(f =>
        {
            var other = f.RequesterId == userId ? f.Addressee! : f.Requester!;
            return new FriendDto(f.Id, other.Id, other.DisplayName, other.Username);
        }).ToList();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> RemoveFriend(int id, [FromQuery] int userId, CancellationToken ct)
    {
        var friendship = await db.Friendships.FirstOrDefaultAsync(
            f => f.Id == id && (f.RequesterId == userId || f.AddresseeId == userId), ct);
        if (friendship is null)
        {
            return NotFound();
        }

        db.Friendships.Remove(friendship);
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    /// <summary>Accepted friend user ids for the given user — used by FeedController.</summary>
    internal static async Task<List<int>> GetFriendIdsAsync(AppDbContext db, int userId, CancellationToken ct)
    {
        var friendships = await db.Friendships
            .Where(f => f.Status == FriendshipStatus.Accepted && (f.RequesterId == userId || f.AddresseeId == userId))
            .ToListAsync(ct);
        return friendships.Select(f => f.RequesterId == userId ? f.AddresseeId : f.RequesterId).ToList();
    }
}
