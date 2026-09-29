using System.Text;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services.Auth;
using Neizlesem.Api.Data;
using Neizlesem.Api.Services;
using Neizlesem.Api.Services.Tmdb;

var builder = WebApplication.CreateBuilder(args);

// ---- Auth: JWT bearer tokens; every endpoint requires one unless it's
// [AllowAnonymous] (sign-up / sign-in / the web deletion page). ----
var jwt = builder.Configuration.GetSection(JwtOptions.SectionName).Get<JwtOptions>() ?? new JwtOptions();
if (Encoding.UTF8.GetByteCount(jwt.Key) < 32)
{
    throw new InvalidOperationException(
        "Jwt:Key must be set to at least 32 bytes (appsettings.Development.json locally; " +
        "the Jwt__Key environment variable in production).");
}
builder.Services.AddSingleton(jwt);
builder.Services.AddSingleton<TokenService>();
builder.Services.AddSingleton<IPasswordHasher<AppUser>, PasswordHasher<AppUser>>();
builder.Services.AddScoped<AccountDeletionService>();

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.MapInboundClaims = false; // keep "sub" as "sub"
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidIssuer = jwt.Issuer,
            ValidAudience = jwt.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Key)),
            ClockSkew = TimeSpan.FromMinutes(2),
        };
    });
builder.Services.AddAuthorization();

// Sign-in / sign-up attempts per IP (brute-force brake).
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    o.AddPolicy("auth", http => RateLimitPartition.GetFixedWindowLimiter(
        http.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1) }));
});

builder.Services.AddControllers(o =>
    {
        o.Filters.Add(new AuthorizeFilter(new AuthorizationPolicyBuilder().RequireAuthenticatedUser().Build()));
        // The acting user always comes from the token, never the request.
        o.Filters.Add<CurrentUserFilter>();
    })
    .AddJsonOptions(o => o.JsonSerializerOptions.Converters.Add(
        new System.Text.Json.Serialization.JsonStringEnumConverter()));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("Default")));

var tmdbOptions = builder.Configuration.GetSection(TmdbOptions.SectionName).Get<TmdbOptions>()
    ?? new TmdbOptions();
builder.Services.AddSingleton(tmdbOptions);
builder.Services.AddTransient<TmdbApiKeyHandler>();

builder.Services.AddHttpClient<ITmdbService, TmdbService>(client =>
{
    client.BaseAddress = new Uri(tmdbOptions.BaseUrl);
}).AddHttpMessageHandler<TmdbApiKeyHandler>();

builder.Services.AddScoped<TitleMapper>();
builder.Services.AddScoped<TitleCacheService>();
builder.Services.AddScoped<SwipeDeckService>();
builder.Services.AddScoped<GroupSuggestionMatcher>();
builder.Services.AddHostedService<TitleLanguageBackfillService>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("Mobile", policy => policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("Mobile");
app.UseHttpsRedirection();
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
