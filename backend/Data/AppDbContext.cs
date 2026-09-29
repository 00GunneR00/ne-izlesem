using Microsoft.EntityFrameworkCore;
using Neizlesem.Api.Models;

namespace Neizlesem.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<AppUser> Users => Set<AppUser>();
    public DbSet<Title> Titles => Set<Title>();
    public DbSet<LibraryEntry> LibraryEntries => Set<LibraryEntry>();
    public DbSet<SwipeInteraction> SwipeInteractions => Set<SwipeInteraction>();
    public DbSet<Friendship> Friendships => Set<Friendship>();
    public DbSet<TitleLike> TitleLikes => Set<TitleLike>();
    public DbSet<Comment> Comments => Set<Comment>();
    public DbSet<Group> Groups => Set<Group>();
    public DbSet<GroupMember> GroupMembers => Set<GroupMember>();
    public DbSet<GroupSwipe> GroupSwipes => Set<GroupSwipe>();
    public DbSet<GroupMatch> GroupMatches => Set<GroupMatch>();
    public DbSet<GroupMatchVote> GroupMatchVotes => Set<GroupMatchVote>();
    public DbSet<WatchPlan> WatchPlans => Set<WatchPlan>();
    public DbSet<PlanAttendee> PlanAttendees => Set<PlanAttendee>();
    public DbSet<UserList> UserLists => Set<UserList>();
    public DbSet<UserListItem> UserListItems => Set<UserListItem>();
    public DbSet<Suggestion> Suggestions => Set<Suggestion>();
    public DbSet<SuggestionRecipient> SuggestionRecipients => Set<SuggestionRecipient>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Title>()
            .HasIndex(t => new { t.TmdbId, t.MediaType })
            .IsUnique();

        modelBuilder.Entity<LibraryEntry>()
            .HasIndex(e => new { e.UserId, e.TitleId })
            .IsUnique();

        modelBuilder.Entity<SwipeInteraction>()
            .HasIndex(s => new { s.UserId, s.TitleId });

        modelBuilder.Entity<AppUser>()
            .HasIndex(u => u.Username)
            .IsUnique();

        modelBuilder.Entity<AppUser>()
            .HasIndex(u => u.FriendCode)
            .IsUnique();

        modelBuilder.Entity<Friendship>()
            .HasIndex(f => new { f.RequesterId, f.AddresseeId })
            .IsUnique();

        modelBuilder.Entity<TitleLike>()
            .HasIndex(l => new { l.UserId, l.TitleId })
            .IsUnique();

        modelBuilder.Entity<Comment>()
            .HasIndex(c => c.TitleId);

        modelBuilder.Entity<GroupMember>()
            .HasIndex(m => new { m.GroupId, m.UserId })
            .IsUnique();

        modelBuilder.Entity<GroupSwipe>()
            .HasIndex(s => new { s.GroupId, s.UserId, s.TitleId })
            .IsUnique();

        modelBuilder.Entity<GroupMatch>()
            .HasIndex(m => new { m.GroupId, m.TitleId })
            .IsUnique();

        modelBuilder.Entity<GroupMatchVote>()
            .HasIndex(v => new { v.GroupMatchId, v.UserId })
            .IsUnique();

        modelBuilder.Entity<GroupMatch>()
            .HasMany(m => m.Votes)
            .WithOne(v => v.GroupMatch)
            .HasForeignKey(v => v.GroupMatchId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<WatchPlan>()
            .HasMany(p => p.Attendees)
            .WithOne(a => a.Plan)
            .HasForeignKey(a => a.PlanId)
            .OnDelete(DeleteBehavior.Cascade);

        // A deleted group keeps its plans (attendees still want them), just
        // without the group label.
        modelBuilder.Entity<WatchPlan>()
            .HasOne(p => p.Group)
            .WithMany()
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<WatchPlan>()
            .HasIndex(p => p.ScheduledAt);

        modelBuilder.Entity<PlanAttendee>()
            .HasIndex(a => new { a.PlanId, a.UserId })
            .IsUnique();

        modelBuilder.Entity<UserList>()
            .HasMany(l => l.Items)
            .WithOne(i => i.List)
            .HasForeignKey(i => i.ListId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserList>()
            .HasIndex(l => l.OwnerId);

        modelBuilder.Entity<UserListItem>()
            .HasIndex(i => new { i.ListId, i.TitleId })
            .IsUnique();

        modelBuilder.Entity<SuggestionRecipient>()
            .HasIndex(r => new { r.RecipientId, r.Status });

        modelBuilder.Entity<Suggestion>()
            .HasOne(s => s.Group)
            .WithMany()
            .OnDelete(DeleteBehavior.SetNull);
    }
}
