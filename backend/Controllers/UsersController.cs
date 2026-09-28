using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;

namespace Neizlesem.Api.Controllers;

[ApiController]
[Route("api/users")]
public class UsersController(AppDbContext db) : ControllerBase
{
    private const string FriendCodeAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

    [HttpPost]
    public async Task<ActionResult<UserDto>> Create(CreateUserRequest request, CancellationToken ct)
    {
        var existing = await db.Users.FirstOrDefaultAsync(u => u.Email == request.Email, ct);
        if (existing is not null)
        {
            return ToDto(existing);
        }

        var usernameTaken = await db.Users.AnyAsync(u => u.Username == request.Username, ct);
        if (usernameTaken)
        {
            return Conflict("Bu kullanıcı adı zaten alınmış.");
        }

        var user = new AppUser
        {
            Email = request.Email,
            DisplayName = request.DisplayName,
            Username = request.Username,
            FriendCode = await GenerateFriendCodeAsync(ct),
        };
        db.Users.Add(user);
        await db.SaveChangesAsync(ct);
        return CreatedAtAction(nameof(GetById), new { id = user.Id }, ToDto(user));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<UserDto>> GetById(int id, CancellationToken ct)
    {
        var user = await db.Users.FindAsync([id], ct);
        return user is null ? NotFound() : ToDto(user);
    }

    /// <summary>Looks up an existing account by email without creating one — used for login.</summary>
    [HttpGet("by-email")]
    public async Task<ActionResult<UserDto>> GetByEmail([FromQuery] string email, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Email == email, ct);
        return user is null ? NotFound() : ToDto(user);
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

    [HttpPut("{id:int}/genres")]
    public async Task<ActionResult<UserDto>> UpdatePreferredGenres(int id, UpdatePreferredGenresRequest request, CancellationToken ct)
    {
        var user = await db.Users.FindAsync([id], ct);
        if (user is null)
        {
            return NotFound();
        }

        user.PreferredGenreIds = request.GenreIds;
        await db.SaveChangesAsync(ct);
        return ToDto(user);
    }

    private async Task<string> GenerateFriendCodeAsync(CancellationToken ct)
    {
        var random = Random.Shared;
        for (var attempt = 0; attempt < 10; attempt++)
        {
            var code = new string(Enumerable.Range(0, 7).Select(_ => FriendCodeAlphabet[random.Next(FriendCodeAlphabet.Length)]).ToArray());
            if (!await db.Users.AnyAsync(u => u.FriendCode == code, ct))
            {
                return code;
            }
        }

        throw new InvalidOperationException("Could not generate a unique friend code.");
    }

    private static UserDto ToDto(AppUser u) => new(u.Id, u.Email, u.DisplayName, u.Username, u.FriendCode, u.PreferredGenreIds);
}
