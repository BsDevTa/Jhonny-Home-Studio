using JhonnyHomeStudio.Domain.Common;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class LoyaltyTransaction : Entity
{
    public Guid CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;
    public Guid AppointmentId { get; set; }
    public Appointment Appointment { get; set; } = null!;
    public int Points { get; set; }
    public string Description { get; set; } = string.Empty;
}
