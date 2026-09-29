namespace Neizlesem.Api.Services.Auth;

public class JwtOptions
{
    public const string SectionName = "Jwt";

    /// <summary>HMAC-SHA256 signing key, at least 32 bytes. Set per environment; never commit a production key.</summary>
    public string Key { get; set; } = string.Empty;
    public string Issuer { get; set; } = "neizlesem-api";
    public string Audience { get; set; } = "neizlesem-app";

    /// <summary>Mobile sessions are long-lived; re-login after this.</summary>
    public int ExpiryDays { get; set; } = 60;
}
