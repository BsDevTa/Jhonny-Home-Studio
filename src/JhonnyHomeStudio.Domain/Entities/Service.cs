using JhonnyHomeStudio.Domain.Common;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class Service : Entity
{
    public Guid ServiceCategoryId { get; set; }
    public ServiceCategory ServiceCategory { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int EstimatedDurationMinutes { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    public ICollection<Story> Stories { get; set; } = new List<Story>();
}