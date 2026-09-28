namespace Neizlesem.Api.Models;

/// <summary>A user-made collection ("En iyi gerilimler", "Sevgilimle izlenecekler").</summary>
public class UserList
{
    public int Id { get; set; }
    public int OwnerId { get; set; }
    public AppUser? Owner { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }

    /// <summary>Visible to the owner's friends (Sosyal → Listem); otherwise private.</summary>
    public bool IsShared { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public List<UserListItem> Items { get; set; } = new();
}

public class UserListItem
{
    public int Id { get; set; }
    public int ListId { get; set; }
    public UserList? List { get; set; }
    public int TitleId { get; set; }
    public Title? Title { get; set; }
    public DateTime AddedAt { get; set; } = DateTime.UtcNow;
}
