namespace JhonnyHomeStudio.Application.Common.Dtos.Availability;

public sealed class BlockedDateResponse
{
    public Guid Id { get; set; }
    public DateOnly Date { get; set; }
    public string Reason { get; set; } = string.Empty;
    public bool IsFullDay { get; set; }
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
