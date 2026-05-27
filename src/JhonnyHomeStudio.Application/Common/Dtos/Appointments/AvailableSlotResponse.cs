namespace JhonnyHomeStudio.Application.Common.Dtos.Appointments;

public sealed class AvailableSlotResponse
{
    public DateTime StartAt { get; set; }
    public DateTime EndAt { get; set; }
    public bool IsAvailable { get; set; }
}