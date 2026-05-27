namespace JhonnyHomeStudio.Application.Common.Dtos.Appointments;

public sealed class AppointmentResponse
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public Guid ServiceId { get; set; }
    public string ServiceName { get; set; } = string.Empty;
    public Guid AddressId { get; set; }
    public string AddressText { get; set; } = string.Empty;
    public DateTime ScheduledAt { get; set; }
    public decimal ServicePriceSnapshot { get; set; }
    public int EstimatedDurationMinutesSnapshot { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? CustomerNotes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}