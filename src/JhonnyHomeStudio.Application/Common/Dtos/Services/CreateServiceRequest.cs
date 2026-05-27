namespace JhonnyHomeStudio.Application.Common.Dtos.Services;

public sealed class CreateServiceRequest
{
    public Guid ServiceCategoryId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int EstimatedDurationMinutes { get; set; }
    public string? ImageUrl { get; set; }
}