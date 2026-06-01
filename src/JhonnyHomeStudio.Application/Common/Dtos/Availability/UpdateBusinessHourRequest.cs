namespace JhonnyHomeStudio.Application.Common.Dtos.Availability;

public sealed class UpdateBusinessHourRequest
{
    public int DayOfWeek { get; set; }
    public bool IsOpen { get; set; }
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }
    public int SlotIntervalMinutes { get; set; }
}
