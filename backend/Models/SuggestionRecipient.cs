namespace Neizlesem.Api.Models;

public class SuggestionRecipient
{
    public int Id { get; set; }
    public int SuggestionId { get; set; }
    public Suggestion? Suggestion { get; set; }
    public int RecipientId { get; set; }
    public AppUser? Recipient { get; set; }
    public SuggestionStatus Status { get; set; } = SuggestionStatus.Pending;
    public DateTime? RespondedAt { get; set; }
    public bool SeenBySender { get; set; }
}
