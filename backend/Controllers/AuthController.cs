using System.Net;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services.Auth;

namespace Neizlesem.Api.Controllers;

/// <summary>
/// Sign-up / sign-in (email + password → JWT), and account deletion — in the
/// app (<c>DELETE /api/auth/account</c>) and on the web page Google Play
/// requires (<c>/hesap-silme</c>).
/// </summary>
[ApiController]
[Route("api/auth")]
public partial class AuthController(
    AppDbContext db,
    TokenService tokens,
    IPasswordHasher<AppUser> hasher,
    AccountDeletionService deletion) : ControllerBase
{
    private const string FriendCodeAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private const int MinPasswordLength = 8;

    [GeneratedRegex(@"^[^@\s]+@[^@\s]+\.[^@\s]+$")]
    private static partial Regex EmailPattern();

    [GeneratedRegex("^[a-z0-9_.]{3,20}$")]
    private static partial Regex UsernamePattern();

    [AllowAnonymous]
    [EnableRateLimiting("auth")]
    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request, CancellationToken ct)
    {
        var email = NormalizeEmail(request.Email);
        var username = request.Username.Trim().ToLowerInvariant();
        var displayName = request.DisplayName.Trim();

        if (!EmailPattern().IsMatch(email))
        {
            return Error(HttpStatusCode.BadRequest, "invalid_email", "Geçerli bir e-posta adresi gir.");
        }
        if (request.Password.Length < MinPasswordLength)
        {
            return Error(HttpStatusCode.BadRequest, "weak_password", $"Şifre en az {MinPasswordLength} karakter olmalı.");
        }
        if (!UsernamePattern().IsMatch(username))
        {
            return Error(HttpStatusCode.BadRequest, "invalid_username",
                "Kullanıcı adı 3–20 karakter olmalı; harf, rakam, _ ve . kullanabilirsin.");
        }
        if (displayName.Length is 0 or > 40)
        {
            return Error(HttpStatusCode.BadRequest, "invalid_name", "Adın 1–40 karakter olmalı.");
        }
        if (await db.Users.AnyAsync(u => u.Email.ToLower() == email, ct))
        {
            return Error(HttpStatusCode.Conflict, "email_taken", "Bu e-posta ile zaten bir hesap var. Giriş yapmayı dene.");
        }
        if (await db.Users.AnyAsync(u => u.Username == username, ct))
        {
            return Error(HttpStatusCode.Conflict, "username_taken", "Bu kullanıcı adı alınmış.");
        }

        var user = new AppUser
        {
            Email = email,
            DisplayName = displayName,
            Username = username,
            FriendCode = await GenerateFriendCodeAsync(ct),
        };
        user.PasswordHash = hasher.HashPassword(user, request.Password);
        db.Users.Add(user);
        await db.SaveChangesAsync(ct);
        return new AuthResponse(tokens.CreateToken(user), UsersController.ToDto(user));
    }

    /// <summary>
    /// Accounts from before passwords existed have none: login answers
    /// 409 <c>password_not_set</c> and the app offers <see cref="SetInitialPassword"/>.
    /// </summary>
    [AllowAnonymous]
    [EnableRateLimiting("auth")]
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest request, CancellationToken ct)
    {
        var email = NormalizeEmail(request.Email);
        var user = await db.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == email, ct);
        if (user is { PasswordHash: null })
        {
            return Error(HttpStatusCode.Conflict, "password_not_set", "Bu hesap için henüz şifre belirlenmemiş.");
        }
        if (user is null || !Verify(user, request.Password))
        {
            return Error(HttpStatusCode.Unauthorized, "invalid_credentials", "E-posta veya şifre hatalı.");
        }
        return new AuthResponse(tokens.CreateToken(user), UsersController.ToDto(user));
    }

    /// <summary>One-time: give a pre-password account its first password and sign in.</summary>
    [AllowAnonymous]
    [EnableRateLimiting("auth")]
    [HttpPost("set-password")]
    public async Task<ActionResult<AuthResponse>> SetInitialPassword(LoginRequest request, CancellationToken ct)
    {
        if (request.Password.Length < MinPasswordLength)
        {
            return Error(HttpStatusCode.BadRequest, "weak_password", $"Şifre en az {MinPasswordLength} karakter olmalı.");
        }
        var email = NormalizeEmail(request.Email);
        var user = await db.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == email && u.PasswordHash == null, ct);
        if (user is null)
        {
            return Error(HttpStatusCode.Conflict, "not_allowed", "Bu hesabın şifresi zaten var; giriş yap.");
        }
        user.PasswordHash = hasher.HashPassword(user, request.Password);
        await db.SaveChangesAsync(ct);
        return new AuthResponse(tokens.CreateToken(user), UsersController.ToDto(user));
    }

    /// <summary>The signed-in user (checks a stored token on app start).</summary>
    [HttpGet("me")]
    public async Task<ActionResult<UserDto>> Me(CancellationToken ct)
    {
        var user = await db.Users.FindAsync([User.GetUserId()], ct);
        return user is null ? Unauthorized() : UsersController.ToDto(user);
    }

    /// <summary>"Hesabımı sil" — password re-entry required; deletes everything.</summary>
    [HttpDelete("account")]
    public async Task<IActionResult> DeleteAccount(DeleteAccountRequest request, CancellationToken ct)
    {
        var user = await db.Users.FindAsync([User.GetUserId()], ct);
        if (user is null)
        {
            return Unauthorized();
        }
        if (!Verify(user, request.Password))
        {
            return Error(HttpStatusCode.Unauthorized, "invalid_credentials", "Şifre hatalı.");
        }
        await deletion.DeleteAsync(user.Id, ct);
        return NoContent();
    }

    // ---- Web account-deletion page (Google Play "delete account" URL) ----

    [AllowAnonymous]
    [HttpGet("/hesap-silme")]
    public ContentResult DeletionPage() => Html(DeletionForm(null));

    [AllowAnonymous]
    [EnableRateLimiting("auth")]
    [HttpPost("/hesap-silme")]
    [Consumes("application/x-www-form-urlencoded")]
    public async Task<ContentResult> DeletionPageSubmit([FromForm] string email, [FromForm] string password, CancellationToken ct)
    {
        var normalized = NormalizeEmail(email ?? string.Empty);
        var user = await db.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == normalized, ct);
        if (user is null || !Verify(user, password ?? string.Empty))
        {
            return Html(DeletionForm("E-posta veya şifre hatalı."));
        }
        await deletion.DeleteAsync(user.Id, ct);
        return Html(Page("Hesabın silindi",
            "<p>Ne İzlesem hesabın ve ona bağlı tüm veriler (kütüphane, listeler, yorumlar, " +
            "arkadaşlıklar, gruplar, planlar) kalıcı olarak silindi.</p>"));
    }

    private bool Verify(AppUser user, string password) =>
        user.PasswordHash is not null
        && hasher.VerifyHashedPassword(user, user.PasswordHash, password) != PasswordVerificationResult.Failed;

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();

    private ObjectResult Error(HttpStatusCode status, string code, string message) =>
        StatusCode((int)status, new AuthError(code, message));

    private async Task<string> GenerateFriendCodeAsync(CancellationToken ct)
    {
        for (var attempt = 0; attempt < 10; attempt++)
        {
            var code = new string(Enumerable.Range(0, 7)
                .Select(_ => FriendCodeAlphabet[Random.Shared.Next(FriendCodeAlphabet.Length)]).ToArray());
            if (!await db.Users.AnyAsync(u => u.FriendCode == code, ct))
            {
                return code;
            }
        }
        throw new InvalidOperationException("Could not generate a unique friend code.");
    }

    private static ContentResult Html(string html) =>
        new() { Content = html, ContentType = "text/html; charset=utf-8" };

    private static string DeletionForm(string? error) => Page("Hesabını sil",
        "<p>Ne İzlesem hesabını ve ona bağlı tüm verileri kalıcı olarak silmek için " +
        "e-posta adresini ve şifreni gir. Bu işlem geri alınamaz. Uygulamadan da " +
        "<b>Profil → Hesabımı sil</b> ile yapabilirsin.</p>" +
        (error is null ? "" : $"<p class=\"err\">{WebUtility.HtmlEncode(error)}</p>") +
        "<form method=\"post\">" +
        "<input name=\"email\" type=\"email\" placeholder=\"E-posta\" required>" +
        "<input name=\"password\" type=\"password\" placeholder=\"Şifre\" required>" +
        "<button type=\"submit\">Hesabımı kalıcı olarak sil</button></form>");

    private static string Page(string title, string body) =>
        "<!doctype html><html lang=\"tr\"><head><meta charset=\"utf-8\">" +
        "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">" +
        $"<title>{title} · Ne İzlesem?</title><style>" +
        "body{font-family:system-ui,sans-serif;background:#0a0a0a;color:#ffdad5;display:flex;" +
        "justify-content:center;padding:32px 16px;margin:0}main{max-width:420px;width:100%}" +
        "h1{color:#e50914}p{line-height:1.5}.err{color:#ffb4aa}input,button{display:block;width:100%;" +
        "box-sizing:border-box;margin:10px 0;padding:12px;border-radius:10px;border:1px solid #462f2c;" +
        "background:#2e1a18;color:#ffdad5;font-size:16px}button{background:#e50914;border:0;color:#fff;" +
        "font-weight:600;cursor:pointer}</style></head>" +
        $"<body><main><h1>{title}</h1>{body}</main></body></html>";
}
