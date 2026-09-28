using Microsoft.EntityFrameworkCore;
using Npgsql;
using Neizlesem.Api.Data;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Services;

/// <summary>Resolves a TMDB id + media type to our cached Title row, fetching from TMDB on first use.</summary>
public class TitleCacheService(AppDbContext db, ITmdbService tmdb, TitleMapper mapper, TmdbOptions options)
{
    public async Task<Title?> GetOrCacheAsync(int tmdbId, MediaType mediaType, CancellationToken ct = default)
    {
        var existing = await db.Titles
            .FirstOrDefaultAsync(t => t.TmdbId == tmdbId && t.MediaType == mediaType, ct);
        if (existing is not null)
        {
            if (existing.Language != options.Language)
            {
                await TryRefreshAsync(existing, ct);
            }
            return existing;
        }

        var fetched = await tmdb.GetDetailsAsync(mediaType, tmdbId, ct);
        if (fetched is null)
        {
            return null;
        }

        var entity = mapper.ToEntity(fetched, mediaType);
        db.Titles.Add(entity);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            // A concurrent request (e.g. the swipe + library calls a right swipe
            // fires together) cached the same title first — use that row instead.
            db.Entry(entity).State = EntityState.Detached;
            return await db.Titles
                .FirstAsync(t => t.TmdbId == tmdbId && t.MediaType == mediaType, ct);
        }
        return entity;
    }

    /// <summary>
    /// Re-fetches a cached row's metadata (e.g. after the TMDB language
    /// changed). Keeps the stale row on TMDB failure — the ids other tables
    /// point at never change, so user data is untouched either way.
    /// </summary>
    public async Task<bool> TryRefreshAsync(Title title, CancellationToken ct = default)
    {
        try
        {
            var fetched = await tmdb.GetDetailsAsync(title.MediaType, title.TmdbId, ct);
            if (fetched is null)
            {
                return false;
            }
            mapper.UpdateEntity(title, fetched);
            await db.SaveChangesAsync(ct);
            return true;
        }
        catch (HttpRequestException)
        {
            return false;
        }
    }
}
