namespace JhonnyHomeStudio.Application.Common.Dtos.Loyalty;

public sealed class LoyaltyTransactionResponse
{
    public Guid Id { get; set; }
    public Guid AppointmentId { get; set; }
    public int Points { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
