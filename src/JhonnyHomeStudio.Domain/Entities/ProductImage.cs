using JhonnyHomeStudio.Domain.Common;

namespace JhonnyHomeStudio.Domain.Entities;

public sealed class ProductImage : Entity
{
    public Guid ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public string ImageUrl { get; set; } = string.Empty;
    public int DisplayOrder { get; set; }
    public bool IsMain { get; set; }
}
