namespace JhonnyHomeStudio.Application.Common.Dtos.Loyalty;

public sealed class LoyaltyResponse
{
    public Guid CustomerId { get; set; }
    public int Points { get; set; }
    public string Level { get; set; } = string.Empty;
    public string? NextLevel { get; set; }
    public int PointsToNextLevel { get; set; }
    public IReadOnlyCollection<string> Benefits { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<LoyaltyTransactionResponse> RecentTransactions { get; set; } = Array.Empty<LoyaltyTransactionResponse>();
}
