using JhonnyHomeStudio.Domain.Common;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class StoryView : Entity
{
    public Guid StoryId { get; set; }
    public Story Story { get; set; } = null!;

    public Guid CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;

    public DateTime ViewedAtUtc { get; set; } = DateTime.UtcNow;
}