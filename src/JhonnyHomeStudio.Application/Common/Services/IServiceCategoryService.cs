using JhonnyHomeStudio.Application.Common.Dtos.ServiceCategories;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface IServiceCategoryService
{
    Task<IEnumerable<ServiceCategoryResponse>> GetAllAsync();
    Task<IEnumerable<ServiceCategoryResponse>> GetActiveAsync();
    Task<ServiceCategoryResponse?> GetByIdAsync(Guid id);
    Task<ServiceCategoryResponse> CreateAsync(CreateServiceCategoryRequest request);
    Task<ServiceCategoryResponse> UpdateAsync(Guid id, UpdateServiceCategoryRequest request);
    Task<bool> DeleteAsync(Guid id);
    Task<bool> ActivateAsync(Guid id);
    Task<bool> DeactivateAsync(Guid id);
}