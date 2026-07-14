using JhonnyHomeStudio.Application.Common.Dtos.Marketplace;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface IMarketplaceService
{
    Task<IEnumerable<ProductResponse>> GetProductsAsync(bool includeInactive, bool? featured = null, string? search = null);
    Task<ProductResponse?> GetProductByIdAsync(Guid id, bool includeInactive);
    Task<ProductResponse> CreateProductAsync(UpsertProductRequest request);
    Task<ProductResponse> UpdateProductAsync(Guid id, UpsertProductRequest request);
    Task<ProductResponse?> ToggleProductAsync(Guid id);
    Task<bool> DeleteProductAsync(Guid id);
}
