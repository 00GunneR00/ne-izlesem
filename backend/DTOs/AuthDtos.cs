namespace Neizlesem.Api.DTOs;

public record RegisterRequest(string Email, string Password, string DisplayName, string Username);

public record LoginRequest(string Email, string Password);

/// <summary>Token for the Authorization header plus the signed-in user.</summary>
public record AuthResponse(string Token, UserDto User);

/// <summary>Password re-entry confirms "Hesabımı sil".</summary>
public record DeleteAccountRequest(string Password);

/// <summary>Machine-readable error, e.g. "password_not_set" (old account → set a password).</summary>
public record AuthError(string Code, string Message);
