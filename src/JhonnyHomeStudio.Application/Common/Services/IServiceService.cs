using JhonnyHomeStudio.Application.Common.Dtos.Services;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface IServiceService
{
    Task<IEnumerable<ServiceResponse>> GetAllAsync();
    Task<IEnumerable<ServiceResponse>> GetActiveAsync();
    Task<ServiceResponse?> GetByIdAsync(Guid id);
    Task<ServiceResponse> CreateAsync(CreateServiceRequest request);
    Task<ServiceResponse> UpdateAsync(Guid id, UpdateServiceRequest request);
    Task<bool> DeleteAsync(Guid id);
    Task<bool> ActivateAsync(Guid id);
    Task<bool> DeactivateAsync(Guid id);
}
