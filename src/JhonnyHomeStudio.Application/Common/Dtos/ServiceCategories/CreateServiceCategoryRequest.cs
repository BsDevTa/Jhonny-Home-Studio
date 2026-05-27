namespace JhonnyHomeStudio.Application.Common.Dtos.ServiceCategories;

public sealed class CreateServiceCategoryRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
}