namespace JhonnyHomeStudio.Application.Common.Dtos.Availability;

public sealed class UpsertBlockedDateRequest
{
    public DateOnly Date { get; set; }
    public string Reason { get; set; } = string.Empty;
    public bool IsFullDay { get; set; }
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }
}
