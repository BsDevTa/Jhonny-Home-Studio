namespace JhonnyHomeStudio.Application.Common.Dtos.Appointments;

public sealed class CreateAppointmentRequest
{
    public Guid ServiceId { get; set; }
    public Guid AddressId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public string? CustomerNotes { get; set; }
}