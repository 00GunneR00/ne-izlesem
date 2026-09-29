using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services.Auth;

namespace Neizlesem.Api.Controllers;

/// <summary>
/// Profiles and friend lookup. Accounts are created and signed into via
/// <see cref="AuthController"/> (the old password-less create / by-email
/// login endpoints are gone).
/// </summary>
[ApiController]
[Route("api/users")]
public class UsersController(AppDbContext db) : ControllerBase
{
    /// <summary>Anyone's public profile; the email is only included for yourself.</summary>
    [HttpGet("{id:int}")]
    public async Task<ActionResult<UserDto>> GetById(int id, CancellationToken ct)
    {
        var user = await db.Users.FindAsync([id], ct);
        if (user is null)
        {
            return NotFound();
        }
        var dto = ToDto(user);
        return id == User.GetUserId() ? dto : dto with { Email = string.Empty };
    }

    [HttpGet("search")]
    public async Task<ActionResult<List<UserSummaryDto>>> Search([FromQuery] string query, [FromQuery] int excludeUserId, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return new List<UserSummaryDto>();
        }

        var results = await db.Users
            .Where(u => u.Id != excludeUserId && EF.Functions.ILike(u.Username, $"%{query}%"))
            .OrderBy(u => u.Username)
            .Take(20)
            .Select(u => new UserSummaryDto(u.Id, u.DisplayName, u.Username))
            .ToListAsync(ct);
        return results;
    }

    [HttpGet("by-code/{code}")]
    public async Task<ActionResult<UserSummaryDto>> GetByFriendCode(string code, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.FriendCode == code.ToUpperInvariant(), ct);
        return user is null ? NotFound() : new UserSummaryDto(user.Id, user.DisplayName, user.Username);
    }

    /// <summary>Only your own genres (the id in the path must be you).</summary>
    [HttpPut("{id:int}/genres")]
    public async Task<ActionResult<UserDto>> UpdatePreferredGenres(int id, UpdatePreferredGenresRequest request, CancellationToken ct)
    {
        if (id != User.GetUserId())
        {
            return Forbid();
        }
        var user = await db.Users.FindAsync([id], ct);
        if (user is null)
        {
            return NotFound();
        }

        user.PreferredGenreIds = request.GenreIds;
        await db.SaveChangesAsync(ct);
        return ToDto(user);
    }

    internal static UserDto ToDto(AppUser u) =>
        new(u.Id, u.Email, u.DisplayName, u.Username, u.FriendCode, u.PreferredGenreIds);
}
