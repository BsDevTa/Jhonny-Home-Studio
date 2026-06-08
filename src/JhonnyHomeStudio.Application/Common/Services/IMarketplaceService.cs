using JhonnyHomeStudio.Application.Common.Dtos.Marketplace;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface IMarketplaceService
{
    Task<IEnumerable<ProductCategoryResponse>> GetCategoriesAsync(bool includeInactive);
    Task<ProductCategoryResponse?> GetCategoryByIdAsync(Guid id, bool includeInactive);
    Task<ProductCategoryResponse> CreateCategoryAsync(UpsertProductCategoryRequest request);
    Task<ProductCategoryResponse> UpdateCategoryAsync(Guid id, UpsertProductCategoryRequest request);
    Task<ProductCategoryResponse?> ToggleCategoryAsync(Guid id);
    Task<bool> DeleteCategoryAsync(Guid id);

    Task<IEnumerable<ProductResponse>> GetProductsAsync(bool includeInactive, Guid? categoryId = null, bool? featured = null, string? search = null);
    Task<ProductResponse?> GetProductByIdAsync(Guid id, bool includeInactive);
    Task<ProductResponse> CreateProductAsync(UpsertProductRequest request);
    Task<ProductResponse> UpdateProductAsync(Guid id, UpsertProductRequest request);
    Task<ProductResponse?> ToggleProductAsync(Guid id);
    Task<bool> DeleteProductAsync(Guid id);
}
