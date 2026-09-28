using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Data;
using Neizlesem.Api.DTOs;
using Neizlesem.Api.Models;
using Neizlesem.Api.Services;
using Neizlesem.Api.Services.Tmdb;

namespace Neizlesem.Api.Controllers;

[ApiController]
[Route("api/comments")]
public class CommentsController(AppDbContext db, TitleCacheService titleCache, TitleMapper mapper) : ControllerBase
{
    private const int MaxLength = 500;

    [HttpPost]
    public async Task<ActionResult<CommentDto>> Create(CreateCommentRequest request, CancellationToken ct)
    {
        var text = request.Text.Trim();
        if (string.IsNullOrEmpty(text))
        {
            return BadRequest("Yorum boş olamaz.");
        }

        if (text.Length > MaxLength)
        {
            text = text[..MaxLength];
        }

        var title = await titleCache.GetOrCacheAsync(request.TmdbId, request.MediaType, ct);
        if (title is null)
        {
            return NotFound("Title not found on TMDB.");
        }

        var user = await db.Users.FindAsync([request.UserId], ct);
        if (user is null)
        {
            return NotFound("User not found.");
        }

        var comment = new Comment { UserId = request.UserId, TitleId = title.Id, Text = text };
        db.Comments.Add(comment);
        await db.SaveChangesAsync(ct);
        return ToDto(comment, user, title);
    }

    [HttpGet]
    public async Task<ActionResult<List<CommentDto>>> GetForTitle([FromQuery] int tmdbId, [FromQuery] MediaType mediaType, CancellationToken ct)
    {
        var comments = await db.Comments
            .Include(c => c.User)
            .Include(c => c.Title)
            .Where(c => c.Title!.TmdbId == tmdbId && c.Title.MediaType == mediaType)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync(ct);
        return comments.Select(c => ToDto(c, c.User!, c.Title!)).ToList();
    }

    private CommentDto ToDto(Comment c, AppUser user, Title title) =>
        new(c.Id, c.UserId, user.DisplayName, mapper.ToDto(title), c.Text, c.CreatedAt);
}
