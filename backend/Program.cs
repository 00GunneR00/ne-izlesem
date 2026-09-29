using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.Services;
using Neizlesem.Api.Services.Tmdb;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers()
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
app.UseAuthorization();
app.MapControllers();

app.Run();
