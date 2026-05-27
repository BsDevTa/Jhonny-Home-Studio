using JhonnyHomeStudio.Application.Common.Dtos.Customers;

namespace JhonnyHomeStudio.Application.Common.Services;

public interface ICustomerService
{
    Task<CustomerProfileResponse> GetMyProfileAsync(Guid userId);
    Task<CustomerProfileResponse> UpdateMyProfileAsync(Guid userId, UpdateCustomerProfileRequest request);
    Task<IEnumerable<CustomerListResponse>> GetAllAsync();
    Task<CustomerProfileResponse?> GetByIdAsync(Guid customerId);
    Task<bool> ActivateAsync(Guid customerId);
    Task<bool> DeactivateAsync(Guid customerId);
}