using JhonnyHomeStudio.Domain.Common;
using JhonnyHomeStudio.Domain.Enums;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class CustomerLoyalty : Entity
{
    public Guid CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;
    public int Points { get; set; }
    public LoyaltyLevel Level { get; set; } = LoyaltyLevel.Bronze;
}
