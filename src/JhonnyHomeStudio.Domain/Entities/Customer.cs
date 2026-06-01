using JhonnyHomeStudio.Domain.Common;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class Customer : Entity
{
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public string? DocumentNumber { get; set; }
    public DateTime? BirthDate { get; set; }

    public ICollection<Address> Addresses { get; set; } = new List<Address>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    public ICollection<StoryView> StoryViews { get; set; } = new List<StoryView>();
    public CustomerLoyalty? Loyalty { get; set; }
    public ICollection<LoyaltyTransaction> LoyaltyTransactions { get; set; } = new List<LoyaltyTransaction>();
}
