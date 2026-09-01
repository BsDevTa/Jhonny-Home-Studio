namespace JhonnyHomeStudio.Application.Common.Dtos.Stories;

public sealed class UpdateStoryRequest
{
    public string Title { get; set; } = string.Empty;
    public string? Subtitle { get; set; }
    public string? ImageUrl { get; set; }
    public bool RemoveImage { get; set; }
    public Guid? ServiceId { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
    public DateTime? StartsAt { get; set; }
    public DateTime? EndsAt { get; set; }
}
