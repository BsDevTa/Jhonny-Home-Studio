using JhonnyHomeStudio.Domain.Common;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class Product : Entity
{
    public Guid ProductCategoryId { get; set; }
    public ProductCategory ProductCategory { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? ShortDescription { get; set; }
    public decimal Price { get; set; }
    public decimal? PromotionalPrice { get; set; }
    public string? MainImageUrl { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsFeatured { get; set; }
    public int DisplayOrder { get; set; }
    public int? StockQuantity { get; set; }

    public ICollection<ProductImage> Images { get; set; } = new List<ProductImage>();
}
