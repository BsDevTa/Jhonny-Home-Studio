namespace JhonnyHomeStudio.Application.Common.Dtos.Appointments;

public sealed class AppointmentListResponse
{
    public Guid Id { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string? CustomerPhone { get; set; }
    public string ServiceName { get; set; } = string.Empty;
    public DateTime ScheduledAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal ServicePriceSnapshot { get; set; }
    public int EstimatedDurationMinutesSnapshot { get; set; }
}
