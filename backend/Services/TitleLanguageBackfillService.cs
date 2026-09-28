using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Services;

/// <summary>
/// On startup, re-fetches cached titles that were stored in a different TMDB
/// language than the configured one, so library/feed/suggestion cards (which
/// read the cache directly) switch language too. Throttled to stay well under
/// TMDB's rate limit; rows that fail are retried on the next start.
/// </summary>
public class TitleLanguageBackfillService(
    IServiceScopeFactory scopeFactory,
    TmdbOptions options,
    ILogger<TitleLanguageBackfillService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        try
        {
            using var scope = scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var cache = scope.ServiceProvider.GetRequiredService<TitleCacheService>();

            var stale = await db.Titles
                .Where(t => t.Language == null || t.Language != options.Language)
                .ToListAsync(ct);
            if (stale.Count == 0)
            {
                return;
            }

            logger.LogInformation("Refreshing {Count} cached titles to {Language}", stale.Count, options.Language);
            var refreshed = 0;
            foreach (var title in stale)
            {
                if (await cache.TryRefreshAsync(title, ct))
                {
                    refreshed++;
                }
                await Task.Delay(250, ct);
            }
            logger.LogInformation("Refreshed {Refreshed}/{Count} cached titles", refreshed, stale.Count);
        }
        catch (OperationCanceledException)
        {
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Cached title language backfill failed");
        }
    }
}
