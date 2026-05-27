using JhonnyHomeStudio.Domain.Common;
using JhonnyHomeStudio.Domain.Enums;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class Story : Entity
{
    public Guid CreatedByAdminUserId { get; set; }
    public AdminUser CreatedByAdminUser { get; set; } = null!;

    public Guid? ServiceId { get; set; }
    public Service? Service { get; set; }

    public string Title { get; set; } = string.Empty;
    public string ShortText { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? ActionButtonText { get; set; }
    public StoryActionType ActionType { get; set; } = StoryActionType.None;
    public string? ActionValue { get; set; }
    public DateTime StartsAtUtc { get; set; }
    public DateTime ExpiresAtUtc { get; set; }
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; }

    public ICollection<StoryView> Views { get; set; } = new List<StoryView>();
}