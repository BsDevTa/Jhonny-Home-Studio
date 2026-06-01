namespace JhonnyHomeStudio.Application.Common.Dtos.Availability;

public sealed class BusinessHourResponse
{
    public Guid Id { get; set; }
    public int DayOfWeek { get; set; }
    public string DayName { get; set; } = string.Empty;
    public bool IsOpen { get; set; }
    public string StartTime { get; set; } = string.Empty;
    public string EndTime { get; set; } = string.Empty;
    public int SlotIntervalMinutes { get; set; }
}
