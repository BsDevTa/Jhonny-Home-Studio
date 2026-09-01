namespace JhonnyHomeStudio.Application.Common.Dtos.Marketplace;

public sealed class ProductImageResponse
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public int DisplayOrder { get; set; }
    public bool IsMain { get; set; }
    public DateTime CreatedAt { get; set; }
}

public sealed class ProductResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? ShortDescription { get; set; }
    public decimal Price { get; set; }
    public decimal? PromotionalPrice { get; set; }
    public string? MainImageUrl { get; set; }
    public bool IsActive { get; set; }
    public bool IsFeatured { get; set; }
    public int DisplayOrder { get; set; }
    public int? StockQuantity { get; set; }
    public IEnumerable<ProductImageResponse> Images { get; set; } = Array.Empty<ProductImageResponse>();
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public sealed class UpsertProductRequest
{
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
    public bool RemoveImage { get; set; }
    public IEnumerable<UpsertProductImageRequest> Images { get; set; } = Array.Empty<UpsertProductImageRequest>();
}

public sealed class UpsertProductImageRequest
{
    public string ImageUrl { get; set; } = string.Empty;
    public int DisplayOrder { get; set; }
    public bool IsMain { get; set; }
}
