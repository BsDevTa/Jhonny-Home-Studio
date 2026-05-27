using JhonnyHomeStudio.Domain.Common;
using JhonnyHomeStudio.Domain.Enums;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class AppointmentStatusHistory : Entity
{
    public Guid AppointmentId { get; set; }
    public Appointment Appointment { get; set; } = null!;

    public AppointmentStatus Status { get; set; }

    public Guid? ChangedByUserId { get; set; }
    public User? ChangedByUser { get; set; }

    public string? Note { get; set; }
    public DateTime ChangedAtUtc { get; set; }
}