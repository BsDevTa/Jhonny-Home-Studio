namespace JhonnyHomeStudio.Application.Common.Dtos.Services;

public sealed class ServiceResponse
{
    public Guid Id { get; set; }
    public Guid ServiceCategoryId { get; set; }
    public string ServiceCategoryName { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int EstimatedDurationMinutes { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}