using JhonnyHomeStudio.Domain.Common;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class AdminUser : Entity
{
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public string? Notes { get; set; }
}