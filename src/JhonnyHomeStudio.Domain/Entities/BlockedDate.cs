using JhonnyHomeStudio.Domain.Common;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class BlockedDate : Entity
{
    public DateOnly Date { get; set; }
    public string Reason { get; set; } = string.Empty;
    public bool IsFullDay { get; set; }
    public TimeOnly? StartTime { get; set; }
    public TimeOnly? EndTime { get; set; }
}
