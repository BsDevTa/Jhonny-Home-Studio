namespace JhonnyHomeStudio.Application.Common.Dtos.ServiceCategories;

public sealed class UpdateServiceCategoryRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; }
}