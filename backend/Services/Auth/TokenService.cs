using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using Neizlesem.Api.Models;

namespace Neizlesem.Api.Services.Auth;

public class TokenService(JwtOptions options)
{
    public string CreateToken(AppUser user)
    {
        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(options.Key)),
            SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: options.Issuer,
            audience: options.Audience,
            claims: [new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString())],
            expires: DateTime.UtcNow.AddDays(options.ExpiryDays),
            signingCredentials: credentials);
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

public static class ClaimsPrincipalExtensions
{
    /// <summary>The signed-in user's id from the token's "sub" claim, or null.</summary>
    public static int? GetUserId(this ClaimsPrincipal user)
    {
        var sub = user.FindFirstValue(JwtRegisteredClaimNames.Sub)
                  ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.TryParse(sub, out var id) ? id : null;
    }
}
