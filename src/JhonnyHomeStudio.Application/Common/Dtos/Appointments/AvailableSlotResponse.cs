namespace JhonnyHomeStudio.Application.Common.Dtos.Appointments;

public sealed class AvailableSlotResponse
{
    public string Name { get; set; } = string.Empty;
    public DateTime StartAt { get; set; }
    public DateTime EndAt { get; set; }
    public bool IsAvailable { get; set; }
}
