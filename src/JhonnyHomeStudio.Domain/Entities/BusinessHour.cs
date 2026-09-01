using JhonnyHomeStudio.Domain.Common;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class BusinessHour : Entity
{
    public int DayOfWeek { get; set; }
    public bool IsOpen { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public int SlotIntervalMinutes { get; set; } = 60;
}
