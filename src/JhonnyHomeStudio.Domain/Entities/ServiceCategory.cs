using JhonnyHomeStudio.Domain.Common;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class ServiceCategory : Entity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<Service> Services { get; set; } = new List<Service>();
}