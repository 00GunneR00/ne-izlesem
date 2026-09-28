namespace Neizlesem.Api.Models;

public class Friendship
{
    public int Id { get; set; }
    public int RequesterId { get; set; }
    public AppUser? Requester { get; set; }
    public int AddresseeId { get; set; }
    public AppUser? Addressee { get; set; }
    public FriendshipStatus Status { get; set; } = FriendshipStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? RespondedAt { get; set; }
    public bool SeenByAddressee { get; set; }
}
