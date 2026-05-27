using JhonnyHomeStudio.Domain.Common;
using JhonnyHomeStudio.Domain.Enums;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class Appointment : Entity
{
    public Guid CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;

    public Guid ServiceId { get; set; }
    public Service Service { get; set; } = null!;

    public Guid AddressId { get; set; }
    public Address Address { get; set; } = null!;

    public DateTime ScheduledAtUtc { get; set; }
    public decimal ServicePriceSnapshot { get; set; }
    public int EstimatedDurationMinutesSnapshot { get; set; }
    public AppointmentStatus Status { get; set; } = AppointmentStatus.Pending;
    public string? CustomerNotes { get; set; }

    public ICollection<AppointmentStatusHistory> StatusHistory { get; set; } = new List<AppointmentStatusHistory>();
}